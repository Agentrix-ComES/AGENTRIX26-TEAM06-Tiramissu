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


# ---------------------------------------------------------------------------
# Tool 3 — Geocoding helper for location name to coordinates
# ---------------------------------------------------------------------------
LOCATION_COORDINATES = {
    "colombo": (79.8612, 6.9271),
    "kandy": (80.6350, 7.2906),
    "ella": (81.0466, 6.8667),
    "galle": (80.2170, 6.0535),
    "sigiriya": (80.7600, 7.9570),
    "nuwara eliya": (80.7670, 6.9497),
    "trincomalee": (81.2152, 8.5874),
    "jaffna": (80.0255, 9.6615),
    "anuradhapura": (80.4036, 8.3114),
    "dambulla": (80.6518, 7.8742),
    "mirissa": (80.4582, 5.9483),
    "arugam bay": (81.8363, 6.8406),
}


@tool
def geocode_location(location_name: str) -> str:
    """Convert a location name to approximate coordinates.
    
    This is a simple lookup tool for major Sri Lankan cities/towns.
    Returns coordinates in 'longitude,latitude' format or an error message.
    
    Args:
        location_name: Name of the location (e.g. "Colombo", "Kandy")
    
    Returns:
        Coordinates string like "79.8612,6.9271" or error message
    """
    location_lower = location_name.lower().strip()
    
    # Try exact match first
    if location_lower in LOCATION_COORDINATES:
        lon, lat = LOCATION_COORDINATES[location_lower]
        return f"{lon},{lat}"
    
    # Try partial match
    for name, coords in LOCATION_COORDINATES.items():
        if name in location_lower or location_lower in name:
            lon, lat = coords
            return f"{lon},{lat}"
    
    return f"Unknown location: {location_name}. Please use one of the known locations: {', '.join(LOCATION_COORDINATES.keys())}"


# ---------------------------------------------------------------------------
# Tool 4 — Overpass API for finding tourist spots and POIs
# ---------------------------------------------------------------------------
import json as json_lib

try:
    import overpass
    OVERPASS_AVAILABLE = True
except ImportError:
    OVERPASS_AVAILABLE = False
    logger.warning("overpass library not installed - POI search will be limited")


# Mapping of interest categories to Overpass queries
INTEREST_TO_OVERPASS_QUERY = {
    "temples": """
        node["tourism"="attraction"]["name"~".*[Tt]emple.*"](around:{radius},{lat},{lon});
        node["amenity"="place_of_worship"]["religion"="buddhist"](around:{radius},{lat},{lon});
        way["tourism"="attraction"]["name"~".*[Tt]emple.*"](around:{radius},{lat},{lon});
    """,
    "nature": """
        node["natural"](around:{radius},{lat},{lon});
        node["leisure"="park"](around:{radius},{lat},{lon});
        node["tourism"="viewpoint"](around:{radius},{lat},{lon});
        way["natural"="water"](around:{radius},{lat},{lon});
    """,
    "museums": """
        node["tourism"="museum"](around:{radius},{lat},{lon});
        node["amenity"="museum"](around:{radius},{lat},{lon});
    """,
    "food": """
        node["amenity"="restaurant"](around:{radius},{lat},{lon});
        node["amenity"="cafe"](around:{radius},{lat},{lon});
        node["amenity"="fast_food"](around:{radius},{lat},{lon});
    """,
    "shopping": """
        node["shop"](around:{radius},{lat},{lon});
        node["amenity"="marketplace"](around:{radius},{lat},{lon});
    """,
    "beaches": """
        node["natural"="beach"](around:{radius},{lat},{lon});
        way["natural"="beach"](around:{radius},{lat},{lon});
        node["leisure"="beach_resort"](around:{radius},{lat},{lon});
    """,
    "history": """
        node["historic"](around:{radius},{lat},{lon});
        node["tourism"="attraction"]["historic"](around:{radius},{lat},{lon});
        way["historic"="ruins"](around:{radius},{lat},{lon});
    """,
    "photography": """
        node["tourism"="viewpoint"](around:{radius},{lat},{lon});
        node["natural"="peak"](around:{radius},{lat},{lon});
        node["tourism"="attraction"](around:{radius},{lat},{lon});
    """,
}

# Cost estimates for different POI types (in Rs)
POI_COST_ESTIMATES = {
    "temple": 500,
    "museum": 800,
    "historical": 1000,
    "nature": 0,
    "beach": 0,
    "viewpoint": 0,
    "restaurant": 600,
    "cafe": 300,
    "market": 0,
    "park": 0,
    "default": 200,
}


