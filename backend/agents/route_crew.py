"""
Route Pivot Crew — Reactive transit recovery agent.

When a traveler reports a disruption (cancelled train, landslide,
road closure), this agent:
  1. Parses the situation into origin / destination / blocked mode.
  2. Calls the OSRM tool for a deterministic driving fallback.
  3. Queries the cultural knowledge base for local negotiation tips.
  4. Synthesises a final recovery plan with a phonetic Sinhala script.

Uses a LangChain ReAct agent backed by Gemini 1.5 Flash.
"""

from __future__ import annotations

import logging
import os

from dotenv import load_dotenv
from langchain.agents import AgentExecutor, create_react_agent
from langchain_core.prompts import PromptTemplate
from langchain_google_genai import ChatGoogleGenerativeAI

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
    model="gemini-1.5-flash",
    google_api_key=_GEMINI_API_KEY,
    temperature=0.3,
    max_output_tokens=2048,
)

# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------
_tools = [calculate_osrm_fallback, search_cultural_knowledge]

# ---------------------------------------------------------------------------
# ReAct prompt
# ---------------------------------------------------------------------------
REACT_PROMPT = PromptTemplate.from_template(
    """\
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

You have access to the following tools:

{tools}

Use the following format:

Question: the input question you must answer
Thought: you should always think about what to do
Action: the action to take, should be one of [{tool_names}]
Action Input: the input to the action
Observation: the result of the action
... (this Thought/Action/Action Input/Observation can repeat N times)
Thought: I now know the final answer
Final Answer: the final answer to the original input question

Begin!

Question: {input}
Thought:{agent_scratchpad}"""
)

# ---------------------------------------------------------------------------
# Agent executor
# ---------------------------------------------------------------------------
_agent = create_react_agent(llm=_llm, tools=_tools, prompt=REACT_PROMPT)

_executor = AgentExecutor(
    agent=_agent,
    tools=_tools,
    verbose=True,
    max_iterations=6,
    handle_parsing_errors=True,
    return_intermediate_steps=True,
)


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
        result = await _executor.ainvoke({"input": user_input})
        logger.info(
            "Route pivot complete: %d intermediate steps",
            len(result.get("intermediate_steps", [])),
        )
        return {
            "output": result.get("output", ""),
            "intermediate_steps": [
                {
                    "tool": step[0].tool,
                    "tool_input": step[0].tool_input,
                    "observation": str(step[1]),
                }
                for step in result.get("intermediate_steps", [])
            ],
        }

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
        result = await _executor.ainvoke({"input": disruption_text})
        logger.info("Route pivot (free-text) complete")
        return {
            "output": result.get("output", ""),
            "intermediate_steps": [
                {
                    "tool": step[0].tool,
                    "tool_input": step[0].tool_input,
                    "observation": str(step[1]),
                }
                for step in result.get("intermediate_steps", [])
            ],
        }

    except Exception as exc:
        logger.exception("Route pivot agent (free-text) failed")
        raise RuntimeError(
            f"Route pivot failed: {type(exc).__name__}: {exc}"
        ) from exc
