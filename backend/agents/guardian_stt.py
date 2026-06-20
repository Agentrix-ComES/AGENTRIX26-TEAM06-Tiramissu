"""
Gemini-powered multilingual Speech-to-Text + Translation layer.

Uses the NEW google-genai SDK (google.genai) with gemini-2.0-flash.
Supports Sinhala (si), Tamil (ta), and English (en) in a single API call.

Supported audio MIME types:
    audio/wav  audio/webm  audio/mp4  audio/aac
    audio/mpeg audio/ogg   audio/flac audio/pcm
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import re
import struct

from google import genai
from google.genai import types
from pydantic import BaseModel, Field

logger = logging.getLogger(__name__)

# ── Output schema ─────────────────────────────────────────────────────────────


class TranscriptionResult(BaseModel):
    """STT + translation result returned by Gemini."""

    original_language: str = Field(
        ...,
        description="Detected language: 'Sinhala', 'Tamil', 'English', or 'Unknown'.",
    )
    original_text: str = Field(
        ...,
        description="Verbatim transcription in the original language.",
    )
    english_text: str = Field(
        ...,
        description="English translation (same as original_text when English).",
    )


# ── Prompt ────────────────────────────────────────────────────────────────────

_STT_PROMPT = """\
You are a transcription and translation assistant specialising in Sri Lankan languages.

TASK:
1. Listen carefully to the audio clip.
2. Identify the spoken language — it will be Sinhala, Tamil, or English.
3. Transcribe the speech EXACTLY as spoken.
   - Sinhala → use Sinhala Unicode script.
   - Tamil   → use Tamil Unicode script.
   - English → transcribe in English.
4. Translate the transcription to English.
   If the audio is already English, repeat the transcription as the translation.

Respond ONLY with a valid JSON object — no markdown fences, no extra text:
{
  "original_language": "<Sinhala | Tamil | English | Unknown>",
  "original_text": "<verbatim transcription>",
  "english_text": "<English translation>"
}

If the audio is silent, too noisy, or unintelligible respond with:
{"original_language":"Unknown","original_text":"","english_text":""}
"""

# ── Core function ─────────────────────────────────────────────────────────────


async def transcribe_and_translate(
    audio_bytes: bytes,
    mime_type: str = "audio/wav",
) -> TranscriptionResult:
    """Transcribe multilingual audio and translate to English using Gemini 2.0 Flash.

    Args:
        audio_bytes: Raw audio bytes from the microphone buffer.
        mime_type:   MIME type of the audio container.
                     Flutter `record` plugin:
                       mobile  → "audio/aac"
                       web     → "audio/webm"

    Returns:
        TranscriptionResult with original_language, original_text, english_text.
    """
    api_key = os.getenv("GEMINI_API_KEY", "").strip()
    if not api_key or api_key == "your_api_key_here":
        raise RuntimeError(
            "GEMINI_API_KEY is not set. Add your key from "
            "https://aistudio.google.com/app/apikey to .env"
        )

    if not audio_bytes:
        return TranscriptionResult(
            original_language="Unknown",
            original_text="",
            english_text="",
        )

    # If mime type is audio/wav but it's raw PCM, add a header so Gemini can read it.
    if mime_type == "audio/wav":
        audio_bytes = _add_wav_header(audio_bytes, 16000, 1, 2)

    try:
        result = await _call_gemini(api_key, audio_bytes, mime_type)
        return result
    except Exception as exc:  # noqa: BLE001
        logger.exception("Gemini STT failed: %s", exc)
        return TranscriptionResult(
            original_language="Unknown",
            original_text="",
            english_text="",
        )


async def _call_gemini(
    api_key: str,
    audio_bytes: bytes,
    mime_type: str,
) -> TranscriptionResult:
    """Run the Gemini generate_content call in a thread pool (stays async-safe)."""

    def _sync_call() -> str:
        client = genai.Client(
            api_key=api_key,
            http_options={'api_version': 'v1'},
        )
        response = client.models.generate_content(
            model="gemini-2.5-flash-lite",
            contents=[
                types.Part.from_bytes(data=audio_bytes, mime_type=mime_type),
                types.Part.from_text(text=_STT_PROMPT),
            ],
            config=types.GenerateContentConfig(
                temperature=0.0,
                max_output_tokens=512,
            ),
        )
        return response.text.strip()

    loop = asyncio.get_event_loop()
    raw = await loop.run_in_executor(None, _sync_call)
    return _parse_response(raw)


def _parse_response(raw: str) -> TranscriptionResult:
    """Extract and validate the JSON object from the Gemini response."""
    try:
        # Strip markdown code fences if present
        clean = re.sub(r"```(?:json)?", "", raw).strip()
        match = re.search(r"\{.*?\}", clean, re.DOTALL)
        if match:
            data = json.loads(match.group())
            return TranscriptionResult(**data)
    except Exception as exc:  # noqa: BLE001
        logger.warning("STT JSON parse failed (%s). Raw: %.200s", exc, raw)

    # Last-resort: treat whole response as English text
    return TranscriptionResult(
        original_language="English",
        original_text=raw,
        english_text=raw,
    )

def _add_wav_header(pcm_bytes: bytes, sample_rate: int = 16000, num_channels: int = 1, sample_width: int = 2) -> bytes:
    """Prepend a standard 44-byte WAV header to raw PCM bytes."""
    if pcm_bytes.startswith(b"RIFF"):
        return pcm_bytes
        
    byte_rate = sample_rate * num_channels * sample_width
    data_size = len(pcm_bytes)
    file_size = data_size + 36

    header = struct.pack(
        "<4sI4s4sIHHIIHH4sI",
        b"RIFF",
        file_size,
        b"WAVE",
        b"fmt ",
        16,
        1,
        num_channels,
        sample_rate,
        byte_rate,
        num_channels * sample_width,
        sample_width * 8,
        b"data",
        data_size,
    )
    return header + pcm_bytes
