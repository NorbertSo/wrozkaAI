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
                'Ups! Coś poszło nie tak...',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 18,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Spróbuj uruchomić aplikację ponownie',
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(
    Phoenix(
      child: const AIWrozkaApp(),
    ),
  );
}

// Reszta kodu pozostaje bez zmian...
class AIWrozkaApp extends StatefulWidget {
  const AIWrozkaApp({super.key});

  @override
  State<AIWrozkaApp> createState() => _AIWrozkaAppState();
}

class _AIWrozkaAppState extends State<AIWrozkaApp> with WidgetsBindingObserver {
  final BackgroundMusicService _musicService = BackgroundMusicService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ✅ INICJALIZACJA MUZYKI - automatyczne uruchomienie
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBackgroundMusic();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _musicService.dispose();
    super.dispose();
  }

  // ✅ OBSŁUGA CYKLU ŻYCIA APLIKACJI DLA MUZYKI
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        //_musicService.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        _musicService.onAppResumed();
        break;
      case AppLifecycleState.detached:
        _musicService.dispose();
        break;
      default:
        break;
    }
  }

  // ✅ INICJALIZACJA I URUCHOMIENIE MUZYKI W TLE
  Future<void> _initializeBackgroundMusic() async {
    try {
      print('🎵 Inicjalizacja muzyki w tle...');
      await _musicService.initialize();
      await _musicService.startBackgroundMusic();
      print('✅ Muzyka w tle uruchomiona pomyślnie');
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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final logger = LoggingService();

    try {
      logger.logToConsole('🚀 Inicjalizacja aplikacji...', tag: 'APP');

      // ✅ DODAJ SPRAWDZENIE FIREBASE
      if (Firebase.apps.isNotEmpty) {
        logger.logToConsole('✅ Firebase dostępny w aplikacji', tag: 'FIREBASE');
        print('🔍 Firebase Project ID: ${Firebase.app().options.projectId}');
      } else {
        logger.logToConsole('❌ Firebase niedostępny w aplikacji', tag: 'ERROR');
      }

      // ✅ Inicjalizacja HapticService
      await _hapticService.initialize();
      await _hapticService.printCapabilities();

      // Sprawdź czy onboarding został ukończony
      final isOnboardingCompleted =
          await UserPreferencesService.isOnboardingCompleted();
      logger.logToConsole('📋 Onboarding completed: $isOnboardingCompleted',
          tag: 'APP');

      if (isOnboardingCompleted) {
        // Sprawdź czy mamy dane użytkownika
        final userData = await UserPreferencesService.getUserData();
        logger.logToConsole('👤 User data: ${userData?.name ?? "BRAK"}',
            tag: 'USER');

        if (userData != null) {
          // Przejdź bezpośrednio do menu głównego
          logger.logToConsole('✅ Przekierowanie do menu głównego', tag: 'USER');
          _targetScreen = MainMenuScreen(
            userName: userData.name,
            userGender: userData.genderForMessages,
            dominantHand: userData.dominantHand,
            birthDate: userData.birthDate,
          );
        } else {
          // Brak danych użytkownika mimo ukończonego onboardingu
          logger.logToConsole('⚠️ Brak danych użytkownika - ponowny onboarding',
              tag: 'USER');
          await UserPreferencesService.clearAllUserData();
          _targetScreen = const WelcomeScreen();
        }
      } else {
        // Pierwszy raz - pokaż welcome screen
        logger.logToConsole('🎉 Pierwsze uruchomienie - welcome screen',
            tag: 'USER');
        _targetScreen = const WelcomeScreen();
      }

      // Debug
      await UserPreferencesService.debugPrintUserData();
    } catch (e) {
      logger.logToConsole('❌ Błąd inicjalizacji: $e', tag: 'ERROR');
      // W przypadku błędu pokaż welcome screen
      _targetScreen = const WelcomeScreen();
    }

    // Symulacja loading (opcjonalne)
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1426),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF00D4FF)),
              SizedBox(height: 20),
              Text(
                'Przywołuję mistyczne moce...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return _targetScreen ?? const WelcomeScreen();
  }
}
