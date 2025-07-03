// lib/services/horoscope_cache_service.dart
// 🔮 SERWIS CACHOWANIA HOROSKOPÓW ROZBUDOWANYCH
// Zarządza zapisanymi horoskopami aby uniknąć podwójnych płatności

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cached_horoscope.dart';
import '../services/anonymous_user_service.dart';
import '../utils/logger.dart';

class HoroscopeCacheService {
  static final HoroscopeCacheService _instance =
      HoroscopeCacheService._internal();
  factory HoroscopeCacheService() => _instance;
  HoroscopeCacheService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnonymousUserService _userService = AnonymousUserService();

  static const String _collectionName = 'cached_horoscopes';

  /// 🏗️ Inicjalizacja serwisu
  Future<void> initialize() async {
    if (!_userService.isInitialized) {
      await _userService.initialize();
    }
    Logger.info('HoroscopeCacheService zainicjalizowany');
  }

  /// 💾 Zapisz horoskop po zakupie
  Future<bool> saveHoroscope(CachedHoroscope horoscope) async {
    try {
      await initialize();

      final docId =
          _generateDocumentId(horoscope.userId, horoscope.purchaseDate);

      await _firestore
          .collection(_collectionName)
          .doc(docId)
          .set(horoscope.toFirestore());

      Logger.info('Zapisano cachowany horoskop: $docId');
      return true;
    } catch (e) {
      Logger.error('Błąd zapisywania horoskopu: $e');
      return false;
    }
  }

  /// 🔍 Sprawdź czy użytkownik ma ważny horoskop na dziś
  Future<CachedHoroscope?> getTodaysHoroscope() async {
    try {
      await initialize();

      final userId = _userService.userId;
      if (userId == null) {
        Logger.warning(
            'Brak userId - nie można sprawdzić cachowanego horoskopu');
        return null;
      }

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final docId = _generateDocumentId(userId, todayDate);

      final doc = await _firestore.collection(_collectionName).doc(docId).get();

      if (!doc.exists) {
        Logger.info('Brak cachowanego horoskopu na dziś');
        return null;
      }

      final horoscope = CachedHoroscope.fromFirestore(doc.data()!);

      // Sprawdź czy horoskop jest nadal ważny
      if (!horoscope.isValid) {
        Logger.info('Cachowany horoskop wygasł - usuwam');
        await _deleteExpiredHoroscope(docId);
        return null;
      }

      Logger.info(
          'Znaleziono ważny cachowany horoskop: ${horoscope.validityInfo}');
      return horoscope;
    } catch (e) {
      Logger.error('Błąd pobierania cachowanego horoskopu: $e');
      return null;
    }
  }

  /// 🔍 Sprawdź czy użytkownik zakupił już dziś horoskop
  Future<bool> hasTodaysHoroscope() async {
    final horoscope = await getTodaysHoroscope();
    return horoscope != null;
  }

  /// 🗑️ Usuń wygasły horoskop
  Future<void> _deleteExpiredHoroscope(String docId) async {
    try {
      await _firestore.collection(_collectionName).doc(docId).delete();
      Logger.info('Usunięto wygasły horoskop: $docId');
    } catch (e) {
      Logger.error('Błąd usuwania wygasłego horoskopu: $e');
    }
  }

  /// 📄 Pobierz historię horoskopów użytkownika
  Future<List<CachedHoroscope>> getHoroscopeHistory({int limit = 30}) async {
    try {
      await initialize();

      final userId = _userService.userId;
      if (userId == null) return [];

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .limit(limit)
          .get();

      final horoscopes = querySnapshot.docs
          .map((doc) => CachedHoroscope.fromFirestore(doc.data()))
          .toList();

      Logger.info('Pobrano ${horoscopes.length} horoskopów z historii');
      return horoscopes;
    } catch (e) {
      Logger.error('Błąd pobierania historii horoskopów: $e');
      return [];
    }
  }

