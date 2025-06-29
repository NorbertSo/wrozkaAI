// lib/services/user_preferences_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../services/secure_user_service.dart';
import '../models/user_data.dart';

/// Wrapper dla backward compatibility
/// Przekierowuje wszystkie wywołania do SecureUserService
class UserPreferencesService {
  // Music preferences keys
  static const String _selectedBackgroundMusicKey = 'selected_background_music';
  static const String _backgroundMusicEnabledKey = 'background_music_enabled';

  // Wszystkie metody teraz używają SecureUserService
  static Future<bool> isOnboardingCompleted() async {
    return await SecureUserService.isOnboardingCompleted();
  }

  static Future<void> setOnboardingCompleted() async {
    return await SecureUserService.setOnboardingCompleted();
  }

  static Future<void> saveUserData(UserData userData) async {
    return await SecureUserService.saveUserData(userData);
  }

  static Future<UserData?> getUserData() async {
    return await SecureUserService.getUserData();
  }

  static Future<bool> hasUserData() async {
    return await SecureUserService.hasUserData();
  }

  static Future<void> clearAllUserData() async {
    return await SecureUserService.clearAllUserData();
  }

  static Future<void> updateUserData(UserData newUserData) async {
    return await SecureUserService.updateUserData(newUserData);
  }

  static Future<void> debugPrintUserData() async {
    return await SecureUserService.debugPrintStorageInfo();
  }

  /// Zapisz wybór muzyki w tle użytkownika
  static Future<void> setSelectedBackgroundMusic(String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedBackgroundMusicKey, trackId);
  }

  /// Pobierz wybór muzyki w tle użytkownika
  static Future<String?> getSelectedBackgroundMusic() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedBackgroundMusicKey);
  }

  /// Zapisz stan włączenia/wyłączenia muzyki w tle
  static Future<void> setBackgroundMusicEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backgroundMusicEnabledKey, enabled);
  }

  /// Pobierz stan włączenia/wyłączenia muzyki w tle
  static Future<bool> isBackgroundMusicEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backgroundMusicEnabledKey) ?? true;
  }

  /// Wyczyść preferencje muzyczne (dla debugowania)
  static Future<void> clearMusicPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedBackgroundMusicKey);
    await prefs.remove(_backgroundMusicEnabledKey);
  }
}
