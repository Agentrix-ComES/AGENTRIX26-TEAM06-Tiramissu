import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Service for handling GPS location and permissions.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;

  /// Get current position once.
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return _currentPosition;
    } catch (e) {
      return null;
    }
  }

  /// Start listening to location updates.
  Stream<Position?> startPositionStream() {
    try {
      _positionStream ??= Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        _currentPosition = position;
      });
      return _positionStream!.asBroadcastStream();
    } catch (e) {
      return Stream.value(null);
    }
  }

  /// Stop listening to location updates.
  void stopPositionStream() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  /// Get last known position.
  Position? get currentPosition => _currentPosition;

  /// Calculate distance between two positions in kilometers.
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}
