// lib/models/horoscope_data.dart
// 🔮 MODEL DANYCH HOROSKOPU
// ✅ Zgodny z wytycznymi: Clean Code, Single Responsibility

import 'package:flutter/material.dart';

class HoroscopeData {
  final String? zodiacSign;
  final String? text;
  final DateTime? date;
  final String? moonPhase;
  final String? moonEmoji;
  final int? luckyNumber;
  final String? luckyColor;
  final bool isFromAI;
  final DateTime? createdAt;
  final double? confidence;

  HoroscopeData({
    this.zodiacSign,
    this.text,
    this.date,
    this.moonPhase,
    this.moonEmoji,
    this.luckyNumber,
    this.luckyColor,
    this.isFromAI = false,
    this.createdAt,
    this.confidence,
  });

  // 🔥 KONSTRUKTOR Z DANYCH FIRESTORE
  factory HoroscopeData.fromFirestore(Map<String, dynamic> data, String dateStr) {
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(dateStr);
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return HoroscopeData(
      text: data['text'] ?? 'Brak horoskopu na dziś',
      date: data['date'] != null ? parseDateTime(data['date']) : parsedDate,
      zodiacSign: data['zodiacSign'] ?? 'Nieznany',
      moonPhase: data['moonPhase'] ?? 'Nieznana',
      moonEmoji: data['moonEmoji'] ?? '🌙',
      luckyNumber: data['luckyNumber'],
      luckyColor: data['luckyColor'],
      isFromAI: data['isFromAI'] ?? false,
      createdAt: data['createdAt'] != null ? parseDateTime(data['createdAt']) : DateTime.now(),
      confidence: data['confidence']?.toDouble(),
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
      'isFromAI': isFromAI,
      'createdAt': createdAt?.toIso8601String(),
      'confidence': confidence,
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
    if (date == null) return 'brak daty';
    
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

    return '${date!.day} ${months[date!.month - 1]} ${date!.year}';
  }

  /// 🌙 Emoji fazy księżyca
  String get moonPhaseEmoji {
    const emojis = {
      'Nów Księżyca': '🌑',
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
    DateTime? date,
    String? moonPhase,
    String? moonEmoji,
    int? luckyNumber,
    String? luckyColor,
    bool? isFromAI,
    DateTime? createdAt,
    double? confidence,
  }) {
    return HoroscopeData(
      zodiacSign: zodiacSign ?? this.zodiacSign,
      text: text ?? this.text,
      date: date ?? this.date,
      moonPhase: moonPhase ?? this.moonPhase,
      moonEmoji: moonEmoji ?? this.moonEmoji,
      luckyNumber: luckyNumber ?? this.luckyNumber,
      luckyColor: luckyColor ?? this.luckyColor,
      isFromAI: isFromAI ?? this.isFromAI,
      createdAt: createdAt ?? this.createdAt,
      confidence: confidence ?? this.confidence,
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