// lib/main.dart - ZAKTUALIZOWANE dla systemu świec
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_menu_screen.dart';
import 'services/user_preferences_service.dart';
import 'services/haptic_service.dart';
import 'services/background_music_service.dart';
import 'services/firebase_remote_config_service.dart';
import 'services/logging_service.dart';
import 'services/anonymous_user_service.dart'; // 🆕 NOWY
import 'services/candle_manager_service.dart'; // 🆕 NOWY
import 'models/user_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📝 Inicjalizuj LoggingService
  final logger = LoggingService();

  // 🔥 BEZPIECZNA INICJALIZACJA FIREBASE
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.logToConsole('✅ Firebase zainicjalizowany pomyślnie',
        tag: 'FIREBASE');

    // ✅ WYŁĄCZ AUTOMATYCZNE DATA COLLECTION w debug
    if (kDebugMode) {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
      logger.logToConsole('📊 Analytics wyłączone w debug mode',
          tag: 'FIREBASE');
    } else {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      logger.logToConsole('📊 Analytics włączone w release mode',
          tag: 'FIREBASE');
    }

    // Debug info
    print('✅ Firebase Project ID: ${Firebase.app().options.projectId}');
    print('✅ Firebase App Name: ${Firebase.app().name}');
  } catch (e) {
    logger.logToConsole('❌ Błąd Firebase: $e', tag: 'ERROR');
    // ✅ Aplikacja powinna dalej działać bez Firebase
  }

  // 🔑 Zainicjalizuj Remote Config
  try {
    final remoteConfig = FirebaseRemoteConfigService();
    await remoteConfig.initialize();
    logger.logToConsole('✅ Remote Config zainicjalizowany', tag: 'FIREBASE');

    // 🔍 Debug - pokaż status konfiguracji
    remoteConfig.debugPrintConfig();
  } catch (e) {
    logger.logToConsole('❌ Błąd Remote Config: $e', tag: 'ERROR');
    // Aplikacja powinna dalej działać bez Remote Config
  }

  // 🛡️ Error Handler
  ErrorWidget.builder = (FlutterErrorDetails details) {
    logger.logToConsole('Flutter Error: ${details.exception}', tag: 'ERROR');

    return Material(
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 50, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                'Ups! Coś poszło nie tak.',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              const SizedBox(height: 10),
              if (kDebugMode)
                Text(
                  details.exception.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(Phoenix(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 🎵 Inicjalizacja muzyki w tle (opcjonalne)
  void _initializeBackgroundMusic() async {
    try {
      await BackgroundMusicService().initialize();
    } catch (e) {
      print('❌ Błąd uruchamiania muzyki w tle: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ustawienia systemowe
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'AI Wróżka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.cinzelDecorativeTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  Widget? _targetScreen;
  final HapticService _hapticService = HapticService();
  final AnonymousUserService _userService = AnonymousUserService(); // 🆕 NOWY
  final CandleManagerService _candleService = CandleManagerService(); // 🆕 NOWY

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final logger = LoggingService();

    try {
      logger.logToConsole('🚀 Inicjalizacja aplikacji...', tag: 'APP');

      // 🆕 INICJALIZUJ SYSTEM ŚWIEC JAKO PIERWSZY
      try {
        logger.logToConsole('🕯️ Inicjalizacja systemu świec...',
            tag: 'CANDLES');

        // Najpierw sprawdź czy Firebase działa
        if (Firebase.apps.isNotEmpty) {
          await _userService.initialize();
          await _candleService.initialize();
          logger.logToConsole('✅ System świec zainicjalizowany',
              tag: 'CANDLES');

          // Pokaż informacje o użytkowniku
          final profile = _userService.currentProfile;
          if (profile != null) {
            logger.logToConsole(
                '👤 Użytkownik: ${profile.userId.substring(0, 8)}..., '
                'Świece: ${profile.candleBalance}, '
                'Seria: ${profile.dailyLoginStreak} dni',
                tag: 'USER');
          }
        } else {
          logger.logToConsole(
              '⚠️ Firebase niedostępny - system świec wyłączony',
              tag: 'WARNING');
        }
      } catch (e) {
        logger.logToConsole('❌ Błąd inicjalizacji systemu świec: $e',
            tag: 'ERROR');
        // Możemy kontynuować bez systemu świec w najgorszym przypadku
      }

      // ✅ SPRAWDŹ ONBOARDING (zmodyfikowane)
      final isOnboardingCompleted =
          await UserPreferencesService.isOnboardingCompleted();
      logger.logToConsole('📋 Onboarding completed: $isOnboardingCompleted',
          tag: 'APP');

      if (isOnboardingCompleted) {
        // Sprawdź czy mamy dane użytkownika
        final userData = await UserPreferencesService.getUserData();
        logger.logToConsole('👤 User data: ${userData?.name ?? "brak"}',
            tag: 'APP');

        if (userData != null) {
          // Użytkownik ukończył onboarding - idź do main menu
          _targetScreen = MainMenuScreen(
            userName: userData.name,
            userGender: userData.gender,
            birthDate: userData.birthDate,
          );
        } else {
          // Błąd - brak danych mimo ukończonego onboardingu
          logger.logToConsole('⚠️ Onboarding ukończony ale brak user data',
              tag: 'WARNING');
          _targetScreen = const WelcomeScreen();
        }
      } else {
        // Pierwszy raz - rozpocznij onboarding
        _targetScreen = const WelcomeScreen();
      }

      // ✅ INICJALIZUJ POZOSTAŁE SERWISY
      try {
        // Haptic service może nie mieć metody initialize()
        // await _hapticService.initialize();
        // await _hapticService.printCapabilities();
        logger.logToConsole('✅ Haptic service gotowy', tag: 'APP');
      } catch (e) {
        logger.logToConsole('❌ Błąd haptic service: $e', tag: 'ERROR');
      }

      // ✅ Krótkie opóźnienie dla płynności UX
      await Future.delayed(const Duration(milliseconds: 1500));

      setState(() {
        _isLoading = false;
      });

      logger.logToConsole('🎉 Aplikacja zainicjalizowana pomyślnie',
          tag: 'APP');
    } catch (e) {
      logger.logToConsole('💥 Krytyczny błąd inicjalizacji: $e', tag: 'ERROR');

      // Fallback - idź do welcome screen
      setState(() {
        _targetScreen = const WelcomeScreen();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return _targetScreen ?? const WelcomeScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1426),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A2332),
              Color(0xFF0B1426),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo lub ikona aplikacji
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.amber,
                      Colors.orange,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 50,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              // Nazwa aplikacji
              Text(
                'AI Wróżka',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 10),

              // Podtytuł
              Text(
                'Odkryj tajemnice swojej przyszłości',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ),

              const SizedBox(height: 50),

              // Loader
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                strokeWidth: 3,
              ),

              const SizedBox(height: 20),

              // 🆕 Status inicjalizacji
              Text(
                'Przygotowywanie magii...',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: Colors.white60,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
