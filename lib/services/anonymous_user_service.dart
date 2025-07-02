// lib/services/anonymous_user_service.dart
// 👤 SERWIS ANONIMOWYCH UŻYTKOWNIKÓW
// Zgodny z wytycznymi projektu AI Wróżka - totalna anonimowość

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import '../models/user_anonymous_profile.dart';
import '../utils/logger.dart';

class AnonymousUserService {
  static final AnonymousUserService _instance =
      AnonymousUserService._internal();
  factory AnonymousUserService() => _instance;
  AnonymousUserService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  UserAnonymousProfile? _currentProfile;
  bool _initialized = false;

  /// 🏗️ Inicjalizacja serwisu
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      Logger.info('Inicjalizacja AnonymousUserService...');

      // Sprawdź czy użytkownik już istnieje
      if (_auth.currentUser != null) {
        Logger.info('Znaleziono istniejącego użytkownika Firebase');
        await _loadExistingProfile();
      } else {
        Logger.info('Tworzenie nowego anonimowego użytkownika');
        await _createNewAnonymousUser();
      }

      // Sprawdź codzienne logowanie
      if (_currentProfile != null) {
        await _checkDailyLogin();
      }

      _initialized = true;
      Logger.info('AnonymousUserService zainicjalizowany pomyślnie');
    } catch (e) {
      Logger.error('Błąd inicjalizacji AnonymousUserService: $e');
      throw Exception('Nie udało się zainicjalizować systemu użytkowników');
    }
  }

  /// 👤 Stwórz nowego anonimowego użytkownika
  Future<void> _createNewAnonymousUser() async {
    try {
      // 1. Zaloguj anonimowo w Firebase
      final userCredential = await _auth.signInAnonymously();
      final firebaseUserId = userCredential.user!.uid;

      Logger.info(
          'Stworzono Firebase Anonymous User: ${firebaseUserId.substring(0, 8)}...');

      // 2. Wygeneruj Device ID jako backup
      final deviceId = await _generateDeviceId();

      // 3. Wygeneruj unikalny kod polecający
      final referralCode = await _generateUniqueReferralCode();

      // 4. Stwórz profil
      _currentProfile = UserAnonymousProfile.createNew(
        userId: firebaseUserId,
        deviceId: deviceId,
        referralCode: referralCode,
      );

      // 5. Zapisz w Firestore
      await _saveProfileToFirestore();

      // 6. Wibracja powitalna
      await _triggerSuccessHaptic();

      Logger.info('Nowy użytkownik stworzony z 30 świecami startowymi');
    } catch (e) {
      Logger.error('Błąd tworzenia nowego użytkownika: $e');
      rethrow;
    }
  }

  /// 📂 Załaduj istniejący profil
  Future<void> _loadExistingProfile() async {
    try {
      final firebaseUserId = _auth.currentUser!.uid;

      final doc =
          await _firestore.collection('users').doc(firebaseUserId).get();

      if (doc.exists && doc.data() != null) {
        _currentProfile = UserAnonymousProfile.fromFirestore(doc.data()!);
        Logger.info('Załadowano istniejący profil użytkownika');
      } else {
        Logger.warning(
            'Profil Firebase użytkownika nie istnieje - tworzenie nowego');
        await _createProfileForExistingFirebaseUser(firebaseUserId);
      }
    } catch (e) {
      Logger.error('Błąd ładowania profilu: $e');
      rethrow;
    }
  }

  /// 🔧 Stwórz profil dla istniejącego Firebase użytkownika
  Future<void> _createProfileForExistingFirebaseUser(
      String firebaseUserId) async {
    try {
      final deviceId = await _generateDeviceId();
      final referralCode = await _generateUniqueReferralCode();

      _currentProfile = UserAnonymousProfile.createNew(
        userId: firebaseUserId,
        deviceId: deviceId,
        referralCode: referralCode,
      );

      await _saveProfileToFirestore();
      Logger.info('Stworzono profil dla istniejącego Firebase użytkownika');
    } catch (e) {
      Logger.error('Błąd tworzenia profilu dla istniejącego użytkownika: $e');
      rethrow;
    }
  }

  /// 📅 Sprawdź codzienne logowanie i nagrody
  Future<void> _checkDailyLogin() async {
    if (_currentProfile == null) return;

    try {
      final oldStreak = _currentProfile!.dailyLoginStreak;
      final updatedProfile = _currentProfile!.updateLoginStreak();

      // Jeśli zmienił się streak, zapisz i ewentualnie daj nagrodę
      if (updatedProfile.dailyLoginStreak != oldStreak) {
        _currentProfile = updatedProfile;
        await _saveProfileToFirestore();

        // Nagroda za codzienne logowanie (tylko jeśli zwiększył się streak)
        if (updatedProfile.dailyLoginStreak > oldStreak) {
          await _giveDailyLoginReward();

          // Bonus za długie serie (co 7 dni)
          if (updatedProfile.dailyLoginStreak % 7 == 0) {
            await _giveStreakBonus();
          }
        }
      }
    } catch (e) {
      Logger.error('Błąd sprawdzania codziennego logowania: $e');
    }
  }

  /// 🎁 Nagroda za codzienne logowanie
  Future<void> _giveDailyLoginReward() async {
    if (_currentProfile == null) return;

    try {
      const dailyReward = 1; // 1 świeca za codzienne logowanie

      _currentProfile = _currentProfile!.addCandles(dailyReward);
      await _saveProfileToFirestore();

      // Zapisz transakcję
      await _recordCandleTransaction(
        type: 'earned',
        amount: dailyReward,
        reason: 'Codzienna nagroda',
        feature: 'daily_login',
      );

      await _triggerLightHaptic();
      Logger.info('Dodano codzienną nagrodę: $dailyReward świeca');
    } catch (e) {
      Logger.error('Błąd dodawania codziennej nagrody: $e');
    }
  }

  /// 🏆 Bonus za długie serie logowań
  Future<void> _giveStreakBonus() async {
    if (_currentProfile == null) return;

    try {
      const streakBonus = 2; // 2 dodatkowe świece za 7-dniową serię

      _currentProfile = _currentProfile!.addCandles(streakBonus);
      await _saveProfileToFirestore();

      // Zapisz transakcję
      await _recordCandleTransaction(
        type: 'earned',
        amount: streakBonus,
        reason:
            'Bonus za regularność (${_currentProfile!.dailyLoginStreak} dni)',
        feature: 'streak_bonus',
      );

      await _triggerSuccessHaptic();
      Logger.info(
          'Dodano bonus za serię: $streakBonus świece za ${_currentProfile!.dailyLoginStreak} dni');
    } catch (e) {
      Logger.error('Błąd dodawania bonusu za serię: $e');
    }
  }

  /// 💾 Zapisz profil do Firestore
  Future<void> _saveProfileToFirestore() async {
    if (_currentProfile == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentProfile!.userId)
          .set(_currentProfile!.toFirestore(), SetOptions(merge: true));

      Logger.info('Profil zapisany do Firestore');
    } catch (e) {
      Logger.error('Błąd zapisywania profilu: $e');
      rethrow;
    }
  }

  /// 📝 Zapisz transakcję świec
  Future<void> _recordCandleTransaction({
    required String type,
    required int amount,
    required String reason,
    String? feature,
  }) async {
    if (_currentProfile == null) return;

    try {
      final transaction = {
        'userId': _currentProfile!.userId,
        'type': type,
        'amount': amount,
        'reason': reason,
        'feature': feature,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('candle_transactions').add(transaction);

      Logger.info('Transakcja świec zapisana: $type $amount');
    } catch (e) {
      Logger.error('Błąd zapisywania transakcji: $e');
    }
  }

  /// 📱 Wygeneruj Device ID jako backup
  Future<String> _generateDeviceId() async {
    try {
      String deviceData = '';

      // Pobierz podstawowe informacje (bez szczegółów prywatnych)
      try {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceData = 'android_${androidInfo.model}';
      } catch (e) {
        try {
          final iosInfo = await _deviceInfo.iosInfo;
          deviceData = 'ios_${iosInfo.model}';
        } catch (e) {
          deviceData = 'unknown_device';
        }
      }

      // Dodaj timestamp dla unikalności
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final combined = '${deviceData}_$timestamp';

      // Hash dla anonimowości
      final bytes = utf8.encode(combined);
      final digest = sha256.convert(bytes);

      return 'dev_${digest.toString().substring(0, 16)}';
    } catch (e) {
      Logger.error('Błąd generowania Device ID: $e');
      // Fallback - losowy ID
      final random = Random();
      final randomId =
          List.generate(16, (index) => random.nextInt(16).toRadixString(16))
              .join();
      return 'dev_$randomId';
    }
  }

  /// 🔤 Wygeneruj unikalny kod polecający
  Future<String> _generateUniqueReferralCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();

    for (int attempt = 0; attempt < 10; attempt++) {
      // Generuj 6-znakowy kod
      final code =
          List.generate(6, (index) => chars[random.nextInt(chars.length)])
              .join();

      // Sprawdź czy kod już istnieje
      final existingCode =
          await _firestore.collection('referral_codes').doc(code).get();

      if (!existingCode.exists) {
        // Kod jest unikalny - zarezerwuj go
        await _firestore.collection('referral_codes').doc(code).set({
          'ownerId': '', // Zostanie uzupełnione później
          'createdAt': FieldValue.serverTimestamp(),
          'totalUses': 0,
          'usedBy': [],
          'isActive': true,
        });

        Logger.info('Wygenerowano unikalny kod polecający: $code');
        return code;
      }
    }

    // Fallback - jeśli nie udało się wygenerować unikalnego kodu
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fallbackCode = 'U${timestamp.toString().substring(7)}';
    Logger.warning('Użyto fallback kodu polecającego: $fallbackCode');
    return fallbackCode;
  }

  /// 🔊 Metody haptyczne (fallback bez dependency na HapticService)
  Future<void> _triggerLightHaptic() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      Logger.error('Błąd wibracji light: $e');
    }
  }

  Future<void> _triggerSuccessHaptic() async {
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
    } catch (e) {
      Logger.error('Błąd wibracji success: $e');
    }
  }

  /// 📊 Publiczne API

  /// Pobierz aktualny profil użytkownika
  UserAnonymousProfile? get currentProfile => _currentProfile;

  /// Sprawdź czy serwis jest zainicjalizowany
  bool get isInitialized => _initialized;

  /// Pobierz ID użytkownika
  String? get userId => _currentProfile?.userId;

  /// Pobierz saldo świec
  int get candleBalance => _currentProfile?.candleBalance ?? 0;

  /// Sprawdź czy użytkownik może wydać świece
  bool canSpendCandles(int amount) =>
      _currentProfile?.canSpendCandles(amount) ?? false;

  /// Dodaj świece (nagroda)
  Future<bool> addCandles(int amount, String reason, {String? feature}) async {
    if (_currentProfile == null || amount <= 0) return false;

    try {
      _currentProfile = _currentProfile!.addCandles(amount);
      await _saveProfileToFirestore();

      await _recordCandleTransaction(
        type: 'earned',
        amount: amount,
        reason: reason,
        feature: feature,
      );

      await _triggerLightHaptic();
      Logger.info('Dodano $amount świec: $reason');
      return true;
    } catch (e) {
      Logger.error('Błąd dodawania świec: $e');
      return false;
    }
  }

  /// Wydaj świece
  Future<bool> spendCandles(int amount, String reason,
      {String? feature}) async {
    if (_currentProfile == null || !canSpendCandles(amount)) return false;

    try {
      _currentProfile = _currentProfile!.spendCandles(amount);
      await _saveProfileToFirestore();

      await _recordCandleTransaction(
        type: 'spent',
        amount: amount,
        reason: reason,
        feature: feature,
      );

      await _triggerLightHaptic();
      Logger.info('Wydano $amount świec: $reason');
      return true;
    } catch (e) {
      Logger.error('Błąd wydawania świec: $e');
      return false;
    }
  }

  /// Sprawdź czy użytkownik użył darmowy skan dłoni w tym miesiącu
  bool hasUsedFreePalmReading() =>
      _currentProfile?.hasUsedFreePalmReading() ?? false;

  /// Sprawdź czy użytkownik użył darmowy rozbudowany horoskop w tym miesiącu
  bool hasUsedFreeExtendedHoroscope() =>
      _currentProfile?.hasUsedFreeExtendedHoroscope() ?? false;

  /// Oznacz użycie darmowego skanu dłoni
  Future<void> markFreePalmReadingUsed() async {
    if (_currentProfile == null) return;

    _currentProfile = _currentProfile!.markFreePalmReadingUsed();
    await _saveProfileToFirestore();
    Logger.info('Oznaczono użycie darmowego skanu dłoni');
  }

  /// Oznacz użycie darmowego rozbudowanego horoskopu
  Future<void> markFreeExtendedHoroscopeUsed() async {
    if (_currentProfile == null) return;

    _currentProfile = _currentProfile!.markFreeExtendedHoroscopeUsed();
    await _saveProfileToFirestore();
    Logger.info('Oznaczono użycie darmowego rozbudowanego horoskopu');
  }

  /// Pobierz kod polecający użytkownika
  String? get referralCode => _currentProfile?.referralCode;

  /// Sprawdź czy użytkownik jest nowy (pierwszy dzień)
  bool get isNewUser => _currentProfile?.isNewUser ?? true;

  /// Pobierz serię codziennych logowań
  int get dailyLoginStreak => _currentProfile?.dailyLoginStreak ?? 0;

  /// Wymusz odświeżenie profilu
  Future<void> refreshProfile() async {
    if (!_initialized || _currentProfile == null) return;

    try {
      await _loadExistingProfile();
      Logger.info('Profil odświeżony');
    } catch (e) {
      Logger.error('Błąd odświeżania profilu: $e');
    }
  }

  /// Wyloguj użytkownika (tylko w celach debugowania)
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentProfile = null;
      _initialized = false;
      Logger.info('Użytkownik wylogowany');
    } catch (e) {
      Logger.error('Błąd wylogowywania: $e');
    }
  }
}
