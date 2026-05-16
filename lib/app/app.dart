import 'package:flutter/foundation.dart'; // Add this import for kDebugMode
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'routes.dart';
import 'error_screen.dart';
import '../core/connectivity/app_connectivity_banner.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElegantStyle',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // Use the initial route from AppRoutes
      initialRoute: AppRoutes.initialRoute,
      navigatorKey: AppRoutes.navigatorKey,

      // Remove the static routes property and use onGenerateRoute exclusively
      // This ensures all navigation goes through the enhanced route generation
      onGenerateRoute: AppRoutes.onGenerateRoute,

      // Handle unknown routes that weren't caught by onGenerateRoute
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder:
              (context) =>
                  ErrorScreen(routeName: settings.name ?? 'Route inconnue'),
          settings: RouteSettings(
            name: AppRoutes.error,
            arguments: {'routeName': settings.name ?? 'Route inconnue'},
          ),
        );
      },

      // Disable debug banner
      debugShowCheckedModeBanner: false,

      // Add global navigation observers for better debugging (optional)
      navigatorObservers: [if (kDebugMode) _AppNavigatorObserver()],

      // Add builder for global error handling (optional)
      builder: (context, child) {
        // Global error boundary wrapper
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.textScalerOf(
                context,
              ).scale(1).clamp(0.86, 1.18).toDouble(),
            ),
          ),
          child: AppConnectivityBanner(
            child: _GlobalErrorBoundary(child: child),
          ),
        );
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
    debugPrint(
      'Navigation: Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}',
    );
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
      title: 'ElegantStyle',

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Routing configuration
      initialRoute: AppRoutes.initialRoute,
      navigatorKey: AppRoutes.navigatorKey,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      onUnknownRoute: _handleUnknownRoute,

      // UI configuration
      debugShowCheckedModeBanner: false,

      // Navigation configuration
      navigatorObservers: [if (kDebugMode) _AppNavigatorObserver()],

      // Global configuration
      builder: (context, child) {
        return MediaQuery(
          // Ensure text scaling doesn't break the UI
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.textScalerOf(
                context,
              ).scale(1).clamp(0.8, 1.2).toDouble(),
            ),
          ),
          child: _GlobalErrorBoundary(child: child),
        );
      },

      // Localization support (if needed)
      locale: const Locale('fr', 'FR'), // French locale for Burkina Faso
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],

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
      builder:
          (context) =>
              ErrorScreen(routeName: settings.name ?? 'Route inconnue'),
      settings: RouteSettings(
        name: AppRoutes.error,
        arguments: {'routeName': settings.name ?? 'Route inconnue'},
      ),
    );
  }
}
