// lib/services/candle_manager_service.dart
// 🕯️ SERWIS ZARZĄDZANIA ŚWIECAMI - ZAKTUALIZOWANY
// Zgodny z wytycznymi projektu AI Wróżka
// WSZYSTKIE FUNKCJE TYLKO PŁATNE ŚWIECAMI

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/candle_transaction.dart';
import '../services/anonymous_user_service.dart';
import '../services/haptic_service.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';
import '../widgets/candle_payment_confirmation_widget.dart';

class CandleManagerService {
  static final CandleManagerService _instance =
      CandleManagerService._internal();
  factory CandleManagerService() => _instance;
  CandleManagerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnonymousUserService _userService = AnonymousUserService();

  // 🎯 CENY FUNKCJI (świece)
  static const int PRICE_EXTENDED_HOROSCOPE = 15;
  static const int PRICE_PALM_READING = 25;
  static const int PRICE_WEEKLY_HOROSCOPE = 10;

  // 🎁 NAGRODY
  static const int REWARD_DAILY_LOGIN = 1;
  static const int REWARD_SHARE_RESULT = 3;
  static const int REWARD_REFERRAL_SUCCESS = 5;
  static const int REWARD_STREAK_BONUS = 2;

  /// 🏗️ Inicjalizacja
  Future<void> initialize() async {
    // Upewnij się że AnonymousUserService jest zainicjalizowany
    if (!_userService.isInitialized) {
      await _userService.initialize();
    }
    Logger.info('CandleManagerService zainicjalizowany');
  }

  /// 💰 Pobierz aktualne saldo świec
  int get currentBalance => _userService.candleBalance;

  /// ✅ Sprawdź czy użytkownik może wydać świece
  bool canAfford(int amount) => _userService.canSpendCandles(amount);

  /// 🔮 Sprawdź czy może użyć rozbudowanego horoskopu
  Future<bool> canUseExtendedHoroscope() async {
    await initialize();
    // TYLKO PŁATNE - sprawdź wyłącznie świece
    return canAfford(PRICE_EXTENDED_HOROSCOPE);
  }

  /// 🖐️ Sprawdź czy może użyć skanu dłoni
  Future<bool> canUsePalmReading() async {
    await initialize();
    // TYLKO PŁATNE - sprawdź wyłącznie świece
    return canAfford(PRICE_PALM_READING);
  }

  /// 📅 Sprawdź czy może użyć horoskopu tygodniowego
  Future<bool> canUseWeeklyHoroscope() async {
    await initialize();
    // TYLKO PŁATNE - sprawdź wyłącznie świece
    return canAfford(PRICE_WEEKLY_HOROSCOPE);
  }

  /// 🔮 Użyj rozbudowanego horoskopu - TYLKO PŁATNY
  Future<CandleUsageResult> useExtendedHoroscope() async {
    await initialize();

    try {
      // Sprawdź czy ma wystarczająco świec (bez wyświetlania dialogu)
      if (!canAfford(PRICE_EXTENDED_HOROSCOPE)) {
        // Usunięto HapticService.triggerError() - będzie obsłużone przez UI
        return CandleUsageResult.failure(
          'Potrzebujesz $PRICE_EXTENDED_HOROSCOPE świec do rozbudowanego horoskopu. Masz tylko $currentBalance.',
        );
      }

      // Wydaj świece
      final success = await _userService.spendCandles(
        PRICE_EXTENDED_HOROSCOPE,
        'Rozbudowany horoskop',
        feature: 'extended_horoscope',
      );

      if (success) {
        await HapticService.triggerSuccess();
        Logger.info(
            'Użyto rozbudowanego horoskopu za $PRICE_EXTENDED_HOROSCOPE świec');
        return CandleUsageResult.success(
          cost: PRICE_EXTENDED_HOROSCOPE,
          wasFree: false,
          message:
              'Wydano $PRICE_EXTENDED_HOROSCOPE świec na rozbudowany horoskop',
        );
      } else {
        return CandleUsageResult.failure('Błąd podczas wydawania świec');
      }
    } catch (e) {
      Logger.error('Błąd używania rozbudowanego horoskopu: $e');
      return CandleUsageResult.failure('Wystąpił błąd: $e');
    }
  }

