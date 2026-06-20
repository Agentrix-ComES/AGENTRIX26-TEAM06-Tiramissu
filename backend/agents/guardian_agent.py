"""
Guardian Agent — Gemini-powered scam-detection engine.

Uses google.genai (new SDK) with api_version='v1' directly, bypassing
LangChain's ChatGoogleGenerativeAI which defaults to the v1beta endpoint
that does not expose newer models on this project.

Input:  transcript (string) + context (string)
Output: GuardianAlert Pydantic model

JSON Output Schema (strict):
{
  "status": "SCAM",           // "SAFE" | "WARNING" | "SCAM" | "LISTENING"
  "transcript_snippet": "...",
  "threat_message": "...",
  "action_suggested": "..."
}
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import re
from typing import Literal

from dotenv import load_dotenv
from google import genai
from google.genai import types
from pydantic import BaseModel, Field

load_dotenv()
logger = logging.getLogger(__name__)

# ── Output schema ─────────────────────────────────────────────────────────────

StatusType = Literal["LISTENING", "SAFE", "WARNING", "SCAM"]


class GuardianAlert(BaseModel):
    """Structured scam-detection alert returned to the Flutter client."""

    status: StatusType = Field(
        ...,
        description=(
            "Threat level: LISTENING (still collecting audio), "
            "SAFE (no concern), WARNING (possible overcharge), "
            "SCAM (confirmed fraudulent intent)."
        ),
    )
    transcript_snippet: str = Field(
        ...,
        description="The verbatim excerpt that triggered this alert.",
    )
    threat_message: str = Field(
        ...,
        description="Plain-English explanation of the detected threat.",
    )
    action_suggested: str = Field(
        ...,
        description="Actionable instruction for the traveler.",
    )


# ── System prompt ─────────────────────────────────────────────────────────────

_SYSTEM_PROMPT = """\
You are The Guardian — an expert anti-scam advisor protecting tourists in Sri Lanka.

Analyse the conversation transcript and decide whether the local vendor / driver
is being honest OR trying to overcharge / mislead the tourist.

COMMON SCAMS IN SRI LANKA:
- Tuk-tuk drivers quoting 3-10x the metered fare
  (Colombo meter start: LKR 60 | Kandy short trip: LKR 200-600)
- Drivers claiming "the place is very far" when it is under 3 km
- Gem / spice shop touts saying government shops are closed
- "Free" temple tours that end with forced donations
- Currency exchange fraud with unofficial rates
- Drivers claiming the tourist's hotel "burned down" or "is full"

CLASSIFICATION RULES:
| STATUS  | When to use                                                            |
|---------|------------------------------------------------------------------------|
| SAFE    | Price fair, no deceptive language, nothing suspicious                  |
| WARNING | Price 1.5-3x local baseline OR vague / evasive language                |
| SCAM    | Price >3x baseline OR classic scam script OR false factual claims      |

Respond ONLY with a JSON object — no markdown fences, no extra prose:
{
  "status": "<SAFE|WARNING|SCAM>",
  "transcript_snippet": "<verbatim excerpt that triggered the assessment>",
  "threat_message": "<plain-English explanation, or a reassuring message if SAFE>",
  "action_suggested": "<actionable advice for traveler, or an encouraging tip if SAFE>"
}
"""


# ── Core function ─────────────────────────────────────────────────────────────


async def run_guardian_agent(
    transcript: str,
    context: str = "Tourist interaction, Sri Lanka",
) -> GuardianAlert:
    """Evaluate a transcript snippet and return a GuardianAlert.

    Uses Gemini 2.0 Flash via the native google.genai SDK (api_version=v1).
    Falls back to a SAFE alert with an error note if the LLM call fails.

    Args:
        transcript: STT-generated text to evaluate.
        context:    Free-text location / situation context for the LLM.

    Returns:
        A validated GuardianAlert Pydantic model.
    """
    if not transcript.strip():
        return GuardianAlert(
            status="LISTENING",
            transcript_snippet="",
            threat_message="",
            action_suggested="",
        )

    api_key = os.getenv("GEMINI_API_KEY", "").strip()
    if not api_key or api_key == "your_api_key_here":
        raise RuntimeError(
            "GEMINI_API_KEY is not set. Get a key at "
            "https://aistudio.google.com/app/apikey and add it to .env"
        )

    try:
        raw = await _call_gemini(api_key, transcript, context)
        alert = _parse_alert(raw, transcript)
        logger.info("Guardian assessed '%s...' -> %s", transcript[:60], alert.status)
        return alert

    except Exception as exc:  # noqa: BLE001
        logger.warning("Guardian LLM failed (%s) — returning rescue response.", exc)
        return _rescue_alert(transcript)


async def _call_gemini(api_key: str, transcript: str, context: str) -> str:
    """Run the Gemini API call in a thread pool (keeps the event loop free)."""

    full_prompt = (
        f"{_SYSTEM_PROMPT}\n\n"
        f"---\n\n"
        f"LOCATION CONTEXT: {context}\n\n"
        f'CONVERSATION TRANSCRIPT:\n"""{transcript}"""\n\n'
        "Analyse the transcript and return your Guardian JSON assessment now."
    )

    def _sync_call() -> str:
        client = genai.Client(
            api_key=api_key,
            http_options={"api_version": "v1"},
        )
        response = client.models.generate_content(
            model="gemini-2.5-flash-lite",
            contents=[
                types.Part.from_text(text=full_prompt),
            ],
            config=types.GenerateContentConfig(
                temperature=0.1,
                max_output_tokens=512,
            ),
        )
        return response.text.strip()

    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(None, _sync_call)


def _parse_alert(raw: str, transcript: str) -> GuardianAlert:
    """Parse and validate the JSON response from Gemini."""
    try:
        clean = re.sub(r"```(?:json)?", "", raw).strip()
        match = re.search(r"\{.*?\}", clean, re.DOTALL)
        if match:
            data = json.loads(match.group())
            return GuardianAlert(**data)
    except Exception as exc:  # noqa: BLE001
        logger.warning("Alert JSON parse failed (%s). Raw: %.200s", exc, raw)

    return _rescue_alert(transcript)


def _rescue_alert(transcript: str) -> GuardianAlert:
    """Return a safe fallback alert when parsing fails."""
    return GuardianAlert(
        status="SAFE",
        transcript_snippet=transcript[:120],
        threat_message="Analysis temporarily unavailable. Monitor manually.",
        action_suggested="",
    )
