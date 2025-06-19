// lib/services/palm_detection_service.dart
// POPRAWIONA WERSJA - spójne wykrywanie dłoni

import 'dart:math' as math;
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import '../models/palm_analysis.dart';

class PalmDetectionService {
  static final PalmDetectionService _instance =
      PalmDetectionService._internal();
  PalmDetectionService._internal();
  factory PalmDetectionService() => _instance;

  final math.Random _random = math.Random();
  Map<String, dynamic>? _palmTemplate;

  // ✅ POPRAWKA: Przechowywanie stanu wykrywania przez całą sesję
  bool _currentSessionDetectionState = false;
  int _sessionAttempts = 0;
  String? _currentUserName;
  String? _currentHandType;

  // Reset sesji dla nowego użytkownika
  void startNewDetectionSession(String userName, String handType) {
    print('🔄 NOWA SESJA WYKRYWANIA:');
    print('   - Użytkownik: $userName');
    print('   - Typ ręki: $handType');

    _currentUserName = userName;
    _currentHandType = handType;
    _sessionAttempts = 0;
    _currentSessionDetectionState = false;
  }

  // ✅ POPRAWKA: Spójne wykrywanie podczas skanowania
  Future<bool> validatePalmDetection({
    required String handType,
    required String userName,
    bool isTestMode = false,
  }) async {
    // Sprawdź czy to ta sama sesja
    if (_currentUserName != userName || _currentHandType != handType) {
      startNewDetectionSession(userName, handType);
    }

    _sessionAttempts++;

    print('🔍 WALIDACJA WYKRYWANIA DŁONI (próba $_sessionAttempts):');
    print('   - Użytkownik: $userName');
    print('   - Typ ręki: $handType');
    print('   - Tryb testowy: $isTestMode');
    print('   - Stan sesji: $_currentSessionDetectionState');

    if (isTestMode) {
      // W trybie testowym zawsze sukces po kilku próbach
      if (_sessionAttempts >= 3) {
        _currentSessionDetectionState = true;
        print(
            '✅ WYKRYWANIE (TEST): Sukces - tryb testowy, próba $_sessionAttempts');
        return true;
      } else {
        print(
            '⏳ WYKRYWANIE (TEST): Zbieranie danych, próba $_sessionAttempts/3');
        return false;
      }
    }

    // ✅ POPRAWKA: Progresywne wykrywanie - szanse rosną z czasem
    double baseSuccessChance = 0.3; // 30% na start
    double progressiveBonus =
        (_sessionAttempts - 1) * 0.15; // +15% za każdą próbę
    double maxChance = 0.85; // Maksymalnie 85%

    double finalChance =
        math.min(maxChance, baseSuccessChance + progressiveBonus);

    // Jeśli już wykryliśmy w tej sesji, utrzymaj wysoki sukces
    if (_currentSessionDetectionState) {
      finalChance = math.max(finalChance, 0.8); // Min 80% jeśli już wykryto
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final detectionSuccess = _random.nextDouble() < finalChance;

    if (detectionSuccess) {
      _currentSessionDetectionState = true;
      print(
          '✅ WYKRYWANIE: Dłoń wykryta (szansa: ${(finalChance * 100).toInt()}%, próba: $_sessionAttempts)');
    } else {
      print(
          '❌ WYKRYWANIE: Nie wykryto dłoni (szansa: ${(finalChance * 100).toInt()}%, próba: $_sessionAttempts)');
    }

    return detectionSuccess;
  }

  // ✅ POPRAWKA: Główna metoda analizy - używa stanu z sesji wykrywania
  Future<PalmAnalysis?> analyzePalm({
    required String handType,
    required String userName,
    bool isTestMode = false,
  }) async {
    print('🔮 ROZPOCZYNAM FINALNĄ ANALIZĘ DŁONI...');
    print('   - Stan sesji wykrywania: $_currentSessionDetectionState');
    print('   - Liczba prób w sesji: $_sessionAttempts');

    // ✅ POPRAWKA: Użyj stanu z sesji wykrywania zamiast nowej losowej walidacji
    bool finalDetectionResult;

    if (isTestMode) {
      // W trybie testowym zawsze sukces
      finalDetectionResult = true;
      print('✅ FINALNA ANALIZA (TEST): Wymuszony sukces');
    } else {
      // Sprawdź czy mieliśmy już sukces w sesji
      if (_currentSessionDetectionState && _sessionAttempts >= 3) {
        // Jeśli już wykrywaliśmy i było dość prób, bardzo wysoka szansa sukcesu
        finalDetectionResult = _random.nextDouble() < 0.9; // 90% sukcesu
        print(
            '✅ FINALNA ANALIZA: Bazując na sesji - wykryto wcześniej (90% szans)');
      } else if (_sessionAttempts >= 5) {
        // Jeśli było dużo prób, daj szansę
        finalDetectionResult = _random.nextDouble() < 0.7; // 70% sukcesu
        print('✅ FINALNA ANALIZA: Dużo prób - umiarkowana szansa (70%)');
      } else {
        // Niska szansa jeśli mało prób i nie było wykrywania
        finalDetectionResult = _random.nextDouble() < 0.4; // 40% sukcesu
        print('❌ FINALNA ANALIZA: Mało prób - niska szansa (40%)');
      }
    }

    if (!finalDetectionResult) {
      print('❌ FINALNA ANALIZA: Nie wykryto dłoni w końcowej analizie');
      return null;
    }

    // KROK 2: Załaduj szablon danych
    await _loadPalmTemplate();

    // KROK 3: Symulacja czasu analizy
    print('⏳ Analizuję cechy dłoni...');
    await Future.delayed(const Duration(seconds: 2));

    // KROK 4: Generowanie analizy
    final analysis = PalmAnalysis(
      handType: handType,
      handShape: _generateHandShape(),
      fingers: _generateFingers(),
      lines: _generatePalmLines(),
      mounts: _generateMounts(),
      skin: _generateSkinCharacteristics(),
      paznokcie: _generateNails(),
      analysisDate: DateTime.now(),
      userName: userName,
    );

    print('✅ FINALNA ANALIZA ZAKOŃCZONA POMYŚLNIE');
    print('   - Typ ręki: ${analysis.handType}');
    print('   - Element dłoni: ${analysis.handShape.elementType}');

    return analysis;
  }

  // Getter do sprawdzania stanu sesji
  bool get currentSessionDetectionState => _currentSessionDetectionState;
  int get sessionAttempts => _sessionAttempts;

  // Resetuj stan (np. przy zmianie użytkownika)
  void resetDetectionState() {
    print('🔄 Reset stanu wykrywania');
    _currentSessionDetectionState = false;
    _sessionAttempts = 0;
    _currentUserName = null;
    _currentHandType = null;
  }

  // Reszta metod pozostaje bez zmian...
  Future<void> _loadPalmTemplate() async {
    if (_palmTemplate == null) {
      try {
        final String jsonString = await rootBundle.loadString(
          'assets/data/palm_analysis_template.json',
        );
        _palmTemplate = json.decode(jsonString);
      } catch (e) {
        print('Błąd ładowania szablonu dłoni: $e');
        _palmTemplate = _getDefaultTemplate();
      }
    }
  }

  HandShape _generateHandShape() {
    return HandShape(
      size: _getRandomFromList(_palmTemplate!['hand_shape']['size']),
      form: _getRandomFromList(_palmTemplate!['hand_shape']['form']),
      elementType: _getRandomFromList(
        _palmTemplate!['hand_shape']['element_type'],
      ),
    );
  }

  Fingers _generateFingers() {
    return Fingers(
      length: _getRandomFromList(_palmTemplate!['fingers']['length']),
      flexibility: _getRandomFromList(_palmTemplate!['fingers']['flexibility']),
      palecWskazujacy: _getRandomFromList(
        _palmTemplate!['fingers']['palec_wskazujący'],
      ),
      palecSerdeczny: _getRandomFromList(
        _palmTemplate!['fingers']['palec_serdeczny'],
      ),
      kciuk: Thumb(
        typ: _getRandomFromList(_palmTemplate!['fingers']['kciuk']['typ']),
        ustawienie: _getRandomFromList(
          _palmTemplate!['fingers']['kciuk']['ustawienie'],
        ),
      ),
    );
  }

  PalmLines _generatePalmLines() {
    return PalmLines(
      lifeLine: LifeLine(
        dlugosc: _getRandomFromList(
          _palmTemplate!['lines']['life_line']['długość'],
        ),
        ksztalt: _getRandomFromList(
          _palmTemplate!['lines']['life_line']['kształt'],
        ),
        rozpoczecie: _getRandomFromList(
          _palmTemplate!['lines']['life_line']['rozpoczęcie'],
        ),
        przebieg: _getRandomFromList(
          _palmTemplate!['lines']['life_line']['przebieg'],
        ),
      ),
      headLine: HeadLine(
        dlugosc: _getRandomFromList(
          _palmTemplate!['lines']['head_line']['długość'],
        ),
        ksztalt: _getRandomFromList(
          _palmTemplate!['lines']['head_line']['kształt'],
        ),
        rozpoczecie: _getRandomFromList(
          _palmTemplate!['lines']['head_line']['rozpoczęcie'],
        ),
        koniec: _getRandomFromList(
          _palmTemplate!['lines']['head_line']['koniec'],
        ),
      ),
      heartLine: HeartLine(
        dlugosc: _getRandomFromList(
          _palmTemplate!['lines']['heart_line']['długość'],
        ),
        ksztalt: _getRandomFromList(
          _palmTemplate!['lines']['heart_line']['kształt'],
        ),
        rozpoczecie: _getRandomFromList(
          _palmTemplate!['lines']['heart_line']['rozpoczęcie'],
        ),
        znaki: _getRandomFromList(
          _palmTemplate!['lines']['heart_line']['znaki'],
        ),
      ),
      fateLine: FateLine(
        obecnosc: _getRandomFromList(
          _palmTemplate!['lines']['fate_line']['obecność'],
        ),
        rozpoczecie: _getRandomFromList(
          _palmTemplate!['lines']['fate_line']['rozpoczęcie'],
        ),
        przebieg: _getRandomFromList(
          _palmTemplate!['lines']['fate_line']['przebieg'],
        ),
      ),
      sunLine: SunLine(
        obecnosc: _getRandomFromList(
          _palmTemplate!['lines']['sun_line']['obecność'],
        ),
        rozpoczecie: _getRandomFromList(
          _palmTemplate!['lines']['sun_line']['rozpoczęcie'],
        ),
        przebieg: _getRandomFromList(
          _palmTemplate!['lines']['sun_line']['przebieg'],
        ),
      ),
      healthLine: HealthLine(
        obecnosc: _getRandomFromList(
          _palmTemplate!['lines']['health_line']['obecność'],
        ),
        przebieg: _getRandomFromList(
          _palmTemplate!['lines']['health_line']['przebieg'],
        ),
      ),
      marriageLines: MarriageLines(
        ilosc: _getRandomFromList(
          _palmTemplate!['lines']['marriage_lines']['ilość'],
        ),
        ksztalt: _getRandomFromList(
          _palmTemplate!['lines']['marriage_lines']['kształt'],
        ),
        znaki: _getRandomFromList(
          _palmTemplate!['lines']['marriage_lines']['znaki'],
        ),
      ),
      childrenLines: ChildrenLines(
        ilosc: _getRandomFromList(
          _palmTemplate!['lines']['children_lines']['ilość'],
        ),
        intensywnosc: _getRandomFromList(
          _palmTemplate!['lines']['children_lines']['intensywność'],
        ),
      ),
    );
  }

  Mounts _generateMounts() {
    return Mounts(
      mountOfJupiter: _getRandomFromList(
        _palmTemplate!['mounts']['Mount of Jupiter'],
      ),
      mountOfSaturne: _getRandomFromList(
        _palmTemplate!['mounts']['Mount of Saturn'],
      ),
      mountOfApollo: _getRandomFromList(
        _palmTemplate!['mounts']['Mount of Apollo'],
      ),
      mountOfMercury: _getRandomFromList(
        _palmTemplate!['mounts']['Mount of Mercury'],
      ),
      mountOfVenus: _getRandomFromList(
        _palmTemplate!['mounts']['Mount of Venus'],
      ),
      mountOfMarsUpper: _getRandomFromList(
        _palmTemplate!['mounts']['Mount of Mars (upper)'],
      ),
      mountOfMarsLower: _getRandomFromList(
        _palmTemplate!['mounts']['Mount of Mars (lower)'],
      ),
      mountOfMoon: _getRandomFromList(
        _palmTemplate!['mounts']['Mount of Moon'],
      ),
    );
  }

  SkinCharacteristics _generateSkinCharacteristics() {
    return SkinCharacteristics(
      tekstura: _getRandomFromList(_palmTemplate!['skin']['tekstura']),
      wilgotnosc: _getRandomFromList(_palmTemplate!['skin']['wilgotność']),
      kolor: _getRandomFromList(_palmTemplate!['skin']['kolor']),
    );
  }

  Nails _generateNails() {
    return Nails(
      dlugosc: _getRandomFromList(_palmTemplate!['paznokcie']['długość']),
      ksztalt: _getRandomFromList(_palmTemplate!['paznokcie']['kształt']),
      kolor: _getRandomFromList(_palmTemplate!['paznokcie']['kolor']),
    );
  }

  String _getRandomFromList(List<dynamic> list) {
    if (list.isEmpty) return 'nieznane';
    return list[_random.nextInt(list.length)].toString();
  }

  Map<String, dynamic> _getDefaultTemplate() {
    return {
      'hand_shape': {
        'size': ['średnia'],
        'form': ['prostokątna'],
        'element_type': ['ziemia'],
      },
      'fingers': {
        'length': ['proporcjonalne'],
        'flexibility': ['giętkie'],
        'palec_wskazujący': ['normalny'],
        'palec_serdeczny': ['równy'],
        'kciuk': {
          'typ': ['mocny'],
          'ustawienie': ['normalnie osadzony'],
        },
      },
      'lines': {
        'life_line': {
          'długość': ['średnia'],
          'kształt': ['głęboka'],
          'rozpoczęcie': ['blisko kciuka'],
          'przebieg': ['przylega do kciuka'],
        },
        'head_line': {
          'długość': ['średnia'],
          'kształt': ['prosta'],
          'rozpoczęcie': ['łączy się z linią życia'],
          'koniec': ['wskazuje prosto'],
        },
        'heart_line': {
          'długość': ['średnia'],
          'kształt': ['prosta'],
          'rozpoczęcie': ['pod palcem wskazującym'],
          'znaki': ['czysta'],
        },
        'fate_line': {
          'obecność': ['jest'],
          'rozpoczęcie': ['od nadgarstka'],
          'przebieg': ['prosta'],
        },
        'sun_line': {
          'obecność': ['jest'],
          'rozpoczęcie': ['od dołu dłoni'],
          'przebieg': ['prosta'],
        },
        'health_line': {
          'obecność': ['brak'],
          'przebieg': ['prosta'],
        },
        'marriage_lines': {
          'ilość': ['1'],
          'kształt': ['prosta'],
          'znaki': ['czysta'],
        },
        'children_lines': {
          'ilość': ['1-2'],
          'intensywność': ['średnie'],
        },
      },
      'mounts': {
        'Mount of Jupiter': ['średni'],
        'Mount of Saturn': ['średni'],
        'Mount of Apollo': ['średni'],
        'Mount of Mercury': ['średni'],
        'Mount of Venus': ['średni'],
        'Mount of Mars (upper)': ['średni'],
        'Mount of Mars (lower)': ['średni'],
        'Mount of Moon': ['średni'],
      },
      'skin': {
        'tekstura': ['średnia'],
        'wilgotność': ['normalna'],
        'kolor': ['różowawa'],
      },
      'paznokcie': {
        'długość': ['średnie'],
        'kształt': ['owalne'],
        'kolor': ['jasne'],
      },
    };
  }

  // Pozostałe metody pomocnicze...
  Future<bool> detectHandInImage() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _currentSessionDetectionState;
  }

