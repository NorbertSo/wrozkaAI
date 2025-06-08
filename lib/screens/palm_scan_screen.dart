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
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  bool _palmDetected = false;
  String _detectionStatus = 'Pozycjonowanie kamery...';
  String? _detectedHand; // 'left' lub 'right'
  double _lightLevel = 0.5;

  // Animacje
  late AnimationController _scanController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  // Serwisy
  final PalmDetectionService _palmDetectionService = PalmDetectionService();
  final LoggingService _loggingService = LoggingService();
  final AIVisionService _aiVisionService = AIVisionService(); // DODANE AI!

  // Timer dla wykrywania
  Timer? _detectionTimer;
  Timer? _forceCloseTimer;
  int _scanAttempts = 0;
  final int _maxScanAttempts = 20; // 10 sekund przy 500ms interwałach

  // Stan AI analizy
  bool _isAnalyzingWithAI = false;

  // Nowe zmienne dla ulepszonego skanowania
  int _countdownSeconds = 5;
  bool _isStable = false;
  bool _hasGoodLighting = false;
  bool _hasPalmColor = false;
  bool _isCentered = false;

  // Timer dla odliczania
  Timer? _countdownTimer;

  // Stan pozycji dłoni
  double _lastBrightnessValue = 0;
  int _stabilityCounter = 0;
  final int _requiredStabilityFrames =
      15; // 1.5 sekundy stabilności przy 100ms interwałach

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    if (widget.testMode) {
      _initializeTestMode();
    } else {
      _initializeCamera();
    }
  }

  void _initializeTestMode() {
    setState(() {
      _isCameraInitialized = true;
      _detectionStatus = 'TRYB TESTOWY - Symulacja skanowania';
    });
    _startPalmDetection();
  }

  void _initializeAnimations() {
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scanController, curve: Curves.linear));

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _loggingService.logCameraActivity('Inicjalizacja kamery');

      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0], // Użyj tylnej kamery
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        setState(() {
          _isCameraInitialized = true;
          _detectionStatus = 'Umieść dłoń w ramce';
        });

        _loggingService.logCameraActivity(
          'Kamera zainicjalizowana',
          details: {
            'Rozdzielczość': 'High',
            'Kamera': 'Tylna',
            'Audio': 'Wyłączone',
          },
        );

        await _loggingService.logFileLocation();
        _startPalmDetection();
        _startForceCloseTimer();
      }
    } catch (e) {
      _loggingService.logToConsole(
        'Błąd inicjalizacji kamery: $e',
        tag: 'ERROR',
      );
      setState(() {
        _detectionStatus = 'Błąd inicjalizacji kamery';
      });
    }
  }

  void _startForceCloseTimer() {
    // Automatyczne zamknięcie kamery po 30 sekundach
    _forceCloseTimer = Timer(const Duration(seconds: 30), () {
      _loggingService.logToConsole(
        'TIMEOUT: Automatyczne zamknięcie kamery po 30 sekundach',
        tag: 'CAMERA',
      );
      _forceCompleteScan();
    });
  }

  void _startPalmDetection() {
    _loggingService.logToConsole(
      'Rozpoczęcie wykrywania dłoni',
      tag: 'DETECTION',
    );

    _detectionTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (!mounted ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized) {
        timer.cancel();
        return;
      }

      _scanAttempts++;
      _checkPalmPosition();

      // Automatyczne zakończenie po maksymalnej liczbie prób
      if (_scanAttempts >= _maxScanAttempts) {
        _loggingService.logToConsole(
          'Osiągnięto maksymalną liczbę prób skanowania: $_scanAttempts',
          tag: 'DETECTION',
        );
        timer.cancel();
        _forceCompleteScan();
      }
    });
  }

  void _forceCompleteScan() {
    _loggingService.logToConsole(
      'Timeout skanowania - sprawdzam czy można zakończyć',
      tag: 'SCAN',
    );

    bool canComplete =
        _palmDetected &&
        _hasGoodLighting &&
        _isStable &&
        _hasPalmColor &&
        _isCentered;

    if (canComplete) {
      _loggingService.logToConsole(
        'Dłoń wykryta w ostatniej chwili - kończę skanowanie',
        tag: 'SCAN',
      );

      setState(() {
        _detectionStatus = 'Skanowanie zakończone - dłoń wykryta';
      });

      _loggingService.logScanningDetails(
        palmDetected: true,
        detectionStatus: 'Skanowanie zakończone - sukces w ostatniej chwili',
        lightLevel: _lightLevel,
        detectedHand: _detectedHand,
        additionalData: {
          'Próby skanowania': _scanAttempts,
          'Powód zakończenia': 'Timeout ale dłoń wykryta',
          'Ostatnie sprawdzenie': 'Pozytywne',
        },
      );

      Future.delayed(const Duration(seconds: 1), () {
        _capturePalmData();
      });
    } else {
      _loggingService.logToConsole(
        'Timeout - dłoń nie została poprawnie wykryta, przerywam skanowanie',
        tag: 'SCAN',
      );

      setState(() {
        _palmDetected = false;
        _detectionStatus = 'Nie udało się wykryć dłoni w odpowiedniej pozycji';
      });

      _loggingService.logScanningDetails(
        palmDetected: false,
        detectionStatus: 'Timeout - skanowanie nieudane',
        lightLevel: _lightLevel,
        additionalData: {
          'Próby skanowania': _scanAttempts,
          'Powód zakończenia': 'Timeout bez wykrycia dłoni',
          'Ostatnie warunki': {
            'Oświetlenie': _hasGoodLighting ? 'OK' : 'Złe',
            'Stabilność': _isStable ? 'OK' : 'Ruch',
            'Kolor skóry': _hasPalmColor ? 'OK' : 'Nie wykryto',
            'Pozycja': _isCentered ? 'OK' : 'Źle wycentrowana',
          },
        },
      );

      _showScanFailureDialog();
    }
  }

  void _showScanFailureDialog() {
    if (!mounted) return;

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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _buildFailureReason('Oświetlenie', _hasGoodLighting),
                  _buildFailureReason('Stabilność', _isStable),
                  _buildFailureReason('Pozycja dłoni', _isCentered),
                  _buildFailureReason('Wewnętrzna strona', _hasPalmColor),
                ],
              ),
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

  Widget _buildFailureReason(String label, bool isOk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.cancel,
            color: isOk ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.cinzelDecorative(
              color: isOk ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _restartScanning() {
    _loggingService.logToConsole(
      'Restart skanowania przez użytkownika',
      tag: 'SCAN',
    );

    setState(() {
      _isDetecting = false;
      _palmDetected = false;
      _detectionStatus = 'Umieść dłoń w ramce';
      _detectedHand = null;
      _lightLevel = 0.5;
      _countdownSeconds = 5;
      _isStable = false;
      _hasGoodLighting = false;
      _hasPalmColor = false;
      _isCentered = false;
      _stabilityCounter = 0;
      _scanAttempts = 0;
    });

    _detectionTimer?.cancel();
    _forceCloseTimer?.cancel();
    _countdownTimer?.cancel();

    _startPalmDetection();
    _startForceCloseTimer();
  }

  bool _canTakePicture() {
    bool allConditionsMet =
        _palmDetected &&
        _hasGoodLighting &&
        _isStable &&
        _stabilityCounter >= _requiredStabilityFrames &&
        _hasPalmColor &&
        _isCentered;

    _loggingService.logToConsole(
      'Sprawdzanie czy można robić zdjęcie: $allConditionsMet',
      tag: 'VALIDATION',
    );

    _loggingService.logToConsole(
      'Warunki: dłoń=$_palmDetected, światło=$_hasGoodLighting, stabilność=$_isStable, licznik=$_stabilityCounter/$_requiredStabilityFrames, kolor=$_hasPalmColor, pozycja=$_isCentered',
      tag: 'VALIDATION',
    );

    return allConditionsMet;
  }

  void _capturePalmData() async {
    if (!_canTakePicture()) {
      _loggingService.logToConsole(
        'BLOKADA: Warunki nie są spełnione, nie robię zdjęcia!',
        tag: 'CAPTURE',
      );

      setState(() {
        _detectionStatus = 'Warunki nie spełnione - nie można zrobić zdjęcia';
      });

      return;
    }

    setState(() {
      _isAnalyzingWithAI = true;
      _detectionStatus = 'Robię zdjęcie dłoni...';
    });

    _loggingService.logToConsole(
      '=== ROZPOCZĘCIE PRAWDZIWEJ ANALIZY DŁONI ===',
      tag: 'CAPTURE',
    );

    try {
      // 1. Zrób PRAWDZIWE zdjęcie dłoni
      final XFile palmPhoto = await _cameraController!.takePicture();
      _loggingService.logToConsole(
        'Zdjęcie dłoni wykonane: ${palmPhoto.path}',
        tag: 'CAPTURE',
      );

      setState(() {
        _detectionStatus = 'Wysyłanie do AI na analizę...';
      });

      // 2. Wyślij do AI na PRAWDZIWĄ analizę
      final palmData = await _aiVisionService.analyzePalmWithAI(
        palmImage: palmPhoto,
        userName: widget.userName,
        userGender: widget.userGender,
      );

      // 3. Zapisz wyniki analizy AI
      await _loggingService.saveAnalysisToFile(palmData);
      await _loggingService.saveDetectionLogsToFile(widget.userName);

      _loggingService.logToConsole(
        '🎯 PRAWDZIWA ANALIZA AI ZAKOŃCZONA!',
        tag: 'CAPTURE',
      );
      _loggingService.logToConsole(
        'Wykryta ręka: ${palmData.handType}',
        tag: 'CAPTURE',
      );
      _loggingService.logToConsole(
        'Linia życia: ${palmData.lines.lifeLine.dlugosc}, ${palmData.lines.lifeLine.ksztalt}',
        tag: 'CAPTURE',
      );

      if (mounted) {
        // Przejdź do wyników
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                PalmAnalysisResultScreen(
                  userName: widget.userName,
                  userGender: widget.userGender,
                  palmData: palmData,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (e) {
      _loggingService.logToConsole('Błąd analizy AI: $e', tag: 'AI-ERROR');

      setState(() {
        _detectionStatus = 'Błąd analizy AI - użyję symulacji';
        _isAnalyzingWithAI = false;
      });

      // Fallback do starej symulacji
      final palmData = await _palmDetectionService.analyzePalm(
        handType: _detectedHand ?? 'right',
        userName: widget.userName,
      );

      await _loggingService.saveAnalysisToFile(palmData);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                PalmAnalysisResultScreen(
                  userName: widget.userName,
                  userGender: widget.userGender,
                  palmData: palmData,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 1500),
          ),
        );
      }
    }
  }

  // Nowe metody dla ulepszonego skanowania
  Future<void> _checkPalmPosition() async {
    if (_isDetecting || !mounted) return;

    setState(() {
      _isDetecting = true;
    });

    try {
      // === PRAWDZIWA WALIDACJA NAWET W TRYBIE TESTOWYM ===
      if (widget.testMode) {
        await Future.delayed(const Duration(milliseconds: 100));

        final random = math.Random();
        bool simulatedLighting = random.nextDouble() > 0.3;
        bool simulatedStability = random.nextDouble() > 0.4;
        bool simulatedPalmColor = random.nextDouble() > 0.5;
        bool simulatedCentering = random.nextDouble() > 0.6;

        setState(() {
          _hasGoodLighting = simulatedLighting;
          _isStable = simulatedStability;
          _hasPalmColor = simulatedPalmColor;
          _isCentered = simulatedCentering;

          if (_hasGoodLighting && _isStable && _hasPalmColor && _isCentered) {
            _palmDetected = true;
            _detectedHand = 'right';
            _detectionStatus = 'Dłoń wykryta - analiza w toku...';
            _stabilityCounter++;

            if (_stabilityCounter >= _requiredStabilityFrames) {
              _startCountdownIfReady();
            }
          } else {
            _palmDetected = false;
            _stabilityCounter = 0;
            _detectionStatus = _getPositioningMessage();
            _countdownTimer?.cancel();
            _countdownTimer = null;
          }

          _isDetecting = false;
        });
        return;
      }

      // === PRAWDZIWA WALIDACJA KAMERY ===
      final bool isCameraClear = await _checkIfCameraClear();
      if (!isCameraClear) {
        setState(() {
          _palmDetected = false;
          _hasGoodLighting = _isStable = _hasPalmColor = _isCentered = false;
          _detectionStatus = 'Kamera jest zasłonięta lub zbyt ciemno';
          _stabilityCounter = 0;
          _isDetecting = false;
        });

        _countdownTimer?.cancel();
        _countdownTimer = null;
        return;
      }

      final double currentLightLevel = await _palmDetectionService
          .checkLightLevel(_cameraController!);
      _hasGoodLighting = currentLightLevel > 0.3;

      _isStable = (currentLightLevel - _lastBrightnessValue).abs() < 0.05;
      _isStable ? _stabilityCounter++ : _stabilityCounter = 0;
      _lastBrightnessValue = currentLightLevel;

      _hasPalmColor = _hasGoodLighting
          ? await _palmDetectionService.checkSkinColor(_cameraController!)
          : false;

      _isCentered = (_hasGoodLighting && _hasPalmColor)
          ? await _palmDetectionService.checkPalmPosition(_cameraController!)
          : false;

      setState(() {
        bool allConditionsMet =
            _hasGoodLighting &&
            _isStable &&
            _stabilityCounter >= _requiredStabilityFrames &&
            _hasPalmColor &&
            _isCentered;

        if (allConditionsMet) {
          _palmDetected = true;
          _detectedHand = math.Random().nextBool() ? 'left' : 'right';
          _detectionStatus = 'Dłoń w dobrej pozycji - utrzymaj nieruchomo';
          _glowController.forward();
          _startCountdownIfReady();
        } else {
          _palmDetected = false;
          _detectionStatus = _getPositioningMessage();
          _lightLevel = currentLightLevel;
          _stabilityCounter = math.max(0, _stabilityCounter - 1);

          if (_countdownTimer != null) {
            _countdownTimer?.cancel();
            _countdownTimer = null;
            _countdownSeconds = 5;
          }
        }

        _isDetecting = false;
      });
    } catch (e) {
      _loggingService.logToConsole(
        'Błąd podczas sprawdzania pozycji dłoni: $e',
        tag: 'ERROR',
      );
      setState(() {
        _isDetecting = false;
        _palmDetected = false;
        _detectionStatus = 'Błąd sprawdzania pozycji';
        _countdownTimer?.cancel();
        _countdownTimer = null;
      });
    }
  }

  Future<bool> _checkIfCameraClear() async {
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return false;
      }

      final lightLevel = await _palmDetectionService.checkLightLevel(
        _cameraController!,
      );
      return lightLevel > 0.1; // Minimum 10% jasności
    } catch (e) {
      _loggingService.logToConsole(
        'Błąd sprawdzania zasłonięcia kamery: $e',
        tag: 'ERROR',
      );
      return false;
    }
  }

  void _startCountdownIfReady() {
    if (!_palmDetected || _countdownTimer != null) return;

    setState(() {
      _countdownSeconds = 5;
      _detectionStatus = 'Utrzymaj pozycję! $_countdownSeconds...';
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_palmDetected) {
        timer.cancel();
        _countdownTimer = null;
        setState(() => _detectionStatus = _getPositioningMessage());
        return;
      }

      setState(() {
        _countdownSeconds--;
        if (_countdownSeconds > 0) {
          _detectionStatus = 'Utrzymaj pozycję! $_countdownSeconds...';
        } else {
          timer.cancel();
          _countdownTimer = null;
          _detectionStatus = 'Robię zdjęcie...';
          _capturePalmData();
        }
      });
    });
  }

  String _getPositioningMessage() {
    if (!_hasGoodLighting) return 'Popraw oświetlenie - zbyt ciemno';
    if (!_isStable) return 'Trzymaj dłoń nieruchomo';
    if (_stabilityCounter < _requiredStabilityFrames) {
      int remainingSeconds =
          ((_requiredStabilityFrames - _stabilityCounter) / 10).ceil();
      return 'Utrzymaj pozycję jeszcze $remainingSeconds sek...';
    }
    if (!_hasPalmColor) return 'Pokaż wewnętrzną stronę dłoni';
    if (!_isCentered) return 'Wycentruj dłoń w ramce';
    return 'Umieść dłoń w ramce';
  }

  @override
  void dispose() {
    _loggingService.logCameraActivity('Zamykanie kamery i zasobów');

    _detectionTimer?.cancel();
    _forceCloseTimer?.cancel();
    _cameraController?.dispose();
    _scanController.dispose();
    _pulseController.dispose();
    _glowController.dispose();

    _loggingService.logToConsole('Zasoby zwolnione pomyślnie', tag: 'CLEANUP');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Podgląd kamery LUB tryb testowy
          if (widget.testMode)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B1426), Color(0xFF1A2332)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_camera_front_outlined,
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
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Symulacja skanowania dłoni',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.cyan.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Kamera niedostępna - testowanie funkcjonalności',
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 12,
                          color: AppColors.cyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(child: CameraPreview(_cameraController!))
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
              ),
            ),

          // Nakładka skanowania
          Positioned.fill(child: _buildScanOverlay()),

          // Panel statusu
          Positioned(top: 0, left: 0, right: 0, child: _buildStatusPanel()),

          // Panel instrukcji na dole
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildInstructionPanel(),
          ),

          // Przycisk manualnego zakończenia
          Positioned(
            bottom: 120,
            right: 20,
            child: _buildManualCaptureButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scanAnimation,
        _pulseAnimation,
        _glowAnimation,
      ]),
      builder: (context, child) {
        return CustomPaint(
          painter: PalmScanOverlayPainter(
            scanProgress: _scanAnimation.value,
            pulseValue: _pulseAnimation.value,
            glowValue: _glowAnimation.value,
            palmDetected: _palmDetected,
            lightLevel: _lightLevel,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildStatusPanel() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.cyan.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: _hasGoodLighting ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Oświetlenie: ${_getLightLevelText()}',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: _hasGoodLighting ? Colors.green : Colors.orange,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isStable
                      ? Icons.accessibility_new
                      : Icons.accessibility_outlined,
                  color: _isStable ? Colors.green : AppColors.cyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isStable ? 'Stabilna pozycja' : 'Ustabilizuj dłoń',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: _isStable ? Colors.green : AppColors.cyan,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusIndicator(
                  icon: Icons.center_focus_strong,
                  label: 'Centrowanie',
                  isActive: _isCentered,
                ),
                _buildStatusIndicator(
                  icon: Icons.color_lens,
                  label: 'Wewnętrzna strona',
                  isActive: _hasPalmColor,
                ),
                _buildStatusIndicator(
                  icon: Icons.timer,
                  label:
                      'Stabilność: ${(_stabilityCounter / _requiredStabilityFrames * 100).toInt()}%',
                  isActive: _stabilityCounter >= _requiredStabilityFrames,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _palmDetected
                  ? 'Świetnie! Utrzymaj pozycję do zakończenia skanowania.'
                  : 'Umieść swoją dłoń w ramce, wewnętrzną stroną do kamery. Utrzymaj stabilną pozycję.',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 13,
                color: _palmDetected ? Colors.green : Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getLightLevelColor() {
    if (_lightLevel > 0.7) return Colors.green;
    if (_lightLevel > 0.4) return Colors.orange;
    return Colors.red;
  }

  String _getLightLevelText() {
    if (_lightLevel > 0.7) return 'Dobre';
    if (_lightLevel > 0.4) return 'Średnie';
    return 'Słabe';
  }

  Widget _buildManualCaptureButton() {
    return FloatingActionButton(
      onPressed: _isAnalyzingWithAI ? null : _forceCompleteScan,
      backgroundColor: _isAnalyzingWithAI
          ? Colors.grey.withOpacity(0.5)
          : AppColors.cyan.withOpacity(0.3),
      child: Icon(
        Icons.camera,
        color: _isAnalyzingWithAI ? Colors.grey : AppColors.cyan,
      ),
    );
  }

  Widget _buildInstructionPanel() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cyan.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _palmDetected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: _palmDetected ? Colors.green : AppColors.cyan,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _detectionStatus,
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            if (_palmDetected) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Pozostało: $_countdownSeconds s',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      color: AppColors.cyan.withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getPositionHint(),
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_detectedHand != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _detectedHand == 'left' ? 'Lewa' : 'Prawa',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPositionHint() {
    if (!_hasGoodLighting) {
      return 'Znajdź lepsze oświetlenie - upewnij się, że dłoń jest dobrze widoczna';
    }
    if (!_isStable) {
      return 'Trzymaj dłoń stabilnie przez kilka sekund, aby umożliwić dokładne skanowanie';
    }
    if (!_hasPalmColor) {
      return 'Pokaż wewnętrzną stronę dłoni - wszystkie linie powinny być widoczne';
    }
    if (!_isCentered) {
      return 'Umieść dłoń dokładnie w środku zaznaczonego obszaru';
    }
    if (_stabilityCounter < _requiredStabilityFrames) {
      return 'Utrzymaj pozycję jeszcze przez ${(_requiredStabilityFrames - _stabilityCounter) / 10} sekund...';
    }
    return 'Gotowe do zrobienia zdjęcia dłoni!';
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.2)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.green : Colors.grey, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 10,
              color: isActive ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Malarz nakładki skanowania dłoni
class PalmScanOverlayPainter extends CustomPainter {
  final double scanProgress;
  final double pulseValue;
  final double glowValue; // Add missing glowValue
  final bool palmDetected;
  final double lightLevel;

  PalmScanOverlayPainter({
    required this.scanProgress,
    required this.pulseValue,
    required this.glowValue,
    required this.palmDetected,
    required this.lightLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Rysuj przyciemnioną nakładkę z wycięciem dla dłoni
    _drawDimmedOverlay(canvas, size, center);

    // Rysuj kontur dłoni
    _drawHandOutline(canvas, center);

    // Rysuj linię skanowania
    if (!palmDetected) {
      _drawScanLine(canvas, size, center);
    }

    // Rysuj efekt wykrycia
    if (palmDetected) {
      _drawDetectionEffect(canvas, center);
    }

    // Rysuj wskaźniki narożników
    _drawCornerIndicators(canvas, center);
  }

  void _drawDimmedOverlay(Canvas canvas, Size size, Offset center) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.6);

    final handPath = _createHandPath(center);

    // Rysuj całą nakładkę
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // Wytnij obszar dłoni
    canvas.drawPath(
      handPath,
      Paint()
        ..color = Colors.transparent
        ..blendMode = BlendMode.clear,
    );
  }

  void _drawHandOutline(Canvas canvas, Offset center) {
    final outlinePaint = Paint()
      ..color = palmDetected
          ? AppColors.cyan.withOpacity(0.8 + (glowValue * 0.2))
          : AppColors.cyan.withOpacity(0.4 + (pulseValue * 0.3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = palmDetected ? 3.0 + (glowValue * 2.0) : 2.0;

    final handPath = _createHandPath(center);
    canvas.drawPath(handPath, outlinePaint);

    // Dodaj poświatę jeśli dłoń wykryta
    if (palmDetected) {
      final glowPaint = Paint()
        ..color = AppColors.cyan.withOpacity(0.3 * glowValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0 + (glowValue * 4.0)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawPath(handPath, glowPaint);
    }
  }

  void _drawScanLine(Canvas canvas, Size size, Offset center) {
    final scanPaint = Paint()
      ..color = AppColors.cyan.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        colors: [
          AppColors.cyan.withOpacity(0.0),
          AppColors.cyan.withOpacity(0.8),
          AppColors.cyan.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 4));

    final handRect = Rect.fromCenter(center: center, width: 180, height: 240);

    final scanY = handRect.top + (handRect.height * scanProgress);

    canvas.drawLine(
      Offset(handRect.left, scanY),
      Offset(handRect.right, scanY),
      scanPaint,
    );
  }

  void _drawDetectionEffect(Canvas canvas, Offset center) {
    // Rysuj pulsujące kółka wokół dłoni
    final effectPaint = Paint()
      ..color = AppColors.cyan.withOpacity(0.3 * glowValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 3; i++) {
      final radius = 100 + (i * 30) + (glowValue * 20);
      canvas.drawCircle(center, radius, effectPaint);
    }

    // Rysuj cząsteczki energii
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2 / 8) + (glowValue * math.pi * 2);
      final distance = 120 + (glowValue * 30);
      final particleCenter = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      canvas.drawCircle(
        particleCenter,
        3.0 + (glowValue * 2.0),
        Paint()..color = AppColors.cyan.withOpacity(0.8 * glowValue),
      );
    }
  }

  void _drawCornerIndicators(Canvas canvas, Offset center) {
    final cornerPaint = Paint()
      ..color = palmDetected
          ? Colors.green.withOpacity(0.8)
          : AppColors.cyan.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final handRect = Rect.fromCenter(center: center, width: 180, height: 240);

    final cornerLength = 20.0;

    // Lewy górny róg
    canvas.drawLine(
      handRect.topLeft,
      handRect.topLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      handRect.topLeft,
      handRect.topLeft + Offset(0, cornerLength),
      cornerPaint,
    );

    // Prawy górny róg
    canvas.drawLine(
      handRect.topRight,
      handRect.topRight + Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      handRect.topRight,
      handRect.topRight + Offset(0, cornerLength),
      cornerPaint,
    );

    // Lewy dolny róg
    canvas.drawLine(
      handRect.bottomLeft,
      handRect.bottomLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      handRect.bottomLeft,
      handRect.bottomLeft + Offset(0, -cornerLength),
      cornerPaint,
    );

    // Prawy dolny róg
    canvas.drawLine(
      handRect.bottomRight,
      handRect.bottomRight + Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      handRect.bottomRight,
      handRect.bottomRight + Offset(0, -cornerLength),
      cornerPaint,
    );
  }

  Path _createHandPath(Offset center) {
    final path = Path();

    // Uproszczony kształt dłoni
    final handWidth = 90.0;
    final handHeight = 120.0;
    final fingerHeight = 60.0;

    // Bazowa część dłoni
    final palmRect = Rect.fromCenter(
      center: center + const Offset(0, 30),
      width: handWidth,
      height: handHeight,
    );

    path.addRRect(RRect.fromRectAndRadius(palmRect, const Radius.circular(15)));

    // Dodaj palce jako elipsy
    for (int i = 0; i < 4; i++) {
      final fingerX = center.dx - handWidth * 0.3 + (i * handWidth * 0.2);
      final fingerCenter = Offset(fingerX, center.dy - handHeight * 0.1);

      final fingerRect = Rect.fromCenter(
        center: fingerCenter,
        width: 12,
        height: fingerHeight,
      );

      path.addRRect(
        RRect.fromRectAndRadius(fingerRect, const Radius.circular(6)),
      );
    }

    // Dodaj kciuk
    final thumbCenter = Offset(center.dx - handWidth * 0.6, center.dy + 10);

    final thumbRect = Rect.fromCenter(
      center: thumbCenter,
      width: 15,
      height: 40,
    );

    path.addRRect(RRect.fromRectAndRadius(thumbRect, const Radius.circular(8)));

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Placeholder dla ekranu wyników analizy
class PalmAnalysisResultScreen extends StatelessWidget {
  final String userName;
  final String userGender;
  final PalmAnalysis palmData;

  const PalmAnalysisResultScreen({
    super.key,
    required this.userName,
    required this.userGender,
    required this.palmData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.welcomeGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Analiza Zakończona!',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 24,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Drogi $userName,\nTwoja dłoń została przeanalizowana.',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Wykryta ręka: ${palmData.handType == "left" ? "Lewa" : "Prawa"}',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 14,
                    color: AppColors.cyan,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
