"""
Quick smoke test for the AI agents.
Run: python backend/test_agents.py
"""

import asyncio
import json
import sys
import os

# Force UTF-8 on Windows terminals
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

# Ensure backend is importable
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
load_dotenv()


async def test_tools():
    """Test the LangChain tools independently."""
    print("=" * 60)
    print("TEST 1: OSRM Fallback Tool")
    print("=" * 60)

    from backend.agents.tools import calculate_osrm_fallback, search_cultural_knowledge

    # Kandy -> Ella (a classic Sri Lanka route)
    result = calculate_osrm_fallback.invoke({
        "origin_coords": "80.6350,7.2906",
        "dest_coords": "81.0466,6.8667",
    })
    print(f"OSRM Result:\n{result}\n")

    print("=" * 60)
    print("TEST 2: Cultural Knowledge Tool (mocked)")
    print("=" * 60)

    for query in ["hiring a tuk-tuk", "visiting a temple", "train cancelled"]:
        result = search_cultural_knowledge.invoke({"query": query})
        print(f"Query: '{query}'\nResult: {result[:80]}...\n")

    print("TOOLS: ALL PASSED ✓\n")


async def test_route_crew():
    """Test the route pivot agent with a real Gemini call."""
    print("=" * 60)
    print("TEST 3: Route Pivot Crew (Gemini + OSRM)")
    print("=" * 60)

    from backend.agents.route_crew import handle_route_pivot_from_text

    result = await handle_route_pivot_from_text(
        "My train from Kandy to Ella has been cancelled due to a landslide. "
        "I need an alternative way to get there."
    )
    print(f"\nFinal Output:\n{result['output']}")
    print(f"\nIntermediate steps: {len(result['intermediate_steps'])}")
    for i, step in enumerate(result["intermediate_steps"]):
        print(f"  Step {i+1}: {step['tool']}({str(step['tool_input'])[:60]}...)")

    print("\nROUTE CREW: PASSED ✓\n")


async def test_vision_agent():
    """Test the vision agent with a tiny synthetic image."""
    print("=" * 60)
    print("TEST 4: Vision Agent (Gemini multimodal)")
    print("=" * 60)

    from backend.agents.vision_agent import analyze_monument

    # Create a minimal 1x1 white JPEG for a quick smoke test.
    # The LLM won't identify anything real, but we verify the
    # pipeline doesn't crash and returns a valid VisionAnalysis.
    import struct
    # Minimal valid JPEG: SOI + APP0 + minimal frame
    # Instead, let's just use a tiny PNG via raw bytes
    # We'll use a small real-ish test: just pass minimal bytes
    # and accept that the LLM will say "unidentified"
    
    # Tiny 1x1 white PNG
    import base64
    tiny_png = base64.b64decode(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4"
        "nGP4z8BQDwAEgAF/pooBPQAAAABJRU5ErkJggg=="
    )

    result = await analyze_monument(
        image_bytes=tiny_png,
        user_context="I am near a historical site in Anuradhapura, Sri Lanka.",
    )
    print(f"Site name: {result.site_name}")
    print(f"Historical context: {result.historical_context[:80]}...")
    print(f"Cultural rules: {result.cultural_rules}")
    print(f"Audio script length: {len(result.audio_script)} chars")

    print("\nVISION AGENT: PASSED ✓\n")


async def test_rag_retriever():
    """Test the FAISS RAG retriever with domain-specific queries."""
    print("=" * 60)
    print("TEST 5: RAG Retriever (FAISS knowledge base)")
    print("=" * 60)

    from backend.rag.retriever import retrieve_knowledge

    test_queries = [
        ("hiring a tuk-tuk in Kandy", "transport"),
        ("temple dress code rules", "etiquette"),
        ("gem scam warning signs", "scam"),
        ("train cancelled alternative transport", "transport"),
        ("Sinhala phrase for how much", "phrases"),
        ("Sigiriya Rock Fortress history", "landmark"),
    ]

    all_passed = True
    for query, expected_topic in test_queries:
        result = retrieve_knowledge(query, top_k=3)
        passed = len(result) > 50  # should return real content
        status = "✓" if passed else "✗ FAILED"
        if not passed:
            all_passed = False
        print(f"  [{status}] Query: '{query}'")
        print(f"          Result preview: {result[:100].strip()}...\n")

    if all_passed:
        print("RAG RETRIEVER: ALL PASSED ✓\n")
    else:
        print("RAG RETRIEVER: SOME TESTS FAILED — check vector store.\n")
        print("  Tip: Run 'python -m backend.rag.ingest' to build the index.\n")


async def main():
    print("\n>>> AGENT SMOKE TESTS\n")

    # Test 1 & 2: Tools (no LLM needed)
    await test_tools()

    # Test 5: RAG retriever (no LLM needed — pure vector search)
    try:
        await test_rag_retriever()
    except Exception as e:
        print(f"RAG RETRIEVER FAILED: {e}\n")
        print("  Tip: Run 'python -m backend.rag.ingest' first.\n")

    # Test 3: Route crew (needs Gemini API key)
    try:
        await test_route_crew()
    except Exception as e:
        print(f"ROUTE CREW FAILED: {e}\n")

    # Test 4: Vision agent (needs Gemini API key)
    try:
        await test_vision_agent()
    except Exception as e:
        print(f"VISION AGENT FAILED: {e}\n")

    print("=" * 60)
    print(">>> ALL SMOKE TESTS COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
