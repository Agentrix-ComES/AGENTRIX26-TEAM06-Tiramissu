import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'ayu/ayu_app.dart';

/// Standalone entry point for the AYU travel-companion app.
///
/// Run with:
///   flutter run -t lib/ayu_main.dart
///
/// The existing Panopticon app is unaffected — its entry point remains lib/main.dart.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const AyuApp());
}
