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

/// Structured route planning request with user preferences.
class RoutePlanningRequest {
  final String origin;
  final String destination;
  final List<String> interests;
  final double budget;
  final int timeAvailableMinutes;
  final String? disruptions;
  final String preferredTransportMode;

  RoutePlanningRequest({
    required this.origin,
    required this.destination,
    required this.interests,
    required this.budget,
    required this.timeAvailableMinutes,
    this.disruptions,
    this.preferredTransportMode = 'any',
  });

  Map<String, dynamic> toJson() => {
    'origin': origin,
    'destination': destination,
    'interests': interests,
    'budget': budget,
    'time_available_minutes': timeAvailableMinutes,
    'disruptions': disruptions,
    'preferred_transport_mode': preferredTransportMode,
  };
}

/// A recommended point of interest along the route.
class RouteRecommendation {
  final String name;
  final String type;
  final String description;
  final double distanceFromRoute;
  final int estimatedDurationMinutes;
  final double cost;
  final double rating;
  final String? imageUrl;

  RouteRecommendation({
    required this.name,
    required this.type,
    required this.description,
    required this.distanceFromRoute,
    required this.estimatedDurationMinutes,
    required this.cost,
    required this.rating,
    this.imageUrl,
  });

  factory RouteRecommendation.fromJson(Map<String, dynamic> json) {
    return RouteRecommendation(
      name: json['name'] ?? '',
      type: json['type'] ?? 'unknown',
      description: json['description'] ?? '',
      distanceFromRoute: (json['distance_from_route'] ?? 0).toDouble(),
      estimatedDurationMinutes: json['estimated_duration_minutes'] ?? 0,
      cost: (json['cost'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      imageUrl: json['image_url'],
    );
  }
}

/// Turn-by-turn navigation step.
class NavigationStep {
  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final String maneuverType;
  final List<double>? location; // [lon, lat]

  NavigationStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuverType,
    this.location,
  });

  factory NavigationStep.fromJson(Map<String, dynamic> json) {
    return NavigationStep(
      instruction: json['instruction'] ?? '',
      distanceMeters: (json['distance'] ?? 0).toDouble(),
      durationSeconds: (json['duration'] ?? 0).toDouble(),
      maneuverType: json['maneuver_type'] ?? 'straight',
      location: json['location'] != null 
          ? List<double>.from(json['location']) 
          : null,
    );
  }
}

/// Complete route plan response from the backend.
class RoutePlanResponse {
  final bool success;
  final String? summary;
  final double totalDistanceKm;
  final double totalDurationMinutes;
  final double estimatedCost;
  final String transportMode;
  final List<NavigationStep> steps;
  final List<RouteRecommendation> recommendations;
  final List<List<double>> polyline; // [[lon, lat], ...]
  final String? error;

  RoutePlanResponse({
    required this.success,
    this.summary,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.estimatedCost,
    required this.transportMode,
    required this.steps,
    required this.recommendations,
    required this.polyline,
    this.error,
  });

  factory RoutePlanResponse.fromJson(Map<String, dynamic> json) {
    return RoutePlanResponse(
      success: json['success'] ?? false,
      summary: json['summary'],
      totalDistanceKm: (json['total_distance_km'] ?? 0).toDouble(),
      totalDurationMinutes: (json['total_duration_minutes'] ?? 0).toDouble(),
      estimatedCost: (json['estimated_cost'] ?? 0).toDouble(),
      transportMode: json['transport_mode'] ?? 'unknown',
      steps: (json['steps'] as List<dynamic>?)
              ?.map((s) => NavigationStep.fromJson(s))
              .toList() ?? [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((r) => RouteRecommendation.fromJson(r))
              .toList() ?? [],
      polyline: (json['polyline'] as List<dynamic>?)
              ?.map((p) => List<double>.from(p))
              .toList() ?? [],
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
