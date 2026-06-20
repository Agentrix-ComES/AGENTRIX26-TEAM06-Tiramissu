class VisionAnalysis {
  final String monumentName;
  final String historicalSignificance;
  final List<String> culturalTips;

  VisionAnalysis({
    required this.monumentName,
    required this.historicalSignificance,
    required this.culturalTips,
  });

  factory VisionAnalysis.fromJson(Map<String, dynamic> json) {
    return VisionAnalysis(
      monumentName: json['monument_name'] ?? 'Unknown',
      historicalSignificance: json['historical_significance'] ?? '',
      culturalTips: List<String>.from(json['cultural_tips'] ?? []),
    );
  }
}

class VisionResponse {
  final bool success;
  final VisionAnalysis? data;
  final String? error;

  VisionResponse({required this.success, this.data, this.error});

  factory VisionResponse.fromJson(Map<String, dynamic> json) {
    return VisionResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? VisionAnalysis.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class RouteResponse {
  final bool success;
  final String? output;
  final String? error;

  RouteResponse({required this.success, this.output, this.error});

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    return RouteResponse(
      success: json['success'] ?? false,
      output: json['output'],
      error: json['error'],
    );
  }
}

class ItineraryStop {
  final String name;
  final double lat;
  final double lon;
  final int costLkr;
  final int durationMins;
  final String description;

  ItineraryStop({
    required this.name,
    required this.lat,
    required this.lon,
    required this.costLkr,
    required this.durationMins,
    required this.description,
  });

  factory ItineraryStop.fromJson(Map<String, dynamic> json) {
    return ItineraryStop(
      name: json['name'] ?? 'Unknown Stop',
      lat: (json['lat'] ?? 0).toDouble(),
      lon: (json['lon'] ?? 0).toDouble(),
      costLkr: json['cost_lkr'] ?? 0,
      durationMins: json['duration_mins'] ?? 0,
      description: json['description'] ?? '',
    );
  }
}

class SmartItineraryResponse {
  final int totalCostLkr;
  final int totalDurationMins;
  final List<ItineraryStop> stops;
  final Map<String, dynamic>? geometry;
  final String transportRecommendation;

  SmartItineraryResponse({
    required this.totalCostLkr,
    required this.totalDurationMins,
    required this.stops,
    this.geometry,
    required this.transportRecommendation,
  });

  factory SmartItineraryResponse.fromJson(Map<String, dynamic> json) {
    var stopList = json['stops'] as List? ?? [];
    return SmartItineraryResponse(
      totalCostLkr: json['total_cost_lkr'] ?? 0,
      totalDurationMins: json['total_duration_mins'] ?? 0,
      stops: stopList.map((e) => ItineraryStop.fromJson(e)).toList(),
      geometry: json['geometry'],
      transportRecommendation: json['transport_recommendation'] ?? '',
    );
  }
}

class SmartItineraryAPIResponse {
  final bool success;
  final SmartItineraryResponse? data;
  final String? error;

  SmartItineraryAPIResponse({required this.success, this.data, this.error});

  factory SmartItineraryAPIResponse.fromJson(Map<String, dynamic> json) {
    return SmartItineraryAPIResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? SmartItineraryResponse.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}
