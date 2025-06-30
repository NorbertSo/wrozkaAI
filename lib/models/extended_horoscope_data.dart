// lib/models/extended_horoscope_data.dart
// 🔮 PROSTY MODEL DANYCH HOROSKOPU ROZBUDOWANEGO
// Kompatybilny z istniejącą strukturą projektu

class ExtendedHoroscopeData {
  final String careerPrediction;
  final String lovePrediction;
  final String financePrediction;
  final String healthPrediction;
  final String personalGrowthPrediction;
  final String familyPrediction;
  final String moonPhase;
  final String? moonEmoji;
  final String recommendedCandle;
  final String? candleReason;
  final DateTime generatedAt;
  final String zodiacSign;

  const ExtendedHoroscopeData({
    required this.careerPrediction,
    required this.lovePrediction,
    required this.financePrediction,
    required this.healthPrediction,
    required this.personalGrowthPrediction,
    required this.familyPrediction,
    required this.moonPhase,
    this.moonEmoji,
    required this.recommendedCandle,
    this.candleReason,
    required this.generatedAt,
    required this.zodiacSign,
  });

  factory ExtendedHoroscopeData.fromMap(Map<String, dynamic> data) {
    return ExtendedHoroscopeData(
      careerPrediction: data['careerPrediction'] ?? '',
      lovePrediction: data['lovePrediction'] ?? '',
      financePrediction: data['financePrediction'] ?? '',
      healthPrediction: data['healthPrediction'] ?? '',
      personalGrowthPrediction: data['personalGrowthPrediction'] ?? '',
      familyPrediction: data['familyPrediction'] ?? '',
      moonPhase: data['moonPhase'] ?? 'Nów',
      moonEmoji: data['moonEmoji'],
      recommendedCandle: data['recommendedCandle'] ?? 'biała',
      candleReason: data['candleReason'],
      generatedAt: data['generatedAt']?.toDate() ?? DateTime.now(),
      zodiacSign: data['zodiacSign'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'careerPrediction': careerPrediction,
      'lovePrediction': lovePrediction,
      'financePrediction': financePrediction,
      'healthPrediction': healthPrediction,
      'personalGrowthPrediction': personalGrowthPrediction,
      'familyPrediction': familyPrediction,
      'moonPhase': moonPhase,
      'moonEmoji': moonEmoji,
      'recommendedCandle': recommendedCandle,
      'candleReason': candleReason,
      'generatedAt': generatedAt,
      'zodiacSign': zodiacSign,
    };
  }
}
