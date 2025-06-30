// ==========================================
// lib/models/candle_data.dart
// 🕯️ MODEL DANYCH ŚWIEC
// ==========================================

class CandleData {
  final int totalCandles;
  final int earnedToday;
  final int earnedThisWeek;
  final int earnedThisMonth;
  final int spentThisMonth;
  final DateTime lastUpdated;
  final List<CandleTransaction> recentTransactions;

  const CandleData({
    required this.totalCandles,
    this.earnedToday = 0,
    this.earnedThisWeek = 0,
    this.earnedThisMonth = 0,
    this.spentThisMonth = 0,
    required this.lastUpdated,
    this.recentTransactions = const [],
  });

  factory CandleData.fromFirestore(Map<String, dynamic> data) {
    return CandleData(
      totalCandles: data['totalCandles'] ?? 0,
      earnedToday: data['earnedToday'] ?? 0,
      earnedThisWeek: data['earnedThisWeek'] ?? 0,
      earnedThisMonth: data['earnedThisMonth'] ?? 0,
      spentThisMonth: data['spentThisMonth'] ?? 0,
      lastUpdated: data['lastUpdated']?.toDate() ?? DateTime.now(),
      recentTransactions: (data['recentTransactions'] as List<dynamic>?)
              ?.map((e) => CandleTransaction.fromFirestore(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalCandles': totalCandles,
      'earnedToday': earnedToday,
      'earnedThisWeek': earnedThisWeek,
      'earnedThisMonth': earnedThisMonth,
      'spentThisMonth': spentThisMonth,
      'lastUpdated': lastUpdated,
      'recentTransactions':
          recentTransactions.map((e) => e.toFirestore()).toList(),
    };
  }
}

class CandleTransaction {
  final String type; // 'earned', 'spent'
  final int amount;
  final String reason;
  final DateTime timestamp;
  final String?
      relatedFeature; // 'daily_horoscope', 'extended_horoscope', 'palm_reading'

  const CandleTransaction({
    required this.type,
    required this.amount,
    required this.reason,
    required this.timestamp,
    this.relatedFeature,
  });

  factory CandleTransaction.fromFirestore(Map<String, dynamic> data) {
    return CandleTransaction(
      type: data['type'] ?? '',
      amount: data['amount'] ?? 0,
      reason: data['reason'] ?? '',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      relatedFeature: data['relatedFeature'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'amount': amount,
      'reason': reason,
      'timestamp': timestamp,
      'relatedFeature': relatedFeature,
    };
  }
}

// ==========================================
// lib/models/subscription_status.dart
// 💳 MODEL STATUSU SUBSKRYPCJI
// ==========================================

class SubscriptionStatus {
  final bool isActive;
  final String? planType; // 'basic', 'premium', 'vip'
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? nextBillingDate;
  final String? provider; // 'apple', 'google', 'stripe'
  final bool isTrialPeriod;
  final int daysRemaining;
  final List<String> features;

  const SubscriptionStatus({
    this.isActive = false,
    this.planType,
    this.startDate,
    this.endDate,
    this.nextBillingDate,
    this.provider,
    this.isTrialPeriod = false,
    this.daysRemaining = 0,
    this.features = const [],
  });

  factory SubscriptionStatus.fromFirestore(Map<String, dynamic> data) {
    return SubscriptionStatus(
      isActive: data['isActive'] ?? false,
      planType: data['planType'],
      startDate: data['startDate']?.toDate(),
      endDate: data['endDate']?.toDate(),
      nextBillingDate: data['nextBillingDate']?.toDate(),
      provider: data['provider'],
      isTrialPeriod: data['isTrialPeriod'] ?? false,
      daysRemaining: data['daysRemaining'] ?? 0,
      features: List<String>.from(data['features'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isActive': isActive,
      'planType': planType,
      'startDate': startDate,
      'endDate': endDate,
      'nextBillingDate': nextBillingDate,
      'provider': provider,
      'isTrialPeriod': isTrialPeriod,
      'daysRemaining': daysRemaining,
      'features': features,
    };
  }

  bool hasFeature(String feature) {
    return features.contains(feature);
  }

  bool get isPremium => planType == 'premium' || planType == 'vip';
  bool get isVip => planType == 'vip';
}

// ==========================================
// lib/models/monthly_usage_data.dart
// 📊 MODEL MIESIĘCZNEGO UŻYCIA
// ==========================================

class MonthlyUsageData {
  final String userId;
  final int year;
  final int month;
  final bool usedFreeExtendedHoroscope;
  final int extendedHoroscopesUsed;
  final int candlesSpent;
  final int candlesEarned;
  final DateTime lastUpdated;
  final Map<String, int> featureUsage;

  const MonthlyUsageData({
    required this.userId,
    required this.year,
    required this.month,
    this.usedFreeExtendedHoroscope = false,
    this.extendedHoroscopesUsed = 0,
    this.candlesSpent = 0,
    this.candlesEarned = 0,
    required this.lastUpdated,
    this.featureUsage = const {},
  });

  factory MonthlyUsageData.fromFirestore(Map<String, dynamic> data) {
    return MonthlyUsageData(
      userId: data['userId'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      month: data['month'] ?? DateTime.now().month,
      usedFreeExtendedHoroscope: data['usedFreeExtendedHoroscope'] ?? false,
      extendedHoroscopesUsed: data['extendedHoroscopesUsed'] ?? 0,
      candlesSpent: data['candlesSpent'] ?? 0,
      candlesEarned: data['candlesEarned'] ?? 0,
      lastUpdated: data['lastUpdated']?.toDate() ?? DateTime.now(),
      featureUsage: Map<String, int>.from(data['featureUsage'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'year': year,
      'month': month,
      'usedFreeExtendedHoroscope': usedFreeExtendedHoroscope,
      'extendedHoroscopesUsed': extendedHoroscopesUsed,
      'candlesSpent': candlesSpent,
      'candlesEarned': candlesEarned,
      'lastUpdated': lastUpdated,
      'featureUsage': featureUsage,
    };
  }

  String get monthKey => '${year}_${month.toString().padLeft(2, '0')}';

  MonthlyUsageData copyWith({
    bool? usedFreeExtendedHoroscope,
    int? extendedHoroscopesUsed,
    int? candlesSpent,
    int? candlesEarned,
    Map<String, int>? featureUsage,
  }) {
    return MonthlyUsageData(
      userId: userId,
      year: year,
      month: month,
      usedFreeExtendedHoroscope:
          usedFreeExtendedHoroscope ?? this.usedFreeExtendedHoroscope,
      extendedHoroscopesUsed:
          extendedHoroscopesUsed ?? this.extendedHoroscopesUsed,
      candlesSpent: candlesSpent ?? this.candlesSpent,
      candlesEarned: candlesEarned ?? this.candlesEarned,
      lastUpdated: DateTime.now(),
      featureUsage: featureUsage ?? this.featureUsage,
    );
  }
}
