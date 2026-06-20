"""
Route Pivot Crew — Reactive transit recovery agent.

When a traveler reports a disruption (cancelled train, landslide,
road closure), this agent:
  1. Parses the situation into origin / destination / blocked mode.
  2. Calls the OSRM tool for a deterministic driving fallback.
  3. Queries the cultural knowledge base for local negotiation tips.
  4. Synthesises a final recovery plan with a phonetic Sinhala script.

Uses a LangGraph ReAct agent backed by Gemini 2.0 Flash.
"""

from __future__ import annotations

import logging
import os

from dotenv import load_dotenv
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_google_genai import ChatGoogleGenerativeAI
from langgraph.prebuilt import create_react_agent

import json
import re
from typing import Any

from .schemas import RoutePivotContext, NavigationStepData, RouteRecommendationData
from .tools import calculate_osrm_fallback, search_cultural_knowledge, geocode_location, search_tourist_pois

load_dotenv()

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# LLM
# ---------------------------------------------------------------------------
_GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

def _get_llm():
    """Lazy initialization of LLM to avoid import-time errors when API key is missing."""
    if not _GEMINI_API_KEY:
        logger.warning(
            "GEMINI_API_KEY is not set — route crew calls will fail at runtime."
        )
    return ChatGoogleGenerativeAI(
        model="gemini-2.0-flash",
        google_api_key=_GEMINI_API_KEY,
        temperature=0.3,
        max_output_tokens=2048,
    )

# Lazy init - only create LLM when actually needed
_llm = None  # Will be initialized on first use

# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------
_tools = [calculate_osrm_fallback, search_cultural_knowledge, geocode_location, search_tourist_pois]

# ---------------------------------------------------------------------------
# System prompt
# ---------------------------------------------------------------------------
SYSTEM_PROMPT = """\
You are the **Transit Recovery Expert** for a Sri Lanka tourism app.

A traveler has reported a transit disruption. Your mission is to:
1. Use the `calculate_osrm_fallback` tool to compute an alternative
   driving route from the origin to the destination.
   - Origin and destination coordinates must be in "longitude,latitude" format.
   - If you don't know exact coordinates, use well-known approximate coords
     for major Sri Lankan cities/towns:
       Colombo: 79.8612,6.9271 | Kandy: 80.6350,7.2906
       Ella: 81.0466,6.8667 | Galle: 80.2170,6.0535
       Sigiriya: 80.7600,7.9570 | Nuwara Eliya: 80.7670,6.9497
       Trincomalee: 81.2152,8.5874 | Jaffna: 80.0255,9.6615
       Anuradhapura: 80.4036,8.3114 | Dambulla: 80.6518,7.8742
       Mirissa: 80.4582,5.9483 | Arugam Bay: 81.8363,6.8406
2. Use the `search_cultural_knowledge` tool to get local transport
   negotiation tips relevant to the situation.
3. Produce a final answer that includes:
   a. A clear summary of the recovery plan.
   b. Distance and estimated travel time of the fallback route.
   c. A phonetic Sinhala negotiation script the traveler can
      read aloud to hire local transport (tuk-tuk, van, etc.).
   d. Cultural tips for navigating the informal transport economy.
"""

