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
