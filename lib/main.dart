import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app/app.dart';
import 'core/utils/logger_utils.dart';
import 'firebase_options.dart';
import '../splash/splash_screen.dart';

enum InitializationState { pending, inProgress, completed, error }

class AppInitializer {
  static InitializationState _state = InitializationState.pending;
  static String? _error;
  static Completer<void>? _initCompleter;

  static InitializationState get state => _state;
  static String? get error => _error;
  static bool get isInitialized => _state == InitializationState.completed;

  static Future<void> initialize() async {
    if (_state == InitializationState.completed) return;
    if (_state == InitializationState.inProgress) {
      return _initCompleter?.future ?? Future.value();
    }

    _state = InitializationState.inProgress;
    _initCompleter = Completer<void>();

    try {
      await _initializeApp();
      _state = InitializationState.completed;
      _initCompleter!.complete();
    } catch (e, stackTrace) {
      _state = InitializationState.error;
      _error = e.toString();
      _initCompleter!.completeError(e, stackTrace);
      rethrow;
    }
  }

  static void reset() {
    _state = InitializationState.pending;
    _error = null;
    _initCompleter = null;
  }
}

// Configuration des notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  LoggerUtils.setupLogger().d("Handling background message: ${message.messageId}");
  _showNotification(message);
}

void _showNotification(RemoteMessage message) async {
  final notification = message.notification;
  final android = message.notification?.android;

  // Configuration pour Android
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'high_importance_channel',
    'Notifications importantes',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );

  // Configuration pour iOS
  const DarwinNotificationDetails darwinPlatformChannelSpecifics =
  DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  final NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: darwinPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    notification?.title,
    notification?.body,
    platformChannelSpecifics,
    payload: message.data['type'] ?? 'general',
  );
}

Future<void> _initializeFirebaseMessaging(Logger logger) async {
  try {
    // Configuration des notifications locales
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // CORRECTION: Nouvelle configuration iOS sans onDidReceiveLocalNotification
    final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // Le callback a été déplacé dans l'initialisation principale
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // CORRECTION: Utilisation de onDidReceiveNotificationResponse pour gérer les interactions
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        logger.d('Notification cliquée: ${response.payload}');
      },
    );

    // Configuration de Firebase Messaging
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Demande de permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    logger.d('Statut des permissions: ${settings.authorizationStatus}');

    // Gestion des messages
    FirebaseMessaging.onMessage.listen(_showNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.d('Notification ouverte: ${message.data}');
    });

    // Handler pour les messages en arrière-plan
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Récupération du token FCM
    String? token = await messaging.getToken();
    logger.d("FCM Token: $token");

    // Enregistrement du token dans Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }

    logger.i('✅ Firebase Messaging initialisé');
  } catch (e, stackTrace) {
    logger.e('❌ Erreur Firebase Messaging', error: e, stackTrace: stackTrace);
    rethrow;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✨ NOUVELLE CONFIGURATION: Force le mode jour
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light, // iOS
      statusBarIconBrightness: Brightness.dark, // Android
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Configuration globale des erreurs
  FlutterError.onError = (details) {
    final logger = LoggerUtils.setupLogger();
    logger.e('Flutter Error: ${details.exception}', stackTrace: details.stack);
  };

  runApp(const MyInitialApp());
}

class MyInitialApp extends StatefulWidget {
  const MyInitialApp({super.key});

  @override
  State<MyInitialApp> createState() => _MyInitialAppState();
}

class _MyInitialAppState extends State<MyInitialApp> {
  Timer? _splashTimer;
  bool _showSplash = true;
  bool _initializationAttempted = false;

