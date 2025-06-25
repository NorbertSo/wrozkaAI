import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/horoscope_data.dart';
import '../services/logging_service.dart';

class HoroscopeService {
  final LoggingService _logger = LoggingService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final List<String> _zodiacSigns = [
    'Baran', 'Byk', 'Bliźnięta', 'Rak', 'Lew', 'Panna',
    'Waga', 'Skorpion', 'Strzelec', 'Koziorożec', 'Wodnik', 'Ryby'
  ];

  // Implementacja initialize
  Future<void> initialize() async {
    try {
      await checkFirebaseConnection();
      _logger.logToConsole('✅ Serwis horoskopów zainicjalizowany', tag: 'HOROSCOPE');
    } catch (e) {
      _logger.logToConsole('❌ Błąd inicjalizacji serwisu horoskopów: $e', tag: 'ERROR');
    }
  }

  // Prawdziwe pobieranie z Firebase
  Future<HoroscopeData?> getDailyHoroscope(String zodiacSign, {DateTime? date}) async {
    try {
      final String dateStr = date != null 
          ? DateFormat('yyyy-MM-dd').format(date)
          : DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      _logger.logToConsole('🔍 Pobieranie horoskopu z Firebase dla $zodiacSign na $dateStr', tag: 'FIREBASE');
      
      // Pobieranie z Firebase
      final docRef = _firestore
          .collection('horoscopes')
          .doc('daily')
          .collection(zodiacSign.toLowerCase())
          .doc(dateStr);
      
      final doc = await docRef.get();
      
      if (doc.exists && doc.data() != null) {
        _logger.logToConsole('✅ Znaleziono horoskop w Firebase', tag: 'FIREBASE');
        return HoroscopeData.fromFirestore(doc.data()!, dateStr);
      } else {
        _logger.logToConsole('⚠️ Brak horoskopu w Firebase, używam fallback', tag: 'FIREBASE');
        
        // Jeśli nie ma w Firebase, spróbuj wygenerować i zapisać
        final fallbackHoroscope = _getFallbackHoroscope(zodiacSign, date ?? DateTime.now());
        await _saveHoroscopeToFirebase(fallbackHoroscope, dateStr);
        return fallbackHoroscope;
      }
    } catch (e) {
      _logger.logToConsole('❌ Błąd pobierania z Firebase: $e', tag: 'ERROR');
      return _getFallbackHoroscope(zodiacSign, date ?? DateTime.now());
    }
  }

  // Pobieranie horoskopu dla konkretnej daty
  Future<HoroscopeData?> getHoroscopeForDate(String zodiacSign, DateTime date) async {
    return await getDailyHoroscope(zodiacSign, date: date);
  }

  // ✅ DODAJ BRAKUJĄCĄ METODĘ _getFallbackHoroscope
  HoroscopeData _getFallbackHoroscope(String zodiacSign, dynamic dateInput) {
    DateTime dateTime;
    
    // Obsługa różnych typów daty
    if (dateInput is DateTime) {
      dateTime = dateInput;
    } else if (dateInput is String) {
      try {
        dateTime = DateTime.parse(dateInput);
      } catch (e) {
        dateTime = DateTime.now();
      }
    } else {
      dateTime = DateTime.now();
    }

    // Generowanie losowego tekstu horoskopu
    String text = _generateHoroscopeText(zodiacSign);
    
    // Obliczanie fazy księżyca
    String moonPhase = calculateMoonPhase(dateTime);

    // Utworzenie danych horoskopu
    return HoroscopeData(
      zodiacSign: zodiacSign,
      text: text,
      date: dateTime,
      moonPhase: moonPhase,
      moonEmoji: _getMoonPhaseEmoji(moonPhase),
      luckyNumber: (DateTime.now().millisecondsSinceEpoch % 10) + 1,
      luckyColor: _getLuckyColor(zodiacSign),
      isFromAI: false,
      createdAt: DateTime.now(),
    );
  }

  // ✅ DODAJ BRAKUJĄCĄ METODĘ calculateMoonPhase (PUBLICZNĄ - bez _)
  String calculateMoonPhase(DateTime date) {
    // Uproszczone obliczanie fazy księżyca
    // W rzeczywistej aplikacji powinieneś użyć bardziej zaawansowanego algorytmu
    final lunarAge = date.difference(DateTime(2000, 1, 6)).inDays % 29.53;
    
    if (lunarAge < 1.84) return 'Nów Księżyca';
    if (lunarAge < 5.53) return 'Przybywający sierp';
    if (lunarAge < 9.22) return 'Pierwsza kwadra';
    if (lunarAge < 12.91) return 'Przybywający garb';
    if (lunarAge < 16.61) return 'Pełnia';
    if (lunarAge < 20.30) return 'Ubywający garb';
    if (lunarAge < 23.99) return 'Ostatnia kwadra';
    if (lunarAge < 27.68) return 'Ubywający sierp';
    return 'Nów Księżyca';
  }

