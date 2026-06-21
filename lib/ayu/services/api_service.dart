import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io' show Platform;
import '../models/api_responses.dart';

class ApiService {
  static String get _host => Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
  static String get _baseUrl => 'http://$_host:8000/api/ai';

  /// Pivot route via structured disruption.
  static Future<RouteResponse> pivotRoute({
    required String origin,
    required String destination,
    required String blockedTransportMode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/route/pivot'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'origin': origin,
          'destination': destination,
          'blocked_transport_mode': blockedTransportMode,
        }),
      );

      if (response.statusCode == 200) {
        return RouteResponse.fromJson(jsonDecode(response.body));
      } else {
        return RouteResponse(
          success: false,
          error: 'Server Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return RouteResponse(success: false, error: 'Network Error: $e');
    }
  }

  /// Send an image to the vision agent to analyze.
  static Future<VisionResponse> analyzeMonument(XFile imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/vision/analyze'),
      );
      
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      request.fields['context'] = 'I am a tourist visiting Sri Lanka.';

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return VisionResponse.fromJson(jsonDecode(response.body));
      } else {
        return VisionResponse(
          success: false,
          error: 'Server Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return VisionResponse(success: false, error: 'Network Error: $e');
    }
  }

  /// Send parameters to the smart itinerary planner.
  static Future<SmartItineraryAPIResponse> planSmartItinerary({
    required double originLat,
    required double originLon,
    required int budgetLkr,
    required int timeHours,
    required String interests,
    String disruptions = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/route/plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'origin_lat': originLat,
          'origin_lon': originLon,
          'budget_lkr': budgetLkr,
          'time_hours': timeHours,
          'interests': interests,
          'disruptions': disruptions,
        }),
      );

      if (response.statusCode == 200) {
        return SmartItineraryAPIResponse.fromJson(jsonDecode(response.body));
      } else {
        return SmartItineraryAPIResponse(
          success: false,
          error: 'Server Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return SmartItineraryAPIResponse(success: false, error: 'Network Error: $e');
    }
  }
}
