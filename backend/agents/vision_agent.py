"""
Vision Agent — analyses camera frames of monuments / sites.

Uses Gemini 1.5 Flash with structured output to return a
VisionAnalysis schema that the Flutter frontend can render
as an AR overlay + trigger TTS narration.
"""

from __future__ import annotations

import base64
import logging
import os

from dotenv import load_dotenv
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_google_genai import ChatGoogleGenerativeAI

from .schemas import VisionAnalysis

load_dotenv()

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# LLM initialisation
# ---------------------------------------------------------------------------
_GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

if not _GEMINI_API_KEY:
    logger.warning(
        "GEMINI_API_KEY is not set — vision agent calls will fail at runtime."
    )

_llm = ChatGoogleGenerativeAI(
    model="gemini-2.0-flash",
    google_api_key=_GEMINI_API_KEY,
    temperature=0.2,
    max_output_tokens=1024,
)

_structured_llm = _llm.with_structured_output(VisionAnalysis)

# ---------------------------------------------------------------------------
# System prompt
# ---------------------------------------------------------------------------
VISION_SYSTEM_PROMPT = """\
You are the Cultural Vision Guide for a Sri Lanka tourism app.

When given a photo from a traveler's camera, you MUST:
1. Identify the landmark, temple, ruin, or natural site in the image.
2. Provide 2-4 sentences of historical context suitable for a tourist.
3. List actionable cultural rules the traveler must follow at this site
   (e.g., dress code, photography restrictions, shoe removal).
4. Write a 60-90 second audio narration script that a text-to-speech
   engine can read aloud as the traveler approaches the site.

If you cannot confidently identify the site, state your best guess and
flag the uncertainty. Never fabricate UNESCO or heritage status.
Respond ONLY with the structured JSON output — no extra commentary.
"""


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
async def analyze_monument(
    image_bytes: bytes,
    user_context: str = "I am a tourist visiting Sri Lanka.",
) -> VisionAnalysis:
    """Analyse a monument/site image and return structured cultural info.

    Parameters
    ----------
    image_bytes:
        Raw bytes of the image captured by the device camera.
    user_context:
        Optional free-text describing the traveler's current situation
        (e.g., "I'm at a temple entrance in Anuradhapura").

    Returns
    -------
    VisionAnalysis
        Typed Pydantic model with site_name, historical_context,
        cultural_rules, and audio_script.

    Raises
    ------
    RuntimeError
        If the Gemini API call fails after retries.
    """
    image_b64 = base64.b64encode(image_bytes).decode("utf-8")

    messages = [
        SystemMessage(content=VISION_SYSTEM_PROMPT),
        HumanMessage(
            content=[
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:image/jpeg;base64,{image_b64}",
                    },
                },
                {
                    "type": "text",
                    "text": (
                        f"Traveler context: {user_context}\n\n"
                        "Analyse this image and return the structured output."
                    ),
                },
            ],
        ),
    ]

    try:
        result: VisionAnalysis = await _structured_llm.ainvoke(messages)
        logger.info("Vision analysis complete: site=%s", result.site_name)
        return result

    except Exception as exc:
        logger.exception("Vision agent failed during Gemini call")
        raise RuntimeError(
            f"Vision analysis failed: {type(exc).__name__}: {exc}"
        ) from exc
