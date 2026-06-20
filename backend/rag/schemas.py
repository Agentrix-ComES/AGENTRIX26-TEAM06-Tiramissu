"""
Pydantic schemas for the RAG (Retrieval-Augmented Generation) layer.

These models define the data contracts between the FAISS retriever
and the LangChain tools that consume the retrieved knowledge.
"""

from __future__ import annotations

from typing import List

from pydantic import BaseModel, Field


class RetrievedChunk(BaseModel):
    """A single document chunk returned by the FAISS retriever."""

    content: str = Field(
        ...,
        description="The raw text content of the retrieved knowledge chunk.",
    )
    source: str = Field(
        ...,
        description="The source filename the chunk was retrieved from (e.g. 'transport.md').",
    )
    score: float = Field(
        ...,
        description="Cosine similarity score — higher is more relevant.",
    )


class RAGResponse(BaseModel):
    """The complete response from the RAG retriever, including all chunks
    and a pre-formatted string ready to be returned by tools.py to the LLM."""

    query: str = Field(
        ...,
        description="The original query sent to the retriever.",
    )
    chunks: List[RetrievedChunk] = Field(
        default_factory=list,
        description="List of retrieved knowledge chunks ordered by relevance.",
    )
    formatted_answer: str = Field(
        ...,
        description=(
            "A clean, LLM-readable string combining the retrieved chunks. "
            "This is the value returned directly by the search_cultural_knowledge tool."
        ),
    )