  // Zapisywanie horoskopu do Firebase
  Future<void> _saveHoroscopeToFirebase(HoroscopeData horoscope, String dateStr) async {
    try {
      if (horoscope.zodiacSign == null) return;
      
      final docRef = _firestore
          .collection('horoscopes')
          .doc('daily')
          .collection(horoscope.zodiacSign!.toLowerCase())
          .doc(dateStr);
      
      await docRef.set(horoscope.toMap());
      _logger.logToConsole('✅ Zapisano horoskop do Firebase', tag: 'FIREBASE');
    } catch (e) {
      _logger.logToConsole('❌ Błąd zapisywania do Firebase: $e', tag: 'ERROR');
    }
  }

  // Sprawdzenie połączenia z Firebase
  Future<bool> checkFirebaseConnection() async {
    try {
      // Prawdziwy test połączenia z Firebase
      await _firestore
          .collection('test')
          .doc('connection')
          .get()
          .timeout(const Duration(seconds: 5));
      
      _logger.logToConsole('✅ Połączenie z Firebase działa', tag: 'FIREBASE');
      return true;
    } catch (e) {
      _logger.logToConsole('❌ Brak połączenia z Firebase: $e', tag: 'ERROR');
      return false;
    }
  }

  // ✅ DODAJ BRAKUJĄCĄ METODĘ _generateHoroscopeText
  String _generateHoroscopeText(String zodiacSign) {
    final List<String> templates = [
      'Dzisiaj $zodiacSign będzie miał szczęśliwy dzień. Gwiazdy sprzyjają Twoim planom.',
      'Dla znaku $zodiacSign to dzień pełen wyzwań, ale poradzisz sobie doskonale.',
      'Księżyc w odpowiedniej fazie zapewni znakowi $zodiacSign powodzenie w miłości.',
      'Znak $zodiacSign powinien dziś zwrócić uwagę na szczegóły. Nie pomijaj niczego.',
      'Dla $zodiacSign to dobry moment na podjęcie ważnych decyzji. Gwiazdy Ci sprzyjają.',
      'Energia planet sprzyja znakowi $zodiacSign w sprawach zawodowych.',
      'Dzisiejszy dzień przyniesie znakowi $zodiacSign nowe możliwości.',
      'Intuicja będzie dziś przewodnikiem dla znaku $zodiacSign.',
    ];

    // Wybierz losowy tekst na podstawie daty i znaku
    final index = (zodiacSign.hashCode + DateTime.now().day) % templates.length;
    return templates[index];
  }

  // ✅ DODAJ BRAKUJĄCĄ METODĘ _getMoonPhaseEmoji
  String _getMoonPhaseEmoji(String phase) {
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
    return emojis[phase] ?? '🌙';
  }

  // ✅ DODAJ BRAKUJĄCĄ METODĘ _getLuckyColor
  String _getLuckyColor(String zodiacSign) {
    const colors = {
      'Baran': 'czerwony',
      'Byk': 'zielony',
      'Bliźnięta': 'żółty',
      'Rak': 'srebrny',
      'Lew': 'złoty',
      'Panna': 'beżowy',
      'Waga': 'różowy',
      'Skorpion': 'ciemnoczerwony',
      'Strzelec': 'fioletowy',
      'Koziorożec': 'granatowy',
      'Wodnik': 'turkusowy',
      'Ryby': 'morski',
    };
    return colors[zodiacSign] ?? 'biały';
  }

  // Pobieranie wszystkich horoskopów dla tygodnia
  Future<List<HoroscopeData>> getWeeklyHoroscopes(String zodiacSign, DateTime startDate) async {
    List<HoroscopeData> horoscopes = [];
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final horoscope = await getDailyHoroscope(zodiacSign, date: date);
      horoscopes.add(horoscope ?? _getFallbackHoroscope(zodiacSign, date));
    }
    return horoscopes;
  }

  // Pobieranie wszystkich horoskopów dla danej daty
  Future<List<HoroscopeData>> getAllHoroscopesForDate(DateTime date) async {
    List<HoroscopeData> horoscopes = [];
    for (String sign in _zodiacSigns) {
      final horoscope = await getDailyHoroscope(sign, date: date);
      horoscopes.add(horoscope ?? _getFallbackHoroscope(sign, date));
    }
    return horoscopes;
  }

  // Metoda do masowego zapisu horoskopów
  Future<void> generateAndSaveHoroscopesForDate(DateTime date) async {
    try {
      final String dateStr = DateFormat('yyyy-MM-dd').format(date);
      _logger.logToConsole('🔄 Generowanie horoskopów na $dateStr', tag: 'FIREBASE');
      
      final batch = _firestore.batch();
      
      for (String sign in _zodiacSigns) {
        final horoscope = _getFallbackHoroscope(sign, date);
        
        final docRef = _firestore
            .collection('horoscopes')
            .doc('daily')
            .collection(sign.toLowerCase())
            .doc(dateStr);
        
        batch.set(docRef, horoscope.toMap());
      }
      
      await batch.commit();
      _logger.logToConsole('✅ Zapisano ${_zodiacSigns.length} horoskopów do Firebase', tag: 'FIREBASE');
    } catch (e) {
      _logger.logToConsole('❌ Błąd zapisu batch do Firebase: $e', tag: 'ERROR');
    }
  }
}