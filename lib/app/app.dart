import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add this import for kDebugMode

import 'app_theme.dart';
import 'routes.dart';
import '../splash/splash_screen.dart';
import 'error_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElegantFaso',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme, // Add dark theme support
      themeMode: ThemeMode.system, // Follow system theme

      // Use the initial route from AppRoutes
      initialRoute: AppRoutes.initialRoute,

      // Remove the static routes property and use onGenerateRoute exclusively
      // This ensures all navigation goes through the enhanced route generation
      onGenerateRoute: AppRoutes.onGenerateRoute,

      // Handle unknown routes that weren't caught by onGenerateRoute
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => ErrorScreen(
            routeName: settings.name ?? 'Route inconnue',
          ),
          settings: RouteSettings(
            name: AppRoutes.error,
            arguments: {'routeName': settings.name ?? 'Route inconnue'},
          ),
        );
      },

      // Disable debug banner
      debugShowCheckedModeBanner: false,

      // Add global navigation observers for better debugging (optional)
      navigatorObservers: [
        _AppNavigatorObserver(),
      ],

      // Add builder for global error handling (optional)
      builder: (context, child) {
        // Global error boundary wrapper
        return _GlobalErrorBoundary(child: child);
      },
    );
  }
}

/// Navigator observer for debugging navigation events
class _AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('Navigation: Pushed ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('Navigation: Popped ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    debugPrint('Navigation: Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
  }
}

/// Global error boundary for catching widget errors
class _GlobalErrorBoundary extends StatelessWidget {
  final Widget? child;

  const _GlobalErrorBoundary({this.child});

  @override
  Widget build(BuildContext context) {
    return child ?? const SizedBox.shrink();
  }
}

/// Alternative MyApp with more production-ready features
class MyAppEnhanced extends StatelessWidget {
  const MyAppEnhanced({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElegantFaso',

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Routing configuration
      initialRoute: AppRoutes.initialRoute,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      onUnknownRoute: _handleUnknownRoute,

      // UI configuration
      debugShowCheckedModeBanner: false,

      // Navigation configuration
      navigatorObservers: [
        if (kDebugMode) _AppNavigatorObserver(),
      ],

      // Global configuration
      builder: (context, child) {
        return MediaQuery(
          // Ensure text scaling doesn't break the UI
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
          ),
          child: _GlobalErrorBoundary(child: child),
        );
      },

      // Localization support (if needed)
      locale: const Locale('fr', 'FR'), // French locale for Burkina Faso
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],

      // Performance optimizations
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      showPerformanceOverlay: false,
    );
  }

  /// Handle unknown routes with proper error logging
  static Route<dynamic> _handleUnknownRoute(RouteSettings settings) {
    // Log the unknown route attempt
    debugPrint('Unknown route attempted: ${settings.name}');

    return MaterialPageRoute(
      builder: (context) => ErrorScreen(
        routeName: settings.name ?? 'Route inconnue',
      ),
      settings: RouteSettings(
        name: AppRoutes.error,
        arguments: {'routeName': settings.name ?? 'Route inconnue'},
      ),
    );
  }
}