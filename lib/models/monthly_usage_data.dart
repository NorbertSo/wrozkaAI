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