  Future<String> determineHandType() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentHandType ?? (_random.nextBool() ? 'left' : 'right');
  }

  double evaluateLighting() {
    return 0.3 + (_random.nextDouble() * 0.7);
  }

  Map<String, dynamic> checkHandPosition() {
    if (_currentSessionDetectionState) {
      return {'isCorrect': true, 'message': 'Pozycja prawidłowa'};
    }

    final random = _random.nextDouble();
    if (random > 0.6) {
      return {'isCorrect': false, 'message': 'Przybliż dłoń do kamery'};
    } else if (random > 0.4) {
      return {'isCorrect': false, 'message': 'Oddal dłoń od kamery'};
    } else if (random > 0.2) {
      return {'isCorrect': false, 'message': 'Wyśrodkuj dłoń w ramce'};
    } else {
      return {'isCorrect': false, 'message': 'Rozłóż palce szerzej'};
    }
  }

  bool checkHandStability() {
    return _currentSessionDetectionState || _random.nextDouble() > 0.4;
  }

  Future<bool> checkSkinColor(CameraController controller) async {
    try {
      print('🔍 Sprawdzam kolor skóry...');
      bool hasSkinColor =
          _currentSessionDetectionState || _random.nextDouble() > 0.4;
      print('🎨 Kolor skóry wykryty: $hasSkinColor');
      return hasSkinColor;
    } catch (e) {
      print('❌ Błąd sprawdzania koloru skóry: $e');
      return false;
    }
  }

  Future<bool> checkPalmPosition(CameraController controller) async {
    try {
      print('📍 Sprawdzam pozycję dłoni...');
      bool isCentered =
          _currentSessionDetectionState || _random.nextDouble() > 0.3;
      print('🎯 Dłoń wycentrowana: $isCentered');
      return isCentered;
    } catch (e) {
      print('❌ Błąd sprawdzania pozycji: $e');
      return false;
    }
  }

  Future<double> checkLightLevel(CameraController controller) async {
    try {
      print('💡 Sprawdzam poziom światła...');
      final random = math.Random();
      double lightLevel = random.nextDouble();
      print('🌟 Poziom światła: ${(lightLevel * 100).toInt()}%');
      return lightLevel;
    } catch (e) {
      print('❌ Błąd sprawdzania światła: $e');
      return 0.0;
    }
  }
}