# ---------------------------------------------------------------------------
# LangGraph ReAct agent
# ---------------------------------------------------------------------------
def _get_agent():
    """Lazy initialization of the agent to avoid import-time errors."""
    global _llm
    if _llm is None:
        _llm = _get_llm()
    return create_react_agent(
        model=_llm,
        tools=_tools,
        prompt=SYSTEM_PROMPT,
    )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _extract_final_output(result: dict) -> dict:
    """Parse LangGraph agent result into a clean response dict."""
    messages = result.get("messages", [])

    # Final answer is the last AI message
    final_output = ""
    if messages:
        final_output = messages[-1].content if hasattr(messages[-1], "content") else str(messages[-1])

    # Extract intermediate tool-call steps
    steps = []
    for msg in messages:
        if hasattr(msg, "tool_calls") and msg.tool_calls:
            for tc in msg.tool_calls:
                steps.append({
                    "tool": tc.get("name", "unknown"),
                    "tool_input": tc.get("args", {}),
                })
        if hasattr(msg, "name") and msg.name:  # ToolMessage
            steps.append({
                "tool": msg.name,
                "observation": msg.content[:500] if hasattr(msg, "content") else "",
            })

    return {
        "output": final_output,
        "intermediate_steps": steps,
    }


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
async def handle_route_pivot(context: RoutePivotContext) -> dict:
    """Run the transit recovery agent for a given disruption context.

    Parameters
    ----------
    context:
        Typed disruption context with origin, destination, and blocked
        transport mode.

    Returns
    -------
    dict
        Keys: "output" (final answer string),
              "intermediate_steps" (tool call trace for debugging).

    Raises
    ------
    RuntimeError
        If the agent executor fails.
    """
    user_input = (
        f"My {context.blocked_transport_mode} from {context.origin} to "
        f"{context.destination} has been cancelled due to a disruption. "
        f"I need an alternative route and help negotiating local transport. "
        f"The blocked transport mode is: {context.blocked_transport_mode}."
    )

    try:
        agent = _get_agent()
        result = await agent.ainvoke(
            {"messages": [HumanMessage(content=user_input)]}
        )
        parsed = _extract_final_output(result)
        logger.info(
            "Route pivot complete: %d intermediate steps",
            len(parsed["intermediate_steps"]),
        )
        return parsed

    except Exception as exc:
        logger.exception("Route pivot agent failed")
        raise RuntimeError(
            f"Route pivot failed: {type(exc).__name__}: {exc}"
        ) from exc


async def handle_route_pivot_from_text(disruption_text: str) -> dict:
    """Convenience wrapper — accepts raw disruption text instead of
    a typed RoutePivotContext.

    Useful when the Flutter frontend sends a free-form disruption
    report and we want the LLM to figure out origin/destination
    from the narrative.

    Parameters
    ----------
    disruption_text:
        Raw user message like "My train from Kandy to Ella was
        cancelled because of a landslide".

    Returns
    -------
    dict
        Same shape as handle_route_pivot output.
    """
    try:
        agent = _get_agent()
        result = await agent.ainvoke(
            {"messages": [HumanMessage(content=disruption_text)]}
        )
        parsed = _extract_final_output(result)
        logger.info("Route pivot (free-text) complete")
        return parsed

    except Exception as exc:
        logger.exception("Route pivot agent (free-text) failed")
        raise RuntimeError(
            f"Route pivot failed: {type(exc).__name__}: {exc}"
        ) from exc


# ── Intelligent Route Planning with structured output ──────────────────────

ROUTE_PLANNING_SYSTEM_PROMPT = """\
You are an **Intelligent Route Planning Assistant** for a Sri Lanka tourism app.

Your task is to plan optimal routes based on user preferences including:
- Origin and destination locations
- User interests (temples, nature, museums, food, shopping, beaches, history, photography)
- Budget constraints (in Sri Lankan Rupees)
- Time available (in minutes)
- Preferred transport mode (car, bus, train, tuktok, walking, or any)
- Current disruptions or news affecting travel

You must:
1. Use `geocode_location` tool to get coordinates for origin and destination if they are city/town names
2. Use `calculate_osrm_fallback` tool to compute driving route between coordinates
3. Use `search_tourist_pois` tool to find points of interest matching user interests along the route
4. Determine the best transport mode based on preferences, budget, and time
5. Recommend POIs along the route matching user interests, filtered by budget and time
6. Provide turn-by-turn navigation instructions
7. Estimate costs and durations
8. Handle disruptions by suggesting alternative routes

Always respond with a JSON object in this exact format:
{
  "success": true,
  "summary": "Brief summary of the route plan",
  "total_distance_km": 12.5,
  "total_duration_minutes": 45.0,
  "estimated_cost": 850.0,
  "transport_mode": "car",
  "steps": [
    {"instruction": "Head north on Main Street", "distance": 500.0, "duration": 120.0, "maneuver_type": "straight", "location": [79.8612, 6.9271]}
  ],
  "recommendations": [
    {"name": "Gangarama Temple", "type": "temple", "description": "Famous Buddhist temple", "distance_from_route": 0.5, "estimated_duration_minutes": 30, "cost": 500.0, "rating": 4.5, "image_url": null}
  ],
  "polyline": [[79.8612, 6.9271], [79.8620, 6.9280]]
}

If you cannot compute exact route data, provide reasonable estimates based on your knowledge of Sri Lankan geography and typical travel times/costs.

Key cost estimates per km:
- Car/Taxi: Rs 45/km
- Bus: Rs 5/km  
- Train: Rs 8/km
- Tuk-tuk: Rs 35/km
- Walking: Rs 0/km

Major city coordinates (lon, lat):
- Colombo: 79.8612, 6.9271
- Kandy: 80.6350, 7.2906
- Ella: 81.0466, 6.8667
- Galle: 80.2170, 6.0535
- Sigiriya: 80.7600, 7.9570
- Nuwara Eliya: 80.7670, 6.9497
- Trincomalee: 81.2152, 8.5874
- Jaffna: 80.0255, 9.6615
- Anuradhapura: 80.4036, 8.3114
- Dambulla: 80.6518, 7.8742
- Mirissa: 80.4582, 5.9483
- Arugam Bay: 81.8363, 6.8406

When using search_tourist_pois, provide center coordinates (lat, lon), user interests list, budget, and time available. The tool will return POIs filtered by those constraints.
"""


