// lib/models/candle_transaction.dart
// 🕯️ MODEL TRANSAKCJI ŚWIEC
// Zgodny z wytycznymi projektu AI Wróżka

import '../utils/logger.dart';

enum CandleTransactionType {
  earned, // Zdobyte świece
  spent, // Wydane świece
}

enum CandleEarnReason {
  dailyLogin, // Codzienna nagroda za logowanie
  shareResult, // Udostępnienie wyniku wróżby
  referralSuccess, // Polecenie znajomego
  streakBonus, // Bonus za serię logowań
  welcomeBonus, // Bonus powitalny
  other, // Inne przyczyny
}

enum CandleSpendReason {
  extendedHoroscope, // Rozbudowany horoskop
  palmReading, // Skan dłoni
  weeklyHoroscope, // Horoskop tygodniowy
  other, // Inne wydatki
}

class CandleTransaction {
  final String id; // Unikalny ID transakcji
  final String userId; // ID użytkownika
  final CandleTransactionType type; // Typ: earned/spent
  final int amount; // Liczba świec
  final String reason; // Opis przyczyny
  final String? feature; // Funkcja związana z transakcją
  final DateTime timestamp; // Kiedy nastąpiła transakcja
  final Map<String, dynamic> metadata; // Dodatkowe dane

  const CandleTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.reason,
    this.feature,
    required this.timestamp,
    this.metadata = const {},
  });

  /// Stwórz transakcję zarobienia świec
  factory CandleTransaction.earned({
    required String userId,
    required int amount,
    required CandleEarnReason reason,
    String? feature,
    Map<String, dynamic>? metadata,
  }) {
    return CandleTransaction(
      id: _generateId(),
      userId: userId,
      type: CandleTransactionType.earned,
      amount: amount,
      reason: _earnReasonToString(reason),
      feature: feature,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  /// Stwórz transakcję wydania świec
  factory CandleTransaction.spent({
    required String userId,
    required int amount,
    required CandleSpendReason reason,
    String? feature,
    Map<String, dynamic>? metadata,
  }) {
    return CandleTransaction(
      id: _generateId(),
      userId: userId,
      type: CandleTransactionType.spent,
      amount: amount,
      reason: _spendReasonToString(reason),
      feature: feature,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  /// Wczytaj z Firestore
  factory CandleTransaction.fromFirestore(Map<String, dynamic> data) {
    try {
      return CandleTransaction(
        id: data['id'] ?? '',
        userId: data['userId'] ?? '',
        type: CandleTransactionType.values.firstWhere(
          (type) => type.name == data['type'],
          orElse: () => CandleTransactionType.earned,
        ),
        amount: data['amount'] ?? 0,
        reason: data['reason'] ?? '',
        feature: data['feature'],
        timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      );
    } catch (e) {
      Logger.error('Błąd parsowania CandleTransaction: $e');
      rethrow;
    }
  }

  /// Zapisz do Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'reason': reason,
      'feature': feature,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }

  /// Pomocnicze metody dla reason
  static String _earnReasonToString(CandleEarnReason reason) {
    switch (reason) {
      case CandleEarnReason.dailyLogin:
        return 'Codzienna nagroda';
      case CandleEarnReason.shareResult:
        return 'Udostępnienie wyniku';
      case CandleEarnReason.referralSuccess:
        return 'Polecenie znajomego';
      case CandleEarnReason.streakBonus:
        return 'Bonus za regularność';
      case CandleEarnReason.welcomeBonus:
        return 'Bonus powitalny';
      case CandleEarnReason.other:
        return 'Inna nagroda';
    }
  }

  static String _spendReasonToString(CandleSpendReason reason) {
    switch (reason) {
      case CandleSpendReason.extendedHoroscope:
        return 'Rozbudowany horoskop';
      case CandleSpendReason.palmReading:
        return 'Skan dłoni';
      case CandleSpendReason.weeklyHoroscope:
        return 'Horoskop tygodniowy';
      case CandleSpendReason.other:
        return 'Inna funkcja';
    }
  }

  /// Generuj unikalny ID
  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'ct_${timestamp}_$random';
  }

  /// Gettery dla wygody
  bool get isEarned => type == CandleTransactionType.earned;
  bool get isSpent => type == CandleTransactionType.spent;
  bool get isToday => _isToday(timestamp);
  bool get isThisWeek => _isThisWeek(timestamp);
  bool get isThisMonth => _isThisMonth(timestamp);

  /// Ikona dla UI
  String get icon {
    if (isEarned) {
      return '🕯️';
    } else {
      switch (feature) {
        case 'extended_horoscope':
          return '🔮';
        case 'palm_reading':
          return '🖐️';
        case 'weekly_horoscope':
          return '📅';
        default:
          return '💫';
      }
    }
  }

  /// Kolor dla UI
  String get colorHex {
    return isEarned
        ? '#4CAF50'
        : '#FF9800'; // Zielony dla zarobienia, pomarańczowy dla wydania
  }

  /// Opis dla UI
  String get displayText {
    final prefix = isEarned ? '+' : '-';
    return '$prefix$amount 🕯️ • $reason';
  }

  /// Pomocnicze metody dat
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
  }

  bool _isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  @override
  String toString() {
    return 'CandleTransaction('
        'type: ${type.name}, '
        'amount: $amount, '
        'reason: $reason, '
        'timestamp: ${timestamp.toString().substring(0, 16)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CandleTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Pomocnicza klasa do statystyk
class CandleTransactionStats {
  final List<CandleTransaction> transactions;

  const CandleTransactionStats(this.transactions);

  int get totalEarned =>
      transactions.where((t) => t.isEarned).fold(0, (sum, t) => sum + t.amount);

  int get totalSpent =>
      transactions.where((t) => t.isSpent).fold(0, (sum, t) => sum + t.amount);

  int get todayEarned => transactions
      .where((t) => t.isEarned && t.isToday)
      .fold(0, (sum, t) => sum + t.amount);

  int get todaySpent => transactions
      .where((t) => t.isSpent && t.isToday)
      .fold(0, (sum, t) => sum + t.amount);

  int get thisWeekEarned => transactions
      .where((t) => t.isEarned && t.isThisWeek)
      .fold(0, (sum, t) => sum + t.amount);

  int get thisWeekSpent => transactions
      .where((t) => t.isSpent && t.isThisWeek)
      .fold(0, (sum, t) => sum + t.amount);

  int get thisMonthEarned => transactions
      .where((t) => t.isEarned && t.isThisMonth)
      .fold(0, (sum, t) => sum + t.amount);

  int get thisMonthSpent => transactions
      .where((t) => t.isSpent && t.isThisMonth)
      .fold(0, (sum, t) => sum + t.amount);

  List<CandleTransaction> get recentTransactions =>
      transactions.take(10).toList();

  Map<String, int> get earnReasonBreakdown {
    final Map<String, int> breakdown = {};
    for (final transaction in transactions.where((t) => t.isEarned)) {
      breakdown[transaction.reason] =
          (breakdown[transaction.reason] ?? 0) + transaction.amount;
    }
    return breakdown;
  }

  Map<String, int> get spendFeatureBreakdown {
    final Map<String, int> breakdown = {};
    for (final transaction in transactions.where((t) => t.isSpent)) {
      final feature = transaction.feature ?? 'other';
      breakdown[feature] = (breakdown[feature] ?? 0) + transaction.amount;
    }
    return breakdown;
  }
}
