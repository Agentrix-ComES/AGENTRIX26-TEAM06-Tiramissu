import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/ayu_colors.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_sheet.dart';
import 'screens/dashboard_screen.dart';
import 'screens/guardian_screen.dart';
import 'screens/routes_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/profile_screen.dart';

/// Screen names — mirrors the React SCREEN_DEPTH map.
enum AyuScreen { welcome, dashboard, guardian, routes, alerts, profile }

const _depth = {
  AyuScreen.welcome: 0,
  AyuScreen.dashboard: 1,
  AyuScreen.guardian: 2,
  AyuScreen.routes: 2,
  AyuScreen.alerts: 2,
  AyuScreen.profile: 2,
};

/// Root of the AYU travel-companion app.
/// Wraps in [MaterialApp] so it can run as a standalone entry point
/// or be embedded inside the existing Panopticon app.
class AyuApp extends StatelessWidget {
  const AyuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AYU — Sri Lanka Travel Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AyuColors.lime),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        scaffoldBackgroundColor: AyuColors.sageBg,
      ),
      home: const AyuNavigator(),
    );
  }
}

/// Handles navigation between screens with horizontal slide transitions,
/// matching the React AnimatePresence behaviour.
class AyuNavigator extends StatefulWidget {
  const AyuNavigator({super.key});

  @override
  State<AyuNavigator> createState() => _AyuNavigatorState();
}

class _AyuNavigatorState extends State<AyuNavigator> {
  AyuScreen _screen = AyuScreen.welcome;
  AyuScreen _prev = AyuScreen.welcome;

  void _navigateTo(AyuScreen to) {
    setState(() {
      _prev = _screen;
      _screen = to;
    });
  }

  void _goBack() => _navigateTo(AyuScreen.dashboard);

  AyuScreen _navTargetToScreen(String t) {
    switch (t) {
      case 'routes':   return AyuScreen.routes;
      case 'guardian': return AyuScreen.guardian;
      case 'alerts':   return AyuScreen.alerts;
      case 'profile':  return AyuScreen.profile;
      default:         return AyuScreen.dashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    final forward = (_depth[_screen] ?? 0) >= (_depth[_prev] ?? 0);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: const Cubic(0.22, 0.85, 0.36, 1.0),
        switchOutCurve: const Cubic(0.22, 0.85, 0.36, 1.0),
        transitionBuilder: (child, animation) {
          final slideIn = Tween<Offset>(
            begin: forward ? const Offset(1, 0) : const Offset(-1, 0),
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(
            position: slideIn,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_screen),
          child: _buildScreen(),
        ),
      ),
    );
  }

  Widget _buildScreen() {
    switch (_screen) {
      case AyuScreen.welcome:
        return WelcomeScreen(
          onGetStarted: () async {
            await showAuthSheet(
              context,
              onLogin: () => _navigateTo(AyuScreen.dashboard),
            );
          },
        );

      case AyuScreen.dashboard:
        return DashboardScreen(
          activeNav: 'explore',
          onNavigate: (target) {
            if (target == 'explore') return;
            _navigateTo(_navTargetToScreen(target));
          },
        );

      case AyuScreen.guardian:
        return GuardianScreen(onBack: _goBack);

      case AyuScreen.routes:
        return RoutesScreen(onBack: _goBack);

      case AyuScreen.alerts:
        return AlertsScreen(onBack: _goBack);

      case AyuScreen.profile:
        return ProfileScreen(onBack: _goBack);
    }
  }
}
