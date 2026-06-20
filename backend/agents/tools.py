"""
LangChain tools available to the AI agents.

Tool 1 — OSRM fallback routing (live HTTP call).
Tool 2 — Cultural knowledge search (MOCKED — Supabase owned by Member 2).
"""

from __future__ import annotations

import logging

import httpx
from langchain_core.tools import tool

from .schemas import OSRMRouteResult

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
OSRM_BASE = "http://router.project-osrm.org/route/v1/driving"
OSRM_TIMEOUT_SECONDS = 15


# ---------------------------------------------------------------------------
# Tool 1 — Deterministic OSRM fallback routing
# ---------------------------------------------------------------------------
@tool
def calculate_osrm_fallback(origin_coords: str, dest_coords: str) -> str:
    """Calculate a driving fallback route between two coordinate pairs
    using the public OSRM API.

    Args:
        origin_coords: Longitude,Latitude of the origin (e.g. "80.6350,7.2906").
        dest_coords:   Longitude,Latitude of the destination (e.g. "81.0466,6.8667").

    Returns:
        A JSON-like summary with distance_km, duration_min and GeoJSON geometry,
        or an error message if the request fails.
    """
    url = f"{OSRM_BASE}/{origin_coords};{dest_coords}"
    params = {"overview": "full", "geometries": "geojson"}

    try:
        with httpx.Client(timeout=OSRM_TIMEOUT_SECONDS) as client:
            resp = client.get(url, params=params)
            resp.raise_for_status()
            data = resp.json()

        if data.get("code") != "Ok" or not data.get("routes"):
            return (
                f"OSRM returned no valid route. API code: {data.get('code')}. "
                "The traveler may need to try a different origin/destination pair."
            )

        route = data["routes"][0]
        result = OSRMRouteResult(
            distance_km=round(route["distance"] / 1000, 2),
            duration_min=round(route["duration"] / 60, 1),
            geometry=route["geometry"],
        )
        return result.model_dump_json()

    except httpx.TimeoutException:
        logger.exception("OSRM request timed out")
        return (
            "ERROR: OSRM request timed out after "
            f"{OSRM_TIMEOUT_SECONDS}s. Suggest the traveler use offline "
            "cached routes or ask a local driver."
        )
    except httpx.HTTPStatusError as exc:
        logger.exception("OSRM HTTP error")
        return f"ERROR: OSRM returned HTTP {exc.response.status_code}."
    except Exception as exc:  # noqa: BLE001
        logger.exception("Unexpected error calling OSRM")
        return f"ERROR: Unexpected failure — {type(exc).__name__}: {exc}"


# ---------------------------------------------------------------------------
# Tool 2 — Cultural knowledge search (MOCKED)
# ---------------------------------------------------------------------------
# NOTE: This is a placeholder. Member 2 will replace the body with a real
# Supabase pgvector similarity search once the embeddings table is live.
# ---------------------------------------------------------------------------
@tool
def search_cultural_knowledge(query: str) -> str:
    """Search the local cultural knowledge base for tips relevant to
    the traveler's situation.

    Args:
        query: Free-text search query (e.g. "hiring a tuk-tuk in Kandy").

    Returns:
        Matching cultural tips and phonetic Sinhala phrases.
    """
    # ── MOCK DATA — DO NOT connect to Supabase here ──────────────────────
    mock_knowledge = {
        "default": (
            "In Sri Lanka, always start bargaining with a warm smile. "
            "Ask for a 30% discount initially. Use the phrase "
            "'Mata aduiyak denne puluwan da?' (Can you give me a good price?). "
            "If hiring a tuk-tuk, agree on the fare BEFORE getting in. "
            "A reasonable rate is roughly LKR 60-80 per kilometre. "
            "Say 'Kiyada?' (How much?) to open the negotiation."
        ),
        "tuk-tuk": (
            "For tuk-tuk hire: Say 'Kiyada?' (කියද?) meaning 'How much?'. "
            "Follow with 'Eka godak wadi' (That's too much). "
            "Offer 60% of the quoted price and settle around 70-75%. "
            "Always confirm the destination by showing it on a map. "
            "Tip: Ask your hotel for the 'normal' fare to calibrate."
        ),
        "temple": (
            "Temple etiquette: Remove shoes and hats before entry. "
            "Dress modestly — cover shoulders and knees. "
            "Walk clockwise around stupas. Never pose with your back "
            "to a Buddha statue. Say 'Ayubowan' (Long life to you) "
            "as a respectful greeting to monks."
        ),
        "train": (
            "Sri Lankan trains are scenic but unreliable. Delays of "
            "1-3 hours are common on the hill-country line. "
            "If your train is cancelled, head to the bus stand — "
            "private buses run the same routes more frequently. "
            "Say 'Me bus eka koheda yanné?' (Where does this bus go?) "
            "to confirm the destination."
        ),
        "food": (
            "Street food is safe at busy stalls with high turnover. "
            "Try 'kottu roti' and 'hoppers'. Vegetarian options are "
            "plentiful — ask for 'elawalu' (vegetables). "
            "Say 'Kanna deyak tiyenawa da?' (Do you have food?)."
        ),
    }

    query_lower = query.lower()

    # Simple keyword match against mock categories
    for key, knowledge in mock_knowledge.items():
        if key != "default" and key in query_lower:
            logger.info("Cultural knowledge mock hit: category=%s", key)
            return knowledge

    logger.info("Cultural knowledge mock: returning default tips")
    return mock_knowledge["default"]
