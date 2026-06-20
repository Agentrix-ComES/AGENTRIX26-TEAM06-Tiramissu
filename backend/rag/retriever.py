"""
RAG Retriever — Core knowledge retrieval logic.

This module is the primary integration point between the FAISS vector store
(built by ingest.py) and Imaadh's LangChain tools in agents/tools.py.

Usage (from tools.py):
    from backend.rag.retriever import retrieve_knowledge

    result = retrieve_knowledge("hiring a tuk-tuk in Kandy")
    # returns a clean, LLM-readable string of the most relevant knowledge chunks

Design:
    - The FAISS index is loaded ONCE at module level (singleton pattern).
      This is critical for performance — loading from disk on every agent
      tool call would be unacceptably slow.
    - Falls back to a hardcoded safety message if the index is not found,
      so the agent never crashes even if ingest.py has not been run yet.
"""

from __future__ import annotations

import logging
import os

logger = logging.getLogger(__name__)

# ── Resolve vector store path ─────────────────────────────────────────────────
_THIS_DIR = os.path.dirname(os.path.abspath(__file__))
_VECTOR_STORE_DIR = os.path.join(_THIS_DIR, "vector_store")

# ── Embedding model (must match the model used in ingest.py) ──────────────────
_EMBEDDING_MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"

# ── Module-level singletons (loaded once, reused on every call) ───────────────
_embeddings = None
_vector_store = None


def _get_embeddings():
    """Lazy-load the HuggingFace embedding model (singleton)."""
    global _embeddings
    if _embeddings is None:
        try:
            from langchain_huggingface import HuggingFaceEmbeddings

            logger.info("Loading embedding model: %s", _EMBEDDING_MODEL_NAME)
            _embeddings = HuggingFaceEmbeddings(
                model_name=_EMBEDDING_MODEL_NAME,
                model_kwargs={"device": "cpu"},
                encode_kwargs={"normalize_embeddings": True},
            )
            logger.info("Embedding model loaded successfully.")
        except Exception as exc:
            logger.error("Failed to load embedding model: %s", exc)
            raise
    return _embeddings


def _get_vector_store():
    """Lazy-load the FAISS index from disk (singleton).

    Returns None if the index has not been built yet (ingest.py not run).
    """
    global _vector_store
    if _vector_store is None:
        if not os.path.isdir(_VECTOR_STORE_DIR):
            logger.warning(
                "Vector store not found at %s. "
                "Run 'python -m backend.rag.ingest' to build the index.",
                _VECTOR_STORE_DIR,
            )
            return None

        index_file = os.path.join(_VECTOR_STORE_DIR, "index.faiss")
        if not os.path.isfile(index_file) or os.path.getsize(index_file) == 0:
            logger.warning(
                "FAISS index file is missing or empty at %s. "
                "Run 'python -m backend.rag.ingest' to build the index.",
                index_file,
            )
            return None

        try:
            from langchain_community.vectorstores import FAISS

            logger.info("Loading FAISS index from: %s", _VECTOR_STORE_DIR)
            _vector_store = FAISS.load_local(
                _VECTOR_STORE_DIR,
                _get_embeddings(),
                allow_dangerous_deserialization=True,
            )
            logger.info("FAISS index loaded successfully.")
        except Exception as exc:
            logger.error("Failed to load FAISS index: %s", exc)
            return None

    return _vector_store


def retrieve_knowledge(query: str, top_k: int = 3) -> str:
    """Query the FAISS vector store and return a formatted string of
    the most relevant knowledge chunks.

    This is the ONLY function that Imaadh's tools.py should call.
    It is designed to be a drop-in replacement for the mock knowledge
    dictionary in search_cultural_knowledge().

    Parameters
    ----------
    query:
        Free-text search query from the LangChain agent
        (e.g. "hiring a tuk-tuk in Kandy").
    top_k:
        Number of most-relevant chunks to retrieve. Defaults to 3.

    Returns
    -------
    str
        A clean, LLM-readable string of the retrieved knowledge,
        formatted with source attribution. Falls back to a safety
        message if the vector store is unavailable.
    """
    store = _get_vector_store()

    # ── Graceful fallback if the FAISS index is not ready ─────────────────────
    if store is None:
        logger.warning("Vector store unavailable — returning fallback message.")
        return (
            "In Sri Lanka, always negotiate tuk-tuk fares before getting in. "
            "A reasonable rate is LKR 60-80 per kilometre. "
            "Use the phrase 'Kiyada?' (How much?) to start negotiations. "
            "If your train is cancelled, private buses run the same routes. "
            "Always dress modestly when visiting temples — cover shoulders and knees."
        )

    try:
        # ── Run similarity search ─────────────────────────────────────────────
        results_with_scores = store.similarity_search_with_score(query, k=top_k)

        if not results_with_scores:
            logger.warning("No results found for query: '%s'", query)
            return "No specific knowledge found for this query. Please ask a local guide."

        # ── Format results into a clean, LLM-readable string ─────────────────
        formatted_parts = []
        for doc, score in results_with_scores:
            source = doc.metadata.get("source", "knowledge base")
            formatted_parts.append(
                f"[Source: {source}]\n{doc.page_content.strip()}"
            )

        formatted_answer = "\n\n---\n\n".join(formatted_parts)

        logger.info(
            "RAG retrieval complete: query='%s', chunks_returned=%d",
            query,
            len(results_with_scores),
        )

        return formatted_answer

    except Exception as exc:
        logger.exception("RAG retrieval failed for query: '%s'", query)
        return (
            f"Knowledge retrieval encountered an error: {type(exc).__name__}. "
            "In Sri Lanka, always negotiate transport fares in advance and "
            "dress modestly when visiting religious sites."
        )