  /// 🧹 Wyczyść wygasłe horokorty (maintenance)
  Future<void> cleanupExpiredHoroscopes() async {
    try {
      await initialize();

      final userId = _userService.userId;
      if (userId == null) return;

      final now = DateTime.now();

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('validUntil', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (querySnapshot.docs.isNotEmpty) {
        await batch.commit();
        Logger.info(
            'Usunięto ${querySnapshot.docs.length} wygasłych horoskopów');
      }
    } catch (e) {
      Logger.error('Błąd czyszczenia wygasłych horoskopów: $e');
    }
  }

  /// 📊 Statystyki cachowania
  Future<HoroscopeCacheStats> getStats() async {
    try {
      await initialize();

      final userId = _userService.userId;
      if (userId == null) {
        return HoroscopeCacheStats.empty();
      }

      final allHoroscopes = await getHoroscopeHistory(limit: 100);
      final validHoroscopes = allHoroscopes.where((h) => h.isValid).toList();
      final todaysHoroscope = allHoroscopes.firstWhere(
        (h) => h.isForToday,
        orElse: () => throw StateError('No today horoscope'),
      );

      return HoroscopeCacheStats(
        totalCached: allHoroscopes.length,
        validCached: validHoroscopes.length,
        hasTodaysHoroscope: allHoroscopes.any((h) => h.isForToday && h.isValid),
        todaysHoroscopeExpiry:
            allHoroscopes.any((h) => h.isForToday && h.isValid)
                ? todaysHoroscope.validUntil
                : null,
      );
    } catch (e) {
      Logger.error('Błąd pobierania statystyk cache: $e');
      return HoroscopeCacheStats.empty();
    }
  }

  /// 🔑 Generuj ID dokumentu na podstawie userId i daty
  String _generateDocumentId(String userId, DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${userId}_$dateStr';
  }

  /// 🎯 Utwórz horoskop z obecnymi danymi użytkownika
  Future<CachedHoroscope> createHoroscopeForUser({
    required Map<String, String> horoscopeData,
    required String userName,
    required String userGender,
    DateTime? birthDate,
    String? dominantHand,
    String? relationshipStatus,
    String? primaryConcern,
  }) async {
    await initialize();

    final userId = _userService.userId;
    if (userId == null) {
      throw Exception('Brak userId - nie można utworzyć horoskopu');
    }

    return CachedHoroscope.forToday(
      userId: userId,
      horoscopeData: horoscopeData,
      userName: userName,
      userGender: userGender,
      birthDate: birthDate,
      dominantHand: dominantHand,
      relationshipStatus: relationshipStatus,
      primaryConcern: primaryConcern,
    );
  }
}

/// 📊 Statystyki cachowania horoskopów
class HoroscopeCacheStats {
  final int totalCached;
  final int validCached;
  final bool hasTodaysHoroscope;
  final DateTime? todaysHoroscopeExpiry;

  const HoroscopeCacheStats({
    required this.totalCached,
    required this.validCached,
    required this.hasTodaysHoroscope,
    this.todaysHoroscopeExpiry,
  });

  factory HoroscopeCacheStats.empty() {
    return const HoroscopeCacheStats(
      totalCached: 0,
      validCached: 0,
      hasTodaysHoroscope: false,
      todaysHoroscopeExpiry: null,
    );
  }

  int get expiredCached => totalCached - validCached;

  bool get hasValidCache => validCached > 0;

  String get todaysExpiryInfo {
    if (!hasTodaysHoroscope || todaysHoroscopeExpiry == null) {
      return 'Brak horoskopu na dziś';
    }

    final now = DateTime.now();
    final remaining = todaysHoroscopeExpiry!.difference(now);

    if (remaining.isNegative) {
      return 'Horoskop wygasł';
    } else if (remaining.inHours > 1) {
      return 'Wygasa za ${remaining.inHours}h ${remaining.inMinutes % 60}min';
    } else {
      return 'Wygasa za ${remaining.inMinutes}min';
    }
  }

  @override
  String toString() {
    return 'HoroscopeCacheStats(total: $totalCached, valid: $validCached, '
        'hasTodays: $hasTodaysHoroscope, expiry: $todaysExpiryInfo)';
  }
}
