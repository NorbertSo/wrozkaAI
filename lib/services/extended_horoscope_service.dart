// ==========================================
// lib/services/extended_horoscope_service.dart
// 🔮 SERWIS HOROSKOPU ROZBUDOWANEGO
// ==========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/extended_horoscope_data.dart';
// import '../models/monthly_usage_data.dart'; // Usuń jeśli nie masz modelu
// import '../services/logger.dart'; // Usuń import loggera

class ExtendedHoroscopeService {
  static final ExtendedHoroscopeService _instance = ExtendedHoroscopeService._internal();
  factory ExtendedHoroscopeService() => _instance;
  ExtendedHoroscopeService._internal();

  FirebaseFirestore? _firestore;
  bool _initialized = false;

  /// 🏗️ Inicjalizacja serwisu
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _firestore = FirebaseFirestore.instance;
      _initialized = true;
      print('ExtendedHoroscopeService zainicjalizowany');
    } catch (e) {
      print('Błąd inicjalizacji ExtendedHoroscopeService: $e');
    }
  }

  /// 🔮 Pobierz rozbudowany horoskop
  Future<ExtendedHoroscopeData> getExtendedHoroscope({
    required String zodiacSign,
    required String userName,
    required String userGender,
    DateTime? birthDate,
    String? dominantHand,
    String? relationshipStatus,
    String? primaryConcern,
  }) async {
    await initialize();

    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // 1️⃣ Sprawdź cache w Firestore
      final cachedHoroscope = await _getCachedExtendedHoroscope(zodiacSign, dateStr);
      if (cachedHoroscope != null) {
        print('Znaleziono cached rozbudowany horoskop dla $zodiacSign');
        return cachedHoroscope;
      }

      // 2️⃣ Generuj nowy horoskop (AI lub fallback)
      final horoscope = await _generateExtendedHoroscope(
        zodiacSign: zodiacSign,
        userName: userName,
        userGender: userGender,
        birthDate: birthDate,
        dominantHand: dominantHand,
        relationshipStatus: relationshipStatus,
        primaryConcern: primaryConcern,
        dateStr: dateStr,
      );

      // 3️⃣ Zapisz do cache
      await _cacheExtendedHoroscope(zodiacSign, dateStr, horoscope);

      return horoscope;
    } catch (e) {
      print('Błąd pobierania rozbudowanego horoskopu: $e');
      return _getFallbackExtendedHoroscope(zodiacSign);
    }
  }

  /// 🗂️ Pobierz cached horoskop
  Future<ExtendedHoroscopeData?> _getCachedExtendedHoroscope(String zodiacSign, String dateStr) async {
    try {
      final doc = await _firestore!
          .collection('extended_horoscopes')
          .doc('${dateStr}_$zodiacSign')
          .get();

      if (doc.exists && doc.data() != null) {
        return ExtendedHoroscopeData.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Błąd pobierania cached horoskopu: $e');
      return null;
    }
  }

  /// 🤖 Generuj nowy horoskop (AI lub fallback)
  Future<ExtendedHoroscopeData> _generateExtendedHoroscope({
    required String zodiacSign,
    required String userName,
    required String userGender,
    DateTime? birthDate,
    String? dominantHand,
    String? relationshipStatus,
    String? primaryConcern,
    required String dateStr,
  }) async {
    try {
      // TODO: Implementacja AI generation przez Firebase Functions
      // Na razie używamy fallback
      print('Generowanie AI horoskopu nie jest jeszcze dostępne, używam fallback');
      return _getFallbackExtendedHoroscope(zodiacSign);
    } catch (e) {
      print('Błąd generowania AI horoskopu: $e');
      return _getFallbackExtendedHoroscope(zodiacSign);
    }
  }

  /// 💾 Zapisz do cache
  Future<void> _cacheExtendedHoroscope(String zodiacSign, String dateStr, ExtendedHoroscopeData horoscope) async {
    try {
      await _firestore!
          .collection('extended_horoscopes')
          .doc('${dateStr}_$zodiacSign')
          .set(horoscope.toFirestore());

      print('Horoskop rozbudowany zapisany do cache');
    } catch (e) {
      print('Błąd zapisywania horoskopu do cache: $e');
    }
  }

  /// 🔧 Fallback horoskop
  ExtendedHoroscopeData _getFallbackExtendedHoroscope(String zodiacSign) {
    final fallbackTexts = _getFallbackTexts(zodiacSign);

    // Usuń pola luckyColor, luckyNumber, bestTimeForActions, generationType jeśli nie istnieją w ExtendedHoroscopeData
    return ExtendedHoroscopeData(
      careerPrediction: fallbackTexts['career'] ?? '',
      lovePrediction: fallbackTexts['love'] ?? '',
      financePrediction: fallbackTexts['finance'] ?? '',
      healthPrediction: fallbackTexts['health'] ?? '',
      personalGrowthPrediction: fallbackTexts['growth'] ?? '',
      familyPrediction: fallbackTexts['family'] ?? '',
      moonPhase: _getCurrentMoonPhase(),
      moonEmoji: _getMoonEmoji(),
      recommendedCandle: _getRecommendedCandle(),
      candleReason: _getCandleReason(),
      // luckyColor: _getLuckyColor(zodiacSign), // usuń jeśli nie istnieje
      // luckyNumber: _getLuckyNumber(), // usuń jeśli nie istnieje
      // bestTimeForActions: _getBestTime(), // usuń jeśli nie istnieje
      generatedAt: DateTime.now(),
      zodiacSign: zodiacSign,
      // generationType: 'fallback', // usuń jeśli nie istnieje
    );
  }

  /// 📝 Fallback teksty dla wszystkich znaków
  Map<String, String> _getFallbackTexts(String zodiacSign) {
    final Map<String, Map<String, String>> allTexts = {
      'aries': {
        'career': 'Twoja naturalna energia i determinacja przyniosą dziś konkretne rezultaty w pracy. Śmiało przedstaw swoje pomysły przełożonym - Twoja pewność siebie otworzy nowe możliwości zawodowe.',
        'love': 'W relacjach panuje dziś harmonia i wzajemne zrozumienie. Jeśli jesteś w związku, to idealny moment na romantyczne gesty. Single mogą spotkać kogoś intrygującego w nieoczekiwanym miejscu.',
        'finance': 'Unikaj dziś impulsywnych zakupów, szczególnie dużych wydatków. Twoja intuicja finansowa jest wyostrzona - zaufaj jej przy podejmowaniu decyzji o inwestycjach lub oszczędnościach.',
        'health': 'Energia płynie w Tobie obficie - wykorzystaj ją do aktywności fizycznej. Pamiętaj o odpoczynku i regeneracji. Zwróć uwagę na dietę, szczególnie na dostarczanie organizmowi składników energetycznych.',
        'growth': 'Dziś szczególnie sprzyjają Ci nowe wyzwania intelektualne. To doskonały moment na rozpoczęcie kursu, czytanie rozwojowej książki lub eksplorowanie nowych hobby. Twój umysł jest wyjątkowo receptywny.',
        'family': 'Atmosfera w domu jest spokojna i przyjazna. To dobry dzień na rozmowy z bliskimi o przyszłości i wspólnych planach. Może pojawić się okazja do pomocy członkowi rodziny w ważnej sprawie.',
      },
      // TODO: Dodaj wszystkie znaki zodiaku
    };

    return allTexts[zodiacSign.toLowerCase()] ?? allTexts['aries']!;
  }

  /// 🌙 Pobierz aktualną fazę księżyca
  String _getCurrentMoonPhase() {
    // Simplified moon phase calculation
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final moonCycle = dayOfYear % 29;

    if (moonCycle < 2) return 'Nów';
    if (moonCycle < 7) return 'Przybywający sierp';
    if (moonCycle < 9) return 'Pierwsza kwadra';
    if (moonCycle < 14) return 'Przybywający garb';
    if (moonCycle < 16) return 'Pełnia';
    if (moonCycle < 21) return 'Ubywający garb';
    if (moonCycle < 23) return 'Ostatnia kwadra';
    return 'Ubywający sierp';
  }

  String _getMoonEmoji() {
    final phase = _getCurrentMoonPhase();
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
    return emojis[phase] ?? '🌑';
  }

  String _getRecommendedCandle() {
    final phase = _getCurrentMoonPhase();
    const candles = {
      'Nów': 'biała',
      'Przybywający sierp': 'zielona',
      'Pierwsza kwadra': 'czerwona',
      'Przybywający garb': 'pomarańczowa',
      'Pełnia': 'złota',
      'Ubywający garb': 'niebieska',
      'Ostatnia kwadra': 'fioletowa',
      'Ubywający sierp': 'czarna',
    };
    return candles[phase] ?? 'biała';
  }

  String _getCandleReason() {
    final phase = _getCurrentMoonPhase();
    const reasons = {
      'Nów': 'Biała świeca symbolizuje czystość, nowe początki i nieskazitelną energię.',
      'Przybywający sierp': 'Zielona świeca wspiera wzrost, rozwój i realizację nowych planów.',
      'Pierwsza kwadra': 'Czerwona świeca daje siłę i determinację do pokonywania przeszkód.',
      'Przybywający garb': 'Pomarańczowa świeca wspiera kreatywność i pozytywną energię.',
      'Pełnia': 'Złota świeca symbolizuje obfitość, sukces i manifestację marzeń.',
      'Ubywający garb': 'Niebieska świeca przynosi spokój, refleksję i głęboką mądrość.',
      'Ostatnia kwadra': 'Fioletowa świeca wspiera transformację i duchowe oczyszczenie.',
      'Ubywający sierp': 'Czarna świeca symbolizuje ochronę i usuwanie negatywnej energii.',
    };
    return reasons[phase] ?? 'Ta świeca wspiera Twoje intencje i harmonizuje energię.';
  }

  String _getLuckyColor(String zodiacSign) {
    const colors = {
      'aries': 'czerwony',
      'taurus': 'zielony',
      'gemini': 'żółty',
      'cancer': 'srebrny',
      'leo': 'złoty',
      'virgo': 'granatowy',
      'libra': 'różowy',
      'scorpio': 'bordowy',
      'sagittarius': 'fioletowy',
      'capricorn': 'czarny',
      'aquarius': 'turkusowy',
      'pisces': 'morski',
    };
    return colors[zodiacSign.toLowerCase()] ?? 'biały';
  }

  int _getLuckyNumber() {
    return DateTime.now().day % 10 + 1;
  }

  String _getBestTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'rano (6:00-12:00)';
    if (hour < 18) return 'popołudnie (12:00-18:00)';
    return 'wieczorem (18:00-24:00)';
  }

  /// 📊 Sprawdź czy użyto darmowego horoskopu w tym miesiącu
  Future<bool> hasUsedMonthlyFree() async {
    try {
      final userData = await SecureUserService.getUserData();
      if (userData == null) return false;

      final userId = userData.id ?? userData.name;
      final now = DateTime.now();
      final monthKey = '${now.year}_${now.month.toString().padLeft(2, '0')}';

      final doc = await _firestore!
          .collection('monthly_usage')
          .doc('${userId}_$monthKey')
          .get();

      if (doc.exists && doc.data() != null) {
        // Jeśli nie masz MonthlyUsageData, zamień na prostą mapę
        return doc.data()!['usedFreeExtendedHoroscope'] == true;
      }

      return false;
    } catch (e) {
      print('Błąd sprawdzania miesięcznego użycia: $e');
      return false;
    }
  }

  /// ✅ Oznacz darmowy horoskop jako użyty
  Future<void> markMonthlyFreeAsUsed() async {
    try {
      final userData = await SecureUserService.getUserData();
      if (userData == null) return;

      final userId = userData.id ?? userData.name;
      final now = DateTime.now();
      final monthKey = '${now.year}_${now.month.toString().padLeft(2, '0')}';

      await _firestore!
          .collection('monthly_usage')
          .doc('${userId}_$monthKey')
          .set({
        'userId': userId,
        'year': now.year,
        'month': now.month,
        'usedFreeExtendedHoroscope': true,
        'lastUpdated': DateTime.now(),
      }, SetOptions(merge: true));

      print('Oznaczono darmowy horoskop miesięczny jako użyty');
    } catch (e) {
      print('Błąd oznaczania miesięcznego użycia: $e');
    }
  }
}

