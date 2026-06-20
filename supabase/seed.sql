-- CeylonGuide Kandy Tourism Seed Data

-- 1. Populate Places (Kandy landmarks)
INSERT INTO public.places (id, name, description, latitude, longitude, rating)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'Temple of the Sacred Tooth Relic', 'The golden-roofed temple houses Sri Lanka’s most important Buddhist relic — a tooth of the Buddha. Located in the royal palace complex of the former Kingdom of Kandy.', 7.2936, 80.6413, 4.8),
    ('22222222-2222-2222-2222-222222222222', 'Kandy Lake', 'A picturesque artificial lake built in 1812 by King Sri Wickrama Rajasinghe, situated in the heart of Kandy city next to the Temple of the Tooth.', 7.2906, 80.6416, 4.3),
    ('33333333-3333-3333-3333-333333333333', 'Royal Botanical Gardens Peradeniya', 'Renowned for its collection of orchids and more than 4,000 species of plants, located just 5.5 km west of the Kandy city centre.', 7.2725, 80.5982, 4.6),
    ('44444444-4444-4444-4444-444444444444', 'Bahirawakanda Vihara Buddha Statue', 'A giant 88-foot tall statue of Buddha sitting on a hilltop, offering panoramic views of Kandy city and surrounding valleys.', 7.2917, 80.6294, 4.4)
ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    rating = EXCLUDED.rating;

-- 2. Populate Place Tags
INSERT INTO public.place_tags (place_id, tag)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'religious'),
    ('11111111-1111-1111-1111-111111111111', 'unesco'),
    ('11111111-1111-1111-1111-111111111111', 'history'),
    ('22222222-2222-2222-2222-222222222222', 'nature'),
    ('22222222-2222-2222-2222-222222222222', 'scenic'),
    ('33333333-3333-3333-3333-333333333333', 'botanical'),
    ('33333333-3333-3333-3333-333333333333', 'nature'),
    ('44444444-4444-4444-4444-444444444444', 'religious'),
    ('44444444-4444-4444-4444-444444444444', 'viewpoint')
ON CONFLICT (place_id, tag) DO NOTHING;

-- 3. Populate Transport Routes
INSERT INTO public.transport_routes (origin_place_id, destination_place_id, mode, estimated_duration, estimated_cost)
VALUES
    ('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'tuk-tuk', '20 mins', 'LKR 600 - LKR 850'),
    ('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'bus', '35 mins', 'LKR 50 - LKR 80'),
    ('11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'tuk-tuk', '10 mins', 'LKR 300 - LKR 400')
ON CONFLICT (origin_place_id, destination_place_id, mode) DO NOTHING;

-- 4. Populate Place Knowledge (Local tips/safety warnings)
INSERT INTO public.place_knowledge (place_id, category, title, content)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'cultural_etiquette', 'Temple Dress Code Guidelines', 'Wear white or light colors. Keep shoulders and knees fully covered. You must remove shoes at the entrance counter. Photography of people posing directly in front of the Buddha statue is considered highly disrespectful.'),
    ('22222222-2222-2222-2222-222222222222', 'scam_alerts', 'Kandy Lake Unofficial Tour Guides', 'Beware of touts offering cheap city tours or pushing you to visit specific gemstone showrooms or spice gardens. Always book activities via registered agencies.'),
    ('33333333-3333-3333-3333-333333333333', 'transport', 'Reaching Peradeniya Gardens by Bus', 'You can catch a public bus (Route 652 Kandy-Pilimathalawa) from the Kandy Clock Tower bus stop. It stops right in front of the Peradeniya gardens entrance.')
ON CONFLICT DO NOTHING;

-- 5. Populate Sinhala Phrases
INSERT INTO public.phrases (sinhala, english, pronunciation, category)
VALUES
    ('Subha udasanak', 'Good morning', 'Soo-bha oo-dhaa-sa-nak', 'greetings'),
    ('Koheda maligawa thiyenne?', 'Where is the temple?', 'Ko-he-dha maa-li-ga-wa thee-yen-ne?', 'transport'),
    ('Mata udaw karanna', 'Help me', 'Ma-ta oo-dhow kar-an-na', 'emergencies'),
    ('Kiyada?', 'How much?', 'Kee-ya-dha?', 'shopping'),
    ('Istuti', 'Thank you', 'Iss-too-thee', 'greetings')
ON CONFLICT DO NOTHING;

-- 6. Populate Fair Price Rules
INSERT INTO public.fair_price_rules (route_name, min_price, max_price, vehicle_type, notes)
VALUES
    ('Kandy Station to Temple of the Tooth', 200.00, 300.00, 'tuk-tuk', 'Always negotiate to ensure the driver turns on the meter, or use ride-hailing apps like PickMe/Uber to compare.'),
    ('Kandy city center to Royal Botanical Gardens', 600.00, 800.00, 'tuk-tuk', 'Base fare for a distance of approximately 6km. Higher rates may apply after 9:00 PM.')
ON CONFLICT DO NOTHING;

-- 7. Populate Emergency Contacts
INSERT INTO public.emergency_contacts (name, number, category)
VALUES
    ('Kandy Tourist Police', '081-2222222', 'police'),
    ('National Emergency Line', '119', 'police'),
    ('General Hospital Kandy', '081-2233337', 'medical'),
    ('Ambulance Service (Suwa Seriya)', '1990', 'medical')
ON CONFLICT DO NOTHING;

-- 8. Populate RAG Chunks (with 768-dimensional mock vector embeddings)
INSERT INTO public.rag_chunks (place_id, content, source, embedding)
VALUES
    (
        '11111111-1111-1111-1111-111111111111',
        'The Sri Dalada Maligawa (Temple of the Sacred Tooth Relic) in Kandy is a UNESCO World Heritage site. It houses the sacred tooth relic of Gautama Buddha, which has been protected by Sri Lankan kings for centuries. Worship rituals (Tewava) are performed three times daily: at dawn, at noon, and in the evening.',
        'landmarks.md',
        array_fill(0.0156::double precision, ARRAY[768])::vector
    ),
    (
        '22222222-2222-2222-2222-222222222222',
        'Kandy Lake, also known as Kiri Muhuda (Sea of Milk), is a man-made body of water built in 1812. It was commissioned by King Sri Wickrama Rajasinghe next to the Palace. The decorative white stone wall running along the perimeter is called the Diyareli Bemma (water wave wall).',
        'transport.md',
        array_fill(0.0245::double precision, ARRAY[768])::vector
    ),
    (
        '33333333-3333-3333-3333-333333333333',
        'The Royal Botanical Gardens of Peradeniya were established in 1371 as a pleasure garden for the Gampola kings, before being developed into formal botanical gardens by the British. Features include an extensive orchid house, a giant Javan fig tree, and an avenue of royal palms.',
        'landmarks.md',
        array_fill(0.0384::double precision, ARRAY[768])::vector
    )
ON CONFLICT DO NOTHING;
