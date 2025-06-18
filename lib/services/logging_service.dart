import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/palm_analysis.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  // ✅ DODAJ FLAGĘ DEBUG
  static const bool _enableDetailedLogging = false; // Ustaw na false w produkcji

  // Logowanie do konsoli z timestampem
  void logToConsole(String message, {String? tag}) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] ${tag != null ? '[$tag] ' : ''}$message';
    print(logMessage);
  }

  // Logowanie szczegółów skanowania
  void logScanningDetails({
    required bool palmDetected,
    required String detectionStatus,
    required double lightLevel,
    String? detectedHand,
    Map<String, dynamic>? additionalData,
  }) {
    logToConsole('=== SKANOWANIE DŁONI ===', tag: 'SCAN');
    logToConsole('Dłoń wykryta: $palmDetected', tag: 'SCAN');
    logToConsole('Status: $detectionStatus', tag: 'SCAN');
    logToConsole('Poziom światła: ${(lightLevel * 100).toInt()}%', tag: 'SCAN');

    if (detectedHand != null) {
      logToConsole(
        'Wykryta ręka: ${detectedHand == "left" ? "LEWA" : "PRAWA"}',
        tag: 'SCAN',
      );
    }

    if (additionalData != null) {
      additionalData.forEach((key, value) {
        logToConsole('$key: $value', tag: 'SCAN');
      });
    }

    logToConsole('========================', tag: 'SCAN');
  }

  // Zapisz pełną analizę dłoni do pliku
  Future<void> saveAnalysisToFile(PalmAnalysis analysis) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'palm_analysis_${analysis.userName}_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');

      final jsonData = {
        'timestamp': DateTime.now().toIso8601String(),
        'analysis': analysis.toJson(),
        'aiPrompt': analysis.toAIPrompt(),
      };

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonData),
      );

      logToConsole('Analiza zapisana: ${file.path}', tag: 'FILE');
      
      // ✅ POPRAWKA: Logowanie szczegółów tylko w trybie debug
      if (_enableDetailedLogging) {
        logToConsole('=== PEŁNA ANALIZA DŁONI ===', tag: 'ANALYSIS');
        logToConsole('Użytkownik: ${analysis.userName}', tag: 'ANALYSIS');
        logToConsole('Typ ręki: ${analysis.handType}', tag: 'ANALYSIS');
        logToConsole('Data analizy: ${analysis.analysisDate}', tag: 'ANALYSIS');
        logToConsole('', tag: 'ANALYSIS');

        _logHandShapeDetails(analysis.handShape);
        _logFingersDetails(analysis.fingers);
        _logLinesDetails(analysis.lines);
        _logMountsDetails(analysis.mounts);
        _logSkinDetails(analysis.skin, analysis.paznokcie);

        logToConsole('=== PROMPT DLA AI ===', tag: 'AI-PROMPT');
        logToConsole(analysis.toAIPrompt(), tag: 'AI-PROMPT');
        logToConsole('==================', tag: 'AI-PROMPT');
      } else {
        // W trybie produkcyjnym tylko podstawowe info
        logToConsole('Analiza dłoni zapisana pomyślnie', tag: 'ANALYSIS');
      }
    } catch (e) {
      logToConsole('Błąd zapisywania analizy: $e', tag: 'ERROR');
    }
  }

  void _logHandShapeDetails(HandShape handShape) {
    if (!_enableDetailedLogging) return;
    logToConsole('--- KSZTAŁT DŁONI ---', tag: 'ANALYSIS');
    logToConsole('Rozmiar: ${handShape.size}', tag: 'ANALYSIS');
    logToConsole('Forma: ${handShape.form}', tag: 'ANALYSIS');
    logToConsole('Element: ${handShape.elementType}', tag: 'ANALYSIS');
  }

  void _logFingersDetails(Fingers fingers) {
    if (!_enableDetailedLogging) return;
    logToConsole('--- PALCE ---', tag: 'ANALYSIS');
    logToConsole('Długość: ${fingers.length}', tag: 'ANALYSIS');
    logToConsole('Elastyczność: ${fingers.flexibility}', tag: 'ANALYSIS');
    logToConsole(
      'Palec wskazujący: ${fingers.palecWskazujacy}',
      tag: 'ANALYSIS',
    );
    logToConsole('Palec serdeczny: ${fingers.palecSerdeczny}', tag: 'ANALYSIS');
    logToConsole(
      'Kciuk - typ: ${fingers.kciuk.typ}, ustawienie: ${fingers.kciuk.ustawienie}',
      tag: 'ANALYSIS',
    );
  }

  void _logLinesDetails(PalmLines lines) {
    if (!_enableDetailedLogging) return;
    logToConsole('--- LINIE DŁONI ---', tag: 'ANALYSIS');
    logToConsole(
      'Linia życia: ${lines.lifeLine.dlugosc}, ${lines.lifeLine.ksztalt}',
      tag: 'ANALYSIS',
    );
    logToConsole(
      'Linia głowy: ${lines.headLine.dlugosc}, ${lines.headLine.ksztalt}',
      tag: 'ANALYSIS',
    );
    logToConsole(
      'Linia serca: ${lines.heartLine.dlugosc}, ${lines.heartLine.ksztalt}',
      tag: 'ANALYSIS',
    );
    logToConsole('Linia losu: ${lines.fateLine.obecnosc}', tag: 'ANALYSIS');
    logToConsole('Linia słońca: ${lines.sunLine.obecnosc}', tag: 'ANALYSIS');
    logToConsole(
      'Linie małżeństwa: ${lines.marriageLines.ilosc}',
      tag: 'ANALYSIS',
    );
    logToConsole('Linie dzieci: ${lines.childrenLines.ilosc}', tag: 'ANALYSIS');
  }

  void _logMountsDetails(Mounts mounts) {
    if (!_enableDetailedLogging) return;
    logToConsole('--- WZGÓRKI ---', tag: 'ANALYSIS');
    logToConsole('Jowisza: ${mounts.mountOfJupiter}', tag: 'ANALYSIS');
    logToConsole('Saturna: ${mounts.mountOfSaturne}', tag: 'ANALYSIS');
    logToConsole('Apollina: ${mounts.mountOfApollo}', tag: 'ANALYSIS');
    logToConsole('Merkurego: ${mounts.mountOfMercury}', tag: 'ANALYSIS');
    logToConsole('Wenus: ${mounts.mountOfVenus}', tag: 'ANALYSIS');
    logToConsole('Mars górny: ${mounts.mountOfMarsUpper}', tag: 'ANALYSIS');
    logToConsole('Mars dolny: ${mounts.mountOfMarsLower}', tag: 'ANALYSIS');
    logToConsole('Księżyc: ${mounts.mountOfMoon}', tag: 'ANALYSIS');
  }

  void _logSkinDetails(SkinCharacteristics skin, Nails nails) {
    if (!_enableDetailedLogging) return;
    logToConsole('--- SKÓRA I PAZNOKCIE ---', tag: 'ANALYSIS');
    logToConsole('Tekstura skóry: ${skin.tekstura}', tag: 'ANALYSIS');
    logToConsole('Wilgotność: ${skin.wilgotnosc}', tag: 'ANALYSIS');
    logToConsole('Kolor skóry: ${skin.kolor}', tag: 'ANALYSIS');
    logToConsole(
      'Paznokcie - długość: ${nails.dlugosc}, kształt: ${nails.ksztalt}, kolor: ${nails.kolor}',
      tag: 'ANALYSIS',
    );
  }

  // Logowanie aktywności kamery
  void logCameraActivity(String activity, {Map<String, dynamic>? details}) {
    logToConsole('=== KAMERA ===', tag: 'CAMERA');
    logToConsole('Aktywność: $activity', tag: 'CAMERA');

    if (details != null) {
      details.forEach((key, value) {
        logToConsole('$key: $value', tag: 'CAMERA');
      });
    }

    logToConsole('==============', tag: 'CAMERA');
  }

  // Zapisz logi wykrywania do pliku
  Future<void> saveDetectionLogsToFile(String userName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'detection_logs_${userName}_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/$fileName');

      final logs =
          '''
LOGI WYKRYWANIA DŁONI
====================
Użytkownik: $userName
Data: ${DateTime.now()}
Aplikacja: AI Wróżka - Analiza Dłoni

UWAGA: To są logi testowe systemu wykrywania.
W pełnej wersji tutaj będą rzeczywiste dane z ML/AI.

Status kamery: Aktywna
Algorytm wykrywania: Symulacja (do zastąpienia ML)
Rozpoznawanie ręki: Losowe (do zastąpienia Computer Vision)

Następne kroki:
1. Integracja z MediaPipe lub TensorFlow Lite
2. Model ML do klasyfikacji lewej/prawej ręki
3. Analiza jakości obrazu i pozycjonowania
4. Ekstrakcja cech dłoni z obrazu

==========================================
''';

      await file.writeAsString(logs);
      logToConsole('Logi wykrywania zapisane: ${file.path}', tag: 'FILE');
    } catch (e) {
      logToConsole('Błąd zapisywania logów: $e', tag: 'ERROR');
    }
  }

  // Sprawdź ścieżkę zapisywania plików
  Future<void> logFileLocation() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      logToConsole('=== LOKALIZACJA PLIKÓW ===', tag: 'FILE');
      logToConsole('Ścieżka: ${directory.path}', tag: 'FILE');
      logToConsole('Pliki będą zapisane w tej lokalizacji', tag: 'FILE');
      logToConsole('==========================', tag: 'FILE');
    } catch (e) {
      logToConsole('Błąd odczytu ścieżki: $e', tag: 'ERROR');
    }
  }
}
