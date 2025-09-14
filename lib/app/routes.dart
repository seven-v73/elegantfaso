import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/types.dart';
import '../views/screens/auth/auth_wrapper.dart';
import '../views/screens/auth/login_screen.dart';
import '../views/screens/auth/register_screen.dart';
import '../views/screens/admin/main_admin.dart';
import '../views/screens/client/home/home_screen.dart';
import '../views/screens/createur/createur_dashboard_screen.dart';
import '../views/screens/boutique/dashboard/boutique_dashboard.dart';
import '../../splash/splash_screen.dart';
import '../data/repositories/auth_repository.dart';
import '../views/screens/error_screen.dart';

/// Enhanced routing system with improved error handling and performance
class AppRoutes {
  // Routes statiques
  static const String splash = '/';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String register = '/register';
  static const String admin = '/admin';
  static const String home = '/home';
  static const String creatorDashboard = '/creator-dashboard';
  static const String shopDashboard = '/shop-dashboard';
  static const String error = '/error';

  static const String initialRoute = splash;

  // Navigation stack with size limit and better management
  static final List<String> _navigationStack = <String>[];
  static String? _lastValidRoute;
  static const int _maxStackSize = 10;

  // Routes with lazy loading and error boundaries
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    auth: (context) => const AuthWrapper(),
    register: (context) => const RegisterScreen(),
    login: (context) => const LoginScreen(),
    home: (context) => const HomeScreen(),
    admin: (context) => AdminApp(),
    creatorDashboard: (context) => const CreateurDashboardScreen(),
    shopDashboard: (context) => const BoutiqueDashboard(),
    error: (context) => _buildErrorScreen(context),
  };

  /// Build error screen with proper argument handling
  static Widget _buildErrorScreen(BuildContext context) {
    try {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final routeName = args?['routeName'] ?? 'Route inconnue';
      return ErrorScreen(routeName: routeName);
    } catch (e) {
      return const ErrorScreen(routeName: 'Erreur de route');
    }
  }

  /// Enhanced route generation with better error handling
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? '/';

    try {
      // Add to navigation stack if not splash
      if (routeName != splash) {
        _addToNavigationStack(routeName);
      }

      // Check if route exists
      if (!routes.containsKey(routeName)) {
        return _createErrorRoute(routeName, settings);
      }

      // Check authentication for protected routes
      if (requiresAuth(routeName)) {
        final User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          return MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
            settings: const RouteSettings(name: auth),
          );
        }
      }

      // Return requested route
      return MaterialPageRoute(
        builder: routes[routeName]!,
        settings: settings,
      );
    } catch (e) {
      // Fallback to error route if something goes wrong
      return _createErrorRoute(routeName, settings);
    }
  }

  /// Create error route with proper error handling
  static Route<dynamic> _createErrorRoute(String routeName, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => ErrorScreen(routeName: routeName),
      settings: RouteSettings(
        name: error,
        arguments: {'routeName': routeName},
      ),
    );
  }

  /// Add to navigation stack with size management
  static void _addToNavigationStack(String route) {
    if (route != splash && route != error) {
      _navigationStack.add(route);
      _lastValidRoute = route;

      // Maintain stack size limit
      if (_navigationStack.length > _maxStackSize) {
        _navigationStack.removeRange(0, _navigationStack.length - _maxStackSize);
      }
    }
  }

  /// Navigate based on user role with error handling
  static Future<void> navigateBasedOnRole(BuildContext context, String role) async {
    try {
      final String route = getRouteForRole(role);
      await Navigator.pushNamedAndRemoveUntil(
        context,
        route,
            (Route<dynamic> route) => false,
      );
      _navigationStack.clear();
      _addToNavigationStack(route);
    } catch (e) {
      handleAuthError(context, 'Erreur de navigation: ${e.toString()}');
    }
  }

  /// Get route for user role
  static String getRouteForRole(String role) {
    switch (role) {
      case AppUserRoles.client:
        return home;
      case AppUserRoles.admin:
        return admin;
      case AppUserRoles.createur:
        return creatorDashboard;
      case AppUserRoles.boutique:
        return shopDashboard;
      default:
        return home;
    }
  }

  /// Enhanced redirect after authentication
  static Future<void> redirectAfterAuth(BuildContext context, AuthResult authResult) async {
    try {
      if (authResult.redirectRoute != null) {
        await Navigator.pushNamedAndRemoveUntil(
          context,
          authResult.redirectRoute!,
              (Route<dynamic> route) => false,
        );
        _navigationStack.clear();
        _addToNavigationStack(authResult.redirectRoute!);
      } else {
        await navigateBasedOnRole(context, authResult.userRole ?? AppUserRoles.client);
      }
    } catch (e) {
      handleAuthError(context, 'Erreur de redirection: ${e.toString()}');
      // Fallback to home
      await Navigator.pushNamedAndRemoveUntil(
        context,
        home,
            (Route<dynamic> route) => false,
      );
    }
  }

  /// Safe navigation to login
  static Future<void> navigateToLogin(BuildContext context) async {
    await _navigateAndClearStack(context, login);
  }

  /// Safe navigation to register
  static Future<void> navigateToRegister(BuildContext context) async {
    await _navigateAndClearStack(context, register);
  }

  /// Helper method for navigation with stack clearing
  static Future<void> _navigateAndClearStack(BuildContext context, String route) async {
    try {
      await Navigator.pushNamedAndRemoveUntil(
        context,
        route,
            (Route<dynamic> route) => false,
      );
      _navigationStack.clear();
      _addToNavigationStack(route);
    } catch (e) {
      handleAuthError(context, 'Erreur de navigation: ${e.toString()}');
    }
  }

  /// Handle register success with improved UX
  static Future<void> handleRegisterSuccess(BuildContext context, AuthResult authResult) async {
    _showSuccessMessage(context, 'Compte créé avec succès ! Bienvenue !');
    await Future.delayed(const Duration(milliseconds: 1500));
    await redirectAfterAuth(context, authResult);
  }

  /// Handle login success with improved UX
  static Future<void> handleLoginSuccess(BuildContext context, AuthResult authResult) async {
    _showSuccessMessage(context, 'Connexion réussie !');
    await Future.delayed(const Duration(milliseconds: 1500));
    await redirectAfterAuth(context, authResult);
  }

  /// Show success message with better styling
  static void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Handle authentication errors with better UX
  static void handleAuthError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(error)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Fermer',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  /// Show route error with navigation
  static Future<void> showRouteError(BuildContext context, String routeName) async {
    try {
      await Navigator.pushNamed(
        context,
        error,
        arguments: {'routeName': routeName},
      );
    } catch (e) {
      handleAuthError(context, 'Erreur de navigation: ${e.toString()}');
    }
  }

  /// Check if route requires authentication
  static bool requiresAuth(String route) {
    const Set<String> publicRoutes = {
      splash,
      auth,
      login,
      register,
      error,
    };
    return !publicRoutes.contains(route);
  }

  /// Get default route for unauthenticated users
  static String getDefaultUnauthenticatedRoute() => auth;

  /// Get default route for authenticated users
  static String getDefaultAuthenticatedRoute(String userRole) => getRouteForRole(userRole);

  /// Enhanced logout with better error handling
  static Future<void> logout(BuildContext context) async {
    try {
      await AuthRepository().signOut();
      _navigationStack.clear();
      await Navigator.pushNamedAndRemoveUntil(
        context,
        auth,
            (Route<dynamic> route) => false,
      );
      _showSuccessMessage(context, 'Déconnexion réussie');
    } catch (error) {
      handleAuthError(context, 'Erreur lors de la déconnexion: $error');
    }
  }

  /// Enhanced initial navigation handling
  static Future<void> handleInitialNavigation(BuildContext context, User? user) async {
    try {
      if (user == null) {
        await Navigator.pushReplacementNamed(context, getDefaultUnauthenticatedRoute());
      } else {
        final authResult = await AuthRepository().getCurrentUserInfo();
        if (authResult != null) {
          await redirectAfterAuth(context, authResult);
        } else {
          await Navigator.pushReplacementNamed(context, home);
          _addToNavigationStack(home);
        }
      }
    } catch (error) {
      await Navigator.pushReplacementNamed(context, auth);
      _addToNavigationStack(auth);
    }
  }

  /// Smart navigation back with improved logic
  static void smartNavigateBack(BuildContext context) {
    try {
      final navigator = Navigator.of(context);

      // If we can pop normally, do it
      if (navigator.canPop()) {
        navigator.pop();
        return;
      }

      // Use navigation stack
      if (_navigationStack.length > 1) {
        _navigationStack.removeLast();
        final previousRoute = _navigationStack.last;
        Navigator.pushReplacementNamed(context, previousRoute);
        return;
      }

      // Fallback to appropriate default route
      _navigateToDefault(context);
    } catch (e) {
      _navigateToDefault(context);
    }
  }

  /// Navigate to default route based on auth state
  static void _navigateToDefault(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Navigator.pushReplacementNamed(context, home);
    } else {
      Navigator.pushReplacementNamed(context, auth);
    }
  }

  /// Navigate with history tracking
  static Future<void> navigateWithHistory(BuildContext context, String route) async {
    try {
      await Navigator.pushNamed(context, route);
      _addToNavigationStack(route);
    } catch (e) {
      handleAuthError(context, 'Erreur de navigation: ${e.toString()}');
    }
  }

  /// Replace current route
  static Future<void> replaceCurrentRoute(BuildContext context, String route) async {
    try {
      await Navigator.pushReplacementNamed(context, route);
      if (_navigationStack.isNotEmpty) {
        _navigationStack.removeLast();
      }
      _addToNavigationStack(route);
    } catch (e) {
      handleAuthError(context, 'Erreur de navigation: ${e.toString()}');
    }
  }

  /// Safe navigate back (alias for smartNavigateBack)
  static void safeNavigateBack(BuildContext context) => smartNavigateBack(context);

  /// Check if user is authenticated
  static Future<bool> isUserAuthenticated() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      return currentUser != null;
    } catch (e) {
      return false;
    }
  }

  /// Get current user role
  static Future<String?> getCurrentUserRole() async {
    try {
      final authResult = await AuthRepository().getCurrentUserInfo();
      return authResult?.userRole;
    } catch (error) {
      return null;
    }
  }

  /// Clear navigation stack
  static void clearNavigationStack() {
    _navigationStack.clear();
    _lastValidRoute = null;
  }

  /// Get previous route
  static String? getPreviousRoute() {
    return _navigationStack.length > 1
        ? _navigationStack[_navigationStack.length - 2]
        : null;
  }

  /// Get current route
  static String? getCurrentRoute() {
    return _navigationStack.isNotEmpty ? _navigationStack.last : null;
  }

  /// Check if currently on splash screen
  static bool isOnSplash(BuildContext context) {
    final route = ModalRoute.of(context);
    return route?.settings.name == splash;
  }

  /// Get navigation stack size (useful for debugging)
  static int getNavigationStackSize() => _navigationStack.length;

  /// Get navigation stack copy (useful for debugging)
  static List<String> getNavigationStackCopy() => List.from(_navigationStack);
}