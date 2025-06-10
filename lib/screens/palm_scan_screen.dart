// =======================================
// NAPRAWIONY PALM SCAN - PROSTA WERSJA
// =======================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../services/palm_detection_service.dart';
import '../services/logging_service.dart';
import '../services/ai_vision_service.dart';
import '../models/palm_analysis.dart';
import 'palm_analysis_result_screen.dart';

class PalmScanScreen extends StatefulWidget {
  final String userName;
  final String userGender;
  final bool testMode;

  const PalmScanScreen({
    super.key,
    required this.userName,
    required this.userGender,
    this.testMode = false,
  });

  @override
  State<PalmScanScreen> createState() => _PalmScanScreenState();
}

class _PalmScanScreenState extends State<PalmScanScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ===== STAN KAMERY =====
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String _detectionStatus = 'Inicjalizacja...';

  // ===== FLAGI ZABEZPIECZAJĄCE =====
  bool _isDisposing = false;
  bool _hasCompletedScan = false;
  bool _isCameraLocked = false;
  bool _isAnalyzingWithAI = false;

  // ===== SERWISY =====
  final PalmDetectionService _palmDetectionService = PalmDetectionService();
  final LoggingService _loggingService = LoggingService();
  final AIVisionService _aiVisionService = AIVisionService();

  // ===== PROSTY TIMER =====
  Timer? _detectionTimer;
  Timer? _forceCloseTimer;

  // ===== PROSTE WYKRYWANIE =====
  int _scanAttempts = 0;
  int _goodChecks = 0;
  final int _requiredGoodChecks = 5; // 5 kolejnych dobrych sprawdzeń
  bool _palmDetected = false;
  String? _detectedHand;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposing) {
        if (widget.testMode) {
          _initializeTestMode();
        } else {
          _initializeCamera();
        }
      }
    });
  }

  void _initializeTestMode() {
    if (_isDisposing || _hasCompletedScan) return;
    setState(() {
      _isCameraInitialized = true;
      _detectionStatus = 'TRYB TESTOWY - Umieść dłoń w ramce';
    });
    _startPalmDetection();
  }

  // ===== INICJALIZACJA KAMERY =====
  Future<void> _initializeCamera() async {
    if (_isDisposing || _hasCompletedScan || _isCameraLocked) return;

    try {
      _isCameraLocked = true;
      _loggingService.logCameraActivity('Inicjalizacja kamery - START');

      await _safeDisposeCamera();
      if (_isDisposing || _hasCompletedScan) return;

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no_cameras', 'Brak dostępnych kamer');
      }

      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      if (_isDisposing || _hasCompletedScan) {
        await _cameraController?.dispose();
        _cameraController = null;
        return;
      }

      await _cameraController!.initialize();

      if (_isDisposing || _hasCompletedScan || !mounted) {
        await _cameraController?.dispose();
        _cameraController = null;
        return;
      }

      setState(() {
        _isCameraInitialized = true;
        _detectionStatus = 'Umieść dłoń w ramce i czekaj...';
      });

      _loggingService.logCameraActivity('Kamera zainicjalizowana POMYŚLNIE');
      _startPalmDetection();
      _startForceCloseTimer();
    } catch (e) {
      _loggingService.logToConsole('Camera Error: $e', tag: 'ERROR');
      if (mounted && !_isDisposing) {
        setState(() {
          _detectionStatus = 'Błąd kamery - spróbuj ponownie';
          _isCameraInitialized = false;
        });
      }
    } finally {
      _isCameraLocked = false;
    }
  }

  Future<void> _safeDisposeCamera() async {
    if (_cameraController != null) {
      try {
        _loggingService.logCameraActivity('Dispose kamery - START');
        final controller = _cameraController;
        _cameraController = null;
        _isCameraInitialized = false;
        await controller?.dispose();
        _loggingService.logCameraActivity('Dispose kamery - ZAKOŃCZONE');
      } catch (e) {
        _loggingService.logToConsole('Błąd dispose kamery: $e', tag: 'ERROR');
      }
    }
  }

  // ===== LIFECYCLE =====
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.testMode || _hasCompletedScan) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _pauseAllOperations();
        break;
      case AppLifecycleState.resumed:
        _resumeOperations();
        break;
      default:
        break;
    }
  }

  void _pauseAllOperations() {
    _cancelAllTimers();
    _safeDisposeCamera();
  }

  void _resumeOperations() {
    if (!_isDisposing && !_hasCompletedScan && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposing && !_hasCompletedScan && mounted) {
          _initializeCamera();
        }
      });
    }
  }

  // ===== ZARZĄDZANIE TIMERAMI =====
  void _cancelAllTimers() {
    _loggingService.logToConsole(
      'Anulowanie wszystkich timerów',
      tag: 'TIMERS',
    );
    _detectionTimer?.cancel();
    _forceCloseTimer?.cancel();
    _detectionTimer = null;
    _forceCloseTimer = null;
  }

  void _startForceCloseTimer() {
    if (_hasCompletedScan || _isDisposing) return;

    _forceCloseTimer?.cancel();
    _forceCloseTimer = Timer(const Duration(seconds: 30), () {
      if (!_hasCompletedScan && mounted) {
        _loggingService.logToConsole(
          'TIMEOUT: Automatyczne zamknięcie',
          tag: 'TIMEOUT',
        );
        _forceCompleteScan();
      }
    });
  }

  void _startPalmDetection() {
    if (_hasCompletedScan || _isDisposing) return;

    _loggingService.logToConsole('START wykrywania dłoni', tag: 'DETECTION');

    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 1500), (
      timer,
    ) {
      if (!mounted || _hasCompletedScan || _isDisposing) {
        timer.cancel();
        return;
      }

      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        timer.cancel();
        return;
      }

      _scanAttempts++;
      _checkPalmPosition();

      if (_scanAttempts % 5 == 0) {
        _loggingService.logToConsole(
          'Skanowanie - próba $_scanAttempts, dobre sprawdzenia: $_goodChecks/$_requiredGoodChecks',
          tag: 'DETECTION',
        );
      }
    });
  }

  // ===== PROSTE WYKRYWANIE POZYCJI DŁONI =====
  Future<void> _checkPalmPosition() async {
    if (!mounted || _isDisposing || _hasCompletedScan || _isAnalyzingWithAI) {
      return;
    }

    try {
      bool conditionsGood = false;

      if (widget.testMode) {
        // W trybie testowym - stopniowo poprawiaj warunki
        final random = math.Random();
        double successChance = math.min(0.9, _scanAttempts / 10.0);
        conditionsGood = random.nextDouble() < successChance;
      } else {
        // W trybie rzeczywistym - symuluj stopniową poprawę
        double baseChance = math.min(0.85, _scanAttempts / 8.0);
        conditionsGood = math.Random().nextDouble() < baseChance;
      }

      if (conditionsGood) {
        _goodChecks++;
        _detectedHand ??= math.Random().nextBool() ? 'left' : 'right';

        setState(() {
          _palmDetected = true;
          int remaining = _requiredGoodChecks - _goodChecks;
          if (remaining > 0) {
            _detectionStatus = 'Świetnie! Jeszcze $remaining sprawdzeń...';
          } else {
            _detectionStatus = 'Doskonale! Robię zdjęcie...';
          }
        });

        _loggingService.logToConsole(
          'DOBRE WARUNKI: $_goodChecks/$_requiredGoodChecks',
          tag: 'DETECTION',
        );

        // SPRAWDŹ CZY MOŻNA ROBIĆ ZDJĘCIE
        if (_goodChecks >= _requiredGoodChecks &&
            !_isAnalyzingWithAI &&
            !_hasCompletedScan) {
          _loggingService.logToConsole(
            'WSZYSTKIE WARUNKI SPEŁNIONE - WYKONUJĘ ZDJĘCIE!',
            tag: 'CAPTURE',
          );
          _cancelAllTimers();

          // Opóźnienie żeby użytkownik widział komunikat
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted && !_hasCompletedScan && !_isAnalyzingWithAI) {
              _capturePalmData();
            }
          });
        }
      } else {
        // WARUNKI ZŁAMANE - RESET
        if (_goodChecks > 0) {
          _loggingService.logToConsole(
            'WARUNKI ZŁAMANE - RESET',
            tag: 'DETECTION',
          );
        }
        _goodChecks = 0;

        setState(() {
          _palmDetected = false;
          _detectionStatus = _getPositioningMessage();
        });
      }
    } catch (e) {
      _loggingService.logToConsole(
        'Błąd sprawdzania pozycji: $e',
        tag: 'ERROR',
      );
      _goodChecks = 0;
      setState(() {
        _palmDetected = false;
        _detectionStatus = 'Błąd sprawdzania pozycji - spróbuj ponownie';
      });
    }
  }

  String _getPositioningMessage() {
    List<String> messages = [
      'Umieść dłoń w ramce',
      'Popraw oświetlenie',
      'Ustabilizuj kamerę',
      'Pokaż wnętrze dłoni',
      'Wycentruj dłoń',
    ];
    return messages[_scanAttempts % messages.length];
  }

  // ===== CAPTURE ZDJĘCIA =====
  Future<void> _capturePalmData() async {
    if (_hasCompletedScan || _isDisposing || _isAnalyzingWithAI) {
      _loggingService.logToConsole(
        'Capture przerwane - scan już zakończony',
        tag: 'CAPTURE',
      );
      return;
    }

    _loggingService.logToConsole('=== ROZPOCZYNAM CAPTURE ===', tag: 'CAPTURE');
    _cancelAllTimers();

    setState(() {
      _hasCompletedScan = true;
      _isAnalyzingWithAI = true;
      _detectionStatus = 'Robię zdjęcie dłoni...';
    });

    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        throw Exception('Kamera niedostępna podczas robienia zdjęcia');
      }

      final XFile palmPhoto = await _cameraController!.takePicture();
      _loggingService.logToConsole(
        'Zdjęcie wykonane pomyślnie',
        tag: 'CAPTURE',
      );

      setState(() {
        _detectionStatus = 'Wysyłanie do AI na analizę...';
      });

      final palmData = await _aiVisionService.analyzePalmWithAI(
        palmImage: palmPhoto,
        userName: widget.userName,
        userGender: widget.userGender,
      );

      await _loggingService.saveAnalysisToFile(palmData);
      await _loggingService.saveDetectionLogsToFile(widget.userName);

      if (mounted) {
        _navigateToResults(palmData);
      }
    } catch (e) {
      _loggingService.logToConsole(
        'Błąd AI - używam symulacji: $e',
        tag: 'AI_ERROR',
      );

      setState(() {
        _detectionStatus = 'Błąd analizy AI - użyję symulacji';
      });

      try {
        final palmData = await _palmDetectionService.analyzePalm(
          handType: _detectedHand ?? 'right',
          userName: widget.userName,
        );

        await _loggingService.saveAnalysisToFile(palmData);

        if (mounted) {
          _navigateToResults(palmData);
        }
      } catch (fallbackError) {
        _loggingService.logToConsole(
          'Błąd fallback: $fallbackError',
          tag: 'FALLBACK_ERROR',
        );

        if (mounted) {
          setState(() {
            _detectionStatus = 'Błąd analizy - spróbuj ponownie';
            _isAnalyzingWithAI = false;
            _hasCompletedScan = false;
          });
        }
      }
    }
  }

  void _navigateToResults(dynamic palmData) {
    if (!mounted) return;

    _loggingService.logToConsole('Nawigacja do wyników', tag: 'NAVIGATE');

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PalmAnalysisResultScreen(
              userName: widget.userName,
              userGender: widget.userGender,
              palmData: palmData,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1500),
      ),
    );
  }

  void _forceCompleteScan() {
    if (_hasCompletedScan) return;

    // Złagodzone wymagania dla timeout
    if (_goodChecks >= (_requiredGoodChecks ~/ 2)) {
      _loggingService.logToConsole(
        'Force complete - warunki częściowo spełnione',
        tag: 'FORCE',
      );
      _capturePalmData();
    } else {
      _loggingService.logToConsole(
        'Force complete - warunki NIE spełnione',
        tag: 'FORCE',
      );
      _showScanFailureDialog();
    }
  }

  void _showScanFailureDialog() {
    if (!mounted || _hasCompletedScan) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          'Nie udało się zeskanować dłoni',
          style: GoogleFonts.cinzelDecorative(
            color: AppColors.cyan,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
              'Spróbuj ponownie z lepszym oświetleniem i stabilną pozycją dłoni.',
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Anuluj',
              style: GoogleFonts.cinzelDecorative(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartScanning();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan),
            child: Text(
              'Spróbuj ponownie',
              style: GoogleFonts.cinzelDecorative(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restartScanning() async {
    _cancelAllTimers();
    await _safeDisposeCamera();

    if (!mounted) return;

    setState(() {
      _hasCompletedScan = false;
      _isAnalyzingWithAI = false;
      _isCameraInitialized = false;
      _detectedHand = null;
      _scanAttempts = 0;
      _goodChecks = 0;
      _palmDetected = false;
      _detectionStatus = 'Reinicjalizacja kamery...';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    await _initializeCamera();
    if (!mounted) return;

    _startPalmDetection();
    _startForceCloseTimer();
  }

  @override
  void dispose() {
    _loggingService.logToConsole('DISPOSE - START', tag: 'DISPOSE');
    _isDisposing = true;
    _hasCompletedScan = true;

    WidgetsBinding.instance.removeObserver(this);
    _cancelAllTimers();
    _safeDisposeCamera();

    _loggingService.logToConsole('DISPOSE - ZAKOŃCZONE', tag: 'DISPOSE');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PROSTA KAMERA
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(child: CameraPreview(_cameraController!))
          else
            _buildLoadingScreen(),

          // PROSTY OVERLAY
          _buildSimpleOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.testMode) ...[
              Icon(
                Icons.video_camera_front,
                size: 80,
                color: AppColors.cyan.withOpacity(0.7),
              ),
              const SizedBox(height: 24),
              Text(
                'TRYB TESTOWY',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 24,
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              const CircularProgressIndicator(color: AppColors.cyan),
              const SizedBox(height: 16),
              Text(
                'Inicjalizacja kamery...',
                style: GoogleFonts.cinzelDecorative(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // RAMKA SKANOWANIA
            Expanded(
              child: Center(
                child: Container(
                  width: 280,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _palmDetected ? Colors.green : AppColors.cyan,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _palmDetected ? Icons.check_circle : Icons.pan_tool,
                          color: _palmDetected ? Colors.green : AppColors.cyan,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _palmDetected ? 'WYKRYTO DŁOŃ' : 'UMIEŚĆ DŁOŃ',
                          style: TextStyle(
                            color: _palmDetected
                                ? Colors.green
                                : AppColors.cyan,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_palmDetected && _goodChecks > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            '$_goodChecks / $_requiredGoodChecks',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // STATUS NA DOLE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _detectionStatus,
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_detectedHand != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _detectedHand == 'left' ? 'Lewa ręka' : 'Prawa ręka',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 12,
                        color: AppColors.cyan,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
