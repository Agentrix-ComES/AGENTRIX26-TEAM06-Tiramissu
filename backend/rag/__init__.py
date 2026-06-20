"""
RAG (Retrieval-Augmented Generation) module for the Sri Lanka Travel Resilience App.

Public API:
    retrieve_knowledge(query, top_k=3) -> str
        Query the FAISS vector store for culturally relevant knowledge.
        This is the sole entry point for Imaadh's tools.py integration.
"""

from .retriever import retrieve_knowledge

__all__ = ["retrieve_knowledge"]