  /// 🖐️ Użyj skanu dłoni - TYLKO PŁATNY
  Future<CandleUsageResult> usePalmReading() async {
    await initialize();

    try {
      // Sprawdź czy ma wystarczająco świec (bez wyświetlania dialogu)
      if (!canAfford(PRICE_PALM_READING)) {
        // Usunięto HapticService.triggerError() - będzie obsłużone przez UI
        return CandleUsageResult.failure(
          'Potrzebujesz $PRICE_PALM_READING świec do skanu dłoni. Masz tylko $currentBalance.',
        );
      }

      // Wydaj świece
      final success = await _userService.spendCandles(
        PRICE_PALM_READING,
        'Skan dłoni',
        feature: 'palm_reading',
      );

      if (success) {
        await HapticService.triggerSuccess();
        Logger.info('Użyto skanu dłoni za $PRICE_PALM_READING świec');
        return CandleUsageResult.success(
          cost: PRICE_PALM_READING,
          wasFree: false,
          message: 'Wydano $PRICE_PALM_READING świec na skan dłoni',
        );
      } else {
        return CandleUsageResult.failure('Błąd podczas wydawania świec');
      }
    } catch (e) {
      Logger.error('Błąd używania skanu dłoni: $e');
      return CandleUsageResult.failure('Wystąpił błąd: $e');
    }
  }

  /// 📅 Użyj horoskopu tygodniowego - TYLKO PŁATNY
  Future<CandleUsageResult> useWeeklyHoroscope() async {
    await initialize();

    try {
      if (!canAfford(PRICE_WEEKLY_HOROSCOPE)) {
        // Usunięto HapticService.triggerError() - będzie obsłużone przez UI
        return CandleUsageResult.failure(
          'Potrzebujesz $PRICE_WEEKLY_HOROSCOPE świec do horoskopu tygodniowego. Masz tylko $currentBalance.',
        );
      }

      final success = await _userService.spendCandles(
        PRICE_WEEKLY_HOROSCOPE,
        'Horoskop tygodniowy',
        feature: 'weekly_horoscope',
      );

      if (success) {
        await HapticService.triggerSuccess();
        Logger.info(
            'Użyto horoskopu tygodniowego za $PRICE_WEEKLY_HOROSCOPE świec');
        return CandleUsageResult.success(
          cost: PRICE_WEEKLY_HOROSCOPE,
          wasFree: false,
          message:
              'Wydano $PRICE_WEEKLY_HOROSCOPE świec na horoskop tygodniowy',
        );
      } else {
        return CandleUsageResult.failure('Błąd podczas wydawania świec');
      }
    } catch (e) {
      Logger.error('Błąd używania horoskopu tygodniowego: $e');
      return CandleUsageResult.failure('Wystąpił błąd: $e');
    }
  }

  /// 🎁 METODY DODAWANIA ŚWIEC

  /// Nagroda za udostępnienie wyniku
  Future<bool> rewardForSharing(String contentType) async {
    await initialize();

    return await _userService.addCandles(
      REWARD_SHARE_RESULT,
      'Udostępnienie $contentType',
      feature: 'share_reward',
    );
  }

  /// Nagroda za polecenie znajomego
  Future<bool> rewardForReferral() async {
    await initialize();

    return await _userService.addCandles(
      REWARD_REFERRAL_SUCCESS,
      'Polecenie znajomego',
      feature: 'referral_reward',
    );
  }

