// offline_mock_data.dart

final Map<String, dynamic> mockOfflinePack = {
  "pack_id": "pack_001",
  "pack_title": "Central Province Survival Pack",
  "itinerary_json": [
    {"stop": 1, "place": "Dalada Maligawa", "transport": "Tuk-Tuk (Meter)", "est_cost_lkr": 400},
    {"stop": 2, "place": "Sigiriya Rock", "transport": "Intercity Bus", "est_cost_lkr": 1500}
  ],
  "phrases_json": [
    {"context": "Negotiation", "english": "Please use the meter.", "sinhala": "Karunakara meter eka danna."},
    {"context": "Declining", "english": "No thank you, I know the price.", "sinhala": "Epa sthuthiy, mama gaana dannawa."}
  ],
  "cultural_rules_json": [
    "Dalada Maligawa: White clothes, cover shoulders/knees.",
    "Do not take photos with your back facing a Buddha statue."
  ],
  "emergency_json": {
    "tourist_police": "1912",
    "ambulance": "1990",
    "kandy_hospital": "0812 222 261"
  }
};
