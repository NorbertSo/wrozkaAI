// lib/services/horoscope_service.dart
// 🔮 SERWIS HOROSKOPÓW - integracja z Firebase i AI backend
// Zgodny z wytycznymi projektu AI Wróżka

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'logging_service.dart';
import 'package:ai_wrozka/models/horoscope_data.dart';

class HoroscopeService {
  static final HoroscopeService _instance = HoroscopeService._internal();
  factory HoroscopeService() => _instance;
  HoroscopeService._internal();

  // 🔥 Firebase Firestore
  FirebaseFirestore? _firestore;

  // 📝 Logging zgodnie z wytycznymi
  final LoggingService _logger = LoggingService();

  // 🏠 Kolekcja horoskopów w Firestore
  static const String _horoscopesCollection = 'horoscopes';

  // 🌟 Znaki zodiaku
  static const List<String> _zodiacSigns = [
    'aries',
    'taurus',
    'gemini',
    'cancer',
    'leo',
    'virgo',
    'libra',
    'scorpio',
    'sagittarius',
    'capricorn',
    'aquarius',
    'pisces'
  ];

  /// 🚀 Inicjalizacja serwisu
  Future<bool> initialize() async {
    try {
      _logger.logToConsole('Inicjalizacja HoroscopeService...',
          tag: 'HOROSCOPE');

      // Sprawdź czy Firebase jest zainicjalizowany
      if (Firebase.apps.isEmpty) {
        _logger.logToConsole('❌ Firebase nie jest zainicjalizowany',
            tag: 'ERROR');
        return false;
      }

      _firestore = FirebaseFirestore.instance;
      _logger.logToConsole('✅ HoroscopeService zainicjalizowany pomyślnie',
          tag: 'HOROSCOPE');
      return true;
    } catch (e) {
      _logger.logToConsole('❌ Błąd inicjalizacji HoroscopeService: $e',
          tag: 'ERROR');
      return false;
    }
  }

