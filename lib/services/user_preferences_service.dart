// lib/services/user_preferences_service.dart
// Serwis do zarządzania danymi użytkownika i onboardingu

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';

class UserPreferencesService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _userDataKey = 'user_data';

  // Sprawdź czy onboarding został ukończony
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  // Oznacz onboarding jako ukończony
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
    print('✅ Onboarding oznaczony jako ukończony');
  }

  // Zapisz dane użytkownika
  static Future<void> saveUserData(UserData userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = jsonEncode(userData.toJson());
      await prefs.setString(_userDataKey, userDataJson);
      print('✅ Dane użytkownika zapisane: ${userData.name}');
    } catch (e) {
      print('❌ Błąd zapisywania danych użytkownika: $e');
      throw Exception('Nie udało się zapisać danych użytkownika');
    }
  }

  // Pobierz dane użytkownika
  static Future<UserData?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString(_userDataKey);

      if (userDataJson == null) {
        print('ℹ️ Brak zapisanych danych użytkownika');
        return null;
      }

      final userDataMap = jsonDecode(userDataJson) as Map<String, dynamic>;
      final userData = UserData.fromJson(userDataMap);
      print('✅ Dane użytkownika pobrane: ${userData.name}');
      return userData;
    } catch (e) {
      print('❌ Błąd odczytu danych użytkownika: $e');
      return null;
    }
  }

  // Sprawdź czy użytkownik ma zapisane dane
  static Future<bool> hasUserData() async {
    final userData = await getUserData();
    return userData != null;
  }

  // Usuń wszystkie dane użytkownika (reset aplikacji)
  static Future<void> clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompletedKey);
      await prefs.remove(_userDataKey);
      print('✅ Wszystkie dane użytkownika usunięte');
    } catch (e) {
      print('❌ Błąd usuwania danych: $e');
    }
  }

  // Aktualizuj dane użytkownika
  static Future<void> updateUserData(UserData newUserData) async {
    await saveUserData(newUserData);
  }

  // Debug: wyświetl wszystkie zapisane dane
  static Future<void> debugPrintUserData() async {
    print('=== DEBUG USER DATA ===');
    print('Onboarding completed: ${await isOnboardingCompleted()}');
    print('Has user data: ${await hasUserData()}');

    final userData = await getUserData();
    if (userData != null) {
      print('User data: $userData');
      print('Full birth info: ${userData.fullBirthInfo}');
    } else {
      print('No user data found');
    }
    print('========================');
  }
}