async def handle_intelligent_route_planning(
    origin: str,
    destination: str,
    interests: list[str],
    budget: float,
    time_available_minutes: int,
    disruptions: str | None = None,
    preferred_transport_mode: str = "any",
) -> dict[str, Any]:
    """Plan an intelligent route with structured JSON output.
    
    This function creates a comprehensive route plan considering user preferences
    and returns structured data compatible with the Flutter frontend's RoutePlanResponse model.
    
    Parameters
    ----------
    origin: Starting location name
    destination: Destination location name
    interests: List of user interests
    budget: Maximum budget in Rs
    time_available_minutes: Available time in minutes
    disruptions: Optional disruption/news text
    preferred_transport_mode: Preferred transport mode
    
    Returns
    -------
    dict
        Structured route plan with keys matching RoutePlanData schema
    """
    # Build the user prompt
    interests_str = ", ".join(interests) if interests else "general sightseeing"
    
    user_prompt = f"""Plan a route from {origin} to {destination}.

User Preferences:
- Interests: {interests_str}
- Budget: Rs {budget}
- Time Available: {time_available_minutes} minutes
- Preferred Transport: {preferred_transport_mode}
"""
    
    if disruptions:
        user_prompt += f"\nCurrent Disruptions/News: {disruptions}\nPlease adjust the route accordingly."
    
    user_prompt += "\n\nProvide the response as a valid JSON object matching the schema described above."
    
    try:
        # Create a temporary agent for route planning with JSON output
        route_llm = _get_llm()
        
        # Add OSRM tool and POI search for route calculation
        route_tools = [calculate_osrm_fallback, geocode_location, search_tourist_pois]
        
        route_agent = create_react_agent(
            model=route_llm,
            tools=route_tools,
            prompt=ROUTE_PLANNING_SYSTEM_PROMPT,
        )
        
        result = await route_agent.ainvoke(
            {"messages": [HumanMessage(content=user_prompt)]}
        )
        
        # Extract the final response
        messages = result.get("messages", [])
        if not messages:
            raise RuntimeError("No response from route planning agent")
        
        final_message = messages[-1].content if hasattr(messages[-1], "content") else str(messages[-1])
        
        # Try to extract JSON from the response
        json_match = re.search(r'\{[\s\S]*\}', final_message)
        if json_match:
            json_str = json_match.group(0)
            try:
                route_data = json.loads(json_str)
                logger.info("Successfully parsed route planning JSON response")
                return route_data
            except json.JSONDecodeError as e:
                logger.warning(f"Failed to parse JSON: {e}")
        
        # Fallback: generate a basic response structure
        logger.warning("Could not parse JSON from LLM response, generating fallback")
        return _generate_fallback_route_plan(origin, destination, interests, budget, time_available_minutes, preferred_transport_mode)
        
    except Exception as exc:
        logger.exception("Intelligent route planning failed")
        raise RuntimeError(
            f"Route planning failed: {type(exc).__name__}: {exc}"
        ) from exc