  /// 📅 Pobierz horoskop dzienny dla znaku zodiaku
  Future<HoroscopeData?> getDailyHoroscope(String zodiacSign,
      {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(targetDate);

      _logger.logToConsole('Pobieranie horoskopu: $zodiacSign na $dateString',
          tag: 'HOROSCOPE');

      if (_firestore == null) {
        _logger.logToConsole('❌ Firestore nie jest zainicjalizowany',
            tag: 'ERROR');
        return _getFallbackHoroscope(zodiacSign, targetDate);
      }

      // Pobierz dokument z Firestore
      final docRef = _firestore!
          .collection(_horoscopesCollection)
          .doc(dateString)
          .collection('signs')
          .doc(zodiacSign);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        _logger.logToConsole('✅ Znaleziono horoskop w Firebase',
            tag: 'HOROSCOPE');
        return HoroscopeData.fromFirestore(docSnapshot);
      } else {
        _logger.logToConsole('⚠️ Brak horoskopu w Firebase - używam fallback',
            tag: 'HOROSCOPE');
        return _getFallbackHoroscope(zodiacSign, targetDate);
      }
    } catch (e) {
      _logger.logToConsole('❌ Błąd pobierania horoskopu: $e', tag: 'ERROR');
      return _getFallbackHoroscope(zodiacSign, targetDate);
    }
  }

  /// 📅 Pobierz horoskop księżycowy (lunar)
  Future<HoroscopeData?> getLunarHoroscope({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(targetDate);

      _logger.logToConsole('Pobieranie horoskopu księżycowego na $dateString',
          tag: 'HOROSCOPE');

      if (_firestore == null) {
        return _getFallbackLunarHoroscope(targetDate);
      }

      final docRef = _firestore!
          .collection(_horoscopesCollection)
          .doc(dateString)
          .collection('signs')
          .doc('lunar');

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        _logger.logToConsole('✅ Znaleziono horoskop księżycowy w Firebase',
            tag: 'HOROSCOPE');
        return HoroscopeData.fromFirestore(docSnapshot);
      } else {
        _logger.logToConsole('⚠️ Brak horoskopu księżycowego - używam fallback',
            tag: 'HOROSCOPE');
        return _getFallbackLunarHoroscope(targetDate);
      }
    } catch (e) {
      _logger.logToConsole('❌ Błąd pobierania horoskopu księżycowego: $e',
          tag: 'ERROR');
      return _getFallbackLunarHoroscope(targetDate);
    }
  }

  /// 📊 Pobierz wszystkie horoskopy na dany dzień
  Future<List<HoroscopeData>> getAllDailyHoroscopes({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(targetDate);

      _logger.logToConsole('Pobieranie wszystkich horoskopów na $dateString',
          tag: 'HOROSCOPE');

      final List<HoroscopeData> horoscopes = [];

      if (_firestore == null) {
        _logger.logToConsole('❌ Firestore niedostępny - używam fallback',
            tag: 'ERROR');
        return _getAllFallbackHoroscopes(targetDate);
      }

      // Pobierz wszystkie znaki zodiaku
      for (String sign in _zodiacSigns) {
        final horoscope = await getDailyHoroscope(sign, date: targetDate);
        if (horoscope != null) {
          horoscopes.add(horoscope);
        }
      }

      // Dodaj horoskop księżycowy
      final lunarHoroscope = await getLunarHoroscope(date: targetDate);
      if (lunarHoroscope != null) {
        horoscopes.add(lunarHoroscope);
      }

      _logger.logToConsole('✅ Pobrano ${horoscopes.length} horoskopów',
          tag: 'HOROSCOPE');
      return horoscopes;
    } catch (e) {
      _logger.logToConsole('❌ Błąd pobierania wszystkich horoskopów: $e',
          tag: 'ERROR');
      return _getAllFallbackHoroscopes(targetDate);
    }
  }

  /// 🔍 Sprawdź czy horoskopy są dostępne dla danej daty
  Future<bool> areHoroscopesAvailable({DateTime? date}) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateString = DateFormat('yyyy-MM-dd').format(targetDate);

      if (_firestore == null) return false;

      final docRef =
          _firestore!.collection(_horoscopesCollection).doc(dateString);
      final docSnapshot = await docRef.get();

      return docSnapshot.exists;
    } catch (e) {
      _logger.logToConsole('❌ Błąd sprawdzania dostępności: $e', tag: 'ERROR');
      return false;
    }
  }

  /// 🌙 Oblicz fazę księżyca
  String calculateMoonPhase(DateTime date) {
    // Uproszczony algorytm - w pełnej wersji można użyć dokładniejszych obliczeń
    final daysSinceNewMoon =
        date.difference(DateTime(2000, 1, 6)).inDays % 29.53;

    if (daysSinceNewMoon < 1.84) return 'Nów Księżyca';
    if (daysSinceNewMoon < 5.53) return 'Przybywający sierp';
    if (daysSinceNewMoon < 9.22) return 'Pierwsza kwadra';
    if (daysSinceNewMoon < 12.91) return 'Przybywający garb';
    if (daysSinceNewMoon < 16.61) return 'Pełnia';
    if (daysSinceNewMoon < 20.30) return 'Ubywający garb';
    if (daysSinceNewMoon < 23.99) return 'Ostatnia kwadra';
    if (daysSinceNewMoon < 27.68) return 'Ubywający sierp';
    return 'Nów Księżyca';
  }

  /// 🛡️ Fallback horoskop gdy Firebase nie działa
  HoroscopeData _getFallbackHoroscope(String zodiacSign, DateTime date) {
    final moonPhase = calculateMoonPhase(date);

    final fallbackTexts = {
      'aries':
          'Dzisiaj Twoja energia i determinacja będą kluczowe. Podejmij odważne decyzje, ale pamiętaj o dyplomacji w kontaktach z innymi.',
      'taurus':
          'Stabilność i wytrwałość to Twoje atuty dzisiaj. Skoncentruj się na praktycznych sprawach i nie spiesz się z ważnymi decyzjami.',
      'gemini':
          'Komunikacja będzie dzisiaj szczególnie ważna. Wykorzystaj swoją naturalną ciekawość i umiejętność nawiązywania kontaktów.',
      'cancer':
          'Intuicja prowadzi Cię we właściwym kierunku. Zaufaj swoim przeczuciom, szczególnie w sprawach osobistych.',
      'leo':
          'Twoja charyzma i pewność siebie będą dzisiaj szczególnie widoczne. To dobry czas na prezentację swoich pomysłów.',
      'virgo':
          'Precyzja i uwaga na szczegóły pomogą Ci dzisiaj osiągnąć cele. Systematyczne podejście przyniesie najlepsze rezultaty.',
      'libra':
          'Harmonia i równowaga są dziś kluczowe. Staraj się unikać konfliktów i szukaj kompromisów w trudnych sytuacjach.',
      'scorpio':
          'Głęboka analiza i intuicja pomogą Ci odkryć ukryte prawdy. Nie bój się spojrzeć na sprawy z nowej perspektywy.',
      'sagittarius':
          'Optymizm i otwartość na nowe doświadczenia będą Twoimi przewodnikami. To dobry dzień na podróże lub naukę.',
      'capricorn':
          'Ambicja i pracowitość przyniosą dziś konkretne rezultaty. Skoncentruj się na długoterminowych celach.',
      'aquarius':
          'Innowacyjność i niezależność myślenia będą dzisiaj szczególnie cenne. Nie bój się być inny.',
      'pisces':
          'Empatia i intuicja to Twoje największe atuty dzisiaj. Zaufaj swoim odczuciom w relacjach z innymi.',
    };

    return HoroscopeData(
      zodiacSign: zodiacSign,
      text: fallbackTexts[zodiacSign] ??
          'Dzisiaj jest dobry dzień na refleksję i podejmowanie pozytywnych działań.',
      date: date,
      moonPhase: moonPhase,
      isFromAI: false,
      createdAt: DateTime.now(),
    );
  }

  /// 🌙 Fallback horoskop księżycowy
  HoroscopeData _getFallbackLunarHoroscope(DateTime date) {
    final moonPhase = calculateMoonPhase(date);

    final lunarTexts = {
      'Nów Księżyca':
          'Czas nowych początków i zamierzeń. Idealna pora na sadzenie ziaren przyszłych sukcesów.',
      'Przybywający sierp':
          'Energia rośnie wraz z Księżycem. Czas na działanie i realizację planów.',
      'Pierwsza kwadra':
          'Moment podejmowania ważnych decyzji. Przezwyciężaj przeszkody z determinacją.',
      'Przybywający garb':
          'Kontynuuj wytrwale swoją pracę. Efekty będą wkrótce widoczne.',
      'Pełnia':
          'Szczyt energii lunalnej. Czas manifestacji i celebrowania osiągnięć.',
      'Ubywający garb':
          'Refleksja nad tym, co zostało osiągnięte. Czas na wdzięczność.',
      'Ostatnia kwadra':
          'Puść to, co Ci już nie służy. Przygotuj miejsce na nowe.',
      'Ubywający sierp': 'Okres oczyszczenia i przygotowań do nowego cyklu.',
    };

    return HoroscopeData(
      zodiacSign: 'lunar',
      text: lunarTexts[moonPhase] ??
          'Księżyc wpływa na nasze emocje i energię. Żyj w zgodzie z jego cyklem.',
      date: date,
      moonPhase: moonPhase,
      isFromAI: false,
      createdAt: DateTime.now(),
    );
  }

  /// 📋 Wszystkie fallback horoskopy
  List<HoroscopeData> _getAllFallbackHoroscopes(DateTime date) {
    final List<HoroscopeData> horoscopes = [];

    // Dodaj wszystkie znaki zodiaku
    for (String sign in _zodiacSigns) {
      horoscopes.add(_getFallbackHoroscope(sign, date));
    }

    // Dodaj horoskop księżycowy
    horoscopes.add(_getFallbackLunarHoroscope(date));

    return horoscopes;
  }

  /// 🔧 Metoda do testowania połączenia z Firebase
  Future<bool> testFirebaseConnection() async {
    try {
      if (_firestore == null) return false;

      // Próba odczytu test collection
      await _firestore!.collection('test').limit(1).get();
      _logger.logToConsole('✅ Połączenie z Firebase działa', tag: 'HOROSCOPE');
      return true;
    } catch (e) {
      _logger.logToConsole('❌ Brak połączenia z Firebase: $e', tag: 'ERROR');
      return false;
    }
  }
}
