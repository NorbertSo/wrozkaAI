// lib/services/background_music_service.dart
// ROZSZERZONA WERSJA - z obsługą wyboru muzyki przez użytkownika

import 'package:just_audio/just_audio.dart';
import 'user_preferences_service.dart';
import 'logging_service.dart';

class BackgroundMusicService {
  static final BackgroundMusicService _instance =
      BackgroundMusicService._internal();
  factory BackgroundMusicService() => _instance;
  BackgroundMusicService._internal();

  late AudioPlayer _backgroundPlayer;
  late AudioPlayer _previewPlayer;

  bool _isInitialized = false;
  bool _wasPlayingBeforePause = false;
  bool _isBackgroundMusicEnabled = true;
  double _volume = 0.14; // 14% głośności
  String _currentTrackFilename = 'musicbg.mp3'; // Domyślny utwór

  /// Inicjalizacja serwisu muzycznego
  Future<void> initialize() async {
    try {
      _backgroundPlayer = AudioPlayer();
      _previewPlayer = AudioPlayer();

      // Załaduj preferencje użytkownika
      await _loadUserPreferences();

      // Ustawienie głośności
      await _backgroundPlayer.setVolume(_volume);
      await _previewPlayer.setVolume(_volume * 1.5); // Preview trochę głośniej

      // Ustaw domyślną muzykę z loop
      if (_isBackgroundMusicEnabled && _currentTrackFilename.isNotEmpty) {
        await _backgroundPlayer.setAsset('assets/sound/$_currentTrackFilename');
        await _backgroundPlayer.setLoopMode(LoopMode.one);
      }

      _isInitialized = true;
      LoggingService().logToConsole('🎵 Background Music Service initialized',
          tag: 'MUSIC');
    } catch (e) {
      LoggingService().logToConsole('❌ Error initializing background music: $e',
          tag: 'ERROR');
    }
  }

  /// Załaduj preferencje użytkownika
  Future<void> _loadUserPreferences() async {
    try {
      final selectedTrack =
          await UserPreferencesService.getSelectedBackgroundMusic();
      final isEnabled = await UserPreferencesService.isBackgroundMusicEnabled();

      _isBackgroundMusicEnabled = isEnabled;

      if (selectedTrack != null && selectedTrack != 'silent_mode') {
        // Mapowanie ID na pliki
        _currentTrackFilename = _getFilenameFromTrackId(selectedTrack);
      }

      LoggingService().logToConsole(
          '🎵 Załadowano preferencje: enabled=$_isBackgroundMusicEnabled, track=$_currentTrackFilename',
          tag: 'MUSIC');
    } catch (e) {
      LoggingService().logToConsole('❌ Błąd ładowania preferencji muzyki: $e',
          tag: 'ERROR');
    }
  }

  /// Mapowanie ID utworu na nazwę pliku
  String _getFilenameFromTrackId(String trackId) {
    switch (trackId) {
      case 'mystic_ambient':
        return 'musicbg.mp3';
      case 'crystal_meditation':
        return 'crystal_meditation.mp3';
      case 'forest_whispers':
        return 'forest_whispers.mp3';
      case 'cosmic_energy':
        return 'cosmic_energy.mp3';
      case 'moonlight_serenade':
        return 'moonlight_serenade.mp3';
      default:
        return 'musicbg.mp3'; // Fallback
    }
  }

