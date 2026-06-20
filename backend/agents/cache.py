"""
Supabase caching layer for AI endpoints.

Provides resilient get/set operations for `ai_route_cache`.
Fails gracefully if Supabase is down or misconfigured.
"""

from __future__ import annotations

import hashlib
import json
import logging
import os

from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

# ── Supabase client init ──────────────────────────────────────────────────
_SUPABASE_URL = os.getenv("SUPABASE_URL", "")
_SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")

_supabase_client = None

if _SUPABASE_URL and _SUPABASE_KEY:
    try:
        from supabase import create_client, Client
        _supabase_client = create_client(_SUPABASE_URL, _SUPABASE_KEY)
        logger.info("Supabase client initialized for caching.")
    except Exception as exc:
        logger.warning(f"Failed to initialize Supabase client: {exc}")
else:
    logger.warning("SUPABASE_URL or SUPABASE_KEY missing. Caching disabled.")


# ── Helpers ───────────────────────────────────────────────────────────────
def _generate_cache_key(origin: str, destination: str, mode: str) -> str:
    """Generate a deterministic hash for the route parameters."""
    raw = f"{origin.strip().lower()}|{destination.strip().lower()}|{mode.strip().lower()}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


# ── Public API ────────────────────────────────────────────────────────────
def get_cached_route(origin: str, destination: str, mode: str) -> dict | None:
    """Retrieve a cached route response from Supabase.
    
    Returns the parsed JSON dictionary if found, else None.
    Fails gracefully on network/auth errors.
    """
    if not _supabase_client:
        return None

    cache_key = _generate_cache_key(origin, destination, mode)
    try:
        response = _supabase_client.table("ai_route_cache").select("response_json").eq("id", cache_key).execute()
        if response.data and len(response.data) > 0:
            logger.info(f"Cache HIT for route: {origin} -> {destination} ({mode})")
            return json.loads(response.data[0]["response_json"])
    except Exception as exc:
        logger.warning(f"Supabase cache read failed: {exc}")

    logger.info(f"Cache MISS for route: {origin} -> {destination} ({mode})")
    return None


def set_cached_route(origin: str, destination: str, mode: str, response_data: dict) -> None:
    """Store a route response in Supabase asynchronously.
    
    Fails gracefully on network/auth errors.
    """
    if not _supabase_client:
        return

    cache_key = _generate_cache_key(origin, destination, mode)
    payload = {
        "id": cache_key,
        "response_json": json.dumps(response_data)
    }

    try:
        _supabase_client.table("ai_route_cache").upsert(payload).execute()
        logger.info(f"Cache SET for route: {origin} -> {destination} ({mode})")
    except Exception as exc:
        logger.warning(f"Supabase cache write failed: {exc}")
