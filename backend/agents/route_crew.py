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

from .schemas import RoutePivotContext
from .tools import calculate_osrm_fallback, search_cultural_knowledge

load_dotenv()

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# LLM
# ---------------------------------------------------------------------------
_GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

if not _GEMINI_API_KEY:
    logger.warning(
        "GEMINI_API_KEY is not set — route crew calls will fail at runtime."
    )

_llm = ChatGoogleGenerativeAI(
    model="gemini-2.0-flash",
    google_api_key=_GEMINI_API_KEY,
    temperature=0.3,
    max_output_tokens=2048,
)

# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------
_tools = [calculate_osrm_fallback, search_cultural_knowledge]

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
_agent = create_react_agent(
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
        result = await _agent.ainvoke(
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
        result = await _agent.ainvoke(
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
