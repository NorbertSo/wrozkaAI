// lib/services/fortune_history_service.dart
// Serwis do zarządzania historią wróżb

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fortune_history.dart';

// ✅ POPRAWKA: Użyjemy prostszej klasy wyników
class SimplePalmAnalysisResult {
  final bool isSuccess;
  final String analysisText;
  final String? handType;
  final String? errorMessage;

  SimplePalmAnalysisResult({
    required this.isSuccess,
    required this.analysisText,
    this.handType,
    this.errorMessage,
  });
}

class FortuneHistoryService {
  static const String _historyKey = 'fortune_history';
  static const int _maxHistoryItems = 5;

  /// Zapisz nową wróżbę do historii
  Future<void> saveFortune(FortuneHistory fortune) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<FortuneHistory> history = await getFortuneHistory();
      
      // Dodaj nową wróżbę na początek listy
      history.insert(0, fortune);
      
      // Ogranicz do maksymalnie 5 elementów
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }
      
      // Konwertuj do JSON i zapisz
      final historyJson = history.map((item) => item.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(historyJson));
      
      print('✅ Wróżba zapisana do historii: ${fortune.userName}');
    } catch (e) {
      print('❌ Błąd zapisywania historii: $e');
    }
  }

  /// Pobierz historię wróżb
  Future<List<FortuneHistory>> getFortuneHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> decoded = jsonDecode(historyJson);
      return decoded
          .map((item) => FortuneHistory.fromJson(item))
          .toList();
    } catch (e) {
      print('❌ Błąd odczytu historii: $e');
      return [];
    }
  }

  /// Usuń konkretną wróżbę z historii
  Future<void> deleteFortune(String fortuneId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<FortuneHistory> history = await getFortuneHistory();
      
      history.removeWhere((item) => item.id == fortuneId);
      
      final historyJson = history.map((item) => item.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(historyJson));
      
      print('✅ Wróżba usunięta z historii: $fortuneId');
    } catch (e) {
      print('❌ Błąd usuwania z historii: $e');
    }
  }

  /// Wyczyść całą historię
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      print('✅ Historia wróżb wyczyszczona');
    } catch (e) {
      print('❌ Błąd czyszczenia historii: $e');
    }
  }

  /// Sprawdź czy historia ma jakieś elementy
  Future<bool> hasHistory() async {
    final history = await getFortuneHistory();
    return history.isNotEmpty;
  }

  /// Pobierz licznik wróżb
  Future<int> getFortuneCount() async {
    final history = await getFortuneHistory();
    return history.length;
  }

  /// Pobierz ostatnią wróżbę
  Future<FortuneHistory?> getLastFortune() async {
    final history = await getFortuneHistory();
    return history.isNotEmpty ? history.first : null;
  }

  /// Zapisz wróżbę z wyników analizy AI - UNIWERSALNA METODA
  Future<void> saveFortuneFromAnalysis(
    dynamic analysisResult, // ✅ Przyjmuje dowolny typ
    String userName,
    String userGender,
  ) async {
    try {
      // ✅ POPRAWKA: Sprawdź różne typy wyników
      bool isSuccess = false;
      String analysisText = '';
      String handType = 'unknown';

      // Sprawdź czy to wynik z Twojego AI serwisu
      if (analysisResult != null) {
        // Spróbuj różne sposoby dostępu do danych
        if (analysisResult.runtimeType.toString().contains('PalmAnalysisResult')) {
          // Twój typ z ai_palm_analysis_service
          isSuccess = analysisResult.isSuccess ?? false;
          analysisText = analysisResult.analysisText ?? '';
          handType = analysisResult.handType ?? 'unknown';
        } else if (analysisResult is Map) {
          // Jeśli to mapa
          isSuccess = analysisResult['isSuccess'] ?? false;
          analysisText = analysisResult['analysisText'] ?? '';
          handType = analysisResult['handType'] ?? 'unknown';
        } else {
          // Fallback - spróbuj przez reflection
          try {
            isSuccess = analysisResult.isSuccess ?? false;
            analysisText = analysisResult.analysisText ?? '';
            handType = analysisResult.handType ?? 'unknown';
          } catch (e) {
            print('❌ Nie można odczytać danych z analysisResult: $e');
            return;
          }
        }
      }

      if (!isSuccess || analysisText.isEmpty) {
        print('❌ Analiza nie powiodła się lub brak tekstu');
        return;
      }

      final fortune = FortuneHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userName: userName,
        userGender: userGender,
        fortuneText: analysisText,
        handType: handType,
        createdAt: DateTime.now(),
        photoPath: null, // Opcjonalne zdjęcie
        metadata: {'source': 'ai_analysis'}, // Dodatkowe dane
      );

      await saveFortune(fortune);
      print('✅ Wróżba zapisana z analizy AI');
    } catch (e) {
      print('❌ Błąd zapisywania z analizy: $e');
    }
  }

  /// Debug: Wyświetl całą historię w konsoli
  Future<void> debugPrintHistory() async {
    final history = await getFortuneHistory();
    print('📜 Historia wróżb (${history.length} elementów):');
    
    for (int i = 0; i < history.length; i++) {
      final item = history[i];
      print('${i + 1}. ${item.userName} - ${item.createdAt}');
      print('   Typ ręki: ${item.handType}');
      print('');
    }
  }
}