// lib/utils/app_config.dart
// Konfiguracja aplikacji

class AppConfig {
  // API endpoints
  static const String baseUrl = 'https://api.openai.com/v1';
  static const String palmAnalysisEndpoint = '/chat/completions';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration cameraTimeout = Duration(seconds: 30);

  // Camera settings
  static const int maxScanAttempts = 20;
  static const int requiredStabilityFrames = 15;
  static const int requiredGoodStreak = 10;
  static const double minLightLevel = 0.3;

  // File paths
  static const String logsDirectory = 'ai_wrozka_logs';
  static const String analysisFileName = 'palm_analysis.json';
  static const String detectionLogsFileName = 'detection_logs.txt';

  // App info
  static const String appName = 'AI Wróżka';
  static const String appVersion = '1.0.0';

  // Animation durations (milliseconds)
  static const int animationFast = 150;
  static const int animationMedium = 300;
  static const int animationSlow = 500;
}
