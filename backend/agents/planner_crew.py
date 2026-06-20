"""
Smart Trip Planner Crew.

1. Retrieves cultural knowledge based on user interests.
2. Uses Gemini with structured output to select stops and estimate costs/durations based on budget/time.
3. Calculates real driving routes between stops using OSRM.
4. Returns a complete SmartItineraryResponse.
"""

from __future__ import annotations

import logging
import os
import json

from dotenv import load_dotenv
from langchain_core.messages import SystemMessage, HumanMessage
from langchain_google_genai import ChatGoogleGenerativeAI

from .schemas import SmartItineraryRequest, SmartItineraryResponse, ItineraryStop
from .tools import calculate_osrm_fallback, search_cultural_knowledge, search_tourist_pois

load_dotenv()

logger = logging.getLogger(__name__)

_GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

_llm = ChatGoogleGenerativeAI(
    model="gemini-2.0-flash",
    google_api_key=_GEMINI_API_KEY,
    temperature=0.3,
    max_output_tokens=2048,
)

# Bind structured output
_planner_llm = _llm.with_structured_output(SmartItineraryResponse)

SYSTEM_PROMPT = """\
You are an expert Sri Lankan travel planner.

The user wants an itinerary based on their interests, time available, and budget.
Available well-known coordinates:
- Colombo: 79.8612,6.9271 | Kandy: 80.6350,7.2906
- Ella: 81.0466,6.8667 | Galle: 80.2170,6.0535
- Sigiriya: 80.7600,7.9570 | Nuwara Eliya: 80.7670,6.9497
- Trincomalee: 81.2152,8.5874 | Jaffna: 80.0255,9.6615
- Anuradhapura: 80.4036,8.3114 | Dambulla: 80.6518,7.8742

INSTRUCTIONS:
1. Review the user's constraints: Budget (LKR), Time (Hours), Interests, Origin location.
2. Use the `search_tourist_pois` tool to find real tourist spots matching the user's interests near their origin or along their route.
   - Pass the user's origin coordinates as lat/lon
   - Use a radius of 5000-10000 meters
   - Pass the user's interests, budget, and time_available
   - Optionally pass start_lat/start_lon for distance calculation from user's starting point
3. Select 2 to 4 POIs from the search results that fit the criteria.
4. Return the structured itinerary with these POIs as stops.
5. DO NOT worry about the exact travel duration or geometry; the backend will calculate the exact driving routes and add them. Just provide a reasonable sequence of stops.
6. The total cost should not exceed the user's budget.
7. If there are disruptions reported, route AROUND them.
8. If search_tourist_pois returns no results, use your knowledge of popular Sri Lankan attractions.
"""

async def plan_smart_itinerary(request: SmartItineraryRequest) -> SmartItineraryResponse:
    # 1. Get knowledge
    try:
        knowledge = search_cultural_knowledge(request.interests)
    except Exception:
        knowledge = "No additional cultural knowledge found."

    user_msg = (
        f"Origin: {request.origin_lat},{request.origin_lon}\n"
        f"Budget: {request.budget_lkr} LKR\n"
        f"Time Available: {request.time_hours} hours\n"
        f"Interests: {request.interests}\n"
        f"Disruptions/News: {request.disruptions}\n\n"
        f"Cultural Context:\n{knowledge}"
    )

    # 2. Get LLM structured plan
    import asyncio
    try:
        plan: SmartItineraryResponse = await asyncio.wait_for(
            _planner_llm.ainvoke([
                SystemMessage(content=SYSTEM_PROMPT),
                HumanMessage(content=user_msg)
            ]),
            timeout=15.0
        )
    except Exception as exc:
        logger.exception("LLM Planner failed or timed out, using failsafe fallback")
        plan = SmartItineraryResponse(
            total_cost_lkr=2000,
            total_duration_mins=0,
            stops=[
                ItineraryStop(
                    name="Temple of the Tooth (Kandy)", 
                    lat=7.2936, lon=80.6413, 
                    cost_lkr=1500, duration_mins=120, 
                    description="Failsafe route: Most popular cultural site in Kandy."
                ),
                ItineraryStop(
                    name="Galle Face Green (Colombo)", 
                    lat=6.9271, lon=79.8451, 
                    cost_lkr=0, duration_mins=60, 
                    description="Failsafe route: Relaxing end to the trip in the capital."
                )
            ],
            transport_recommendation="Failsafe mode active (AI Unavailable or Timeout). Displaying popular fallback route computed purely by OSRM."
        )

    # 3. Calculate actual routes using OSRM
    total_travel_time = 0.0
    merged_coords = []
    
    # We start from the user's origin
    prev_lon = request.origin_lon
    prev_lat = request.origin_lat
    
    for stop in plan.stops:
        try:
            # calculate_osrm_fallback takes "lon,lat"
            origin_str = f"{prev_lon},{prev_lat}"
            dest_str = f"{stop.lon},{stop.lat}"
            
            osrm_json = calculate_osrm_fallback.invoke({
                "origin_coords": origin_str,
                "dest_coords": dest_str
            })
            if not osrm_json.startswith("Error"):
                import json
                osrm_data = json.loads(osrm_json)
                total_travel_time += osrm_data.get("duration_min", 0)
                
                # Merge geometry coordinates
                geom = osrm_data.get("geometry", {})
                if geom.get("type") == "LineString":
                    merged_coords.extend(geom.get("coordinates", []))
            
            prev_lon = stop.lon
            prev_lat = stop.lat
        except Exception as e:
            logger.warning(f"OSRM calculation failed for stop {stop.name}: {e}")
            continue

    plan.total_duration_mins = int(total_travel_time) + sum(s.duration_mins for s in plan.stops)
    
    if merged_coords:
        plan.geometry = {
            "type": "LineString",
            "coordinates": merged_coords
        }
    
    return plan
