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
  
  // ✅ POPRAWKA: Flaga do symulacji rzeczywistego wykrywania
  bool _lastDetectionSuccessful = false;

  // ✅ POPRAWKA: Metoda walidacji wykrywania dłoni
  Future<bool> validatePalmDetection({
    required String handType,
    required String userName,
    bool isTestMode = false,
  }) async {
    print('🔍 WALIDACJA WYKRYWANIA DŁONI:');
    print('   - Użytkownik: $userName');
    print('   - Typ ręki: $handType');
    print('   - Tryb testowy: $isTestMode');

    if (isTestMode) {
      // W trybie testowym zawsze sukces
      _lastDetectionSuccessful = true;
      print('✅ WYKRYWANIE (TEST): Sukces - tryb testowy');
      return true;
    }

    // Symulacja rzeczywistego wykrywania (50% szans na sukces)
    await Future.delayed(const Duration(milliseconds: 500));
    
    final detectionSuccess = _random.nextDouble() > 0.5;
    _lastDetectionSuccessful = detectionSuccess;

    if (detectionSuccess) {
      print('✅ WYKRYWANIE: Dłoń została pomyślnie wykryta i przeanalizowana');
    } else {
      print('❌ WYKRYWANIE: Nie udało się wykryć dłoni w obrazie');
    }

    return detectionSuccess;
  }

  // ✅ POPRAWKA: Główna metoda analizy z walidacją
  Future<PalmAnalysis?> analyzePalm({
    required String handType,
    required String userName,
    bool isTestMode = false,
  }) async {
    print('🔮 ROZPOCZYNAM ANALIZĘ DŁONI...');
    
    // KROK 1: Walidacja wykrywania dłoni
    final detectionValid = await validatePalmDetection(
      handType: handType,
      userName: userName,
      isTestMode: isTestMode,
    );

    if (!detectionValid) {
      print('❌ ANALIZA PRZERWANA: Nie wykryto dłoni w obrazie');
      return null; // ✅ Zwróć null jeśli nie wykryto dłoni
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

    print('✅ ANALIZA ZAKOŃCZONA POMYŚLNIE');
    return analysis;
  }

  // Getter do sprawdzania ostatniego stanu wykrywania
  bool get lastDetectionWasSuccessful => _lastDetectionSuccessful;

  // Załaduj szablon danych z assets
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

  // Generowanie losowych, ale realistycznych danych na podstawie szablonu
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

  // Funkcja pomocnicza do losowania z listy
  String _getRandomFromList(List<dynamic> list) {
    if (list.isEmpty) return 'nieznane';
    return list[_random.nextInt(list.length)].toString();
  }

  // Domyślny szablon w przypadku błędu ładowania
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

  // Symulacja wykrywania dłoni w obrazie (w przyszłości można zastąpić prawdziwym ML)
  Future<bool> detectHandInImage(/* XFile image */) async {
    // Symulacja czasu przetwarzania
    await Future.delayed(const Duration(milliseconds: 800));

    // Zwróć losowy wynik z większą szansą na sukces
    return _random.nextDouble() > 0.3;
  }

  // Symulacja określania typu ręki (lewa/prawa)
  Future<String> determineHandType(/* XFile image */) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _random.nextBool() ? 'left' : 'right';
  }

  // Ocena jakości oświetlenia
  double evaluateLighting(/* XFile image */) {
    // Symulacja oceny oświetlenia
    return 0.3 + (_random.nextDouble() * 0.7);
  }

  // Sprawdzanie pozycji dłoni w ramce
  Map<String, dynamic> checkHandPosition(/* XFile image */) {
    final random = _random.nextDouble();

    if (random > 0.8) {
      return {'isCorrect': true, 'message': 'Pozycja prawidłowa'};
    } else if (random > 0.6) {
      return {'isCorrect': false, 'message': 'Przybliż dłoń do kamery'};
    } else if (random > 0.4) {
      return {'isCorrect': false, 'message': 'Oddal dłoń od kamery'};
    } else if (random > 0.2) {
      return {'isCorrect': false, 'message': 'Wyśrodkuj dłoń w ramce'};
    } else {
      return {'isCorrect': false, 'message': 'Rozłóż palce szerzej'};
    }
  }

  // Sprawdzanie stabilności dłoni
  bool checkHandStability(/* Lista ostatnich pozycji */) {
    // Symulacja sprawdzania stabilności
    return _random.nextDouble() > 0.4;
  }

  Future<bool> checkSkinColor(CameraController controller) async {
    try {
      print('🔍 Sprawdzam kolor skóry...');
      final random = math.Random();
      bool hasSkinColor = random.nextDouble() > 0.4;
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
      final random = math.Random();
      bool isCentered = random.nextDouble() > 0.3;
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
