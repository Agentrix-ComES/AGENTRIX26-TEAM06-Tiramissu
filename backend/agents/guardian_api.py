"""
Guardian WebSocket API — two-mode real-time audio pipeline.

MODE 1: "translate"
    Flutter mic  →  audio chunks  →  Gemini STT+Translate
    Response: { mode, original_language, original_text, english_text }

MODE 2: "guardian"  (default)
    Flutter mic  →  audio chunks  →  Gemini STT+Translate  →  GuardianAgent
    Response: { mode, original_language, original_text, english_text,
                status, threat_message, action_suggested }

WebSocket URL:
    ws://host/api/guardian/stream                     ← guardian mode (default)
    ws://host/api/guardian/stream?mode=translate      ← translate only
    ws://host/api/guardian/stream?mode=guardian&context=Kandy+Sri+Lanka

Audio frame protocol (client → server):
    Binary frame         : raw audio bytes
    Text "base64:<data>" : base64-encoded audio
    Text "PING"          : keep-alive  → server replies {"type":"PONG"}
    Text "STOP"          : graceful disconnect

Query parameters:
    mode         : "translate" | "guardian"   (default: "guardian")
    audio_format : MIME type of the audio     (default: "audio/wav")
                   Flutter record plugin outputs:
                     Android/iOS → "audio/aac"
                     Web         → "audio/webm"
    context      : Location/situation hint for the Guardian LLM
                   e.g. "Tuk-tuk negotiation, Kandy, Sri Lanka"
"""

from __future__ import annotations

import asyncio
import base64
import logging
import os
from typing import Dict, Optional

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from fastapi.websockets import WebSocketState
from pydantic import BaseModel

from .guardian_agent import GuardianAlert, run_guardian_agent
from .guardian_stt import TranscriptionResult, transcribe_and_translate

logger = logging.getLogger(__name__)

guardian_router = APIRouter()

# ── Tuneable constants ────────────────────────────────────────────────────────

# Bytes to accumulate before sending to STT.
# 16 kHz / 16-bit mono: ~32 000 bytes ≈ 1 second
# Default 64 000 = ~2 seconds (shorter = more responsive)
BUFFER_FLUSH_BYTES: int = int(os.getenv("GUARDIAN_BUFFER_BYTES", 64_000))
PIPELINE_TIMEOUT_SECONDS: float = float(os.getenv("GUARDIAN_TIMEOUT_S", 20.0))


# ── Unified response schema ───────────────────────────────────────────────────


class GuardianResponse(BaseModel):
    """Unified response for both translate and guardian modes."""

    mode: str                        # "translate" | "guardian"
    original_language: str           # "Sinhala" | "Tamil" | "English" | "Unknown"
    original_text: str               # Verbatim transcription in original language
    english_text: str                # English translation

    # Guardian-mode fields (null in translate mode)
    status: Optional[str] = None            # "SAFE" | "WARNING" | "SCAM" | "LISTENING"
    threat_message: Optional[str] = None
    action_suggested: Optional[str] = None


# ── WebSocket manager ─────────────────────────────────────────────────────────


class WebSocketManager:
    """Manages active Guardian WebSocket connections."""

    def __init__(self) -> None:
        self._active: Dict[int, WebSocket] = {}

    async def connect(self, websocket: WebSocket) -> int:
        await websocket.accept()
        conn_id = id(websocket)
        self._active[conn_id] = websocket
        logger.info("Guardian WS connected [id=%d] total=%d", conn_id, len(self._active))
        return conn_id

    def disconnect(self, websocket: WebSocket) -> None:
        self._active.pop(id(websocket), None)
        logger.info("Guardian WS disconnected [id=%d] total=%d", id(websocket), len(self._active))

    async def send_json(self, websocket: WebSocket, payload: dict) -> None:
        if websocket.client_state != WebSocketState.CONNECTED:
            return
        try:
            await websocket.send_json(payload)
        except Exception as exc:  # noqa: BLE001
            logger.warning("WS send failed: %s", exc)

    @property
    def active_count(self) -> int:
        return len(self._active)


manager = WebSocketManager()


# ── WebSocket endpoint ────────────────────────────────────────────────────────


