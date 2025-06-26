// lib/models/fortune_history.dart
// Model dla historii wróżb użytkownika

import 'dart:convert';

class FortuneHistory {
  final String id;
  final String userName;
  final String userGender;
  final String handType; // 'left' lub 'right'
  final String fortuneText;
  final DateTime createdAt;
  final String? photoPath; // Ścieżka do zdjęcia dłoni (opcjonalne)
  final Map<String, dynamic>? metadata; // Dodatkowe dane

  FortuneHistory({
    required this.id,
    required this.userName,
    required this.userGender,
    required this.handType,
    required this.fortuneText,
    required this.createdAt,
    this.photoPath,
    this.metadata,
  });

  // Fabryka do tworzenia z PalmAnalysisResult
  factory FortuneHistory.fromAnalysisResult({
    required String userName,
    required String userGender,
    required String handType,
    required String fortuneText,
    String? photoPath,
    Map<String, dynamic>? metadata,
  }) {
    return FortuneHistory(
      id: _generateId(),
      userName: userName,
      userGender: userGender,
      handType: handType,
      fortuneText: fortuneText,
      createdAt: DateTime.now(),
      photoPath: photoPath,
      metadata: metadata,
    );
  }

  // Konwersja do JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'userGender': userGender,
      'handType': handType,
      'fortuneText': fortuneText,
      'createdAt': createdAt.toIso8601String(),
      'photoPath': photoPath,
      'metadata': metadata,
    };
  }

  // Konwersja z JSON
  factory FortuneHistory.fromJson(Map<String, dynamic> json) {
    return FortuneHistory(
      id: json['id'] ?? _generateId(),
      userName: json['userName'] ?? '',
      userGender: json['userGender'] ?? '',
      handType: json['handType'] ?? 'right',
      fortuneText: json['fortuneText'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      photoPath: json['photoPath'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  // Konwersja do JSON string
  String toJsonString() => jsonEncode(toJson());

  // Konwersja z JSON string
  factory FortuneHistory.fromJsonString(String jsonString) {
    return FortuneHistory.fromJson(jsonDecode(jsonString));
  }

  // Generowanie unikalnego ID
  static String _generateId() {
    return 'fortune_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  // Getter dla sformatowanej daty
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Przed chwilą';
        }
        return '${difference.inMinutes} min temu';
      }
      return '${difference.inHours} godz. temu';
    } else if (difference.inDays == 1) {
      return 'Wczoraj';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dni temu';
    } else {
      return '${createdAt.day}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}';
    }
  }

  // Getter dla krótkiego podglądu tekstu
  String get previewText {
    if (fortuneText.length <= 150) {
      return fortuneText;
    }
    return '${fortuneText.substring(0, 150)}...';
  }

  // Getter dla nazwy ręki po polsku
  String get handName {
    return handType == 'left' ? 'Lewa dłoń' : 'Prawa dłoń';
  }

  // Getter dla ikony w zależności od płci
  String get genderIcon {
    switch (userGender.toLowerCase()) {
      case 'female':
        return '👩';
      case 'male':
        return '👨';
      default:
        return '👤';
    }
  }

  // Getter dla nazwy typu ręki (do UI)
  String get handTypeName {
    switch (handType) {
      case 'left':
        return 'Lewa dłoń';
      case 'right':
        return 'Prawa dłoń';
      default:
        return 'Dłoń';
    }
  }

  // Getter dla ikony dłoni (do UI)
  String get handIcon {
    switch (handType) {
      case 'left':
        return '🤚';
      case 'right':
        return '🖐️';
      default:
        return '✋';
    }
  }

  // Getter dla krótkiego podsumowania wróżby (do UI)
  String get shortSummary {
    if (fortuneText.length <= 80) {
      return fortuneText;
    }
    return '${fortuneText.substring(0, 80)}...';
  }

  // Metoda do kopiowania z nowymi danymi
  FortuneHistory copyWith({
    String? id,
    String? userName,
    String? userGender,
    String? handType,
    String? fortuneText,
    DateTime? createdAt,
    String? photoPath,
    Map<String, dynamic>? metadata,
  }) {
    return FortuneHistory(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userGender: userGender ?? this.userGender,
      handType: handType ?? this.handType,
      fortuneText: fortuneText ?? this.fortuneText,
      createdAt: createdAt ?? this.createdAt,
      photoPath: photoPath ?? this.photoPath,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'FortuneHistory(id: $id, userName: $userName, handType: $handType, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FortuneHistory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Klasa pomocnicza do zarządzania listą wróżb
class FortuneHistoryList {
  final List<FortuneHistory> fortunes;

  FortuneHistoryList(this.fortunes);

  // Sortowanie po dacie (najnowsze pierwsze)
  List<FortuneHistory> get sortedByDate {
    final sorted = List<FortuneHistory>.from(fortunes);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  // Pobranie ostatnich N wróżb
  List<FortuneHistory> getLatest(int count) {
    return sortedByDate.take(count).toList();
  }

  // Filtrowanie po typie ręki
  List<FortuneHistory> getByHandType(String handType) {
    return fortunes.where((f) => f.handType == handType).toList();
  }

  // Filtrowanie po dacie (ostatnie N dni)
  List<FortuneHistory> getFromLastDays(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return fortunes.where((f) => f.createdAt.isAfter(cutoffDate)).toList();
  }

  // Statystyki
  Map<String, int> get statistics {
    return {
      'total': fortunes.length,
      'leftHand': fortunes.where((f) => f.handType == 'left').length,
      'rightHand': fortunes.where((f) => f.handType == 'right').length,
      'thisWeek': getFromLastDays(7).length,
      'thisMonth': getFromLastDays(30).length,
    };
  }

  // Konwersja do JSON
  Map<String, dynamic> toJson() {
    return {
      'fortunes': fortunes.map((f) => f.toJson()).toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  // Konwersja z JSON
  factory FortuneHistoryList.fromJson(Map<String, dynamic> json) {
    final fortunesList = (json['fortunes'] as List<dynamic>?)
            ?.map((item) => FortuneHistory.fromJson(item))
            .toList() ??
        [];

    return FortuneHistoryList(fortunesList);
  }

  // Dodawanie nowej wróżby (z limitem 5)
  FortuneHistoryList addFortune(FortuneHistory newFortune, {int maxCount = 5}) {
    final updatedList = List<FortuneHistory>.from(fortunes);
    updatedList.insert(0, newFortune); // Dodaj na początku

    // Ogranicz do maksymalnej liczby
    if (updatedList.length > maxCount) {
      updatedList.removeRange(maxCount, updatedList.length);
    }

    return FortuneHistoryList(updatedList);
  }

  // Usuwanie wróżby po ID
  FortuneHistoryList removeFortune(String id) {
    final updatedList = fortunes.where((f) => f.id != id).toList();
    return FortuneHistoryList(updatedList);
  }

  // Aktualizacja wróżby
  FortuneHistoryList updateFortune(FortuneHistory updatedFortune) {
    final updatedList = fortunes.map((f) {
      return f.id == updatedFortune.id ? updatedFortune : f;
    }).toList();

    return FortuneHistoryList(updatedList);
  }

  @override
  String toString() {
    return 'FortuneHistoryList(count: ${fortunes.length})';
  }
}
