// lib/services/horoscope_service.dart
// 🔮 SERWIS HOROSKOPÓW - integracja z Firebase i AI backend
// Zgodny z wytycznymi projektu AI Wróżka - ZAKTUALIZOWANY dla nowej struktury Firebase

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

  // 🏠 Kolekcje horoskopów w Firestore - NOWA STRUKTURA
  static const String _horoscopesCollection = 'horoscopes';
  static const String _dailySubCollection = 'daily';
  static const String _weeklySubCollection = 'weekly';
  static const String _monthlySubCollection = 'monthly';

  // 🌟 Znaki zodiaku - angielskie nazwy zgodne z Firebase
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

  // 🔄 Mapowanie polskich nazw na angielskie
  static const Map<String, String> _polishToEnglishZodiac = {
    'Baran': 'aries',
    'Byk': 'taurus',
    'Bliźnięta': 'gemini',
    'Rak': 'cancer',
    'Lew': 'leo',
    'Panna': 'virgo',
    'Waga': 'libra',
    'Skorpion': 'scorpio',
    'Strzelec': 'sagittarius',
    'Koziorożec': 'capricorn',
    'Wodnik': 'aquarius',
    'Ryby': 'pisces',
  };

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

  /// 🔄 Konwertuj polską nazwę znaku na angielską
  String _convertZodiacToEnglish(String zodiacSign) {
    return _polishToEnglishZodiac[zodiacSign] ?? zodiacSign.toLowerCase();
  }

  /// 📅 Pobierz horoskop dzienny dla znaku zodiaku - NOWA STRUKTURA
  Future<HoroscopeData?> getDailyHoroscope(String zodiacSign,
      {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(targetDate);
      final englishZodiac = _convertZodiacToEnglish(zodiacSign);

      _logger.logToConsole(
          'Pobieranie horoskopu: $englishZodiac na $dateString',
          tag: 'HOROSCOPE');

      if (_firestore == null) {
        _logger.logToConsole('❌ Firestore nie jest zainicjalizowany',
            tag: 'ERROR');
        return _getFallbackHoroscope(englishZodiac, targetDate);
      }

      // NOWA ŚCIEŻKA: horoscopes/daily/[zodiacSign]/[date]
      final docRef = _firestore!
          .collection(_horoscopesCollection)
          .doc(_dailySubCollection)
          .collection(englishZodiac)
          .doc(dateString);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        _logger.logToConsole('✅ Znaleziono horoskop w Firebase',
            tag: 'HOROSCOPE');
        return HoroscopeData.fromFirestore(docSnapshot);
      } else {
        _logger.logToConsole('⚠️ Brak horoskopu w Firebase - używam fallback',
            tag: 'HOROSCOPE');
        return _getFallbackHoroscope(englishZodiac, targetDate);
      }
    } catch (e) {
      _logger.logToConsole('❌ Błąd pobierania horoskopu: $e', tag: 'ERROR');
      return _getFallbackHoroscope(zodiacSign, targetDate);
    }
  }

  /// 📅 Pobierz horoskop tygodniowy - NOWA IMPLEMENTACJA
  Future<HoroscopeData?> getWeeklyHoroscope(String zodiacSign,
      {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();

    try {
      final englishZodiac = _convertZodiacToEnglish(zodiacSign);
      final weekKey = _getWeekKey(targetDate);

      _logger.logToConsole(
          'Pobieranie horoskopu tygodniowego: $englishZodiac ($weekKey)',
          tag: 'HOROSCOPE');

      if (_firestore == null) {
        _logger.logToConsole('❌ Firestore nie jest zainicjalizowany',
            tag: 'ERROR');
        return _getFallbackWeeklyHoroscope(englishZodiac, targetDate);
      }

      // ŚCIEŻKA: horoscopes/weekly/weeks/[weekKey] -> znajdź dokument ze zodiacSign
      final collectionRef = _firestore!
          .collection(_horoscopesCollection)
          .doc(_weeklySubCollection)
          .collection('weeks')
          .doc(weekKey);

      final docSnapshot = await collectionRef.get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (data['zodiacSign'] == englishZodiac) {
          _logger.logToConsole('✅ Znaleziono horoskop tygodniowy w Firebase',
              tag: 'HOROSCOPE');
          return HoroscopeData.fromFirestore(docSnapshot);
        }
      }

      _logger.logToConsole('⚠️ Brak horoskopu tygodniowego - używam fallback',
          tag: 'HOROSCOPE');
      return _getFallbackWeeklyHoroscope(englishZodiac, targetDate);
    } catch (e) {
      _logger.logToConsole('❌ Błąd pobierania horoskopu tygodniowego: $e',
          tag: 'ERROR');
      return _getFallbackWeeklyHoroscope(zodiacSign, targetDate);
    }
  }

  /// 📅 Pobierz horoskop miesięczny - NOWA IMPLEMENTACJA
  Future<HoroscopeData?> getMonthlyHoroscope(String zodiacSign,
      {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();

    try {
      final englishZodiac = _convertZodiacToEnglish(zodiacSign);
      final monthKey = _getMonthKey(targetDate);

      _logger.logToConsole(
          'Pobieranie horoskopu miesięcznego: $englishZodiac ($monthKey)',
          tag: 'HOROSCOPE');

      if (_firestore == null) {
        _logger.logToConsole('❌ Firestore nie jest zainicjalizowany',
            tag: 'ERROR');
        return _getFallbackMonthlyHoroscope(englishZodiac, targetDate);
      }

      // ŚCIEŻKA: horoscopes/monthly/months/[monthKey] -> znajdź dokument ze zodiacSign
      final collectionRef = _firestore!
          .collection(_horoscopesCollection)
          .doc(_monthlySubCollection)
          .collection('months')
          .doc(monthKey);

      final docSnapshot = await collectionRef.get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (data['zodiacSign'] == englishZodiac) {
          _logger.logToConsole('✅ Znaleziono horoskop miesięczny w Firebase',
              tag: 'HOROSCOPE');
          return HoroscopeData.fromFirestore(docSnapshot);
        }
      }

      _logger.logToConsole('⚠️ Brak horoskopu miesięcznego - używam fallback',
          tag: 'HOROSCOPE');
      return _getFallbackMonthlyHoroscope(englishZodiac, targetDate);
    } catch (e) {
      _logger.logToConsole('❌ Błąd pobierania horoskopu miesięcznego: $e',
          tag: 'ERROR');
      return _getFallbackMonthlyHoroscope(zodiacSign, targetDate);
    }
  }

  /// 📊 Pobierz wszystkie horoskopy dzienne na dany dzień
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
  Future<bool> areHoroscopesAvailable(
      {DateTime? date, String type = 'daily'}) async {
    try {
      final targetDate = date ?? DateTime.now();
      String docId;

      switch (type) {
        case 'weekly':
          docId = _getWeekKey(targetDate);
          break;
        case 'monthly':
          docId = _getMonthKey(targetDate);
          break;
        default:
          docId = DateFormat('yyyy-MM-dd').format(targetDate);
          break;
      }

      if (_firestore == null) return false;

      final docRef = _firestore!
          .collection(_horoscopesCollection)
          .doc(type)
          .collection(type == 'daily' ? 'aquarius' : '${type}s')
          .doc(docId);

      final docSnapshot = await docRef.get();
      return docSnapshot.exists;
    } catch (e) {
      _logger.logToConsole('❌ Błąd sprawdzania dostępności: $e', tag: 'ERROR');
      return false;
    }
  }

  /// 🗓️ Generuj klucz tygodnia
  String _getWeekKey(DateTime date) {
    final year = date.year;
    final weekNumber = _getWeekNumber(date);
    return '$year-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// 📅 Generuj klucz miesiąca
  String _getMonthKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  /// 📊 Oblicz numer tygodnia
  int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday =
        startOfYear.add(Duration(days: (8 - startOfYear.weekday) % 7));

    if (date.isBefore(firstMonday)) {
      return _getWeekNumber(DateTime(date.year - 1, 12, 31));
    }

    return ((date.difference(firstMonday).inDays) / 7).floor() + 1;
  }

  /// 🌙 Oblicz fazę księżyca
  String calculateMoonPhase(DateTime date) {
    final daysSinceNewMoon =
        date.difference(DateTime(2000, 1, 6)).inDays % 29.53;

    if (daysSinceNewMoon < 1.84) return 'Nów';
    if (daysSinceNewMoon < 5.53) return 'Przybywający sierp';
    if (daysSinceNewMoon < 9.22) return 'Pierwsza kwadra';
    if (daysSinceNewMoon < 12.91) return 'Przybywający garb';
    if (daysSinceNewMoon < 16.61) return 'Pełnia';
    if (daysSinceNewMoon < 20.30) return 'Ubywający garb';
    if (daysSinceNewMoon < 23.99) return 'Ostatnia kwadra';
    if (daysSinceNewMoon < 27.68) return 'Ubywający sierp';
    return 'Nów';
  }

  /// 🛡️ Fallback horoskop gdy Firebase nie działa
  HoroscopeData _getFallbackHoroscope(String zodiacSign, DateTime date) {
    final moonPhase = calculateMoonPhase(date);

    final fallbackTexts = {
      'aries':
          'Dzisiaj Twoja energia i determinacja będą kluczowe. Podejmij odważne decyzje, ale pamiętaj o dyplomacji w kontaktach z innymi.',
      'taurus':
          'Stabilność i praktyczność pomogą Ci osiągnąć cele. Skup się na budowaniu trwałych fundamentów.',
      'gemini':
          'Twoja komunikatywność otwiera nowe możliwości. Wykorzystaj umiejętność adaptacji do zmieniających się sytuacji.',
      'cancer':
          'Intuicja podpowiada właściwe decyzje. Zadbaj o równowagę między życiem zawodowym a osobistym.',
      'leo':
          'Twoje przywództwo jest dzisiaj szczególnie potrzebne. Inspiruj innych swoją kreatywnością i entuzjazmem.',
      'virgo':
          'Uwaga na szczegóły przynosi doskonałe rezultaty. Metodyczne podejście zaprowadzi Cię do sukcesu.',
      'libra':
          'Harmonia i równowaga są kluczowe. Polegaj na swojej naturalnej dyplomacji w trudnych sytuacjach.',
      'scorpio':
          'Twoja intuicja jest wyjątkowo silna. Wykorzystaj tę moc do przekształcenia planów w rzeczywistość.',
      'sagittarius':
          'Optymizm i poszukiwanie przygód otwierają nowe horyzonty. Podążaj za swoimi marzeniami.',
      'capricorn':
          'Konsekwencja i cierpliwość przynoszą wymierne korzyści. Twoje ambicje znajdą uznanie.',
      'aquarius':
          'Twoja oryginalność inspiruje innych. Wykorzystaj innowacyjne myślenie do rozwiązania problemów.',
      'pisces':
          'Wrażliwość i empatia są Twoimi mocnymi stronami. Zaufaj swojej intuicji w ważnych decyzjach.',
    };

    return HoroscopeData(
      zodiacSign: zodiacSign,
      text: fallbackTexts[zodiacSign] ??
          'Dzisiaj jest dobry dzień na nowe początki.',
      date: date,
      moonPhase: moonPhase,
      moonEmoji: _getMoonEmoji(moonPhase),
      isFromAI: false,
      createdAt: DateTime.now(),
      type: 'daily',
      generatedBy: 'fallback',
      lunarDescription: _getFallbackLunarDescription(moonPhase),
      recommendedCandle: _getFallbackCandle(moonPhase),
      recommendedCandleReason: _getFallbackCandleReason(moonPhase),
    );
  }

  /// 🛡️ Fallback horoskop tygodniowy
  HoroscopeData _getFallbackWeeklyHoroscope(String zodiacSign, DateTime date) {
    final moonPhase = calculateMoonPhase(date);
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 6));

    final fallbackTexts = {
      'aries':
          'Ten tydzień przyniesie energię do działania. Poniedziałek rozpocznij z determinacją, środa może przynieść ważne decyzje.',
      'taurus':
          'Stabilność i konsekwencja będą kluczowe w tym tygodniu. Skupuj się na długoterminowych celach.',
      'gemini':
          'Komunikacja i elastyczność otworzą nowe możliwości. Środa może przynieść inspirujące spotkania.',
      'cancer':
          'Intuicja będzie Twoim przewodnikiem. Zadbaj o równowagę między pracą a odpoczynkiem.',
      'leo':
          'Twoje przywództwo znajdzie uznanie. Piątek może przynieść ważne osiągnięcia.',
      'virgo':
          'Precyzja i uwaga na szczegóły przyniosą doskonałe rezultaty w tym tygodniu.',
      'libra':
          'Dyplomacja i umiejętność budowania mostów będą szczególnie cenne.',
      'scorpio': 'Intensywność i determinacja pomogą Ci osiągnąć ambitne cele.',
      'sagittarius':
          'Optymizm i otwartość na nowe doświadczenia otworzą fascynujące możliwości.',
      'capricorn':
          'Metodyczne podejście i cierpliwość przyniosą wymierne korzyści.',
      'aquarius': 'Innowacyjne myślenie będzie Twoim atutem w tym tygodniu.',
      'pisces': 'Intuicja i kreatywność poprowadzą Cię ku sukcesowi.',
    };

    return HoroscopeData(
      zodiacSign: zodiacSign,
      text: fallbackTexts[zodiacSign] ??
          'Ten tydzień przyniesie nowe możliwości.',
      date: date,
      moonPhase: moonPhase,
      moonEmoji: _getMoonEmoji(moonPhase),
      isFromAI: false,
      createdAt: DateTime.now(),
      type: 'weekly',
      generatedBy: 'fallback',
      weekKey: _getWeekKey(date),
      weekStart: weekStart,
      weekEnd: weekEnd,
    );
  }

  /// 🛡️ Fallback horoskop miesięczny
  HoroscopeData _getFallbackMonthlyHoroscope(String zodiacSign, DateTime date) {
    final moonPhase = calculateMoonPhase(date);
    final monthStart = DateTime(date.year, date.month, 1);
    final monthEnd = DateTime(date.year, date.month + 1, 0);

    final fallbackTexts = {
      'aries':
          'Ten miesiąc to czas działania i podejmowania odważnych decyzji. Energia planet wspiera Twoje inicjatywy.',
      'taurus':
          'Stabilność i konsekwentne budowanie fundamentów przyniosą trwałe rezultaty w tym miesiącu.',
      'gemini':
          'Komunikacja i adaptacyjność otworzą przed Tobą nowe horyzonty. Wykorzystaj swoją wszechstronność.',
      'cancer':
          'Intuicja i empatia będą Twoimi największymi atutami. Zadbaj o harmonię w relacjach.',
      'leo':
          'Twoja kreatywność i charyzma znajdą uznanie. To doskonały czas na realizację artystycznych projektów.',
      'virgo':
          'Uwaga na szczegóły i metodyczne podejście przyniosą doskonałe rezultaty.',
      'libra':
          'Harmonia i dyplomacja pomogą Ci osiągnąć ważne cele. Relacje z innymi będą kluczowe.',
      'scorpio':
          'Transformacja i głębokie zmiany charakteryzują ten miesiąc. Zaufaj swojej intuicji.',
      'sagittarius':
          'Poszukiwanie przygód i nowych doświadczeń otworzy fascynujące możliwości.',
      'capricorn':
          'Cierpliwość i wytrwałość przyniosą wymierne korzyści. Twoje ambicje znajdą uznanie.',
      'aquarius':
          'Innowacyjność i niezależność będą Twoimi najcenniejszymi atutami.',
      'pisces':
          'Wrażliwość i intuicja poprowadzą Cię ku duchowemu rozwojowi i kreatywnym osiągnięciom.',
    };

    return HoroscopeData(
      zodiacSign: zodiacSign,
      text: fallbackTexts[zodiacSign] ??
          'Ten miesiąc przyniesie pozytywne zmiany.',
      date: date,
      moonPhase: moonPhase,
      moonEmoji: _getMoonEmoji(moonPhase),
      isFromAI: false,
      createdAt: DateTime.now(),
      type: 'monthly',
      generatedBy: 'fallback',
      monthKey: _getMonthKey(date),
      monthName: _getMonthName(date),
      monthStart: monthStart,
      monthEnd: monthEnd,
    );
  }

  /// 🌙 Emoji dla fazy księżyca
  String _getMoonEmoji(String moonPhase) {
    const moonEmojis = {
      'Nów': '🌑',
      'Przybywający sierp': '🌒',
      'Pierwsza kwadra': '🌓',
      'Przybywający garb': '🌔',
      'Pełnia': '🌕',
      'Ubywający garb': '🌖',
      'Ostatnia kwadra': '🌗',
      'Ubywający sierp': '🌘',
    };

    return moonEmojis[moonPhase] ?? '🌙';
  }

  /// 🌙 Fallback opis księżycowy
  String _getFallbackLunarDescription(String moonPhase) {
    const lunarDescriptions = {
      'Nów':
          'Dziś panuje energia Nowiu, symbolizująca **nowe początki i czystą kartę**. To idealny czas na zasiewanie intencji.',
      'Przybywający sierp':
          'Energia przybywającego sierpa wspiera **inicjowanie nowych projektów**. Czas na pierwsze kroki.',
      'Pierwsza kwadra':
          'Pierwsza kwadra to moment **podejmowania ważnych decyzji**. Przezwyciężaj przeszkody z determinacją.',
      'Przybywający garb':
          'Energia przybywającego garba zachęca do **wytrwałej pracy**. Efekty będą wkrótce widoczne.',
      'Pełnia':
          'Pełnia to **szczyt energii lunalnej**. Czas manifestacji i celebrowania osiągnięć.',
      'Ubywający garb':
          'Czas **refleksji nad osiągnięciami**. Podziękuj za to, co udało się zrealizować.',
      'Ostatnia kwadra':
          'Ostatnia kwadra to czas **puszczenia tego, co już nie służy**. Przygotuj miejsce na nowe.',
      'Ubywający sierp':
          'Okres **oczyszczenia i przygotowań** do nowego cyklu księżycowego.',
    };

    return lunarDescriptions[moonPhase] ??
        'Księżyc wpływa na nasze emocje i energię. Żyj w zgodzie z jego cyklem.';
  }

  /// 🕯️ Fallback świeca
  String _getFallbackCandle(String moonPhase) {
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

    return candles[moonPhase] ?? 'biała';
  }

  /// 🕯️ Fallback powód świecy
  String _getFallbackCandleReason(String moonPhase) {
    const reasons = {
      'Nów':
          'Biała świeca symbolizuje czystość, nowe początki i nieskazitelną energię.',
      'Przybywający sierp':
          'Zielona świeca wspiera wzrost, rozwój i realizację nowych planów.',
      'Pierwsza kwadra':
          'Czerwona świeca daje siłę i determinację do pokonywania przeszkód.',
      'Przybywający garb':
          'Pomarańczowa świeca wspiera kreatywność i pozytywną energię.',
      'Pełnia':
          'Złota świeca symbolizuje obfitość, sukces i manifestację marzeń.',
      'Ubywający garb':
          'Niebieska świeca przynosi spokój, refleksję i głęboką mądrość.',
      'Ostatnia kwadra':
          'Fioletowa świeca wspiera transformację i duchowe oczyszczenie.',
      'Ubywający sierp':
          'Czarna świeca symbolizuje ochronę i usuwanie negatywnej energii.',
    };

    return reasons[moonPhase] ??
        'Ta świeca wspiera Twoje intencje i harmonizuje energię.';
  }

  /// 📅 Nazwa miesiąca
  String _getMonthName(DateTime date) {
    const monthNames = [
      'Styczeń',
      'Luty',
      'Marzec',
      'Kwiecień',
      'Maj',
      'Czerwiec',
      'Lipiec',
      'Sierpień',
      'Wrzesień',
      'Październik',
      'Listopad',
      'Grudzień'
    ];

    return monthNames[date.month - 1];
  }

  /// 📋 Wszystkie fallback horoskopy
  List<HoroscopeData> _getAllFallbackHoroscopes(DateTime date) {
    final List<HoroscopeData> horoscopes = [];

    // Dodaj wszystkie znaki zodiaku
    for (String sign in _zodiacSigns) {
      horoscopes.add(_getFallbackHoroscope(sign, date));
    }

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

  /// 🌟 Pobierz dostępne znaki zodiaku
  static List<String> get zodiacSigns => List.unmodifiable(_zodiacSigns);

  /// 🔄 Pobierz mapowanie polskich nazw
  static Map<String, String> get polishToEnglishZodiac =>
      Map.unmodifiable(_polishToEnglishZodiac);
}