@tool
def search_tourist_pois(
    center_lat: float,
    center_lon: float,
    interests: list[str],
    budget: float,
    time_available_minutes: int,
    radius_km: float = 10.0,
) -> str:
    """Search for tourist points of interest using OpenStreetMap Overpass API.
    
    Finds POIs matching user interests within a specified radius, filtered by
    budget and time constraints. Returns structured JSON with POI details.
    
    Args:
        center_lat: Latitude of the center point (e.g., route midpoint or origin)
        center_lon: Longitude of the center point
        interests: List of user interests (temples, nature, museums, food, etc.)
        budget: Maximum budget in Rs for POI visits
        time_available_minutes: Time available for visiting POIs
        radius_km: Search radius in kilometers (default 10km)
    
    Returns:
        JSON string with list of POIs matching criteria, or error message
    """
    if not OVERPASS_AVAILABLE:
        return json_lib.dumps({
            "error": "Overpass API not available",
            "pois": _generate_fallback_pois(center_lat, center_lon, interests, budget, time_available_minutes)
        })
    
    try:
        api = overpass.API(timeout=25)
        all_pois = []
        
        # Build Overpass query for each interest category
        for interest in interests:
            if interest not in INTEREST_TO_OVERPASS_QUERY:
                continue
            
            query_template = INTEREST_TO_OVERPASS_QUERY[interest]
            # Clean up the query template and format it properly
            query_parts = [part.strip() for part in query_template.strip().split('\n') if part.strip()]
            formatted_query = ' '.join(query_parts).format(radius=radius_km*1000, lat=center_lat, lon=center_lon)
            
            query = f"""
                [out:json][timeout:25];
                ({formatted_query});
                out body;
                >;
                out skel qt;
            """
            
            try:
                response = api.get(query)
                elements = response.get('elements', [])
                
                for elem in elements[:10]:  # Limit to 10 per category
                    if elem.get('type') not in ['node', 'way']:
                        continue
                    
                    tags = elem.get('tags', {})
                    if not tags:
                        continue
                    
                    # Extract POI information
                    poi = _extract_poi_from_osm_element(elem, center_lat, center_lon, interest)
                    if poi:
                        # Filter by budget
                        if poi['cost'] <= budget:
                            all_pois.append(poi)
                            
            except Exception as e:
                logger.warning(f"Overpass query failed for {interest}: {e}")
                continue
        
        # Remove duplicates and sort by rating/distance
        seen_names = set()
        unique_pois = []
        for poi in all_pois:
            if poi['name'] not in seen_names:
                seen_names.add(poi['name'])
                unique_pois.append(poi)
        
        # Sort by estimated relevance (rating, then distance)
        unique_pois.sort(key=lambda p: (-p.get('rating', 0), p.get('distance_km', 999)))
        
        # Limit to top recommendations based on time available
        max_pois = max(1, time_available_minutes // 30)  # ~30 min per POI
        result_pois = unique_pois[:max_pois * 2]  # Give some extra options
        
        # If no POIs found from Overpass, use fallback
        if not result_pois:
            result_pois = _generate_fallback_pois(center_lat, center_lon, interests, budget, time_available_minutes)
        
        return json_lib.dumps({
            "success": True,
            "pois": result_pois,
            "center": {"lat": center_lat, "lon": center_lon},
            "radius_km": radius_km,
        })
        
    except Exception as exc:
        logger.exception("Overpass POI search failed")
        # Fallback to generated POIs
        return json_lib.dumps({
            "success": False,
            "error": str(exc),
            "pois": _generate_fallback_pois(center_lat, center_lon, interests, budget, time_available_minutes)
        })


def _extract_poi_from_osm_element(
    elem: dict,
    center_lat: float,
    center_lon: float,
    interest_category: str,
) -> dict | None:
    """Extract POI information from an OSM element."""
    tags = elem.get('tags', {})
    
    # Get name
    name = tags.get('name', tags.get('alt_name', 'Unknown'))
    if not name or name == 'Unknown':
        return None
    
    # Get coordinates
    if elem.get('type') == 'node':
        lat = elem.get('lat', 0)
        lon = elem.get('lon', 0)
    else:
        # For ways, we'd need center point calculation - simplified here
        lat = center_lat
        lon = center_lon
    
    # Calculate distance from center
    distance_km = _haversine_distance(center_lat, center_lon, lat, lon)
    
    # Determine POI type
    poi_type = _determine_poi_type(tags, interest_category)
    
    # Estimate cost
    cost = POI_COST_ESTIMATES.get(poi_type, POI_COST_ESTIMATES['default'])
    if tags.get('fee') == 'yes':
        cost = max(cost, 500)
    elif tags.get('fee') == 'no':
        cost = 0
    
    # Generate description
    description = _generate_poi_description(tags, poi_type)
    
    # Estimate rating (based on tag completeness as a proxy)
    rating = min(5.0, 3.0 + len([k for k, v in tags.items() if v]) * 0.1)
    
    # Estimate visit duration
    duration_map = {
        "temple": 30,
        "museum": 60,
        "viewpoint": 20,
        "beach": 60,
        "park": 45,
        "restaurant": 45,
        "default": 30,
    }
    duration = duration_map.get(poi_type, duration_map['default'])
    
    return {
        "name": name,
        "type": poi_type,
        "description": description,
        "distance_km": round(distance_km, 2),
        "estimated_duration_minutes": duration,
        "cost": cost,
        "rating": round(rating, 1),
        "location": [lon, lat],
        "osm_id": elem.get('id'),
        "image_url": tags.get('image', None),
    }


def _determine_poi_type(tags: dict, interest_category: str) -> str:
    """Determine POI type from OSM tags."""
    if tags.get('amenity') == 'place_of_worship' or 'temple' in tags.get('name', '').lower():
        return "temple"
    if tags.get('tourism') == 'museum' or tags.get('amenity') == 'museum':
        return "museum"
    if tags.get('historic'):
        return "historical"
    if tags.get('natural') == 'beach' or tags.get('leisure') == 'beach_resort':
        return "beach"
    if tags.get('tourism') == 'viewpoint' or tags.get('natural') == 'peak':
        return "viewpoint"
    if tags.get('natural') or tags.get('leisure') == 'park':
        return "nature"
    if tags.get('amenity') in ['restaurant', 'cafe', 'fast_food']:
        return "restaurant"
    if tags.get('shop') or tags.get('amenity') == 'marketplace':
        return "market"
    return interest_category


def _generate_poi_description(tags: dict, poi_type: str) -> str:
    """Generate a human-readable description for a POI."""
    descriptions = {
        "temple": "Beautiful Buddhist temple with historical significance",
        "museum": "Cultural museum showcasing local heritage and history",
        "historical": "Ancient ruins with rich cultural heritage",
        "viewpoint": "Scenic viewpoint perfect for photography",
        "beach": "Clean sandy beach perfect for relaxation",
        "nature": "Natural attraction with scenic landscapes",
        "restaurant": "Local dining spot serving authentic cuisine",
        "market": "Traditional market for crafts and souvenirs",
        "park": "Peaceful park ideal for leisure walks",
    }
    
    base_desc = descriptions.get(poi_type, "Interesting local attraction")
    
    # Enhance with additional info if available
    extras = []
    if tags.get('opening_hours'):
        extras.append(f"Open: {tags['opening_hours']}")
    if tags.get('website'):
        extras.append("More info available online")
    if tags.get('phone'):
        extras.append("Contact available")
    
    if extras:
        return f"{base_desc}. {'; '.join(extras)}"
    return base_desc


def _haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate the great-circle distance between two points in km."""
    import math
    R = 6371  # Earth's radius in km
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)
    
    a = math.sin(delta_lat / 2) ** 2 + \
        math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    return R * c


def _generate_fallback_pois(
    center_lat: float,
    center_lon: float,
    interests: list[str],
    budget: float,
    time_available_minutes: int,
) -> list[dict]:
    """Generate fallback POIs when Overpass API is unavailable."""
    # Predefined POIs near major Sri Lankan cities
    fallback_pois = [
        {
            "name": "Gangarama Temple",
            "type": "temple",
            "description": "Famous Buddhist temple in Colombo",
            "distance_km": 0.5,
            "estimated_duration_minutes": 30,
            "cost": 500,
            "rating": 4.5,
            "location": [79.8612, 6.9271],
            "image_url": None,
        },
        {
            "name": "National Museum",
            "type": "museum",
            "description": "Sri Lanka's largest museum",
            "distance_km": 1.2,
            "estimated_duration_minutes": 60,
            "cost": 800,
            "rating": 4.3,
            "location": [79.8620, 6.9280],
            "image_url": None,
        },
        {
            "name": "Galle Face Green",
            "type": "nature",
            "description": "Ocean-side urban park",
            "distance_km": 0.8,
            "estimated_duration_minutes": 45,
            "cost": 0,
            "rating": 4.4,
            "location": [79.8550, 6.9250],
            "image_url": None,
        },
        {
            "name": "Pettah Market",
            "type": "market",
            "description": "Bustling traditional market",
            "distance_km": 1.5,
            "estimated_duration_minutes": 40,
            "cost": 0,
            "rating": 4.1,
            "location": [79.8650, 6.9350],
            "image_url": None,
        },
    ]
    
    # Filter by interests and budget
    filtered = []
    for poi in fallback_pois:
        if any(interest in poi['type'] for interest in interests):
            if poi['cost'] <= budget:
                filtered.append(poi)
    
    return filtered if filtered else fallback_pois[:2]
