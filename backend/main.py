"""
AYU Backend — FastAPI application entry point.

Starts the unified FastAPI server that serves:
  • /api/ai/…         — Vision analysis, route pivot (existing agents)
  • /api/guardian/…   — Real-time Guardian scam-detection WebSocket
  • /health           — Top-level health check

Run locally:
    uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload

Production (Render / Railway / GCP Cloud Run):
    uvicorn backend.main:app --host 0.0.0.0 --port $PORT --workers 2
"""

from __future__ import annotations

import logging
import os
import time
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# ── Load env before any sub-module import ─────────────────────────────────────
load_dotenv()

# ── Logging ───────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# ── Routers ───────────────────────────────────────────────────────────────────
from backend.agents.api import router as ai_router                     # noqa: E402
from backend.agents.guardian_api import guardian_router, manager       # noqa: E402


# ── Lifespan (startup / shutdown hooks) ───────────────────────────────────────


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan — run startup tasks, then teardown on exit."""
    logger.info("🛡️  AYU backend starting up…")

    # Pre-warm the Gemini LLM connection (avoids cold-start latency on first WS call)
    try:
        from backend.agents.guardian_agent import run_guardian_agent
        await run_guardian_agent("warmup", "Sri Lanka")
        logger.info("✅  Guardian LLM pre-warmed.")
    except Exception as exc:  # noqa: BLE001
        logger.warning("⚠️  Guardian LLM pre-warm failed (non-fatal): %s", exc)

    yield  # ← server is live from here

    logger.info("🔻  AYU backend shutting down. Active WS: %d", manager.active_count)


# ── App factory ───────────────────────────────────────────────────────────────


def create_app() -> FastAPI:
    app = FastAPI(
        title="AYU — AI Travel Companion API",
        description=(
            "Backend for the AYU tourist-safety app. "
            "Provides vision analysis, smart routing, and real-time Guardian scam detection."
        ),
        version="1.0.0",
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url="/redoc",
    )

    # ── CORS ─────────────────────────────────────────────────────────────────
    # Allow Flutter web, mobile debug, and local Next.js front-ends.
    allowed_origins = os.getenv(
        "CORS_ORIGINS",
        "http://localhost,http://localhost:3000,http://localhost:8080",
    ).split(",")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],          # tighten to allowed_origins in production
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ── Request timing middleware ─────────────────────────────────────────────
    @app.middleware("http")
    async def add_process_time_header(request: Request, call_next):
        start = time.perf_counter()
        response = await call_next(request)
        elapsed = round((time.perf_counter() - start) * 1000, 1)
        response.headers["X-Process-Time-Ms"] = str(elapsed)
        return response

    # ── Global exception handler ──────────────────────────────────────────────
    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception):
        logger.exception("Unhandled exception on %s %s", request.method, request.url)
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error", "error": str(exc)},
        )

    # ── Mount routers ─────────────────────────────────────────────────────────
    app.include_router(ai_router,       prefix="/api/ai",       tags=["AI Agents"])
    app.include_router(guardian_router, prefix="/api/guardian",  tags=["Guardian"])

    # ── Root health checks ────────────────────────────────────────────────────
    @app.get("/health", tags=["System"])
    async def health():
        """Top-level liveness probe for load balancers and Docker HEALTHCHECK."""
        return {
            "status": "ok",
            "service": "ayu-backend",
            "guardian_connections": manager.active_count,
        }

    @app.get("/", tags=["System"])
    async def root():
        return {
            "message": "🛡️ AYU Backend is running.",
            "docs": "/docs",
            "guardian_ws": "ws://<host>/api/guardian/stream",
        }

    return app


# ── Module-level app instance (for uvicorn) ───────────────────────────────────
app = create_app()
