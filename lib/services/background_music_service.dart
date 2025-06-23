// lib/services/background_music_service.dart
// NAPRAWIONA WERSJA - dodane metody onAppPaused i onAppResumed

import 'package:just_audio/just_audio.dart';

class BackgroundMusicService {
  static final BackgroundMusicService _instance =
      BackgroundMusicService._internal();
  factory BackgroundMusicService() => _instance;
  BackgroundMusicService._internal();

  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;
  bool _wasPlayingBeforePause = false; // ✅ DODANE: Pamięć stanu przed pauzą
  double _volume = 0.14; // Minimalna głośność (30%)

  /// Inicjalizacja serwisu muzycznego
  Future<void> initialize() async {
    try {
      _audioPlayer = AudioPlayer();

      // Ustawienie głośności
      await _audioPlayer.setVolume(_volume);

      // Ustaw źródło audio z loop
      await _audioPlayer.setAsset('assets/sound/musicbg.mp3');
      await _audioPlayer.setLoopMode(LoopMode.one); // Loop single track

      _isInitialized = true;
      print('🎵 Background Music Service initialized');
    } catch (e) {
      print('❌ Error initializing background music: $e');
    }
  }

  /// Rozpocznij odtwarzanie muzyki w tle
  Future<void> startBackgroundMusic() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _audioPlayer.play();
      print('🎵 Background music started');
    } catch (e) {
      print('❌ Error starting background music: $e');
    }
  }

  /// Zatrzymaj muzykę w tle
  Future<void> stopBackgroundMusic() async {
    try {
      await _audioPlayer.stop();
      print('🔇 Background music stopped');
    } catch (e) {
      print('❌ Error stopping background music: $e');
    }
  }

  /// Pauza muzyki
  Future<void> pauseBackgroundMusic() async {
    try {
      await _audioPlayer.pause();
      print('⏸️ Background music paused');
    } catch (e) {
      print('❌ Error pausing background music: $e');
    }
  }

  /// Wznów muzykę
  Future<void> resumeBackgroundMusic() async {
    try {
      await _audioPlayer.play();
      print('▶️ Background music resumed');
    } catch (e) {
      print('❌ Error resuming background music: $e');
    }
  }

  // ✅ DODANE: Metody obsługi cyklu życia aplikacji
  /// Obsługa pauzowania aplikacji
  Future<void> onAppPaused() async {
    try {
      // Zapamiętaj czy muzyka grała przed pauzą
      _wasPlayingBeforePause = _audioPlayer.playing;

      if (_wasPlayingBeforePause) {
        await pauseBackgroundMusic();
        print('🎵 App paused - music paused');
      }
    } catch (e) {
      print('❌ Error handling app pause: $e');
    }
  }

  /// Obsługa wznawiania aplikacji
  Future<void> onAppResumed() async {
    try {
      // Wznów muzykę tylko jeśli grała przed pauzą
      if (_wasPlayingBeforePause && !_audioPlayer.playing) {
        await resumeBackgroundMusic();
        print('🎵 App resumed - music resumed');
      }
    } catch (e) {
      print('❌ Error handling app resume: $e');
    }
  }

  /// Ustaw głośność (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(_volume);
      print('🔊 Volume set to: ${(_volume * 100).round()}%');
    } catch (e) {
      print('❌ Error setting volume: $e');
    }
  }

  /// Fade in effect
  Future<void> fadeIn({Duration duration = const Duration(seconds: 3)}) async {
    try {
      await _audioPlayer.setVolume(0.0);

      const steps = 30;
      const stepDuration = Duration(milliseconds: 100);
      final volumeStep = _volume / steps;

      for (int i = 0; i <= steps; i++) {
        await Future.delayed(stepDuration);
        final currentVolume = volumeStep * i;
        await _audioPlayer.setVolume(currentVolume);
      }

      print('🎵 Fade in completed');
    } catch (e) {
      print('❌ Error during fade in: $e');
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
        await _audioPlayer.setVolume(currentVolume);
      }

      await _audioPlayer.pause();
      await _audioPlayer.setVolume(_volume);
      print('🎵 Fade out completed');
    } catch (e) {
      print('❌ Error during fade out: $e');
    }
  }

  /// Sprawdź czy muzyka gra
  bool get isPlaying => _audioPlayer.playing;

  /// Pobierz aktualną głośność
  double get volume => _volume;

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
      print('🗑️ Background Music Service disposed');
    } catch (e) {
      print('❌ Error disposing background music: $e');
    }
  }
}

// ✅ DODANE: Globalna instancja dla łatwego dostępu
final backgroundMusic = BackgroundMusicService();
