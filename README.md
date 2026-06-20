# AYU: Resilient Tourism & Cultural Navigator 🇱🇰

AYU is a travel-companion application designed to help independent travelers navigate the volatile local transit systems and cultural nuances of Sri Lanka. When trains are delayed, landslides block roads, or cultural barriers arise, AYU steps in as a resilient, offline-capable fallback to prevent itinerary collapse.

Built for **AGENTRIX 2026** by Team 06 (Tiramissu).

## Features

- **Route Pivot Agent:** When transport fails (e.g., train cancellation), AYU instantly calculates alternative routes using public APIs (OSRM) and generates localized negotiation scripts (e.g., how to hire a tuk-tuk).
- **Vision Agent:** Point your camera at a monument, and AYU uses advanced multimodal AI to analyze the site and provide cultural context.
- **Cultural Knowledge Base:** RAG-powered retrieval of local customs, scam warnings, and phonetic Sinhala phrases.
- **High Resilience:** Caches AI responses in Supabase to eliminate redundant API calls and save bandwidth/latency on mass disruption events.

## Tech Stack

### Frontend
- **Framework:** Flutter
- **Features:** Designed for offline-first architecture, Hive cache, and flutter_map integration.

### Backend & AI
- **API Framework:** FastAPI (Python)
- **AI Orchestration:** LangGraph / LangChain
- **LLM:** Google Gemini 2.0 Flash
- **Knowledge Base:** FAISS local vector store (RAG)
- **Routing:** Public OSRM API integration
- **Database & Caching:** Supabase

## Getting Started

### 1. Supabase Setup
Create a Supabase project and run the following SQL to set up the AI caching table:
```sql
CREATE TABLE ai_route_cache (
    id text PRIMARY KEY,
    response_json text NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);
```

### 2. Backend Setup
1. Navigate to the `backend` directory.
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Create a `.env` file in the root directory:
   ```env
   GEMINI_API_KEY=your_gemini_api_key
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_KEY=your_supabase_anon_key
   ```
4. Run the RAG ingest to build the vector store:
   ```bash
   python -m backend.rag.ingest
   ```
5. Start the FastAPI server (mounted by the main app):
   ```bash
   uvicorn backend.main:app --reload
   ```

### 3. Frontend Setup
1. Ensure Flutter is installed.
2. Navigate to the `lib` directory and run:
   ```bash
   flutter pub get
   flutter run
   ```

## API Documentation

- **`POST /api/ai/vision/analyze`**: Accepts an image upload to analyze landmarks.
- **`POST /api/ai/route/pivot`**: Accepts `origin`, `destination`, and `blocked_transport_mode` to calculate a fallback route.
- **`POST /api/ai/route/pivot/freetext`**: Natural language processing for unstructured disruption complaints.
