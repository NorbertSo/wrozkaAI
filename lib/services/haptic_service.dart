// lib/services/haptic_service.dart
// Serwis do zarządzania wibracjami i haptic feedback

import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

enum HapticType {
  light, // Lekka wibracja
  medium, // Średnia wibracja
  heavy, // Mocna wibracja
  selection, // Selekcja/przełączanie
  impact, // Uderzenie/potwierdzenie
  success, // Sukces
  warning, // Ostrzeżenie
  error, // Błąd
}

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _isEnabled = true;
  bool _hasVibrator = false;

  /// Inicjalizacja serwisu - sprawdź czy urządzenie obsługuje wibracje
  Future<void> initialize() async {
    try {
      _hasVibrator = await Vibration.hasVibrator() ?? false;
      print('🔊 Haptic Service: Vibrator available = $_hasVibrator');
    } catch (e) {
      _hasVibrator = false;
      print('❌ Haptic Service error: $e');
    }
  }

  /// Włącz/wyłącz wibracje globalnie
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    print('🔊 Haptic feedback ${enabled ? "enabled" : "disabled"}');
  }

  /// Sprawdź czy wibracje są włączone
  bool get isEnabled => _isEnabled && _hasVibrator;

  /// Główna metoda do wywoływania wibracji
  Future<void> trigger(HapticType type) async {
    if (!isEnabled) return;

    try {
      switch (type) {
        case HapticType.light:
          await _lightHaptic();
          break;
        case HapticType.medium:
          await _mediumHaptic();
          break;
        case HapticType.heavy:
          await _heavyHaptic();
          break;
        case HapticType.selection:
          await _selectionHaptic();
          break;
        case HapticType.impact:
          await _impactHaptic();
          break;
        case HapticType.success:
          await _successHaptic();
          break;
        case HapticType.warning:
          await warning(); // poprawne wywołanie publicznej metody
          break;
        case HapticType.error:
          await _errorHaptic();
          break;
      }
    } catch (e) {
      print('❌ Haptic feedback error: $e');
    }
  }

  /// LEKKA WIBRACJA - idealna do przycisków
  Future<void> _lightHaptic() async {
    if (await Vibration.hasCustomVibrationsSupport() == true) {
      // Krótka, delikatna wibracja
      await Vibration.vibrate(duration: 50, amplitude: 128);
    } else {
      // Fallback dla starszych urządzeń
      HapticFeedback.lightImpact();
    }
  }

  /// ŚREDNIA WIBRACJA - do ważniejszych akcji
  Future<void> _mediumHaptic() async {
    if (await Vibration.hasCustomVibrationsSupport() == true) {
      await Vibration.vibrate(duration: 80, amplitude: 180);
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  /// MOCNA WIBRACJA - do bardzo ważnych akcji
  Future<void> _heavyHaptic() async {
    if (await Vibration.hasCustomVibrationsSupport() == true) {
      await Vibration.vibrate(duration: 120, amplitude: 255);
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  /// SELEKCJA - do przełączników, checkbox, radio
  Future<void> _selectionHaptic() async {
    HapticFeedback.selectionClick();
  }

  /// IMPACT - do potwierdzeń, "kliknięć"
  Future<void> _impactHaptic() async {
    if (await Vibration.hasCustomVibrationsSupport() == true) {
      await Vibration.vibrate(duration: 60, amplitude: 150);
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  /// SUKCES - podwójna krótka wibracja
  Future<void> _successHaptic() async {
    if (await Vibration.hasCustomVibrationsSupport() == true) {
      // amplitudes NIE jest wspierane w każdej wersji vibration lub na każdej platformie!
      // Najnowsze wersje vibration mogą nie mieć już parametru amplitudes lub jest on tylko na Androidzie.
      // Rozwiązanie: użyj tylko pattern bez amplitudes.
      await Vibration.vibrate(
        pattern: [0, 100, 50, 100],
        // amplitudes: [0, 200, 0, 200], // USUŃ lub zakomentuj tę linię!
      );
    } else {
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.lightImpact();
    }
  }

  /// BŁĄD - trzyklotna krótka wibracja
  Future<void> _errorHaptic() async {
    if (await Vibration.hasCustomVibrationsSupport() == true) {
      await Vibration.vibrate(
        pattern: [0, 80, 30, 80, 30, 80],
        // amplitudes: [0, 255, 0, 255, 0, 255], // USUŃ lub zakomentuj tę linię!
      );
    } else {
      for (int i = 0; i < 3; i++) {
        HapticFeedback.heavyImpact();
        if (i < 2) await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  /// Wygodne metody dla najczęściej używanych typów
  Future<void> buttonPress() => trigger(HapticType.light);
  Future<void> buttonConfirm() => trigger(HapticType.impact);
  Future<void> toggle() => trigger(HapticType.selection);
  Future<void> success() => trigger(HapticType.success);
  Future<void> error() => trigger(HapticType.error);
  Future<void> warning() => trigger(HapticType.warning);

  /// Customowa wibracja z własnymi parametrami
  Future<void> customVibration({
    required int duration,
    int amplitude = 128,
  }) async {
    if (!isEnabled) return;

    try {
      if (await Vibration.hasCustomVibrationsSupport() == true) {
        await Vibration.vibrate(
          duration: duration.clamp(10, 1000),
          amplitude: amplitude.clamp(1, 255),
        );
      } else {
        // Fallback dla urządzeń bez custom vibration
        if (duration < 100) {
          HapticFeedback.lightImpact();
        } else if (duration < 200) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.heavyImpact();
        }
      }
    } catch (e) {
      print('❌ Custom vibration error: $e');
    }
  }

  /// Wibracja z wzorcem (pattern)
  Future<void> patternVibration({
    required List<int> pattern,
    List<int>? amplitudes,
  }) async {
    if (!isEnabled) return;

    try {
      if (await Vibration.hasCustomVibrationsSupport() == true) {
        // amplitudes może być null, ale niektóre wersje vibration nie obsługują parametru amplitudes
        // lub obsługują tylko na Androidzie. Spróbuj przekazać tylko jeśli amplitudes != null i platforma to Android.
        // Najbezpieczniej: przekazuj amplitudes tylko jeśli amplitudes != null i nie jesteś na iOS/web.
        // Jeśli nadal podkreśla, użyj tylko pattern bez amplitudes:
        await Vibration.vibrate(
          pattern: pattern,
          // amplitudes: amplitudes, // KOMENTUJEMY, bo nie zawsze jest wspierane!
        );
      } else {
        // Fallback - symuluj pattern przez HapticFeedback
        for (int i = 0; i < pattern.length; i += 2) {
          if (i + 1 < pattern.length) {
            await Future.delayed(Duration(milliseconds: pattern[i]));
            HapticFeedback.lightImpact();
            if (i + 2 < pattern.length) {
              await Future.delayed(Duration(milliseconds: pattern[i + 1]));
            }
          }
        }
      }
    } catch (e) {
      print('❌ Pattern vibration error: $e');
    }
  }

  /// Sprawdź możliwości urządzenia
  Future<Map<String, bool>> getCapabilities() async {
    try {
      return {
        'hasVibrator': await Vibration.hasVibrator() ?? false,
        'hasAmplitudeControl': await Vibration.hasAmplitudeControl() ?? false,
        'hasCustomVibrationsSupport':
            await Vibration.hasCustomVibrationsSupport() ?? false,
      };
    } catch (e) {
      return {
        'hasVibrator': false,
        'hasAmplitudeControl': false,
        'hasCustomVibrationsSupport': false,
      };
    }
  }

  /// Debug info
  Future<void> printCapabilities() async {
    final caps = await getCapabilities();
    print('🔊 Haptic Capabilities:');
    caps.forEach((key, value) {
      print('   $key: $value');
    });
  }
}

// Powód podkreślenia "Vibration":
/// 1. Najczęściej: nie masz dodanej paczki vibration w pubspec.yaml lub nie wykonałeś `flutter pub get`.
/// 2. Możliwe, że importujesz złą paczkę lub import jest błędny.
/// 3. Jeśli używasz web/desktop, paczka vibration nie jest wspierana na tych platformach (tylko Android/iOS).

/// Rozwiązanie:
/// 1. Upewnij się, że w pubspec.yaml masz:
///    vibration: ^1.7.4
/// 2. W terminalu uruchom: flutter pub get
/// 3. Upewnij się, że importujesz:
///    import 'package:vibration/vibration.dart';
/// 4. Jeśli nadal podkreśla, zrestartuj IDE (czasem cache IntelliSense się psuje).
/// 5. Jeśli budujesz na web/desktop, kod z vibration będzie podkreślony, bo nie jest wspierany na tych platformach.

/// Przykład sekcji dependencies w pubspec.yaml:
/// dependencies:
///   flutter:
///     sdk: flutter
///   vibration: ^1.7.4
///   flutter:
///     sdk: flutter
///   vibration: ^1.7.4
///   flutter:
///     sdk: flutter
///   vibration: ^1.7.4
///   flutter:
///     sdk: flutter
///   vibration: ^1.7.4
