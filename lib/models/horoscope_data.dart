// lib/models/horoscope_data.dart
// 🔮 MODEL DANYCH HOROSKOPU - zgodny z Firebase Firestore
// Zgodny z wytycznymi projektu AI Wróżka - ZAKTUALIZOWANY

import 'package:cloud_firestore/cloud_firestore.dart';

class HoroscopeData {
  final String zodiacSign; // Znak zodiaku (aries, taurus, itp.) lub 'lunar'
  final String text; // Treść horoskopu
  final DateTime date; // Data horoskopu
  final String moonPhase; // Faza księżyca
  final String moonEmoji; // 🆕 Emoji księżyca
  final bool isFromAI; // Czy wygenerowany przez AI
  final DateTime createdAt; // Kiedy został utworzony
  final String? confidence; // Poziom pewności AI (opcjonalne)
  final String type; // 🆕 Typ horoskopu: daily, weekly, monthly
  final String generatedBy; // 🆕 Kto wygenerował: AI, fallback, etc.

  // 🆕 NOWE POLA dla horoskopów dziennych
  final String? lunarDescription; // Opis wpływu księżyca
  final String? recommendedCandle; // Rekomendowana świeca
  final String? recommendedCandleReason; // Powód rekomendacji świecy

  // 🗓️ POLA dla horoskopów tygodniowych
  final String? weekKey; // Klucz tygodnia (np. "2025-W26")
  final DateTime? weekStart; // Początek tygodnia
  final DateTime? weekEnd; // Koniec tygodnia

  // 📅 POLA dla horoskopów miesięcznych
  final String? monthKey; // Klucz miesiąca (np. "2025-06")
  final String? monthName; // Nazwa miesiąca
  final DateTime? monthStart; // Początek miesiąca
  final DateTime? monthEnd; // Koniec miesiąca

  const HoroscopeData({
    required this.zodiacSign,
    required this.text,
    required this.date,
    required this.moonPhase,
    required this.moonEmoji,
    required this.isFromAI,
    required this.createdAt,
    required this.type,
    required this.generatedBy,
    this.confidence,
    this.lunarDescription,
    this.recommendedCandle,
    this.recommendedCandleReason,
    this.weekKey,
    this.weekStart,
    this.weekEnd,
    this.monthKey,
    this.monthName,
    this.monthStart,
    this.monthEnd,
  });

