-- CeylonGuide AI database schema migration

-- Enable PostgreSQL Extensions
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. App Users (Registered CeylonGuide app users)
CREATE TABLE IF NOT EXISTS public.app_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    display_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 2. Places (Landmarks / Attractions in Sri Lanka)
CREATE TABLE IF NOT EXISTS public.places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    description TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    rating NUMERIC(3, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 3. Trips (Traveler-planned trips)
CREATE TABLE IF NOT EXISTS public.trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.app_users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 4. Place Tags (Categorisation for discovery search)
CREATE TABLE IF NOT EXISTS public.place_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id UUID NOT NULL REFERENCES public.places(id) ON DELETE CASCADE,
    tag TEXT NOT NULL,
    UNIQUE (place_id, tag)
);

-- 5. Transport Routes (Travel times/costs between landmarks)
CREATE TABLE IF NOT EXISTS public.transport_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    origin_place_id UUID NOT NULL REFERENCES public.places(id) ON DELETE CASCADE,
    destination_place_id UUID NOT NULL REFERENCES public.places(id) ON DELETE CASCADE,
    mode TEXT NOT NULL CHECK (mode IN ('train', 'bus', 'tuk-tuk', 'taxi')),
    estimated_duration TEXT NOT NULL,
    estimated_cost TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE (origin_place_id, destination_place_id, mode)
);

-- 6. Itinerary Items (Trips planning schedule)
CREATE TABLE IF NOT EXISTS public.itinerary_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    place_id UUID NOT NULL REFERENCES public.places(id) ON DELETE CASCADE,
    visit_time TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT,
    sequence INTEGER NOT NULL,
    UNIQUE (trip_id, sequence)
);

-- 7. Place Knowledge (Local cultural etiquette, tips, safety instructions)
CREATE TABLE IF NOT EXISTS public.place_knowledge (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id UUID REFERENCES public.places(id) ON DELETE CASCADE,
    category TEXT NOT NULL CHECK (category IN ('cultural_etiquette', 'scam_alerts', 'emergency', 'transport', 'landmarks')),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 8. RAG Chunks (For semantic AI agent searches)
CREATE TABLE IF NOT EXISTS public.rag_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id UUID REFERENCES public.places(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    source TEXT NOT NULL,
    embedding vector(768) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 9. Vision Scans (Monument detection & history analysis history)
CREATE TABLE IF NOT EXISTS public.vision_scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.app_users(id) ON DELETE SET NULL,
    image_url TEXT NOT NULL,
    analysis_result JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 10. Conversation Sessions (Chatbot sessions)
CREATE TABLE IF NOT EXISTS public.conversation_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.app_users(id) ON DELETE CASCADE,
    title TEXT DEFAULT 'New Chat' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 11. Conversation Messages (Chat logs)
CREATE TABLE IF NOT EXISTS public.conversation_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.conversation_sessions(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 12. Sinhala Phrases (For quick translation feature)
CREATE TABLE IF NOT EXISTS public.phrases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sinhala TEXT NOT NULL,
    english TEXT NOT NULL,
    pronunciation TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('greetings', 'transport', 'dining', 'shopping', 'emergencies'))
);

-- 13. Fair Price Rules (To prevent traveler overcharging)
CREATE TABLE IF NOT EXISTS public.fair_price_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_name TEXT NOT NULL,
    min_price NUMERIC(10, 2) NOT NULL,
    max_price NUMERIC(10, 2) NOT NULL,
    vehicle_type TEXT NOT NULL,
    notes TEXT
);

-- 14. Emergency Contacts (Help lines in Sri Lanka)
CREATE TABLE IF NOT EXISTS public.emergency_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    number TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('police', 'medical', 'embassy', 'road_assistance'))
);

-- 15. Offline Packs (Offline maps / local DB packages)
CREATE TABLE IF NOT EXISTS public.offline_packs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    region TEXT NOT NULL,
    size_mb NUMERIC(6, 2) NOT NULL,
    download_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 16. Agent Logs (Trace agent performance and token costs)
CREATE TABLE IF NOT EXISTS public.agent_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES public.conversation_sessions(id) ON DELETE CASCADE,
    agent_name TEXT NOT NULL,
    action TEXT NOT NULL,
    input_tokens INTEGER DEFAULT 0,
    output_tokens INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- ── Create Similarity Search function for RAG chunks ──
CREATE OR REPLACE FUNCTION public.match_rag_chunks (
  query_embedding vector(768),
  match_threshold float,
  match_count int
)
RETURNS TABLE (
  id UUID,
  place_id UUID,
  content TEXT,
  source TEXT,
  similarity float
)
LANGUAGE plpgsql STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT
    rc.id,
    rc.place_id,
    rc.content,
    rc.source,
    1 - (rc.embedding <=> query_embedding) AS similarity
  FROM public.rag_chunks rc
  WHERE 1 - (rc.embedding <=> query_embedding) > match_threshold
  ORDER BY rc.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;
