// lib/services/firebase_remote_config_service.dart
// 🔑 BEZPIECZNE ZARZĄDZANIE KONFIGURACJĄ - zgodne z wytycznymi projektu

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'logging_service.dart';

class FirebaseRemoteConfigService {
  static final FirebaseRemoteConfigService _instance =
      FirebaseRemoteConfigService._internal();
  factory FirebaseRemoteConfigService() => _instance;
  FirebaseRemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _isInitialized = false;

  // 🔑 KLUCZE KONFIGURACJI
  static const String _geminiApiKeyParam = 'gemini_api_key';
  static const String _geminiApiUrlParam = 'gemini_api_url';
  static const String _enableAiFallbackParam = 'enable_ai_fallback';

  // 📝 LOGGING SERVICE
  final LoggingService _logger = LoggingService();

  // 🛡️ WARTOŚCI DOMYŚLNE (fallback)
  static const Map<String, dynamic> _defaultValues = {
    _geminiApiKeyParam: '', // PUSTE - wymusza użycie Remote Config
    _geminiApiUrlParam:
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent',
    _enableAiFallbackParam: true,
  };

  /// 🚀 INICJALIZACJA Remote Config
  Future<bool> initialize() async {
    if (_isInitialized) {
      _logger.logToConsole('Remote Config już zainicjalizowany',
          tag: 'FIREBASE');
      return true;
    }

    try {
      _logger.logToConsole('Inicjalizacja Firebase Remote Config...',
          tag: 'FIREBASE');

      _remoteConfig = FirebaseRemoteConfig.instance;

      // Ustaw wartości domyślne
      await _remoteConfig!.setDefaults(_defaultValues);

      // Konfiguracja ustawień
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 1), // Dla developmentu
      ));

      // Pobierz konfigurację z serwera
      await _fetchAndActivate();

      _isInitialized = true;
      _logger.logToConsole('✅ Remote Config zainicjalizowany pomyślnie',
          tag: 'FIREBASE');
      return true;
    } catch (e) {
      _logger.logToConsole('❌ Błąd inicjalizacji Remote Config: $e',
          tag: 'ERROR');
      return false;
    }
  }

  /// 📥 POBIERZ I AKTYWUJ KONFIGURACJĘ
  Future<bool> _fetchAndActivate() async {
    try {
      _logger.logToConsole('Pobieranie konfiguracji z Firebase...',
          tag: 'FIREBASE');

      bool updated = await _remoteConfig!.fetchAndActivate();

      if (updated) {
        _logger.logToConsole('✅ Konfiguracja zaktualizowana z serwera',
            tag: 'FIREBASE');
      } else {
        _logger.logToConsole('📋 Używam cache\'owanej konfiguracji',
            tag: 'FIREBASE');
      }

      return true;
    } catch (e) {
      _logger.logToConsole('❌ Błąd pobierania konfiguracji: $e', tag: 'ERROR');
      // Nie rzucaj błędu - użyj wartości domyślnych
      return false;
    }
  }

  /// 🔄 ODŚWIEŻ KONFIGURACJĘ RĘCZNIE
  Future<bool> refreshConfig() async {
    if (!_isInitialized) {
      _logger.logToConsole('Remote Config nie jest zainicjalizowany',
          tag: 'WARNING');
      return false;
    }

    try {
      _logger.logToConsole('Odświeżanie konfiguracji...', tag: 'FIREBASE');
      await _fetchAndActivate();
      return true;
    } catch (e) {
      _logger.logToConsole('❌ Błąd odświeżania konfiguracji: $e', tag: 'ERROR');
      return false;
    }
  }

  // 🔑 POBIERANIE WARTOŚCI KONFIGURACJI

  /// Pobierz klucz API Gemini
  String get geminiApiKey {
    if (!_isInitialized || _remoteConfig == null) {
      _logger.logToConsole(
          'Remote Config nie zainicjalizowany - używam pustego klucza',
          tag: 'WARNING');
      return '';
    }

    final key = _remoteConfig!.getString(_geminiApiKeyParam);

    if (key.isEmpty) {
      _logger.logToConsole('⚠️ Brak klucza Gemini API w Remote Config',
          tag: 'WARNING');
    }

    return key;
  }

  /// Pobierz URL API Gemini
  String get geminiApiUrl {
    if (!_isInitialized || _remoteConfig == null) {
      return _defaultValues[_geminiApiUrlParam] as String;
    }

    return _remoteConfig!.getString(_geminiApiUrlParam);
  }

  /// Czy włączony fallback AI
  bool get isAiFallbackEnabled {
    if (!_isInitialized || _remoteConfig == null) {
      return _defaultValues[_enableAiFallbackParam] as bool;
    }

    return _remoteConfig!.getBool(_enableAiFallbackParam);
  }

  /// 🔍 DEBUG - wyświetl wszystkie wartości
  void debugPrintConfig() {
    if (!_isInitialized) {
      _logger.logToConsole('Remote Config nie zainicjalizowany',
          tag: 'WARNING');
      return;
    }

    _logger.logToConsole('🔧 REMOTE CONFIG DEBUG:', tag: 'CONFIG');
    _logger.logToConsole(
        '  Gemini API Key: ${geminiApiKey.isNotEmpty ? "***UKRYTY***" : "PUSTY"}',
        tag: 'CONFIG');
    _logger.logToConsole('  Gemini API URL: $geminiApiUrl', tag: 'CONFIG');
    _logger.logToConsole('  AI Fallback: $isAiFallbackEnabled', tag: 'CONFIG');
  }

  /// 🧪 SPRAWDŹ CZY KONFIGURACJA JEST GOTOWA
  bool get isConfigReady {
    return _isInitialized && _remoteConfig != null && geminiApiKey.isNotEmpty;
  }

  /// 📊 STATUS POŁĄCZENIA
  RemoteConfigFetchStatus get lastFetchStatus {
    return _remoteConfig?.lastFetchStatus ?? RemoteConfigFetchStatus.noFetchYet;
  }

  /// 🕐 OSTATNIA UDANA AKTUALIZACJA
  DateTime? get lastFetchTime {
    return _remoteConfig?.lastFetchTime;
  }
}
