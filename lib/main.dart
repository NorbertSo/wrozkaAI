// lib/main.dart
// Zaktualizowany main.dart z Background Music

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/user_preferences_service.dart';
import 'services/haptic_service.dart';
import 'services/background_music_service.dart'; // ✅ NOWY IMPORT
import 'models/user_data.dart';

void main() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Coś poszło nie tak', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Phoenix.rebirth(context),
                  child: const Text('Restartuj aplikację'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };
  runApp(Phoenix(child: const AIWrozkaApp()));
}

class AIWrozkaApp extends StatefulWidget {
  const AIWrozkaApp({super.key});

  @override
  State<AIWrozkaApp> createState() => _AIWrozkaAppState();
}

class _AIWrozkaAppState extends State<AIWrozkaApp> with WidgetsBindingObserver {
  final BackgroundMusicService _musicService =
      BackgroundMusicService(); // ✅ NOWY SERWIS

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
    _musicService.dispose(); // ✅ ZWOLNIJ ZASOBY MUZYCZNE
    super.dispose();
  }

  // ✅ OBSŁUGA CYKLU ŻYCIA APLIKACJI DLA MUZYKI
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _musicService.onAppPaused();
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
    try {
      print('🚀 Inicjalizacja aplikacji...');

      // ✅ Inicjalizacja HapticService
      await _hapticService.initialize();
      await _hapticService.printCapabilities();

      // Sprawdź czy onboarding został ukończony
      final isOnboardingCompleted =
          await UserPreferencesService.isOnboardingCompleted();
      print('📋 Onboarding completed: $isOnboardingCompleted');

      if (isOnboardingCompleted) {
        // Sprawdź czy mamy dane użytkownika
        final userData = await UserPreferencesService.getUserData();
        print('👤 User data: ${userData?.name ?? "BRAK"}');

        if (userData != null) {
          // Przejdź bezpośrednio do menu głównego
          print('✅ Przekierowanie do menu głównego');
          _targetScreen = MainMenuScreen(
            userName: userData.name,
            userGender: userData.genderForMessages,
            dominantHand: userData.dominantHand,
            birthDate: userData.birthDate,
          );
        } else {
          // Brak danych użytkownika mimo ukończonego onboardingu - powtórz onboarding
          print('⚠️ Brak danych użytkownika - ponowny onboarding');
          await UserPreferencesService.clearAllUserData();
          _targetScreen = const WelcomeScreen();
        }
      } else {
        // Pierwszy raz - pokaż welcome screen
        print('🎉 Pierwsze uruchomienie - welcome screen');
        _targetScreen = const WelcomeScreen();
      }

      // Debug
      await UserPreferencesService.debugPrintUserData();
    } catch (e) {
      print('❌ Błąd inicjalizacji: $e');
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
