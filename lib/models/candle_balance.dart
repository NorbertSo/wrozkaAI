// ==========================================
// lib/models/candle_balance.dart
// 🕯️ PROSTY MODEL BALANSU ŚWIEC
// ==========================================

class CandleBalance {
  final int totalCandles;
  final DateTime lastUpdated;

  const CandleBalance({
    required this.totalCandles,
    required this.lastUpdated,
  });

  factory CandleBalance.fromMap(Map<String, dynamic> data) {
    return CandleBalance(
      totalCandles: data['totalCandles'] ?? 0,
      lastUpdated: data['lastUpdated']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalCandles': totalCandles,
      'lastUpdated': lastUpdated,
    };
  }

  CandleBalance copyWith({
    int? totalCandles,
    DateTime? lastUpdated,
  }) {
    return CandleBalance(
      totalCandles: totalCandles ?? this.totalCandles,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
