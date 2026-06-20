"""
Main FastAPI application entry point.

Run with:
    uvicorn backend.main:app --reload --port 8000
"""

import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.agents.api import router as ai_router

logging.basicConfig(level=logging.INFO)

app = FastAPI(
    title="Sri Lanka Travel Resilience API",
    description="AI-powered travel companion backend for the AYU app.",
    version="1.0.0",
)

# Allow requests from Flutter (local dev + any device on the same network)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount AI agent routes under /api/ai
app.include_router(ai_router, prefix="/api/ai", tags=["AI Agents"])

@app.get("/")
async def root():
    return {"message": "AYU Travel Resilience API is running 🚀"}

@app.get("/health")
async def health():
    return {"status": "ok"}
