"""
Pydantic schemas for structured Gemini output.

These models enforce strict JSON contracts on LLM responses,
preventing hallucination drift and guaranteeing downstream
consumers (Flutter frontend, route crew) get typed data.
"""

from __future__ import annotations

from pydantic import BaseModel, Field


class VisionAnalysis(BaseModel):
    """Structured output from the monument/site vision agent.

    Gemini returns this schema when analyzing a camera frame,
    giving the frontend everything it needs to render an AR overlay
    and trigger the audio guide.
    """

    site_name: str = Field(
        ...,
        description="Canonical English name of the identified landmark or site.",
    )
    historical_context: str = Field(
        ...,
        description=(
            "Two-to-four sentence historical background suitable for "
            "text-to-speech narration to a tourist."
        ),
    )
    cultural_rules: list[str] = Field(
        default_factory=list,
        description=(
            "Actionable etiquette rules the traveler must follow at this site "
            "(e.g., 'Remove shoes before entering the temple')."
        ),
    )
    audio_script: str = Field(
        ...,
        description=(
            "A ready-to-read narration script (60-90 seconds when spoken) "
            "that a TTS engine can directly consume."
        ),
    )


class RoutePivotContext(BaseModel):
    """Input context for the reactive route-pivot agent.

    Captures the traveler's current situation when a disruption
    is reported so the route crew can compute a fallback.
    """

    origin: str = Field(
        ...,
        description="Human-readable origin location (e.g., 'Kandy Railway Station').",
    )
    destination: str = Field(
        ...,
        description="Human-readable destination (e.g., 'Ella Town').",
    )
    blocked_transport_mode: str = Field(
        ...,
        description=(
            "The transport mode that is currently disrupted "
            "(e.g., 'train', 'bus', 'road')."
        ),
    )


class OSRMRouteResult(BaseModel):
    """Parsed response from the OSRM public routing API."""

    distance_km: float = Field(
        ..., description="Total route distance in kilometres."
    )
    duration_min: float = Field(
        ..., description="Estimated travel duration in minutes."
    )
    geometry: dict = Field(
        ..., description="GeoJSON geometry object for the route polyline."
    )


class PivotResponse(BaseModel):
    """Final structured output returned by the route-pivot crew."""

    summary: str = Field(
        ...,
        description="One-paragraph human-readable recovery plan.",
    )
    fallback_route: OSRMRouteResult | None = Field(
        default=None,
        description="OSRM-computed alternative route details (None if lookup failed).",
    )
    negotiation_script: str = Field(
        ...,
        description=(
            "Phonetic Sinhala negotiation script the traveler can read "
            "aloud to hire a local tuk-tuk or van."
        ),
    )
    local_tips: str = Field(
        ...,
        description="Cultural tips for navigating the informal transport economy.",
    )