  /// Rozpocznij odtwarzanie muzyki w tle
  Future<void> startBackgroundMusic() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isBackgroundMusicEnabled) {
      LoggingService().logToConsole(
          '🔇 Muzyka w tle wyłączona przez użytkownika',
          tag: 'MUSIC');
      return;
    }

    try {
      await _backgroundPlayer.play();
      LoggingService().logToConsole(
          '🎵 Background music started: $_currentTrackFilename',
          tag: 'MUSIC');
    } catch (e) {
      LoggingService()
          .logToConsole('❌ Error starting background music: $e', tag: 'ERROR');
    }
  }

  /// Zatrzymaj muzykę w tle
  Future<void> stopBackgroundMusic() async {
    try {
      await _backgroundPlayer.stop();
      LoggingService()
          .logToConsole('🔇 Background music stopped', tag: 'MUSIC');
    } catch (e) {
      LoggingService()
          .logToConsole('❌ Error stopping background music: $e', tag: 'ERROR');
    }
  }

  /// Pauza muzyki w tle
  Future<void> pauseBackgroundMusic() async {
    try {
      await _backgroundPlayer.pause();
      LoggingService().logToConsole('⏸️ Background music paused', tag: 'MUSIC');
    } catch (e) {
      LoggingService()
          .logToConsole('❌ Error pausing background music: $e', tag: 'ERROR');
    }
  }

  /// Wznów muzykę w tle
  Future<void> resumeBackgroundMusic() async {
    if (!_isBackgroundMusicEnabled) return;

    try {
      await _backgroundPlayer.play();
      LoggingService()
          .logToConsole('▶️ Background music resumed', tag: 'MUSIC');
    } catch (e) {
      LoggingService()
          .logToConsole('❌ Error resuming background music: $e', tag: 'ERROR');
    }
  }

  /// Zmień muzykę w tle na nowy utwór
  Future<void> changeBackgroundMusic(String filename) async {
    try {
      final wasPlaying = _backgroundPlayer.playing;

      // Zatrzymaj aktualną muzykę
      await _backgroundPlayer.stop();

      // Załaduj nowy utwór
      _currentTrackFilename = filename;
      await _backgroundPlayer.setAsset('assets/sound/$filename');
      await _backgroundPlayer.setLoopMode(LoopMode.one);

      // Jeśli muzyka grała wcześniej, uruchom nowy utwór
      if (wasPlaying && _isBackgroundMusicEnabled) {
        await _backgroundPlayer.play();
      }

      LoggingService()
          .logToConsole('🎵 Zmieniono muzykę na: $filename', tag: 'MUSIC');
    } catch (e) {
      LoggingService().logToConsole('❌ Błąd zmiany muzyki: $e', tag: 'ERROR');
    }
  }

  /// Włącz/wyłącz muzykę w tle
  Future<void> setBackgroundMusicEnabled(bool enabled) async {
    _isBackgroundMusicEnabled = enabled;

    try {
      // Zapisz preferencje
      await UserPreferencesService.setBackgroundMusicEnabled(enabled);

      if (enabled) {
        // Włącz muzykę
        if (!_backgroundPlayer.playing) {
          await startBackgroundMusic();
        }
        LoggingService().logToConsole('🎵 Muzyka w tle włączona', tag: 'MUSIC');
      } else {
        // Wyłącz muzykę
        await stopBackgroundMusic();
        LoggingService()
            .logToConsole('🔇 Muzyka w tle wyłączona', tag: 'MUSIC');
      }
    } catch (e) {
      LoggingService()
          .logToConsole('❌ Błąd przełączania muzyki: $e', tag: 'ERROR');
    }
  }

  /// Odtwórz podgląd utworu (preview)
  Future<void> previewTrack(String filename) async {
    try {
      // Zatrzymaj poprzedni preview
      await _previewPlayer.stop();

      // Załaduj i odtwórz nowy preview
      await _previewPlayer.setAsset('assets/sound/$filename');
      await _previewPlayer.play();

      LoggingService().logToConsole('🎵 Preview: $filename', tag: 'MUSIC');
    } catch (e) {
      LoggingService().logToConsole('❌ Błąd preview: $e', tag: 'ERROR');
    }
  }

  /// Zatrzymaj podgląd utworu
  Future<void> stopPreview() async {
    try {
      await _previewPlayer.stop();
      LoggingService().logToConsole('⏹️ Preview zatrzymany', tag: 'MUSIC');
    } catch (e) {
      LoggingService()
          .logToConsole('❌ Błąd zatrzymywania preview: $e', tag: 'ERROR');
    }
  }

  /// Obsługa pauzowania aplikacji
  Future<void> onAppPaused() async {
    try {
      _wasPlayingBeforePause = _backgroundPlayer.playing;

      if (_wasPlayingBeforePause) {
        await pauseBackgroundMusic();
        LoggingService()
            .logToConsole('🎵 App paused - music paused', tag: 'MUSIC');
      }
    } catch (e) {
      LoggingService()
          .logToConsole('❌ Error handling app pause: $e', tag: 'ERROR');
    }
  }

  /// Obsługa wznawiania aplikacji
  Future<void> onAppResumed() async {
    try {
      if (_wasPlayingBeforePause &&
          !_backgroundPlayer.playing &&
          _isBackgroundMusicEnabled) {
        await resumeBackgroundMusic();
        LoggingService()
            .logToConsole('🎵 App resumed - music resumed', tag: 'MUSIC');
      }
    } catch (e) {
      LoggingService()
          .logToConsole('❌ Error handling app resume: $e', tag: 'ERROR');
    }
  }

  /// Ustaw głośność (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _backgroundPlayer.setVolume(_volume);
      await _previewPlayer.setVolume(_volume * 1.5);
      LoggingService().logToConsole(
          '🔊 Volume set to: ${(_volume * 100).round()}%',
          tag: 'MUSIC');
    } catch (e) {
      LoggingService().logToConsole('❌ Error setting volume: $e', tag: 'ERROR');
    }
  }

  /// Fade in effect
  Future<void> fadeIn({Duration duration = const Duration(seconds: 3)}) async {
    try {
      await _backgroundPlayer.setVolume(0.0);

      const steps = 30;
      const stepDuration = Duration(milliseconds: 100);
      final volumeStep = _volume / steps;

      for (int i = 0; i <= steps; i++) {
        await Future.delayed(stepDuration);
        final currentVolume = volumeStep * i;
        await _backgroundPlayer.setVolume(currentVolume);
      }

      LoggingService().logToConsole('🎵 Fade in completed', tag: 'MUSIC');
    } catch (e) {
      LoggingService().logToConsole('❌ Error during fade in: $e', tag: 'ERROR');
    }
  }

  /// Fade out effect
  Future<void> fadeOut({Duration duration = const Duration(seconds: 2)}) async {
    try {
      const steps = 20;
      const stepDuration = Duration(milliseconds: 100);
      final volumeStep = _volume / steps;

      for (int i = steps; i >= 0; i--) {
        await Future.delayed(stepDuration);
        final currentVolume = volumeStep * i;
        await _backgroundPlayer.setVolume(currentVolume);
      }

      await _backgroundPlayer.pause();
      await _backgroundPlayer.setVolume(_volume);
      LoggingService().logToConsole('🎵 Fade out completed', tag: 'MUSIC');
    } catch (e) {
      LoggingService()
          .logToConsole('❌ Error during fade out: $e', tag: 'ERROR');
    }
  }

  /// Gettery dla stanu
  bool get isPlaying => _backgroundPlayer.playing;
  bool get isPreviewPlaying => _previewPlayer.playing;
  bool get isBackgroundMusicEnabled => _isBackgroundMusicEnabled;
  double get volume => _volume;
  String get currentTrackFilename => _currentTrackFilename;

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _backgroundPlayer.dispose();
      await _previewPlayer.dispose();
      _isInitialized = false;
      LoggingService()
          .logToConsole('🗑️ Background Music Service disposed', tag: 'MUSIC');
    } catch (e) {
      LoggingService()
          .logToConsole('❌ Error disposing background music: $e', tag: 'ERROR');
    }
  }
}

// Globalna instancja dla łatwego dostępu
final backgroundMusic = BackgroundMusicService();
