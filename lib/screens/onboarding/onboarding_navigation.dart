// lib/screens/onboarding/onboarding_navigation.dart
// Główny kontroler nawigacji dla całego procesu onboarding

import 'package:flutter/material.dart';
import '../welcome_screen.dart'; // Istniejący
import '../onboarding_screen.dart'; // Istniejący
import '../main_menu_screen.dart'; // Istniejący
import 'music_selection_screen.dart'; // Nowy
import 'data_intro_screen.dart'; // Nowy
import 'mystical_world_intro_screen.dart'; // Nowy
import '../../services/logging_service.dart';
import '../../services/user_preferences_service.dart';

class OnboardingNavigationController {
  /// Sprawdź aktualny stan onboarding i przekieruj do odpowiedniego ekranu
  static Future<Widget> determineInitialScreen() async {
    try {
      // Sprawdź czy onboarding został ukończony
      final isOnboardingCompleted =
          await UserPreferencesService.isOnboardingCompleted();

      if (isOnboardingCompleted) {
        // Sprawdź czy mamy kompletne dane użytkownika
        final userData = await UserPreferencesService.getUserData();

        if (userData != null) {
          LoggingService()
              .logToConsole('✅ Przekierowanie do MainMenu', tag: 'NAVIGATION');
          return MainMenuScreen(
            userName: userData.name,
            userGender: userData.genderForMessages,
            dominantHand: userData.dominantHand,
            birthDate: userData.birthDate,
          );
        } else {
          LoggingService().logToConsole('⚠️ Brak danych - restart onboarding',
              tag: 'NAVIGATION');
          await UserPreferencesService.clearAllUserData();
          return const WelcomeScreen();
        }
      } else {
        LoggingService().logToConsole('🎉 Pierwszy raz - Welcome Screen',
            tag: 'NAVIGATION');
        return const WelcomeScreen();
      }
    } catch (e) {
      LoggingService().logToConsole('❌ Błąd nawigacji: $e', tag: 'ERROR');
      return const WelcomeScreen();
    }
  }
}
