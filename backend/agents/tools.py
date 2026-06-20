"""
LangChain tools available to the AI agents.

Tool 1 — OSRM fallback routing (live HTTP call).
Tool 2 — Cultural knowledge search (RAG-powered via FAISS).
Tool 3 — Tourist POI Search (Overpass API).
"""

from __future__ import annotations

import logging
import math
import json

import httpx
from langchain_core.tools import tool

from .schemas import OSRMRouteResult

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
OSRM_BASE = "http://router.project-osrm.org/route/v1/driving"
OSRM_TIMEOUT_SECONDS = 15
OVERPASS_URL = "http://overpass-api.de/api/interpreter"
OVERPASS_TIMEOUT_SECONDS = 15


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


# ---------------------------------------------------------------------------
# Helper functions for POI search
# ---------------------------------------------------------------------------
def _haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance in km between two points."""
    R = 6371.0
    lat1_rad, lon1_rad = math.radians(lat1), math.radians(lon1)
    lat2_rad, lon2_rad = math.radians(lat2), math.radians(lon2)
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    a = math.sin(dlat / 2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


def _determine_poi_type(tags: dict) -> str:
    """Categorize a POI based on OSM tags."""
    if tags.get("historic") in ["archaeological_site", "monument", "ruins"]:
        return "History"
    if tags.get("amenity") == "place_of_worship":
        return "Temple/Shrine"
    if tags.get("natural") in ["beach", "coastline"]:
        return "Beach"
    if tags.get("natural") in ["water", "peak", "wood", "forest"]:
        return "Nature"
    if tags.get("tourism") == "museum":
        return "Museum"
    if tags.get("amenity") in ["restaurant", "cafe"]:
        return "Food"
    if tags.get("shop"):
        return "Shopping"
    return "Attraction"


def _extract_poi_from_osm_element(element: dict) -> dict | None:
    """Safely extract POI data from an Overpass element."""
    tags = element.get("tags", {})
    name = tags.get("name") or tags.get("name:en")
    if not name:
        return None
    
    lat = element.get("lat")
    lon = element.get("lon")
    if lat is None and "center" in element:
        lat = element["center"].get("lat")
        lon = element["center"].get("lon")
        
    if lat is None or lon is None:
        return None
    
    fee = tags.get("fee", "unknown").lower()
    cost_estimate = 0
    if fee in ["yes", "true", "1"]:
        cost_estimate = 1500
    elif fee in ["no", "false", "0", "free"]:
        cost_estimate = 0
    
    return {
        "name": name,
        "type": _determine_poi_type(tags),
        "lat": lat,
        "lon": lon,
        "cost_estimate_lkr": cost_estimate,
        "description": tags.get("description", f"A {tags.get('tourism', 'tourist spot')} in Sri Lanka.")
    }


def _generate_fallback_pois(lat: float, lon: float) -> str:
    """Fallback list of major POIs if Overpass fails."""
    fallbacks = [
        {"name": "Temple of the Tooth", "lat": 7.2936, "lon": 80.6413, "type": "Temple/Shrine", "cost_estimate_lkr": 2000},
        {"name": "Galle Face Green", "lat": 6.9271, "lon": 79.8451, "type": "Attraction", "cost_estimate_lkr": 0},
        {"name": "Sigiriya Rock Fortress", "lat": 7.9570, "lon": 80.7600, "type": "History", "cost_estimate_lkr": 5000},
        {"name": "Nine Arches Bridge", "lat": 6.8767, "lon": 81.0608, "type": "Attraction", "cost_estimate_lkr": 0},
    ]
    # Filter to nearest 2
    for p in fallbacks:
        p["dist"] = _haversine_distance(lat, lon, p["lat"], p["lon"])
    fallbacks.sort(key=lambda x: x["dist"])
    return json.dumps(fallbacks[:2])


# ---------------------------------------------------------------------------
# Tool 3 — Tourist POI Search (Overpass API)
# ---------------------------------------------------------------------------
@tool
def search_tourist_pois(
    lat: float, 
    lon: float, 
    radius: int, 
    interests: str, 
    budget: int, 
    time_available: int,
    start_lat: float | None = None,
    start_lon: float | None = None
) -> str:
    """Search for real-world tourist POIs using OpenStreetMap Overpass API.
    
    Args:
        lat: Center latitude for search.
        lon: Center longitude for search.
        radius: Search radius in meters (max 10000).
        interests: Comma-separated user interests (e.g. "temples,nature,history").
        budget: Max cost in LKR the user is willing to spend per POI.
        time_available: Max hours available (used to limit the number of returned POIs).
        start_lat: Optional starting point latitude for distance calculation.
        start_lon: Optional starting point longitude for distance calculation.
        
    Returns:
        JSON string of matched POIs with coordinates, estimated costs, and distances.
    """
    radius = min(radius, 10000)
    interests_lower = interests.lower()
    
    # Use start location for distance calculation if provided, otherwise use search center
    dist_lat = start_lat if start_lat is not None else lat
    dist_lon = start_lon if start_lon is not None else lon
    
    query_filters = []
    
    # Interest-to-Overpass query mappings for all 8 interest categories
    if "temple" in interests_lower or "religion" in interests_lower or "shrine" in interests_lower:
        query_filters.append('node["amenity"="place_of_worship"](around:{radius},{lat},{lon});')
        query_filters.append('way["amenity"="place_of_worship"](around:{radius},{lat},{lon});')
    
    if "nature" in interests_lower or "park" in interests_lower or "hiking" in interests_lower:
        query_filters.append('node["natural"](around:{radius},{lat},{lon});')
        query_filters.append('way["leisure"="park"](around:{radius},{lat},{lon});')
        query_filters.append('way["natural"](around:{radius},{lat},{lon});')
    
    if "history" in interests_lower or "ruin" in interests_lower or "archaeological" in interests_lower:
        query_filters.append('node["historic"](around:{radius},{lat},{lon});')
        query_filters.append('way["historic"](around:{radius},{lat},{lon});')
    
    if "museum" in interests_lower or "gallery" in interests_lower:
        query_filters.append('node["tourism"="museum"](around:{radius},{lat},{lon});')
        query_filters.append('node["amenity"="arts_centre"](around:{radius},{lat},{lon});')
    
    if "food" in interests_lower or "restaurant" in interests_lower or "cafe" in interests_lower:
        query_filters.append('node["amenity"="restaurant"](around:{radius},{lat},{lon});')
        query_filters.append('node["amenity"="cafe"](around:{radius},{lat},{lon});')
    
    if "shopping" in interests_lower or "market" in interests_lower or "store" in interests_lower:
        query_filters.append('node["shop"](around:{radius},{lat},{lon});')
        query_filters.append('way["shop"](around:{radius},{lat},{lon});')
    
    if "beach" in interests_lower or "coast" in interests_lower or "swimming" in interests_lower:
        query_filters.append('node["natural"="beach"](around:{radius},{lat},{lon});')
        query_filters.append('way["natural"="beach"](around:{radius},{lat},{lon});')
    
    if "photography" in interests_lower or "photo" in interests_lower or "viewpoint" in interests_lower:
        query_filters.append('node["tourism"="viewpoint"](around:{radius},{lat},{lon});')
        query_filters.append('node["man_made"="lighthouse"](around:{radius},{lat},{lon});')
    
    # Default to general tourism if no specific filters
    if not query_filters:
        query_filters.append('node["tourism"](around:{radius},{lat},{lon});')
        query_filters.append('way["tourism"](around:{radius},{lat},{lon});')

    query_body = "".join(query_filters).format(radius=radius, lat=lat, lon=lon)
    overpass_query = f"[out:json][timeout:15];({query_body});out center 50;"

    try:
        with httpx.Client(timeout=OVERPASS_TIMEOUT_SECONDS) as client:
            headers = {
                "User-Agent": "TiramissuTravelBot/1.0",
                "Accept": "application/json"
            }
            resp = client.post(OVERPASS_URL, data={"data": overpass_query}, headers=headers)
            resp.raise_for_status()
            data = resp.json()

        pois = []
        seen_names = set()
        
        for element in data.get("elements", []):
            poi = _extract_poi_from_osm_element(element)
            if poi and poi["name"] not in seen_names:
                # Filter by budget
                if poi["cost_estimate_lkr"] > budget:
                    continue
                
                # Calculate exact distance from start point (or search center)
                poi["dist_km"] = round(_haversine_distance(dist_lat, dist_lon, poi["lat"], poi["lon"]), 2)
                pois.append(poi)
                seen_names.add(poi["name"])

        # Sort by distance from start point
        pois.sort(key=lambda x: x["dist_km"])

        # Limit by time (e.g., 1 POI per 1.5 hours, minimum 1)
        max_pois = max(1, int(time_available / 1.5))
        return json.dumps(pois[:max_pois])

    except Exception as exc:
        logger.warning(f"Overpass API failed: {exc}. Using fallback POIs.")
        return _generate_fallback_pois(dist_lat, dist_lon)
    if "museum" in interests_lower:
        query_filters.append('node["tourism"="museum"](around:{radius},{lat},{lon});')
    if "food" in interests_lower or "restaurant" in interests_lower:
        query_filters.append('node["amenity"="restaurant"](around:{radius},{lat},{lon});')
    
    # Default to general tourism if no specific filters
    if not query_filters:
        query_filters.append('node["tourism"](around:{radius},{lat},{lon});')
        query_filters.append('way["tourism"](around:{radius},{lat},{lon});')
        
    query_body = "".join(query_filters).format(radius=radius, lat=lat, lon=lon)
    overpass_query = f"[out:json][timeout:15];({query_body});out center 20;"
    
    try:
        with httpx.Client(timeout=OVERPASS_TIMEOUT_SECONDS) as client:
            headers = {"User-Agent": "TiramissuTravelBot/1.0", "Accept": "application/json"}
            resp = client.post(OVERPASS_URL, data={"data": overpass_query}, headers=headers)
            resp.raise_for_status()
            data = resp.json()
            
        pois = []
        for element in data.get("elements", []):
            poi = _extract_poi_from_osm_element(element)
            if poi:
                # Filter by budget
                if poi["cost_estimate_lkr"] > budget:
                    continue
                # Calculate exact distance from center
                poi["dist_km"] = round(_haversine_distance(lat, lon, poi["lat"], poi["lon"]), 2)
                pois.append(poi)
                
        # Sort by distance
        pois.sort(key=lambda x: x["dist_km"])
        
        # Limit by time (e.g., 1 POI per 1.5 hours)
        max_pois = max(1, int(time_available / 1.5))
        return json.dumps(pois[:max_pois])
        
    except Exception as exc:
        logger.warning(f"Overpass API failed: {exc}. Using fallback POIs.")
        return _generate_fallback_pois(lat, lon)
