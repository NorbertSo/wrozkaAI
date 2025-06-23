// lib/models/user_data.dart
// Zaktualizowany model z miejscem i godziną urodzenia

class UserData {
  final String name;
  final DateTime birthDate;
  final String? birthTime; // Opcjonalna godzina urodzenia (HH:mm format)
  final String? birthPlace; // Miejsce urodzenia
  final String gender; // 'male', 'female', 'other'
  final String dominantHand; // 'left', 'right'
  final DateTime registrationDate;

  UserData({
    required this.name,
    required this.birthDate,
    this.birthTime,
    this.birthPlace,
    required this.gender,
    required this.dominantHand,
    required this.registrationDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'birthTime': birthTime,
      'birthPlace': birthPlace,
      'gender': gender,
      'dominantHand': dominantHand,
      'registrationDate': registrationDate.toIso8601String(),
    };
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'],
      birthDate: DateTime.parse(json['birthDate']),
      birthTime: json['birthTime'],
      birthPlace: json['birthPlace'],
      gender: json['gender'],
      dominantHand: json['dominantHand'],
      registrationDate: DateTime.parse(json['registrationDate']),
    );
  }

  // Oblicz wiek użytkownika
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Zwróć znak zodiaku - POPRAWIONE ZAKRESY
  String get zodiacSign {
    final month = birthDate.month;
    final day = birthDate.day;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Baran';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Byk';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20))
      return 'Bliźnięta';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Rak';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Lew';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Panna';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Waga';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21))
      return 'Skorpion';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21))
      return 'Strzelec';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19))
      return 'Koziorożec';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Wodnik';
    return 'Ryby';
  }

  // Zwróć płeć w odpowiednim formacie do komunikatów
  String get genderForMessages {
    switch (gender) {
      case 'female':
        return 'female';
      case 'male':
        return 'male';
      default:
        return 'neutral';
    }
  }

  // Skopiuj z nowymi danymi
  UserData copyWith({
    String? name,
    DateTime? birthDate,
    String? birthTime,
    String? birthPlace,
    String? gender,
    String? dominantHand,
    DateTime? registrationDate,
  }) {
    return UserData(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      birthTime: birthTime ?? this.birthTime,
      birthPlace: birthPlace ?? this.birthPlace,
      gender: gender ?? this.gender,
      dominantHand: dominantHand ?? this.dominantHand,
      registrationDate: registrationDate ?? this.registrationDate,
    );
  }

  // Sformatowana godzina urodzenia dla UI
  String get formattedBirthTime {
    if (birthTime == null) return 'Nie podano';
    return birthTime!;
  }

  // Sformatowane miejsce urodzenia dla UI
  String get formattedBirthPlace {
    if (birthPlace == null || birthPlace!.isEmpty) return 'Nie podano';
    return birthPlace!;
  }

  // Pełne dane do przekazania AI
  String get fullBirthInfo {
    final dateStr = '${birthDate.day}.${birthDate.month}.${birthDate.year}';
    final timeStr = birthTime ?? 'godzina nieznana';
    final placeStr = birthPlace ?? 'miejsce nieznane';

    return 'Data urodzenia: $dateStr, Godzina: $timeStr, Miejsce: $placeStr';
  }

  @override
  String toString() {
    return 'UserData(name: $name, age: $age, gender: $gender, dominantHand: $dominantHand, zodiacSign: $zodiacSign, birthPlace: $birthPlace, birthTime: $birthTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserData &&
        other.name == name &&
        other.birthDate == birthDate &&
        other.birthTime == birthTime &&
        other.birthPlace == birthPlace &&
        other.gender == gender &&
        other.dominantHand == dominantHand;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        birthDate.hashCode ^
        (birthTime?.hashCode ?? 0) ^
        (birthPlace?.hashCode ?? 0) ^
        gender.hashCode ^
        dominantHand.hashCode;
  }
}
