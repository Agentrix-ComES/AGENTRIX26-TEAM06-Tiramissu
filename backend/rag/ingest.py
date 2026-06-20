"""
RAG Ingestion Pipeline — One-time script to build the FAISS vector store.

Run this script once after updating any .md knowledge files to rebuild
the local FAISS index:

    python -m backend.rag.ingest

Pipeline:
    1. Load all .md files from backend/rag/data/
    2. Split documents into overlapping chunks
    3. Generate embeddings using HuggingFace all-MiniLM-L6-v2 (local, free)
    4. Build a FAISS index from the embeddings
    5. Save the index to backend/rag/vector_store/
"""

from __future__ import annotations

import logging
import os
import sys

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)

# ── Resolve paths ──────────────────────────────────────────────────────────────
# Support running as: python -m backend.rag.ingest  OR  python backend/rag/ingest.py
_THIS_DIR = os.path.dirname(os.path.abspath(__file__))
_DATA_DIR = os.path.join(_THIS_DIR, "data")
_VECTOR_STORE_DIR = os.path.join(_THIS_DIR, "vector_store")


def build_vector_store() -> None:
    """Load knowledge docs, chunk, embed, and save the FAISS index."""

    # ── Lazy imports (only needed at ingest time, not at serve time) ──────────
    try:
        from langchain_community.document_loaders import DirectoryLoader, TextLoader
        from langchain.text_splitter import RecursiveCharacterTextSplitter
        from langchain_huggingface import HuggingFaceEmbeddings
        from langchain_community.vectorstores import FAISS
    except ImportError as exc:
        logger.error(
            "Missing dependency: %s\n"
            "Run: pip install -r backend/requirements.txt",
            exc,
        )
        sys.exit(1)

    # ── Step 1: Load all .md files from data/ ─────────────────────────────────
    logger.info("Loading knowledge documents from: %s", _DATA_DIR)

    if not os.path.isdir(_DATA_DIR):
        logger.error("Data directory not found: %s", _DATA_DIR)
        sys.exit(1)

    loader = DirectoryLoader(
        _DATA_DIR,
        glob="**/*.md",
        loader_cls=TextLoader,
        loader_kwargs={"encoding": "utf-8"},
        show_progress=True,
    )
    documents = loader.load()

    if not documents:
        logger.error(
            "No .md documents found in %s. "
            "Add knowledge files before running ingest.",
            _DATA_DIR,
        )
        sys.exit(1)

    logger.info("Loaded %d document(s).", len(documents))

    # ── Step 2: Split documents into overlapping chunks ───────────────────────
    logger.info("Splitting documents into chunks...")

    splitter = RecursiveCharacterTextSplitter(
        chunk_size=500,
        chunk_overlap=50,
        separators=["\n\n", "\n", ". ", " ", ""],
    )
    chunks = splitter.split_documents(documents)
    logger.info("Created %d chunk(s) from %d document(s).", len(chunks), len(documents))

    # Add source metadata (basename only) to each chunk for the retriever
    for chunk in chunks:
        raw_source = chunk.metadata.get("source", "unknown")
        chunk.metadata["source"] = os.path.basename(raw_source)

    # ── Step 3: Load embedding model ──────────────────────────────────────────
    logger.info("Loading HuggingFace embedding model (all-MiniLM-L6-v2)...")
    logger.info("This may take a moment on first run while the model downloads.")

    embeddings = HuggingFaceEmbeddings(
        model_name="sentence-transformers/all-MiniLM-L6-v2",
        model_kwargs={"device": "cpu"},
        encode_kwargs={"normalize_embeddings": True},
    )

    # ── Step 4: Build FAISS index ─────────────────────────────────────────────
    logger.info("Building FAISS index from %d chunks...", len(chunks))
    vector_store = FAISS.from_documents(chunks, embeddings)
    logger.info("FAISS index built successfully.")

    # ── Step 5: Save the index to disk ────────────────────────────────────────
    os.makedirs(_VECTOR_STORE_DIR, exist_ok=True)
    vector_store.save_local(_VECTOR_STORE_DIR)
    logger.info("FAISS index saved to: %s", _VECTOR_STORE_DIR)
    logger.info(
        "Files created: index.faiss, index.pkl"
    )
    logger.info("Ingestion complete. Run this script again after updating .md files.")


if __name__ == "__main__":
    build_vector_store()