  @override
  void initState() {
    super.initState();
    _startSplashTimer();
    _initializeApplication();
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  void _startSplashTimer() {
    _splashTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  Future<void> _initializeApplication() async {
    if (_initializationAttempted) return;
    _initializationAttempted = true;

    try {
      await AppInitializer.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppInitializer.isInitialized && !_showSplash) {
      return const MyApp();
    }

    return switch (AppInitializer.state) {
      InitializationState.pending ||
      InitializationState.inProgress => _buildSplashApp(),

      InitializationState.completed =>
      _showSplash ? _buildSplashApp() : const MyApp(),

      InitializationState.error => InitializationErrorApp(
        error: AppInitializer.error ?? 'Erreur inconnue',
        onRetry: _retryInitialization,
      ),
    };
  }

  void _retryInitialization() {
    AppInitializer.reset();
    _initializationAttempted = false;
    _startSplashTimer();
    setState(() => _showSplash = true);
    _initializeApplication();
  }

  Widget _buildSplashApp() {
    return MaterialApp(
      title: 'ElegantFaso',
      debugShowCheckedModeBanner: false,
      // ✨ AMÉLIORATION: Force le mode jour pour l'écran de splash aussi
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ✨ NOUVELLE CLASSE: Widget wrapper pour forcer le mode jour
class LightThemeWrapper extends StatelessWidget {
  final Widget child;

  const LightThemeWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        // Configuration personnalisée pour votre app
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        brightness: Brightness.light,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      child: child,
    );
  }
}

// === INITIALISATION CORE ===

Future<void> _initializeApp() async {
  final logger = LoggerUtils.setupLogger();
  logger.d('🚀 Initialisation de l\'application...');

  try {
    // ✨ AMÉLIORATION: Configuration du thème système au niveau système
    _configureSystemTheme();

    // Chargement séquentiel des éléments critiques
    await _loadEnvironmentVariables(logger);

    // Initialisations parallèles avec timeout
    await Future.wait([
      _initializeLocalization(logger),
      _initializeFirebase(logger),
    ]).timeout(const Duration(seconds: 20));

    // Initialisation des notifications Firebase
    await _initializeFirebaseMessaging(logger);

    // Diagnostic léger en production, complet en debug
    if (kDebugMode) {
      await _runBasicDiagnostics(logger);
    }

    logger.i('✅ Application initialisée avec succès');
  } catch (e, stackTrace) {
    logger.e('❌ Échec de l\'initialisation', error: e, stackTrace: stackTrace);
    rethrow;
  }
}

// ✨ NOUVELLE FONCTION: Configuration du thème système
void _configureSystemTheme() {
  // Force l'interface système en mode clair
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light, // iOS
      statusBarIconBrightness: Brightness.dark, // Android
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.grey,
    ),
  );
}

Future<void> _loadEnvironmentVariables(Logger logger) async {
  try {
    await dotenv.load(fileName: ".env");

    // Vérification des variables critiques uniquement
    const requiredVars = ['GEMINI_API_KEY', 'STABILITY_API_KEY', 'SERPAPI_KEY'];
    final missingVars = requiredVars.where((varName) => dotenv.env[varName] == null).toList();

    if (missingVars.isNotEmpty) {
      throw MissingEnvVariablesException(missingVars);
    }

    logger.i('✅ Variables d\'environnement chargées');
  } catch (e) {
    logger.e('❌ Erreur chargement .env: $e');
    rethrow;
  }
}

Future<void> _initializeLocalization(Logger logger) async {
  try {
    final locale = WidgetsBinding.instance.platformDispatcher.locales.first;
    final localeCode = '${locale.languageCode}_${locale.countryCode}';
    await initializeDateFormatting(localeCode, null);
    logger.i('✅ Localisation: $localeCode');
  } catch (e) {
    logger.w('⚠️ Localisation par défaut utilisée');
    await initializeDateFormatting('fr_FR', null);
  }
}

Future<void> _initializeFirebase(Logger logger) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Configuration Firestore optimisée
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    logger.i('✅ Firebase initialisé');
  } catch (e) {
    logger.e('❌ Erreur Firebase: $e');
    rethrow;
  }
}

// === DIAGNOSTICS SIMPLIFIÉS ===

Future<void> _runBasicDiagnostics(Logger logger) async {
  logger.d('🔍 Diagnostic basique...');

  try {
    await Future.wait([
      _checkFirebaseConnectivity(logger),
      _checkNotificationPermissions(logger),
    ]).timeout(const Duration(seconds: 10));

    logger.i('✅ Diagnostic terminé');
  } catch (e) {
    logger.w('⚠️ Diagnostic partiel: $e');
  }
}

Future<void> _checkFirebaseConnectivity(Logger logger) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      logger.i('👤 Utilisateur connecté: ${user.uid}');
    }

    // Test rapide de connectivité
    await FirebaseFirestore.instance.enableNetwork();

    logger.i('✅ Connectivité Firebase OK');
  } catch (e) {
    logger.w('⚠️ Problème connectivité: $e');
  }
}

Future<void> _checkNotificationPermissions(Logger logger) async {
  try {
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      logger.d('Permissions notifications iOS: ${settings.authorizationStatus}');
    } else if (Platform.isAndroid) {
      final granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      logger.d('Notifications Android activées: $granted');
    }
  } catch (e) {
    logger.w('⚠️ Erreur vérification permissions: $e');
  }
}

// === ERROR HANDLING ===

class InitializationErrorApp extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const InitializationErrorApp({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElegantFaso - Erreur',
      debugShowCheckedModeBanner: false,
      // ✨ AMÉLIORATION: Force le mode jour même pour les erreurs
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: LightThemeWrapper(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Erreur d\'initialisation',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      error,
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: error));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erreur copiée'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text('Copier l\'erreur'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MissingEnvVariablesException implements Exception {
  final List<String> missingVars;
  const MissingEnvVariablesException(this.missingVars);

  @override
  String toString() => 'Variables manquantes: ${missingVars.join(', ')}';
}