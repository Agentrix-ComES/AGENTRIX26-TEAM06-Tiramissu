"""
FastAPI router for AI agent endpoints.

These routes are mounted by Member 2's main FastAPI app. They expose
the vision agent and route-pivot crew to the Flutter frontend.

Mount with:
    from backend.agents.api import router as ai_router
    app.include_router(ai_router, prefix="/api/ai", tags=["AI Agents"])
"""

from __future__ import annotations

import logging
from typing import Optional

from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from pydantic import BaseModel

from .route_crew import handle_route_pivot, handle_route_pivot_from_text
from .schemas import PivotResponse, RoutePivotContext, VisionAnalysis
from .vision_agent import analyze_monument

logger = logging.getLogger(__name__)

router = APIRouter()


# ── Request / Response models for the API layer ──────────────────────────


class RouteDisruptionRequest(BaseModel):
    """Structured disruption report from the Flutter frontend."""
    origin: str
    destination: str
    blocked_transport_mode: str


class FreeTextDisruptionRequest(BaseModel):
    """Free-form disruption report — lets the LLM parse it."""
    message: str


class VisionResponse(BaseModel):
    """Wraps VisionAnalysis with an API-level success flag."""
    success: bool
    data: VisionAnalysis | None = None
    error: str | None = None


class RouteResponse(BaseModel):
    """Wraps route pivot output with an API-level success flag."""
    success: bool
    output: str | None = None
    steps: list[dict] | None = None
    error: str | None = None


# ── Vision endpoint ──────────────────────────────────────────────────────


@router.post("/vision/analyze", response_model=VisionResponse)
async def vision_analyze(
    image: UploadFile = File(...),
    context: str = Form(default="I am a tourist visiting Sri Lanka."),
):
    """Analyse a monument/site photo and return cultural context.

    Accepts a multipart image upload + optional text context.
    Returns structured VisionAnalysis or an error message.
    """
    try:
        image_bytes = await image.read()
        if not image_bytes:
            raise HTTPException(status_code=400, detail="Empty image file.")

        result = await analyze_monument(image_bytes, user_context=context)
        return VisionResponse(success=True, data=result)

    except RuntimeError as exc:
        logger.exception("Vision endpoint failed")
        return VisionResponse(success=False, error=str(exc))
    except Exception as exc:
        logger.exception("Unexpected error in vision endpoint")
        raise HTTPException(status_code=500, detail=str(exc))


# ── Route Pivot endpoints ────────────────────────────────────────────────


@router.post("/route/pivot", response_model=RouteResponse)
async def route_pivot_structured(body: RouteDisruptionRequest):
    """Handle a structured transit disruption report.

    The frontend sends origin, destination, and blocked transport mode.
    The agent computes a fallback route and returns negotiation scripts.
    """
    try:
        ctx = RoutePivotContext(
            origin=body.origin,
            destination=body.destination,
            blocked_transport_mode=body.blocked_transport_mode,
        )
        result = await handle_route_pivot(ctx)
        return RouteResponse(
            success=True,
            output=result["output"],
            steps=result.get("intermediate_steps"),
        )

    except RuntimeError as exc:
        logger.exception("Route pivot endpoint failed")
        return RouteResponse(success=False, error=str(exc))
    except Exception as exc:
        logger.exception("Unexpected error in route pivot endpoint")
        raise HTTPException(status_code=500, detail=str(exc))


@router.post("/route/pivot/freetext", response_model=RouteResponse)
async def route_pivot_freetext(body: FreeTextDisruptionRequest):
    """Handle a free-text transit disruption report.

    The traveler describes their situation in natural language and the
    agent figures out origin/destination/mode from the text.
    """
    try:
        if not body.message.strip():
            raise HTTPException(
                status_code=400, detail="Disruption message cannot be empty."
            )

        result = await handle_route_pivot_from_text(body.message)
        return RouteResponse(
            success=True,
            output=result["output"],
            steps=result.get("intermediate_steps"),
        )

    except RuntimeError as exc:
        logger.exception("Route pivot freetext endpoint failed")
        return RouteResponse(success=False, error=str(exc))
    except Exception as exc:
        logger.exception("Unexpected error in route pivot freetext endpoint")
        raise HTTPException(status_code=500, detail=str(exc))


# ── Health check ─────────────────────────────────────────────────────────


@router.get("/health")
async def ai_health():
    """Quick health check for the AI subsystem."""
    return {"status": "ok", "agent": "ai-core"}
