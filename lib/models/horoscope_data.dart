// lib/models/horoscope_data.dart
// 🔮 MODEL DANYCH HOROSKOPU - zgodny z Firebase Firestore
// Zgodny z wytycznymi projektu AI Wróżka

import 'package:cloud_firestore/cloud_firestore.dart';

class HoroscopeData {
  final String zodiacSign; // Znak zodiaku (aries, taurus, itp.) lub 'lunar'
  final String text; // Treść horoskopu
  final DateTime date; // Data horoskopu
  final String moonPhase; // Faza księżyca
  final bool isFromAI; // Czy wygenerowany przez AI
  final DateTime createdAt; // Kiedy został utworzony
  final String? confidence; // Poziom pewności AI (opcjonalne)

  const HoroscopeData({
    required this.zodiacSign,
    required this.text,
    required this.date,
    required this.moonPhase,
    required this.isFromAI,
    required this.createdAt,
    this.confidence,
  });

  /// 🔥 Tworzenie z dokumentu Firestore
  factory HoroscopeData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return HoroscopeData(
      zodiacSign: data['zodiacSign'] ?? doc.id,
      text: data['text'] ?? '',
      date: _parseDate(data['date']),
      moonPhase: data['moonPhase'] ?? 'Nieznana',
      isFromAI: data['isFromAI'] ?? false,
      createdAt: _parseDateTime(data['createdAt']),
      confidence: data['confidence'],
    );
  }

  /// 🔥 Konwersja do mapy dla Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'zodiacSign': zodiacSign,
      'text': text,
      'date': Timestamp.fromDate(date),
      'moonPhase': moonPhase,
      'isFromAI': isFromAI,
      'createdAt': Timestamp.fromDate(createdAt),
      if (confidence != null) 'confidence': confidence,
    };
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
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// ⏱️ Czy horoskop jest aktualny (nie starszy niż 24h)
  bool get isCurrent {
    final now = DateTime.now();
    final difference = now.difference(date);
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
    bool? isFromAI,
    DateTime? createdAt,
    String? confidence,
  }) {
    return HoroscopeData(
      zodiacSign: zodiacSign ?? this.zodiacSign,
      text: text ?? this.text,
      date: date ?? this.date,
      moonPhase: moonPhase ?? this.moonPhase,
      isFromAI: isFromAI ?? this.isFromAI,
      createdAt: createdAt ?? this.createdAt,
      confidence: confidence ?? this.confidence,
    );
  }

  /// 🔧 Debug String
  @override
  String toString() {
    return 'HoroscopeData(zodiacSign: $zodiacSign, date: $formattedDate, moonPhase: $moonPhase, isFromAI: $isFromAI)';
  }

  /// ⚖️ Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HoroscopeData &&
        other.zodiacSign == zodiacSign &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day;
  }

  /// 🔢 Hash code
  @override
  int get hashCode {
    return zodiacSign.hashCode ^
        date.year.hashCode ^
        date.month.hashCode ^
        date.day.hashCode;
  }
}