@guardian_router.websocket("/stream")
async def guardian_stream(
    websocket: WebSocket,
    mode: str = "guardian",
    context: str = "Tourist interaction, Sri Lanka",
    audio_format: str = "audio/wav",
) -> None:
    """Bidirectional Guardian WebSocket.

    Query params:
        mode         : "translate" or "guardian" (default: "guardian")
        context      : Situation context for scam detection LLM
        audio_format : MIME type of incoming audio (default: "audio/wav")
                       Set to "audio/aac" for Flutter mobile,
                       "audio/webm" for Flutter web.
    """
    await manager.connect(websocket)

    # Send handshake confirming mode and readiness
    await manager.send_json(websocket, {
        "type": "READY",
        "mode": mode,
        "message": (
            f"Guardian listening in [{mode.upper()}] mode. "
            "Supports Sinhala, Tamil, English."
        ),
    })

    audio_buffer = bytearray()

    try:
        while True:
            # ── Receive frame ─────────────────────────────────────────────────
            try:
                message = await asyncio.wait_for(
                    websocket.receive(),
                    timeout=PIPELINE_TIMEOUT_SECONDS + 10,
                )
            except asyncio.TimeoutError:
                audio_buffer.clear()
                continue

            if message.get("type") == "websocket.disconnect":
                break

            raw_bytes: bytes | None = message.get("bytes")
            raw_text: str | None = message.get("text")

            # ── Parse text control frames ─────────────────────────────────────
            if raw_text is not None:
                text_stripped = raw_text.strip()

                if text_stripped == "STOP":
                    logger.info("Guardian WS STOP received.")
                    break

                if text_stripped == "PING":
                    await manager.send_json(websocket, {"type": "PONG"})
                    continue

                if text_stripped == "FLUSH":
                    logger.info("Guardian WS FLUSH received.")
                    if len(audio_buffer) > 0:
                        chunk = bytes(audio_buffer)
                        audio_buffer.clear()
                        asyncio.create_task(
                            _process_chunk(
                                websocket=websocket,
                                audio_bytes=chunk,
                                mode=mode,
                                context=context,
                                audio_format=audio_format,
                            )
                        )
                    else:
                        await manager.send_json(websocket, {
                            "type": "ERROR", 
                            "message": "No audio captured. Check microphone."
                        })
                    continue

                if text_stripped.startswith("base64:"):
                    try:
                        raw_bytes = base64.b64decode(text_stripped[7:])
                    except Exception as exc:  # noqa: BLE001
                        logger.warning("Bad base64 frame: %s", exc)
                        continue
                else:
                    logger.debug("Unknown text frame ignored: %.80s", text_stripped)
                    continue
            if raw_bytes:
                audio_buffer.extend(raw_bytes)

            # ── Flush when buffer is large enough ─────────────────────────────
            if len(audio_buffer) >= BUFFER_FLUSH_BYTES:
                chunk = bytes(audio_buffer)
                audio_buffer.clear()

                # Fire-and-forget: keeps receive loop non-blocking
                asyncio.create_task(
                    _process_chunk(
                        websocket=websocket,
                        audio_bytes=chunk,
                        mode=mode,
                        context=context,
                        audio_format=audio_format,
                    )
                )

    except WebSocketDisconnect:
        logger.info("Guardian WS client disconnected.")
    except Exception as exc:  # noqa: BLE001
        logger.exception("Guardian WS unhandled error: %s", exc)
    finally:
        manager.disconnect(websocket)


# ── Pipeline task ─────────────────────────────────────────────────────────────


async def _process_chunk(
    websocket: WebSocket,
    audio_bytes: bytes,
    mode: str,
    context: str,
    audio_format: str,
) -> None:
    """Background task: STT → (optional) Agent → emit JSON response.

    Runs as an asyncio.Task — never blocks the WebSocket receive loop.
    """
    try:
        # ── Step 1: Gemini STT + Translation ─────────────────────────────────
        stt: TranscriptionResult = await asyncio.wait_for(
            transcribe_and_translate(audio_bytes, mime_type=audio_format),
            timeout=PIPELINE_TIMEOUT_SECONDS,
        )

        logger.info(
            "STT: lang=%s | original='%s...' | english='%s...'",
            stt.original_language,
            stt.original_text[:60],
            stt.english_text[:60],
        )

        # If nothing was transcribed, don't emit noise
        if not stt.original_text.strip():
            logger.debug("Empty transcription — skipping emit.")
            await manager.send_json(websocket, {
                "type": "ERROR",
                "message": "Couldn't hear anything clearly.",
            })
            return

        # ── Step 2a: Translate mode ───────────────────────────────────────────
        if mode == "translate":
            response = GuardianResponse(
                mode="translate",
                original_language=stt.original_language,
                original_text=stt.original_text,
                english_text=stt.english_text,
            )
            await manager.send_json(websocket, response.model_dump())
            return

        # ── Step 2b: Guardian mode — run scam detection on English text ───────
        alert: GuardianAlert = await asyncio.wait_for(
            run_guardian_agent(
                transcript=stt.english_text,
                context=context,
            ),
            timeout=PIPELINE_TIMEOUT_SECONDS,
        )

        response = GuardianResponse(
            mode="guardian",
            original_language=stt.original_language,
            original_text=stt.original_text,
            english_text=stt.english_text,
            status=alert.status,
            threat_message=alert.threat_message,
            action_suggested=alert.action_suggested,
        )
        await manager.send_json(websocket, response.model_dump())

    except asyncio.TimeoutError:
        logger.warning("Pipeline timed out — skipping chunk.")
        await manager.send_json(websocket, {
            "type": "ERROR",
            "message": "Processing timed out. Still listening...",
        })
    except Exception as exc:  # noqa: BLE001
        logger.exception("_process_chunk error: %s", exc)
        await manager.send_json(websocket, {
            "type": "ERROR",
            "message": f"Server error: {type(exc).__name__}",
        })
