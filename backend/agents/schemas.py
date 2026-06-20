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


class NavigationStepData(BaseModel):
    """A single turn-by-turn navigation step."""

    instruction: str = Field(..., description="Turn-by-turn instruction")
    distance: float = Field(..., description="Distance in meters")
    duration: float = Field(..., description="Duration in seconds")
    maneuver_type: str = Field(default="straight", description="Type of maneuver")
    location: list[float] | None = Field(default=None, description="[lon, lat] coordinate")


class RouteRecommendationData(BaseModel):
    """A recommended point of interest along the route."""

    name: str = Field(..., description="Name of the POI")
    type: str = Field(..., description="Type of POI (temple, restaurant, etc.)")
    description: str = Field(..., description="Description of the POI")
    distance_from_route: float = Field(default=0.0, description="Distance from route in km")
    estimated_duration_minutes: int = Field(default=0, description="Visit duration in minutes")
    cost: float = Field(default=0.0, description="Entry/visit cost in Rs")
    rating: float = Field(default=0.0, description="Rating out of 5")
    image_url: str | None = Field(default=None, description="Optional image URL")


class RoutePlanData(BaseModel):
    """Complete structured route plan response for the intelligent planning endpoint."""

    success: bool = Field(default=True, description="Whether the planning was successful")
    summary: str | None = Field(default=None, description="Brief summary of the route")
    total_distance_km: float = Field(default=0.0, description="Total route distance in km")
    total_duration_minutes: float = Field(default=0.0, description="Total duration in minutes")
    estimated_cost: float = Field(default=0.0, description="Estimated total cost in Rs")
    transport_mode: str = Field(default="unknown", description="Recommended transport mode")
    steps: list[NavigationStepData] = Field(default_factory=list, description="Turn-by-turn steps")
    recommendations: list[RouteRecommendationData] = Field(default_factory=list, description="POI recommendations")
    polyline: list[list[float]] = Field(default_factory=list, description="Route polyline as [[lon, lat], ...]")
    error: str | None = Field(default=None, description="Error message if failed")
