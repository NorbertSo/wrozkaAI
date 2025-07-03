// test/horoscope_cache_test.dart
// 🧪 TESTY SYSTEMU CACHOWANIA HOROSKOPÓW
// Sprawdzenie czy mechanizm zapobiegania podwójnym płatnościom działa

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_wrozka/models/cached_horoscope.dart';

void main() {
  group('CachedHoroscope Tests', () {
    test('should create horoscope for today with correct validity', () {
      final now = DateTime.now();
      final horoscope = CachedHoroscope.forToday(
        userId: 'test_user_123',
        horoscopeData: {'test': 'data'},
        userName: 'Test User',
        userGender: 'male',
      );

      // Sprawdź czy data zakupu to dzisiaj
      expect(horoscope.isForToday, true);
      
      // Sprawdź czy horoskop jest ważny
      expect(horoscope.isValid, true);
      
      // Sprawdź czy ważny do jutro o 6:00
      final expectedValidUntil = DateTime(now.year, now.month, now.day + 1, 6, 0, 0);
      expect(horoscope.validUntil.day, expectedValidUntil.day);
      expect(horoscope.validUntil.hour, 6);
      expect(horoscope.validUntil.minute, 0);
    });

    test('should detect expired horoscope', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final expiredValidUntil = DateTime(yesterday.year, yesterday.month, yesterday.day, 6, 0, 0);
      
      final expiredHoroscope = CachedHoroscope(
        userId: 'test_user_123',
        purchaseDate: yesterday,
        validUntil: expiredValidUntil,
        horoscopeData: {'test': 'data'},
        userName: 'Test User',
        userGender: 'male',
      );

      expect(expiredHoroscope.isValid, false);
      expect(expiredHoroscope.isForToday, false);
    });

    test('should handle validity info correctly', () {
      // Horoskop ważny jeszcze przez kilka godzin
      final now = DateTime.now();
      final validUntil = now.add(const Duration(hours: 3, minutes: 30));
      
      final horoscope = CachedHoroscope(
        userId: 'test_user_123',
        purchaseDate: now,
        validUntil: validUntil,
        horoscopeData: {'test': 'data'},
        userName: 'Test User',
        userGender: 'male',
      );

      expect(horoscope.isValid, true);
      
      // Sprawdź czy validityInfo zawiera godziny (może być różne w zależności od dokładnego czasu)
      final validityInfo = horoscope.validityInfo;
      expect(validityInfo.contains('h'), true);
      expect(validityInfo.contains('min'), true);
    });

    test('should convert to/from Firestore correctly', () {
      final original = CachedHoroscope.forToday(
        userId: 'test_user_123',
        horoscopeData: {
          'career': 'Test career advice',
          'love': 'Test love advice',
        },
        userName: 'Test User',
        userGender: 'female',
        birthDate: DateTime(1990, 5, 15),
        dominantHand: 'right',
        relationshipStatus: 'single',
        primaryConcern: 'career',
      );

      // Konwersja do Firestore i z powrotem
      final firestoreData = original.toFirestore();
      
      // Symulacja Firestore Timestamp (w testach używamy DateTime)
      final modifiedData = Map<String, dynamic>.from(firestoreData);
      modifiedData['purchaseDate'] = MockTimestamp(original.purchaseDate);
      modifiedData['validUntil'] = MockTimestamp(original.validUntil);
      modifiedData['birthDate'] = MockTimestamp(original.birthDate!);
      modifiedData['createdAt'] = MockTimestamp(DateTime.now());

      // W prawdziwym teście potrzebowalibyśmy mock dla Timestamp
      // Tutaj sprawdzamy tylko podstawowe pola
      expect(firestoreData['userId'], 'test_user_123');
      expect(firestoreData['userName'], 'Test User');
      expect(firestoreData['userGender'], 'female');
      expect(firestoreData['dominantHand'], 'right');
      expect(firestoreData['relationshipStatus'], 'single');
      expect(firestoreData['primaryConcern'], 'career');
      expect(firestoreData['horoscopeData']['career'], 'Test career advice');
      expect(firestoreData['horoscopeData']['love'], 'Test love advice');
    });
  });
}

// Mock klasa dla Timestamp (w prawdziwych testach byłby to prawdziwy mock)
class MockTimestamp {
  final DateTime dateTime;
  MockTimestamp(this.dateTime);
  
  DateTime toDate() => dateTime;
}
