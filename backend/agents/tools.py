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
# Tool 2 — Cultural knowledge search (RAG-powered via FAISS)
# ---------------------------------------------------------------------------
# Bhagya's RAG retriever replaces the previous mock dictionary.
# The retriever queries a FAISS vector store built from local .md knowledge
# files in backend/rag/data/. To rebuild the index after updating the docs:
#     python -m backend.rag.ingest
# ---------------------------------------------------------------------------
from backend.rag.retriever import retrieve_knowledge


@tool
def search_cultural_knowledge(query: str) -> str:
    """Search the local cultural knowledge base for tips relevant to
    the traveler's situation.

    Args:
        query: Free-text search query (e.g. "hiring a tuk-tuk in Kandy").

    Returns:
        Matching cultural tips and phonetic Sinhala phrases.
    """
    logger.info("RAG retrieval triggered: query='%s'", query)
    return retrieve_knowledge(query, top_k=3)
