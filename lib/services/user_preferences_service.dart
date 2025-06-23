// lib/services/user_preferences_service.dart
// ZASTĄP CAŁĄ ZAWARTOŚĆ tym kodem:

import '../services/secure_user_service.dart';
import '../models/user_data.dart';

/// Wrapper dla backward compatibility
/// Przekierowuje wszystkie wywołania do SecureUserService
class UserPreferencesService {
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
}
