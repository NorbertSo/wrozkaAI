// lib/models/user_anonymous_profile.dart
// 👤 MODEL ANONIMOWEGO PROFILU UŻYTKOWNIKA
// Zgodny z wytycznymi projektu AI Wróżka - totalna anonimowość

import '../utils/logger.dart';

class UserAnonymousProfile {
  final String userId; // Firebase Anonymous UID
  final String deviceId; // Backup Device ID
  final DateTime createdAt; // Kiedy utworzono profil
  final DateTime lastSeen; // Ostatnia aktywność
  final int candleBalance; // Aktualne świece
  final int dailyLoginStreak; // Seria codziennych logowań
  final String referralCode; // Unikalny kod polecający
  final String? referredBy; // Przez kogo został polecony
  final Map<String, bool> monthlyFreeUsage; // Miesięczne darmowe użycia

  const UserAnonymousProfile({
    required this.userId,
    required this.deviceId,
    required this.createdAt,
    required this.lastSeen,
    this.candleBalance = 30, // 30 świec startowych
    this.dailyLoginStreak = 1,
    required this.referralCode,
    this.referredBy,
    this.monthlyFreeUsage = const {},
  });

  /// Stwórz nowy profil z domyślnymi wartościami
  factory UserAnonymousProfile.createNew({
    required String userId,
    required String deviceId,
    required String referralCode,
    String? referredBy,
  }) {
    final now = DateTime.now();

    return UserAnonymousProfile(
      userId: userId,
      deviceId: deviceId,
      createdAt: now,
      lastSeen: now,
      candleBalance: 30, // Bonus startowy
      dailyLoginStreak: 1,
      referralCode: referralCode,
      referredBy: referredBy,
      monthlyFreeUsage: _generateEmptyMonthlyUsage(now),
    );
  }

  /// Wczytaj z Firestore
  factory UserAnonymousProfile.fromFirestore(Map<String, dynamic> data) {
    try {
      return UserAnonymousProfile(
        userId: data['userId'] ?? '',
        deviceId: data['deviceId'] ?? '',
        createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
        lastSeen: data['lastSeen']?.toDate() ?? DateTime.now(),
        candleBalance: data['candleBalance'] ?? 0,
        dailyLoginStreak: data['dailyLoginStreak'] ?? 1,
        referralCode: data['referralCode'] ?? '',
        referredBy: data['referredBy'],
        monthlyFreeUsage: Map<String, bool>.from(
          data['monthlyFreeUsage'] ?? {},
        ),
      );
    } catch (e) {
      Logger.error('Błąd parsowania UserAnonymousProfile: $e');
      rethrow;
    }
  }