// Dodaj tymczasowe klasy/model na górze pliku jeśli nie masz ich w projekcie:

class UserData {
  final String name;
  final String? id;
  UserData({required this.name, this.id});
}

class SecureUserService {
  static Future<UserData?> getUserData() async {
    // Zwraca przykładowego użytkownika, zamień na własną logikę
    return UserData(name: 'demoUser', id: 'demoUserId');
  }
}

class ExtendedHoroscopeData {
  final String careerPrediction;
  final String lovePrediction;
  final String financePrediction;
  final String healthPrediction;
  final String personalGrowthPrediction;
  final String familyPrediction;
  final String moonPhase;
  final String moonEmoji;
  final String recommendedCandle;
  final String candleReason;
  final DateTime generatedAt;
  final String zodiacSign;

  ExtendedHoroscopeData({
    required this.careerPrediction,
    required this.lovePrediction,
    required this.financePrediction,
    required this.healthPrediction,
    required this.personalGrowthPrediction,
    required this.familyPrediction,
    required this.moonPhase,
    required this.moonEmoji,
    required this.recommendedCandle,
    required this.candleReason,
    required this.generatedAt,
    required this.zodiacSign,
  });

  Map<String, dynamic> toFirestore() => {
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
    'generatedAt': generatedAt.toIso8601String(),
    'zodiacSign': zodiacSign,
  };

  static ExtendedHoroscopeData fromFirestore(Map<String, dynamic> data) {
    return ExtendedHoroscopeData(
      careerPrediction: data['careerPrediction'] ?? '',
      lovePrediction: data['lovePrediction'] ?? '',
      financePrediction: data['financePrediction'] ?? '',
      healthPrediction: data['healthPrediction'] ?? '',
      personalGrowthPrediction: data['personalGrowthPrediction'] ?? '',
      familyPrediction: data['familyPrediction'] ?? '',
      moonPhase: data['moonPhase'] ?? '',
      moonEmoji: data['moonEmoji'] ?? '',
      recommendedCandle: data['recommendedCandle'] ?? '',
      candleReason: data['candleReason'] ?? '',
      generatedAt: DateTime.tryParse(data['generatedAt'] ?? '') ?? DateTime.now(),
      zodiacSign: data['zodiacSign'] ?? '',
    );
  }
}