  /// 🔥 Tworzenie z dokumentu Firestore
  factory HoroscopeData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return HoroscopeData(
      zodiacSign: data['zodiacSign'] ?? doc.id,
      text: data['text'] ?? '',
      date: _parseDate(data['date']),
      moonPhase: data['moonPhase'] ?? 'Nieznana',
      moonEmoji: data['moonEmoji'] ?? '🌙',
      isFromAI: data['generatedBy'] != 'fallback',
      createdAt: _parseDateTime(data['createdAt']),
      type: data['type'] ?? 'daily',
      generatedBy: data['generatedBy'] ?? 'unknown',
      confidence: data['confidence'],
      lunarDescription: data['lunarDescription'],
      recommendedCandle: data['recommendedCandle'],
      recommendedCandleReason: data['recommendedCandleReason'],
      weekKey: data['weekKey'],
      weekStart: _parseDate(data['weekStart']),
      weekEnd: _parseDate(data['weekEnd']),
      monthKey: data['monthKey'],
      monthName: data['monthName'],
      monthStart: _parseDate(data['monthStart']),
      monthEnd: _parseDate(data['monthEnd']),
    );
  }

  /// 🔥 Konwersja do mapy dla Firestore
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'zodiacSign': zodiacSign,
      'text': text,
      'date':
          type == 'daily' ? _formatDateString(date) : Timestamp.fromDate(date),
      'moonPhase': moonPhase,
      'moonEmoji': moonEmoji,
      'isFromAI': isFromAI,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type,
      'generatedBy': generatedBy,
    };

    if (confidence != null) data['confidence'] = confidence;
    if (lunarDescription != null) data['lunarDescription'] = lunarDescription;
    if (recommendedCandle != null)
      data['recommendedCandle'] = recommendedCandle;
    if (recommendedCandleReason != null)
      data['recommendedCandleReason'] = recommendedCandleReason;

    if (weekKey != null) data['weekKey'] = weekKey;
    if (weekStart != null) data['weekStart'] = _formatDateString(weekStart!);
    if (weekEnd != null) data['weekEnd'] = _formatDateString(weekEnd!);

    if (monthKey != null) data['monthKey'] = monthKey;
    if (monthName != null) data['monthName'] = monthName;
    if (monthStart != null) data['monthStart'] = _formatDateString(monthStart!);
    if (monthEnd != null) data['monthEnd'] = _formatDateString(monthEnd!);

    return data;
  }

  /// 📅 Parsowanie daty z różnych formatów
  static DateTime _parseDate(dynamic dateData) {
    if (dateData == null) return DateTime.now();

    if (dateData is Timestamp) {
      return dateData.toDate();
    }

    if (dateData is String) {
      try {
        return DateTime.parse(dateData);
      } catch (e) {
        return DateTime.now();
      }
    }

    if (dateData is DateTime) {
      return dateData;
    }

    return DateTime.now();
  }

  /// ⏰ Parsowanie czasu utworzenia
  static DateTime _parseDateTime(dynamic dateTimeData) {
    if (dateTimeData == null) return DateTime.now();

    if (dateTimeData is Timestamp) {
      return dateTimeData.toDate();
    }

    if (dateTimeData is String) {
      try {
        return DateTime.parse(dateTimeData);
      } catch (e) {
        return DateTime.now();
      }
    }

    if (dateTimeData is DateTime) {
      return dateTimeData;
    }

    return DateTime.now();
  }

  /// 📝 Formatowanie daty do stringa
  static String _formatDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 🌟 Nazwa wyświetlana znaku zodiaku
  String get zodiacDisplayName {
    const names = {
      'aries': 'Baran',
      'taurus': 'Byk',
      'gemini': 'Bliźnięta',
      'cancer': 'Rak',
      'leo': 'Lew',
      'virgo': 'Panna',
      'libra': 'Waga',
      'scorpio': 'Skorpion',
      'sagittarius': 'Strzelec',
      'capricorn': 'Koziorożec',
      'aquarius': 'Wodnik',
      'pisces': 'Ryby',
      'lunar': 'Kalendarz Księżycowy',
    };

    return names[zodiacSign] ?? zodiacSign;
  }

  /// 🎨 Ikona znaku zodiaku
  String get zodiacIcon {
    const icons = {
      'aries': '♈',
      'taurus': '♉',
      'gemini': '♊',
      'cancer': '♋',
      'leo': '♌',
      'virgo': '♍',
      'libra': '♎',
      'scorpio': '♏',
      'sagittarius': '♐',
      'capricorn': '♑',
      'aquarius': '♒',
      'pisces': '♓',
      'lunar': '🌙',
    };

    return icons[zodiacSign] ?? '🌙';
  }

  /// 📄 Sformatowana data
  String get formattedDate {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// 🎯 Czy to horoskop dzienny
  bool get isDaily => type == 'daily';

  /// 📅 Czy to horoskop tygodniowy
  bool get isWeekly => type == 'weekly';

  /// 📆 Czy to horoskop miesięczny
  bool get isMonthly => type == 'monthly';

  /// 🕯️ Czy ma rekomendowaną świecę
  bool get hasRecommendedCandle =>
      recommendedCandle != null && recommendedCandle!.isNotEmpty;

  /// 🌙 Czy ma opis księżycowy
  bool get hasLunarDescription =>
      lunarDescription != null && lunarDescription!.isNotEmpty;

  /// 📄 Kopia z nowymi danymi
  HoroscopeData copyWith({
    String? zodiacSign,
    String? text,
    DateTime? date,
    String? moonPhase,
    String? moonEmoji,
    bool? isFromAI,
    DateTime? createdAt,
    String? type,
    String? generatedBy,
    String? confidence,
    String? lunarDescription,
    String? recommendedCandle,
    String? recommendedCandleReason,
    String? weekKey,
    DateTime? weekStart,
    DateTime? weekEnd,
    String? monthKey,
    String? monthName,
    DateTime? monthStart,
    DateTime? monthEnd,
  }) {
    return HoroscopeData(
      zodiacSign: zodiacSign ?? this.zodiacSign,
      text: text ?? this.text,
      date: date ?? this.date,
      moonPhase: moonPhase ?? this.moonPhase,
      moonEmoji: moonEmoji ?? this.moonEmoji,
      isFromAI: isFromAI ?? this.isFromAI,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      generatedBy: generatedBy ?? this.generatedBy,
      confidence: confidence ?? this.confidence,
      lunarDescription: lunarDescription ?? this.lunarDescription,
      recommendedCandle: recommendedCandle ?? this.recommendedCandle,
      recommendedCandleReason:
          recommendedCandleReason ?? this.recommendedCandleReason,
      weekKey: weekKey ?? this.weekKey,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      monthKey: monthKey ?? this.monthKey,
      monthName: monthName ?? this.monthName,
      monthStart: monthStart ?? this.monthStart,
      monthEnd: monthEnd ?? this.monthEnd,
    );
  }

  /// 🔧 Debug String
  @override
  String toString() {
    return 'HoroscopeData(zodiacSign: $zodiacSign, date: $formattedDate, type: $type, moonPhase: $moonPhase, isFromAI: $isFromAI)';
  }

  /// ⚖️ Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HoroscopeData &&
        other.zodiacSign == zodiacSign &&
        other.type == type &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day;
  }

  /// 🔢 Hash code
  @override
  int get hashCode {
    return zodiacSign.hashCode ^
        type.hashCode ^
        date.year.hashCode ^
        date.month.hashCode ^
        date.day.hashCode;
  }
}