  /// Zapisz do Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'deviceId': deviceId,
      'createdAt': createdAt,
      'lastSeen': lastSeen,
      'candleBalance': candleBalance,
      'dailyLoginStreak': dailyLoginStreak,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'monthlyFreeUsage': monthlyFreeUsage,
      'version': 1, // Wersjonowanie dla przyszłych migracji
    };
  }

  /// Sprawdź czy użytkownik użył darmowy skan dłoni w tym miesiącu
  bool hasUsedFreePalmReading() {
    final monthKey = _getCurrentMonthKey();
    return monthlyFreeUsage['palmReading_$monthKey'] ?? false;
  }

  /// Sprawdź czy użytkownik użył darmowy rozbudowany horoskop w tym miesiącu
  bool hasUsedFreeExtendedHoroscope() {
    final monthKey = _getCurrentMonthKey();
    return monthlyFreeUsage['extendedHoroscope_$monthKey'] ?? false;
  }

  /// Oznacz że użytkownik użył darmowy skan dłoni
  UserAnonymousProfile markFreePalmReadingUsed() {
    final monthKey = _getCurrentMonthKey();
    final newUsage = Map<String, bool>.from(monthlyFreeUsage);
    newUsage['palmReading_$monthKey'] = true;

    return copyWith(
      monthlyFreeUsage: newUsage,
      lastSeen: DateTime.now(),
    );
  }

  /// Oznacz że użytkownik użył darmowy rozbudowany horoskop
  UserAnonymousProfile markFreeExtendedHoroscopeUsed() {
    final monthKey = _getCurrentMonthKey();
    final newUsage = Map<String, bool>.from(monthlyFreeUsage);
    newUsage['extendedHoroscope_$monthKey'] = true;

    return copyWith(
      monthlyFreeUsage: newUsage,
      lastSeen: DateTime.now(),
    );
  }

  /// Dodaj świece do salda
  UserAnonymousProfile addCandles(int amount) {
    return copyWith(
      candleBalance: candleBalance + amount,
      lastSeen: DateTime.now(),
    );
  }

  /// Odejmij świece z salda
  UserAnonymousProfile spendCandles(int amount) {
    final newBalance = candleBalance - amount;
    if (newBalance < 0) {
      throw Exception('Niewystarczające saldo świec: $candleBalance < $amount');
    }

    return copyWith(
      candleBalance: newBalance,
      lastSeen: DateTime.now(),
    );
  }

  /// Sprawdź czy może wydać określoną liczbę świec
  bool canSpendCandles(int amount) {
    return candleBalance >= amount;
  }

  /// Zaktualizuj serię logowań
  UserAnonymousProfile updateLoginStreak() {
    final now = DateTime.now();
    final lastSeenDate = DateTime(lastSeen.year, lastSeen.month, lastSeen.day);
    final todayDate = DateTime(now.year, now.month, now.day);
    final daysDiff = todayDate.difference(lastSeenDate).inDays;

    int newStreak;
    if (daysDiff == 0) {
      // Ten sam dzień - nie zmieniaj streak
      newStreak = dailyLoginStreak;
    } else if (daysDiff == 1) {
      // Kolejny dzień - zwiększ streak
      newStreak = dailyLoginStreak + 1;
    } else {
      // Przerwa w logowaniu - resetuj streak
      newStreak = 1;
    }

    return copyWith(
      dailyLoginStreak: newStreak,
      lastSeen: now,
    );
  }

  /// Kopiuj z możliwością modyfikacji pól
  UserAnonymousProfile copyWith({
    String? userId,
    String? deviceId,
    DateTime? createdAt,
    DateTime? lastSeen,
    int? candleBalance,
    int? dailyLoginStreak,
    String? referralCode,
    String? referredBy,
    Map<String, bool>? monthlyFreeUsage,
  }) {
    return UserAnonymousProfile(
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      candleBalance: candleBalance ?? this.candleBalance,
      dailyLoginStreak: dailyLoginStreak ?? this.dailyLoginStreak,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      monthlyFreeUsage: monthlyFreeUsage ?? this.monthlyFreeUsage,
    );
  }

  /// Pomocnicze metody
  String _getCurrentMonthKey() {
    final now = DateTime.now();
    return '${now.year}_${now.month.toString().padLeft(2, '0')}';
  }

  static Map<String, bool> _generateEmptyMonthlyUsage(DateTime date) {
    final monthKey = '${date.year}_${date.month.toString().padLeft(2, '0')}';
    return {
      'palmReading_$monthKey': false,
      'extendedHoroscope_$monthKey': false,
    };
  }

  /// Gettery dla wygody
  bool get isNewUser => DateTime.now().difference(createdAt).inDays < 1;
  bool get hasLongStreak => dailyLoginStreak >= 7;
  int get daysActive => DateTime.now().difference(createdAt).inDays + 1;

  @override
  String toString() {
    return 'UserAnonymousProfile('
        'userId: ${userId.substring(0, 8)}..., '
        'candles: $candleBalance, '
        'streak: $dailyLoginStreak, '
        'daysActive: $daysActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserAnonymousProfile && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