  /// Dodaj niestandardową nagrodę
  Future<bool> addCustomReward(int amount, String reason,
      {String? feature}) async {
    await initialize();

    if (amount <= 0) return false;

    return await _userService.addCandles(amount, reason, feature: feature);
  }

  /// 📊 STATYSTYKI

  /// Pobierz historię transakcji
  Future<List<CandleTransaction>> getTransactionHistory(
      {int limit = 20}) async {
    await initialize();

    try {
      final userId = _userService.userId;
      if (userId == null) return [];

      final querySnapshot = await _firestore
          .collection('candle_transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => CandleTransaction.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      Logger.error('Błąd pobierania historii transakcji: $e');
      return [];
    }
  }

  /// Pobierz statystyki świec
  Future<CandleStats> getStats() async {
    await initialize();

    try {
      final transactions = await getTransactionHistory(limit: 100);
      final stats = CandleTransactionStats(transactions);

      return CandleStats(
        currentBalance: currentBalance,
        totalEarned: stats.totalEarned,
        totalSpent: stats.totalSpent,
        todayEarned: stats.todayEarned,
        todaySpent: stats.todaySpent,
        thisWeekEarned: stats.thisWeekEarned,
        thisWeekSpent: stats.thisWeekSpent,
        thisMonthEarned: stats.thisMonthEarned,
        thisMonthSpent: stats.thisMonthSpent,
        dailyStreak: _userService.dailyLoginStreak,
      );
    } catch (e) {
      Logger.error('Błąd pobierania statystyk: $e');
      return CandleStats.empty();
    }
  }

  /// Informacje o cenach
  Map<String, int> get prices => {
        'extended_horoscope': PRICE_EXTENDED_HOROSCOPE,
        'palm_reading': PRICE_PALM_READING,
        'weekly_horoscope': PRICE_WEEKLY_HOROSCOPE,
      };

  /// Informacje o nagrodach
  Map<String, int> get rewards => {
        'daily_login': REWARD_DAILY_LOGIN,
        'share_result': REWARD_SHARE_RESULT,
        'referral_success': REWARD_REFERRAL_SUCCESS,
        'streak_bonus': REWARD_STREAK_BONUS,
      };

  /// 🛒 METODY POMOCNICZE DLA UI

  /// Pobierz informacje o funkcji
  FeatureInfo getFeatureInfo(String featureKey) {
    switch (featureKey) {
      case 'extended_horoscope':
        return FeatureInfo(
          name: 'Rozbudowany horoskop',
          icon: '🔮',
          cost: PRICE_EXTENDED_HOROSCOPE,
          description:
              'Szczegółowa analiza wszystkich sfer Twojego życia na dziś',
        );
      case 'palm_reading':
        return FeatureInfo(
          name: 'Skanowanie Dłoni',
          icon: '�',
          cost: PRICE_PALM_READING,
          description:
              'Odkryj sekrety ukryte w liniach Twojej dłoni. Analiza linii życia, miłości i szczęścia.',
        );
      case 'weekly_horoscope':
        return FeatureInfo(
          name: 'Horoskop tygodniowy',
          icon: '📅',
          cost: PRICE_WEEKLY_HOROSCOPE,
          description: 'Przewidywania na cały nadchodzący tydzień',
        );
      default:
        return FeatureInfo(
          name: 'Nieznana funkcja',
          icon: '❓',
          cost: 0,
          description: 'Opis niedostępny',
        );
    }
  }

  /// 🎨 UNIWERSALNA METODA PŁATNOŚCI + UI
  static Future<bool> showPaymentDialog(
      BuildContext context, String featureKey) async {
    final service = CandleManagerService();
    await service.initialize();

    final featureInfo = service.getFeatureInfo(featureKey);

    final confirmed = await CandlePaymentHelper.showPaymentConfirmation(
      context: context,
      featureName: featureInfo.name,
      featureIcon: featureInfo.icon,
      candleCost: featureInfo.cost,
      featureDescription: featureInfo.description,
      currentBalance: service.currentBalance,
      accentColor: AppColors.cyan,
    );

    if (confirmed) {
      late CandleUsageResult result;
      switch (featureKey) {
        case 'extended_horoscope':
          result = await service.useExtendedHoroscope();
          break;
        case 'palm_reading':
          result = await service.usePalmReading();
          break;
        case 'weekly_horoscope':
          result = await service.useWeeklyHoroscope();
          break;
        default:
          return false;
      }
      return result.success;
    }
    return false;
  }

  /// 🔄 Zwróć świece w przypadku błędu po płatności
  Future<bool> refundCandles(int amount, String reason) async {
    await initialize();

    try {
      final success = await _userService.addCandles(
        amount,
        'Zwrot: $reason',
        feature: 'refund',
      );

      if (success) {
        await HapticService.triggerSuccess();
        Logger.info('Zwrócono $amount świec: $reason');
        return true;
      } else {
        Logger.error('Nie udało się zwrócić $amount świec: $reason');
        return false;
      }
    } catch (e) {
      Logger.error('Błąd zwrotu świec: $e');
      return false;
    }
  }

  /// 🔄 Specjalny zwrot dla skanu dłoni
  Future<bool> refundPalmReading(String reason) async {
    return refundCandles(PRICE_PALM_READING, 'Skan dłoni - $reason');
  }
}

/// 📊 Model wyniku użycia świec
class CandleUsageResult {
  final bool success;
  final int cost;
  final bool wasFree;
  final String message;