def _generate_fallback_route_plan(
    origin: str,
    destination: str,
    interests: list[str],
    budget: float,
    time_available_minutes: int,
    preferred_transport_mode: str,
) -> dict[str, Any]:
    """Generate a basic fallback route plan when LLM parsing fails."""
    
    # Determine transport mode
    if preferred_transport_mode != "any":
        transport_mode = preferred_transport_mode
    elif budget < 100:
        transport_mode = "bus"
    elif budget < 500:
        transport_mode = "tuktok"
    else:
        transport_mode = "car"
    
    # Cost per km mapping
    cost_per_km = {
        "car": 45.0,
        "bus": 5.0,
        "train": 8.0,
        "tuktok": 35.0,
        "walking": 0.0,
    }.get(transport_mode, 35.0)
    
    # Estimate distance based on time and mode
    speed_kmh = {"car": 40, "bus": 30, "train": 50, "tuktok": 25, "walking": 5}.get(transport_mode, 30)
    estimated_distance_km = (speed_kmh * time_available_minutes) / 60
    
    # Calculate estimated cost
    estimated_cost = min(estimated_distance_km * cost_per_km, budget)
    
    # Generate basic steps
    steps = [
        NavigationStepData(
            instruction=f"Start from {origin}",
            distance=0,
            duration=0,
            maneuver_type="start",
            location=None,
        ).model_dump(),
        NavigationStepData(
            instruction=f"Travel towards {destination} via main roads",
            distance=estimated_distance_km * 1000 * 0.5,
            duration=time_available_minutes * 60 * 0.4,
            maneuver_type="straight",
            location=None,
        ).model_dump(),
        NavigationStepData(
            instruction=f"Arrive at {destination}",
            distance=estimated_distance_km * 1000 * 0.5,
            duration=time_available_minutes * 60 * 0.6,
            maneuver_type="arrive",
            location=None,
        ).model_dump(),
    ]
    
    # Generate POI recommendations based on interests
    recommendations = []
    poi_templates = {
        "temples": {"name": "Local Temple", "type": "temple", "description": "Beautiful Buddhist temple with historical significance", "cost": 500},
        "nature": {"name": "Scenic Viewpoint", "type": "nature", "description": "Panoramic views of the surrounding landscape", "cost": 0},
        "museums": {"name": "Cultural Museum", "type": "museum", "description": "Exhibits showcasing local heritage and history", "cost": 800},
        "food": {"name": "Local Restaurant", "type": "restaurant", "description": "Authentic Sri Lankan cuisine", "cost": 600},
        "shopping": {"name": "Local Market", "type": "market", "description": "Traditional crafts and souvenirs", "cost": 0},
        "beaches": {"name": "Beach Access Point", "type": "beach", "description": "Clean sandy beach perfect for relaxation", "cost": 0},
        "history": {"name": "Historical Site", "type": "historical", "description": "Ancient ruins with rich cultural heritage", "cost": 1000},
        "photography": {"name": "Photo Spot", "type": "viewpoint", "description": "Instagram-worthy scenic location", "cost": 0},
    }
    
    for interest in interests[:3]:  # Max 3 recommendations
        if interest in poi_templates:
            template = poi_templates[interest]
            recommendations.append(
                RouteRecommendationData(
                    name=template["name"],
                    type=template["type"],
                    description=template["description"],
                    distance_from_route=0.3,
                    estimated_duration_minutes=20,
                    cost=template["cost"],
                    rating=4.2,
                    image_url=None,
                ).model_dump()
            )
    
    return {
        "success": True,
        "summary": f"Route from {origin} to {destination} via {transport_mode}",
        "total_distance_km": round(estimated_distance_km, 2),
        "total_duration_minutes": float(time_available_minutes),
        "estimated_cost": round(estimated_cost, 2),
        "transport_mode": transport_mode,
        "steps": steps,
        "recommendations": recommendations,
        "polyline": [],
        "error": None,
    }
