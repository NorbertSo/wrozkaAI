// lib/services/secure_user_service.dart
// Bezpieczny serwis do zarządzania danymi użytkownika

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_data.dart';
import '../utils/logger.dart';

class SecureUserService {
  // Konfiguracja bezpiecznego storage
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'ai_wrozka_secure_prefs',
      preferencesKeyPrefix: 'ai_wrozka_',
    ),
    iOptions: IOSOptions(
      groupId: 'group.com.yourapp.aiwrozka',
      accountName: 'ai_wrozka_account',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Klucze dla różnych typów danych
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _userDataKey = 'user_data_encrypted';
  static const String _appSettingsKey = 'app_settings';

  /// Sprawdź czy onboarding został ukończony
  static Future<bool> isOnboardingCompleted() async {
    try {
      final result = await _storage.read(key: _onboardingCompletedKey);
      return result == 'true';
    } catch (e) {
      Logger.error('Błąd odczytu onboarding status: $e');
      return false;
    }
  }

  /// Oznacz onboarding jako ukończony
  static Future<void> setOnboardingCompleted() async {
    try {
      await _storage.write(key: _onboardingCompletedKey, value: 'true');
      Logger.info('Onboarding oznaczony jako ukończony');
    } catch (e) {
      Logger.error('Błąd zapisywania onboarding status: $e');
      throw Exception('Nie udało się zapisać statusu onboarding');
    }
  }

  /// Zapisz dane użytkownika (zaszyfrowane)
  static Future<void> saveUserData(UserData userData) async {
    try {
      // Walidacja danych przed zapisem
      if (userData.name.isEmpty) {
        throw Exception('Imię użytkownika nie może być puste');
      }

      final userDataJson = jsonEncode(userData.toJson());
      await _storage.write(key: _userDataKey, value: userDataJson);

      Logger.info('Dane użytkownika bezpiecznie zapisane');
    } catch (e) {
      Logger.error('Błąd zapisywania danych użytkownika: $e');
      throw Exception('Nie udało się zapisać danych użytkownika');
    }
  }

  /// Pobierz dane użytkownika (odszyfrowane)
  static Future<UserData?> getUserData() async {
    try {
      final userDataJson = await _storage.read(key: _userDataKey);

      if (userDataJson == null || userDataJson.isEmpty) {
        Logger.info('Brak zapisanych danych użytkownika');
        return null;
      }

      final userDataMap = jsonDecode(userDataJson) as Map<String, dynamic>;
      final userData = UserData.fromJson(userDataMap);

      Logger.info('Dane użytkownika bezpiecznie pobrane');
      return userData;
    } catch (e) {
      Logger.error('Błąd odczytu danych użytkownika: $e');
      return null;
    }
  }

  /// Sprawdź czy użytkownik ma zapisane dane
  static Future<bool> hasUserData() async {
    final userData = await getUserData();
    return userData != null;
  }

  /// Aktualizuj dane użytkownika
  static Future<void> updateUserData(UserData newUserData) async {
    await saveUserData(newUserData);
  }

  /// Usuń wszystkie dane użytkownika (bezpieczne wylogowanie)
  static Future<void> clearAllUserData() async {
    try {
      await _storage.delete(key: _onboardingCompletedKey);
      await _storage.delete(key: _userDataKey);
      await _storage.delete(key: _appSettingsKey);

      Logger.info('Wszystkie dane użytkownika bezpiecznie usunięte');
    } catch (e) {
      Logger.error('Błąd usuwania danych: $e');
      throw Exception('Nie udało się usunąć danych użytkownika');
    }
  }

  /// Usuń tylko dane użytkownika (zachowaj ustawienia)
  static Future<void> clearUserDataOnly() async {
    try {
      await _storage.delete(key: _userDataKey);
      Logger.info('Dane użytkownika usunięte (ustawienia zachowane)');
    } catch (e) {
      Logger.error('Błąd usuwania danych użytkownika: $e');
      throw Exception('Nie udało się usunąć danych użytkownika');
    }
  }

  /// Zapisz ustawienia aplikacji
  static Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      final settingsJson = jsonEncode(settings);
      await _storage.write(key: _appSettingsKey, value: settingsJson);
      Logger.info('Ustawienia aplikacji zapisane');
    } catch (e) {
      Logger.error('Błąd zapisywania ustawień: $e');
      throw Exception('Nie udało się zapisać ustawień');
    }
  }

  /// Pobierz ustawienia aplikacji
  static Future<Map<String, dynamic>?> getAppSettings() async {
    try {
      final settingsJson = await _storage.read(key: _appSettingsKey);

      if (settingsJson == null || settingsJson.isEmpty) {
        return null;
      }

      return jsonDecode(settingsJson) as Map<String, dynamic>;
    } catch (e) {
      Logger.error('Błąd odczytu ustawień: $e');
      return null;
    }
  }

  /// Sprawdź integralność danych (walidacja)
  static Future<bool> validateStoredData() async {
    try {
      final userData = await getUserData();
      if (userData == null) return true; // Brak danych = OK

      // Walidacja podstawowych pól
      if (userData.name.isEmpty) return false;
      if (userData.gender.isEmpty) return false;

      // Walidacja daty urodzenia
      final now = DateTime.now();
      if (userData.birthDate.isAfter(now)) return false;
      if (userData.birthDate.year < 1900) return false;

      Logger.info('Walidacja danych zakończona pomyślnie');
      return true;
    } catch (e) {
      Logger.error('Błąd walidacji danych: $e');
      return false;
    }
  }

  /// Debug: sprawdź stan storage (tylko w trybie debug)
  static Future<void> debugPrintStorageInfo() async {
    assert(() {
      _debugStorageInfo();
      return true;
    }());
  }

  static Future<void> _debugStorageInfo() async {
    try {
      final onboardingCompleted = await isOnboardingCompleted();
      final hasUserData = await SecureUserService.hasUserData();

      print('=== SECURE STORAGE DEBUG INFO ===');
      print('Onboarding completed: $onboardingCompleted');
      print('Has user data: $hasUserData');

      if (hasUserData) {
        final userData = await getUserData();
        print('User name: ${userData?.name ?? "N/A"}');
        print('User gender: ${userData?.gender ?? "N/A"}');
        print('Birth date: ${userData?.birthDate ?? "N/A"}');
      }
      print('================================');
    } catch (e) {
      print('Debug storage error: $e');
    }
  }

  /// Wymuś ponowną inicjalizację storage (w przypadku problemów)
  static Future<void> reinitializeStorage() async {
    try {
      // Ta metoda może być przydatna jeśli storage ma problemy
      Logger.info('Ponowna inicjalizacja secure storage');
    } catch (e) {
      Logger.error('Błąd reinicjalizacji storage: $e');
    }
  }
}
