"""
Guardian two-mode smoke-test.

Tests both pipeline modes WITHOUT a real microphone:
  - Synthesises a tiny silent WAV buffer
  - Sends it through Gemini STT (will return empty / Unknown — expected for silence)
  - Then tests the agent directly with hardcoded Sinhala / Tamil / English text

Run from project root:
    python -m backend.test_guardian
"""

from __future__ import annotations

import asyncio
import struct
import wave
import io
import os

# ── Helpers ───────────────────────────────────────────────────────────────────


def make_silent_wav(duration_s: float = 2.0, sample_rate: int = 16_000) -> bytes:
    """Generate a silent WAV buffer to test the STT pipeline without a mic."""
    num_frames = int(sample_rate * duration_s)
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(b"\x00\x00" * num_frames)
    buf.seek(0)
    return buf.read()


# ── Test cases ────────────────────────────────────────────────────────────────

AGENT_TEST_CASES = [
    {
        "label": "English SCAM",
        "transcript": "No problem sir, only 2500 rupees. Very far, traffic also.",
        "context": "Tuk-tuk negotiation outside Kandy railway station, Sri Lanka",
        "expect": "SCAM or WARNING",
    },
    {
        "label": "English SAFE",
        "transcript": "The entry ticket is 500 rupees per person, the temple is open.",
        "context": "Temple of the Tooth, Kandy, Sri Lanka",
        "expect": "SAFE",
    },
    {
        "label": "Sinhala SCAM (pre-translated)",
        "transcript": "This shop is government certified, very cheap price for you only today.",
        "context": "Gem shop, Colombo, Sri Lanka",
        "expect": "SCAM or WARNING",
    },
]


async def test_stt_module(silent_wav: bytes) -> None:
    """Test the Gemini STT module with a silent audio buffer."""
    from backend.agents.guardian_stt import transcribe_and_translate

    print("\n[STT TEST] Sending silent WAV to Gemini STT...")
    result = await transcribe_and_translate(silent_wav, mime_type="audio/wav")
    print(f"  Language : {result.original_language}")
    print(f"  Original : '{result.original_text}'")
    print(f"  English  : '{result.english_text}'")
    print("  [OK] STT module responded without crashing.")


async def test_agent(cases: list) -> None:
    """Test the Guardian agent with pre-translated English text."""
    from backend.agents.guardian_agent import run_guardian_agent

    print("\n[AGENT TEST] Running scam detection on pre-translated text...")
    for tc in cases:
        print(f"\n  [{tc['label']}]  Expect: {tc['expect']}")
        print(f"    Transcript : {tc['transcript'][:80]}")
        alert = await run_guardian_agent(
            transcript=tc["transcript"],
            context=tc["context"],
        )
        print(f"    >> Status   : {alert.status}")
        print(f"    >> Threat   : {alert.threat_message}")
        print(f"    >> Action   : {alert.action_suggested}")


async def main() -> None:
    print("\n" + "=" * 60)
    print("  GUARDIAN PIPELINE SMOKE-TEST")
    print("  GEMINI_API_KEY present:", bool(os.getenv("GEMINI_API_KEY", "").strip().replace("your_api_key_here", "")))
    print("=" * 60)

    silent_wav = make_silent_wav()

    # Test 1 — STT module
    await test_stt_module(silent_wav)

    # Test 2 — Agent module (bypasses STT, uses hardcoded English text)
    await test_agent(AGENT_TEST_CASES)

    print("\n" + "=" * 60)
    print("  [DONE] Smoke-test complete.")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    asyncio.run(main())
