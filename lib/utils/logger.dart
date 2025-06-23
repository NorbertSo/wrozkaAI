// =============================================================================
// lib/utils/logger.dart
// Bezpieczny system logowania (bez wrażliwych danych w produkcji)

import 'package:flutter/foundation.dart';

class Logger {
  static bool _isDebugMode = kDebugMode;

  /// Ustaw tryb debugowania
  static void setDebugMode(bool debug) {
    _isDebugMode = debug;
  }

  /// Log informacyjny (tylko w debug)
  static void info(String message) {
    if (_isDebugMode) {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  /// Log błędów (zawsze, ale bez wrażliwych danych)
  static void error(String message) {
    final sanitizedMessage = _sanitizeMessage(message);
    if (_isDebugMode) {
      debugPrint('❌ ERROR: $sanitizedMessage');
    } else {
      // W produkcji loguj tylko ogólne błędy
      debugPrint('❌ ERROR: Wystąpił błąd aplikacji');
    }
  }

  /// Log ostrzeżeń (tylko w debug)
  static void warning(String message) {
    if (_isDebugMode) {
      debugPrint('⚠️ WARNING: $message');
    }
  }

  /// Log sukcesu (tylko w debug)
  static void success(String message) {
    if (_isDebugMode) {
      debugPrint('✅ SUCCESS: $message');
    }
  }

  /// Usuń wrażliwe dane z wiadomości log
  static String _sanitizeMessage(String message) {
    // Lista słów kluczowych do usunięcia/zastąpienia
    final sensitivePatterns = [
      RegExp(r'\b\d{4}-\d{2}-\d{2}\b'), // Daty
      RegExp(r'\b[A-Z][a-z]+\s+[A-Z][a-z]+\b'), // Imiona i nazwiska
      RegExp(r'\b\d{2}:\d{2}\b'), // Godziny
      RegExp(r'\bkey[_\s]*[:=][^,\s]+', caseSensitive: false), // API keys
      RegExp(r'\btoken[_\s]*[:=][^,\s]+', caseSensitive: false), // Tokeny
    ];

    String sanitized = message;
    for (final pattern in sensitivePatterns) {
      sanitized = sanitized.replaceAll(pattern, '[REDACTED]');
    }

    return sanitized;
  }

  /// Log tylko w trybie debug z pełnymi szczegółami
  static void debug(String message) {
    assert(() {
      debugPrint('🐛 DEBUG: $message');
      return true;
    }());
  }
}
