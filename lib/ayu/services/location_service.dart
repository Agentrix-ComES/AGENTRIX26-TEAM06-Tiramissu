import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static Future<LatLng?> getCurrentLocation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        _showSettingsDialog(
          context, 
          'Enable GPS', 
          'Your device GPS is disabled. Please enable it to calculate accurate smart routes.',
          () => Geolocator.openLocationSettings(),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        _showSettingsDialog(
          context, 
          'Permission Denied', 
          'Location permissions are permanently denied. Please grant them in app settings.',
          () => Geolocator.openAppSettings(),
        );
      }
      return null;
    } 

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    
    return LatLng(position.latitude, position.longitude);
  }

  static void _showSettingsDialog(BuildContext context, String title, String msg, VoidCallback onSettingsClick) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(msg, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                onSettingsClick();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC6F621)),
              child: const Text('Open Settings', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