  const CandleUsageResult._({
    required this.success,
    required this.cost,
    required this.wasFree,
    required this.message,
  });

  factory CandleUsageResult.success({
    required int cost,
    required bool wasFree,
    required String message,
  }) {
    return CandleUsageResult._(
      success: true,
      cost: cost,
      wasFree: wasFree,
      message: message,
    );
  }

  factory CandleUsageResult.failure(String message) {
    return CandleUsageResult._(
      success: false,
      cost: 0,
      wasFree: false,
      message: message,
    );
  }
}

/// 📈 Model statystyk świec - ZAKTUALIZOWANY
class CandleStats {
  final int currentBalance;
  final int totalEarned;
  final int totalSpent;
  final int todayEarned;
  final int todaySpent;
  final int thisWeekEarned;
  final int thisWeekSpent;
  final int thisMonthEarned;
  final int thisMonthSpent;
  final int dailyStreak;

  const CandleStats({
    required this.currentBalance,
    required this.totalEarned,
    required this.totalSpent,
    required this.todayEarned,
    required this.todaySpent,
    required this.thisWeekEarned,
    required this.thisWeekSpent,
    required this.thisMonthEarned,
    required this.thisMonthSpent,
    required this.dailyStreak,
  });

  factory CandleStats.empty() {
    return const CandleStats(
      currentBalance: 0,
      totalEarned: 0,
      totalSpent: 0,
      todayEarned: 0,
      todaySpent: 0,
      thisWeekEarned: 0,
      thisWeekSpent: 0,
      thisMonthEarned: 0,
      thisMonthSpent: 0,
      dailyStreak: 0,
    );
  }

  int get netBalance => totalEarned - totalSpent;
  int get todayNet => todayEarned - todaySpent;
  int get thisWeekNet => thisWeekEarned - thisWeekSpent;
  int get thisMonthNet => thisMonthEarned - thisMonthSpent;

  bool get isActiveUser => dailyStreak > 0;
  bool get hasLongStreak => dailyStreak >= 7;

  double get spendingRate => totalEarned > 0 ? (totalSpent / totalEarned) : 0.0;
}

/// 🎯 Model informacji o funkcji
class FeatureInfo {
  final String name;
  final String icon;
  final int cost;
  final String description;

  const FeatureInfo({
    required this.name,
    required this.icon,
    required this.cost,
    required this.description,
  });
}
