// lib/models/horoscope_data.dart
// 🔮 MODEL DANYCH HOROSKOPU
// ✅ Zgodny z wytycznymi: Clean Code, Single Responsibility

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HoroscopeData {
  final String? zodiacSign;
  final String? text;
  final String? moonPhase;
  final String? moonEmoji;
  final String? lunarDescription;
  final String? recommendedCandle;
  final String? recommendedCandleReason;
  final int? luckyNumber;
  final String? luckyColor;
  final DateTime? date;
  final bool? isFromAI; // ✅ PARAMETR DODANY
  final DateTime? createdAt; // ✅ PARAMETR DODANY

  const HoroscopeData({
    this.zodiacSign,
    this.text,
    this.moonPhase,
    this.moonEmoji,
    this.lunarDescription,
    this.recommendedCandle,
    this.recommendedCandleReason,
    this.luckyNumber,
    this.luckyColor,
    this.date,
    this.isFromAI, // ✅ W KONSTRUKTORZE
    this.createdAt, // ✅ W KONSTRUKTORZE
  });

  // 🔥 KONSTRUKTOR Z DANYCH FIRESTORE
  factory HoroscopeData.fromFirestore(Map<String, dynamic> data) {
    return HoroscopeData(
      zodiacSign: data['zodiacSign'] ?? '',
      text: data['text'] ?? '',
      date: data['date'] != null
          ? (data['date'] is Timestamp
              ? (data['date'] as Timestamp).toDate()
              : DateTime.parse(data['date'].toString()))
          : DateTime.now(),
      moonPhase: data['moonPhase'] ?? '',
      moonEmoji: data['moonEmoji'],
      lunarDescription: data['lunarDescription'],
      recommendedCandle: data['recommendedCandle'],
      recommendedCandleReason: data['recommendedCandleReason'],
      luckyNumber: data['luckyNumber']?.toInt(),
      luckyColor: data['luckyColor'],
      isFromAI: data['isFromAI'] ?? false, // ✅ OBSŁUGA FIRESTORE
      createdAt: data['createdAt'] != null // ✅ OBSŁUGA FIRESTORE
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
    );
  }

  // 📋 KONWERSJA DO MAPY
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'date': date?.toIso8601String(),
      'zodiacSign': zodiacSign,
      'moonPhase': moonPhase,
      'moonEmoji': moonEmoji,
      'luckyNumber': luckyNumber,
      'luckyColor': luckyColor,
      'lunarDescription': lunarDescription,
      'recommendedCandle': recommendedCandle,
      'recommendedCandleReason': recommendedCandleReason,
      'isFromAI': isFromAI, // ✅ W MAPIE
      'createdAt': createdAt?.toIso8601String(), // ✅ W MAPIE
    };
  }

  /// ⏰ Parsowanie czasu utworzenia
  static DateTime parseDateTime(dynamic dateTimeData) {
    if (dateTimeData == null) return DateTime.now();

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

    if (dateTimeData is Timestamp) {
      return dateTimeData.toDate();
    }

    return DateTime.now();
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

    return names[zodiacSign] ?? (zodiacSign ?? 'Nieznany');
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

    return icons[zodiacSign] ?? '⭐';
  }

  /// 🌈 Kolor znaku zodiaku
  String get zodiacColorHex {
    const colors = {
      'aries': '#FF6B6B', // Czerwony
      'taurus': '#4ECDC4', // Turkusowy
      'gemini': '#45B7D1', // Niebieski
      'cancer': '#96CEB4', // Zielony
      'leo': '#FFEAA7', // Żółty
      'virgo': '#DDA0DD', // Fioletowy
      'libra': '#FFB6C1', // Różowy
      'scorpio': '#8B4513', // Brązowy
      'sagittarius': '#9370DB', // Fioletowy
      'capricorn': '#2F4F4F', // Ciemnoszary
      'aquarius': '#00CED1', // Ciemny turkus
      'pisces': '#87CEEB', // Błękit nieba
      'lunar': '#E6E6FA', // Lawendowy
    };

    return colors[zodiacSign] ?? '#FFFFFF';
  }

  /// 📊 Czy horoskop jest świeży (z dzisiaj)
  bool get isFresh {
    if (date == null) return false;
    final now = DateTime.now();
    return date?.year == now.year &&
        date?.month == now.month &&
        date?.day == now.day;
  }

  /// ⏱️ Czy horoskop jest aktualny (nie starszy niż 24h)
  bool get isCurrent {
    if (date == null) return false;
    final now = DateTime.now();
    final difference = now.difference(date!);
    return difference.inHours < 24;
  }

  /// 🎯 Status horoskopu
  String get status {
    if (isFresh) return 'Dzisiejszy';
    if (isCurrent) return 'Aktualny';
    return 'Archiwalny';
  }

  /// 📝 Sformatowana data
  String get formattedDate {
    if (date == null) return 'Brak daty';

    final months = [
      'stycznia',
      'lutego',
      'marca',
      'kwietnia',
      'maja',
      'czerwca',
      'lipca',
      'sierpnia',
      'września',
      'października',
      'listopada',
      'grudnia'
    ];

    return '${date?.day} ${months[date!.month - 1]} ${date?.year}';
  }

  /// 🌙 Emoji fazy księżyca
  String get moonPhaseEmoji {
    const emojis = {
      'Nów': '🌑',
      'Przybywający sierp': '🌒',
      'Pierwsza kwadra': '🌓',
      'Przybywający garb': '🌔',
      'Pełnia': '🌕',
      'Ubywający garb': '🌖',
      'Ostatnia kwadra': '🌗',
      'Ubywający sierp': '🌘',
    };

    return emojis[moonPhase] ?? '🌙';
  }

  /// 📄 Kopia z nowymi danymi
  HoroscopeData copyWith({
    String? zodiacSign,
    String? text,
    String? moonPhase,
    String? moonEmoji,
    String? lunarDescription,
    String? recommendedCandle,
    String? recommendedCandleReason,
    int? luckyNumber,
    String? luckyColor,
    DateTime? date,
    bool? isFromAI, // ✅ W copyWith
    DateTime? createdAt, // ✅ W copyWith
  }) {
    return HoroscopeData(
      zodiacSign: zodiacSign ?? this.zodiacSign,
      text: text ?? this.text,
      moonPhase: moonPhase ?? this.moonPhase,
      moonEmoji: moonEmoji ?? this.moonEmoji,
      lunarDescription: lunarDescription ?? this.lunarDescription,
      recommendedCandle: recommendedCandle ?? this.recommendedCandle,
      recommendedCandleReason:
          recommendedCandleReason ?? this.recommendedCandleReason,
      luckyNumber: luckyNumber ?? this.luckyNumber,
      luckyColor: luckyColor ?? this.luckyColor,
      date: date ?? this.date,
      isFromAI: isFromAI ?? this.isFromAI, // ✅ W copyWith
      createdAt: createdAt ?? this.createdAt, // ✅ W copyWith
    );
  }

  /// ⚖️ Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HoroscopeData &&
        other.zodiacSign == zodiacSign &&
        other.date?.year == date?.year &&
        other.date?.month == date?.month &&
        other.date?.day == date?.day;
  }

  /// 🔢 Hash code
  @override
  int get hashCode =>
      (zodiacSign?.hashCode ?? 0) ^
      (date?.year.hashCode ?? 0) ^
      (date?.month.hashCode ?? 0) ^
      (date?.day.hashCode ?? 0);

  @override
  String toString() {
    return 'HoroscopeData(zodiacSign: $zodiacSign, date: $formattedDate, moonPhase: $moonPhase, isFromAI: $isFromAI)';
  }
}
