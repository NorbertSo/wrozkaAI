// lib/models/cached_horoscope.dart
// 🔮 MODEL CACHOWANEGO HOROSKOPU ROZBUDOWANEGO
// Przechowuje zakupiony horoskop z datą ważności

import 'package:cloud_firestore/cloud_firestore.dart';

class CachedHoroscope {
  final String userId;
  final DateTime purchaseDate;
  final DateTime validUntil; // Ważny do 6:00 następnego dnia
  final Map<String, String> horoscopeData;
  final String userName;
  final String userGender;
  final DateTime? birthDate;
  final String? dominantHand;
  final String? relationshipStatus;
  final String? primaryConcern;

  const CachedHoroscope({
    required this.userId,
    required this.purchaseDate,
    required this.validUntil,
    required this.horoscopeData,
    required this.userName,
    required this.userGender,
    this.birthDate,
    this.dominantHand,
    this.relationshipStatus,
    this.primaryConcern,
  });

  /// 🏗️ Konstruktor z obecnej daty (automatycznie oblicza validUntil)
  factory CachedHoroscope.forToday({
    required String userId,
    required Map<String, String> horoscopeData,
    required String userName,
    required String userGender,
    DateTime? birthDate,
    String? dominantHand,
    String? relationshipStatus,
    String? primaryConcern,
  }) {
    final now = DateTime.now();
    final purchaseDate = DateTime(now.year, now.month, now.day);

    // Ważny do 6:00 następnego dnia
    final validUntil = DateTime(now.year, now.month, now.day + 1, 6, 0, 0);

    return CachedHoroscope(
      userId: userId,
      purchaseDate: purchaseDate,
      validUntil: validUntil,
      horoscopeData: horoscopeData,
      userName: userName,
      userGender: userGender,
      birthDate: birthDate,
      dominantHand: dominantHand,
      relationshipStatus: relationshipStatus,
      primaryConcern: primaryConcern,
    );
  }

  /// 📄 Konwersja z Firestore
  factory CachedHoroscope.fromFirestore(Map<String, dynamic> data) {
    return CachedHoroscope(
      userId: data['userId'] ?? '',
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      validUntil: (data['validUntil'] as Timestamp).toDate(),
      horoscopeData: Map<String, String>.from(data['horoscopeData'] ?? {}),
      userName: data['userName'] ?? '',
      userGender: data['userGender'] ?? '',
      birthDate: data['birthDate'] != null
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      dominantHand: data['dominantHand'],
      relationshipStatus: data['relationshipStatus'],
      primaryConcern: data['primaryConcern'],
    );
  }

  /// 📄 Konwersja do Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'validUntil': Timestamp.fromDate(validUntil),
      'horoscopeData': horoscopeData,
      'userName': userName,
      'userGender': userGender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'dominantHand': dominantHand,
      'relationshipStatus': relationshipStatus,
      'primaryConcern': primaryConcern,
      'createdAt': Timestamp.now(),
    };
  }

  /// ✅ Sprawdź czy horoskop jest nadal ważny
  bool get isValid {
    final now = DateTime.now();
    return now.isBefore(validUntil);
  }

  /// 📅 Sprawdź czy to horoskop na dziś
  bool get isForToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final horoscopeDay = DateTime(
      purchaseDate.year,
      purchaseDate.month,
      purchaseDate.day,
    );

    return today.isAtSameMomentAs(horoscopeDay);
  }

  /// 🕕 Czas pozostały do wygaśnięcia
  Duration get timeUntilExpiration {
    final now = DateTime.now();
    if (now.isAfter(validUntil)) {
      return Duration.zero;
    }
    return validUntil.difference(now);
  }

  /// 📊 Informacje o ważności
  String get validityInfo {
    if (!isValid) {
      return 'Horoskop wygasł';
    }

    final remaining = timeUntilExpiration;
    if (remaining.inHours > 1) {
      return 'Ważny jeszcze ${remaining.inHours}h ${remaining.inMinutes % 60}min';
    } else {
      return 'Ważny jeszcze ${remaining.inMinutes}min';
    }
  }

  @override
  String toString() {
    return 'CachedHoroscope(userId: $userId, purchaseDate: $purchaseDate, '
        'validUntil: $validUntil, isValid: $isValid, isForToday: $isForToday)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedHoroscope &&
        other.userId == userId &&
        other.purchaseDate == purchaseDate;
  }

  @override
  int get hashCode => userId.hashCode ^ purchaseDate.hashCode;
}
