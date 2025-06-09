// =======================================
// NAPRAWIONE ROZWIĄZANIE:
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
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  bool _palmDetected = false;
  String _detectionStatus = 'Pozycjonowanie kamery...';
  String? _detectedHand;
  double _lightLevel = 0.5;
  bool _isDisposing = false;

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
  final AIVisionService _aiVisionService = AIVisionService();

  // Timer dla wykrywania
  Timer? _detectionTimer;
  Timer? _forceCloseTimer;
  int _scanAttempts = 0;

  // Stan AI analizy
  bool _isAnalyzingWithAI = false;

  // ====== POPRAWIONA STABILIZACJA ======
  int _countdownSeconds = 5;
  bool _isStable = true; // ← ZMIANA: Domyślnie stabilna
  bool _hasGoodLighting = false;
  bool _hasPalmColor = false;
  bool _isCentered = false;

  Timer? _countdownTimer;

  // NOWY INTELIGENTNY SYSTEM STABILNOŚCI
  List<double> _lightLevelHistory = [];
  final int _historySize = 8; // Mniejsza historia
  final double _lightThreshold = 0.15; // BARDZO niski próg
  final double _stabilityThreshold = 0.15; // BARDZO łagodny próg

  int _stabilityCounter = 0;
  final int _requiredStabilityFrames = 2; // Minimalne wymagania

  // Lepszy UX
  int _goodConditionsStreak = 0;
  final int _requiredGoodStreak = 3; // Bardzo mały streak
  bool _isInCooldown = false;

  DateTime? _lastCheck;
  final Duration _checkDelay = const Duration(
    milliseconds: 600,
  ); // Bardzo rzadko

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    if (_isDisposing) return;

    try {
      _loggingService.logCameraActivity('Inicjalizacja kamery');

      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _disposeCamera();

        if (_isDisposing) return;

        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        try {
          await _cameraController!.initialize();

          if (_isDisposing || !mounted) return;

          setState(() {
            _isCameraInitialized = true;
            _detectionStatus = 'Umieść dłoń w ramce';
          });

          _loggingService.logCameraActivity('Kamera zainicjalizowana');
          await _loggingService.logFileLocation();
          _startPalmDetection();
          _startForceCloseTimer();
        } catch (e) {
          _loggingService.logToConsole(
            'Błąd inicjalizacji kamery: $e',
            tag: 'ERROR',
          );
          if (mounted) {
            setState(() {
              _detectionStatus = 'Błąd inicjalizacji kamery';
              _isCameraInitialized = false;
            });
          }
        }
      }
    } catch (e) {
      _loggingService.logToConsole(
        'Błąd inicjalizacji kamery: $e',
        tag: 'ERROR',
      );
      if (mounted) {
        setState(() {
          _detectionStatus = 'Błąd inicjalizacji kamery';
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      try {
        await _cameraController!.dispose();
        _cameraController = null;
        _isCameraInitialized = false;
      } catch (e) {
        _loggingService.logToConsole('Błąd dispose kamery: $e', tag: 'ERROR');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.testMode) return;

    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _loggingService.logToConsole(
          'App paused - disposing camera',
          tag: 'LIFECYCLE',
        );
        _disposeCamera();
        break;
      case AppLifecycleState.resumed:
        _loggingService.logToConsole(
          'App resumed - reinitializing camera',
          tag: 'LIFECYCLE',
        );
        if (!_isDisposing) {
          _initializeCamera();
        }
        break;
      default:
        break;
    }
  }

  void _startForceCloseTimer() {
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
      'Rozpoczęcie wykrywania dłoni - tryb ciągły',
      tag: 'DETECTION',
    );

    _detectionTimer = Timer.periodic(const Duration(milliseconds: 600), (
      timer,
    ) {
      // BARDZO rzadko
      if (!mounted ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized ||
          _isDisposing) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      if (_lastCheck != null && now.difference(_lastCheck!) < _checkDelay) {
        return;
      }
      _lastCheck = now;

      _scanAttempts++;
      _checkPalmPosition();

      if (_scanAttempts % 20 == 0) {
        _loggingService.logToConsole(
          'Skanowanie - próba $_scanAttempts, streak: $_goodConditionsStreak/$_requiredGoodStreak',
          tag: 'DETECTION',
        );
      }
    });
  }

  void _forceCompleteScan() {
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
      Future.delayed(const Duration(seconds: 1), () {
        _capturePalmData();
      });
    } else {
      _loggingService.logToConsole(
        'Timeout - dłoń nie została poprawnie wykryta',
        tag: 'SCAN',
      );
      setState(() {
        _palmDetected = false;
        _detectionStatus = 'Nie udało się wykryć dłoni w odpowiedniej pozycji';
      });
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

  void _restartScanning() {
    setState(() {
      _isDetecting = false;
      _palmDetected = false;
      _detectionStatus = 'Umieść dłoń w ramce';
      _detectedHand = null;
      _lightLevel = 0.5;
      _countdownSeconds = 5;
      _isStable = true; // Domyślnie stabilna
      _hasGoodLighting = false;
      _hasPalmColor = false;
      _isCentered = false;
      _stabilityCounter = 0;
      _scanAttempts = 0;
      _lightLevelHistory.clear();
      _goodConditionsStreak = 0;
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
    return allConditionsMet;
  }

  void _capturePalmData() async {
    if (!_canTakePicture()) {
      setState(() {
        _detectionStatus = 'Warunki nie spełnione - nie można zrobić zdjęcia';
      });
      return;
    }

    setState(() {
      _isAnalyzingWithAI = true;
      _detectionStatus = 'Robię zdjęcie dłoni...';
    });

    try {
      final XFile palmPhoto = await _cameraController!.takePicture();
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
      setState(() {
        _detectionStatus = 'Błąd analizy AI - użyję symulacji';
        _isAnalyzingWithAI = false;
      });

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

  // ====== POPRAWIONA LOGIKA WYKRYWANIA ======
  Future<void> _checkPalmPosition() async {
    if (_isDetecting || !mounted || _isInCooldown || _isDisposing) return;

    setState(() {
      _isDetecting = true;
    });

    try {
      if (widget.testMode) {
        await _simulateTestModeChecks();
      } else {
        await _performRealChecks();
      }

      bool allConditionsGood =
          _hasGoodLighting && _isStable && _hasPalmColor && _isCentered;

      if (allConditionsGood) {
        _goodConditionsStreak++;

        setState(() {
          _palmDetected = true;
          _detectedHand ??= math.Random().nextBool() ? 'left' : 'right';

          int remaining = _requiredGoodStreak - _goodConditionsStreak;
          if (remaining > 0) {
            _detectionStatus =
                'Świetnie! Utrzymaj pozycję jeszcze ${remaining} kroków';
          } else {
            _detectionStatus = 'Doskonale! Robię zdjęcie za chwilę...';
          }
        });

        if (_goodConditionsStreak >= _requiredGoodStreak &&
            !_isAnalyzingWithAI) {
          _detectionTimer?.cancel();
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _capturePalmData();
          }
        }
      } else {
        _goodConditionsStreak = 0;

        setState(() {
          _palmDetected = false;
          _detectionStatus = _getPositioningMessage();
        });

        _countdownTimer?.cancel();
        _countdownTimer = null;
      }

      setState(() {
        _isDetecting = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDetecting = false;
          _palmDetected = false;
          _detectionStatus = 'Błąd sprawdzania pozycji - spróbuj ponownie';
          _goodConditionsStreak = 0;
        });
      }
    }
  }

  Future<void> _simulateTestModeChecks() async {
    await Future.delayed(const Duration(milliseconds: 100));

    final random = math.Random();
    setState(() {
      _hasGoodLighting = random.nextDouble() > 0.1; // Bardzo łatwo
      _isStable = true; // Zawsze stabilne w trybie testowym
      _hasPalmColor = random.nextDouble() > 0.2;
      _isCentered = random.nextDouble() > 0.3;

      if (_hasGoodLighting && _isStable && _hasPalmColor && _isCentered) {
        _stabilityCounter++;
      } else {
        _stabilityCounter = 0;
      }
    });
  }

  // ====== KOMPLETNIE NOWA LOGIKA STABILIZACJI ======
  Future<void> _performRealChecks() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() {
        _palmDetected = false;
        _hasGoodLighting = _isStable = _hasPalmColor = _isCentered = false;
        _detectionStatus = 'Kamera niedostępna';
        _stabilityCounter = 0;
      });
      return;
    }

    // Pobierz aktualny poziom światła
    final double currentLightLevel = await _palmDetectionService
        .checkLightLevel(_cameraController!);

    // Dodaj do historii
    _lightLevelHistory.add(currentLightLevel);
    if (_lightLevelHistory.length > _historySize) {
      _lightLevelHistory.removeAt(0);
    }

    // Oblicz średni poziom światła
    double averageLightLevel = _lightLevelHistory.isNotEmpty
        ? _lightLevelHistory.reduce((a, b) => a + b) / _lightLevelHistory.length
        : currentLightLevel;

    // Sprawdź oświetlenie
    _hasGoodLighting = averageLightLevel > _lightThreshold;

    // ===== NOWA LOGIKA STABILNOŚCI =====
    // Sprawdzaj stabilność tylko po zebraniu wystarczających danych
    if (_lightLevelHistory.length <= 2) {
      _isStable = true; // Domyślnie stabilne na początku
    } else {
      // Oblicz różnicę między ostatnimi pomiarami
      double lastDiff =
          (_lightLevelHistory.last -
                  _lightLevelHistory[_lightLevelHistory.length - 2])
              .abs();

      // Stabilne jeśli różnica jest mała ALBO światło jest bardzo jasne
      _isStable = (lastDiff < _stabilityThreshold) || (averageLightLevel > 0.7);

      // Dodatkowo: jeśli jest ciemno, uznaj za niestabilne
      if (averageLightLevel < 0.1) {
        _isStable = false;
      }
    }

    // Sprawdź inne warunki
    _hasPalmColor = _hasGoodLighting
        ? await _palmDetectionService.checkSkinColor(_cameraController!)
        : false;

    _isCentered = (_hasGoodLighting && _hasPalmColor)
        ? await _palmDetectionService.checkPalmPosition(_cameraController!)
        : false;

    // Licznik stabilności - bardzo łagodny
    if (_hasGoodLighting && _isStable && _hasPalmColor && _isCentered) {
      _stabilityCounter++;
    } else {
      _stabilityCounter = math.max(0, _stabilityCounter - 1);
    }

    // Ustaw poziom światła dla UI
    _lightLevel = averageLightLevel;
  }

  String _getPositioningMessage() {
    if (!_hasGoodLighting) return 'Popraw oświetlenie - zbyt ciemno';
    if (!_isStable) return 'Utrzymuj kamerę stabilnie';
    if (_stabilityCounter < _requiredStabilityFrames) {
      return 'Utrzymaj pozycję jeszcze chwilę...';
    }
    if (!_hasPalmColor) return 'Pokaż wewnętrzną stronę dłoni';
    if (!_isCentered) return 'Wycentruj dłoń w ramce';
    return 'Umieść dłoń w ramce';
  }

  @override
  void dispose() {
    _isDisposing = true;
    WidgetsBinding.instance.removeObserver(this);

    _detectionTimer?.cancel();
    _forceCloseTimer?.cancel();
    _countdownTimer?.cancel();

    _scanController.stop();
    _pulseController.stop();
    _glowController.stop();

    _disposeCamera();
    _scanController.dispose();
    _pulseController.dispose();
    _glowController.dispose();

    _isDetecting = false;
    _palmDetected = false;
    _isAnalyzingWithAI = false;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ===== NAPRAWIONY PODGLĄD KAMERY - BEZ ROZCIĄGANIA =====
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
                  ],
                ),
              ),
            )
          else if (_isCameraInitialized && _cameraController != null)
            // ===== NAPRAWIONY PREVIEW - Z ZACHOWANIEM PROPORCJI =====
            Center(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
              ),
            ),

          // Nakładka skanowania - JESZCZE MNIEJ PRZYCIEMNIONA
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
          painter: ImprovedPalmScanOverlayPainter(
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
          color: Colors.black.withOpacity(0.8),
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
                  'Światło: ${_getLightLevelText()}',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: _hasGoodLighting ? Colors.green : Colors.orange,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isStable ? Icons.check_circle : Icons.motion_photos_on,
                  color: _isStable ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isStable ? 'Stabilna' : 'Stabilizowanie...',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: _isStable ? Colors.green : Colors.orange,
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
                  label: 'Dłoń',
                  isActive: _hasPalmColor,
                ),
                _buildStatusIndicator(
                  icon: Icons.timer,
                  label:
                      'Progres: ${(_goodConditionsStreak * 100 / _requiredGoodStreak).toInt()}%',
                  isActive: _goodConditionsStreak >= _requiredGoodStreak,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getLightLevelText() {
    if (_lightLevel > 0.4) return 'Dobre';
    if (_lightLevel > 0.2) return 'Średnie';
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
            if (_palmDetected && _goodConditionsStreak > 0) ...[
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
                    const Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Postęp: $_goodConditionsStreak/$_requiredGoodStreak',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_detectedHand != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _detectedHand == 'left' ? 'Lewa ręka' : 'Prawa ręka',
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

// ====== POPRAWIONY MALARZ - JESZCZE MNIEJ PRZYCIEMNIONY ======
class ImprovedPalmScanOverlayPainter extends CustomPainter {
  final double scanProgress;
  final double pulseValue;
  final double glowValue;
  final bool palmDetected;
  final double lightLevel;

  ImprovedPalmScanOverlayPainter({
    required this.scanProgress,
    required this.pulseValue,
    required this.glowValue,
    required this.palmDetected,
    required this.lightLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // JESZCZE MNIEJSZE PRZYCIEMNIENIE TŁA
    _drawMinimalDimmedOverlay(canvas, size, center);

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

  void _drawMinimalDimmedOverlay(Canvas canvas, Size size, Offset center) {
    // MINIMALNE PRZYCIEMNIENIE - z 0.2 na 0.1
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.1);

    final handPath = _createHandPath(center);

    // Rysuj bardzo lekko przyciemnioną nakładkę
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // Wytnij obszar dłoni (pozostaw przezroczysty)
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
          ? AppColors.cyan.withOpacity(0.9 + (glowValue * 0.1))
          : AppColors.cyan.withOpacity(0.7 + (pulseValue * 0.2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = palmDetected ? 3.0 + (glowValue * 1.0) : 2.5;

    final handPath = _createHandPath(center);
    canvas.drawPath(handPath, outlinePaint);

    // Dodaj delikatną poświatę
    if (palmDetected) {
      final glowPaint = Paint()
        ..color = AppColors.cyan.withOpacity(0.15 * glowValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0 + (glowValue * 1.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawPath(handPath, glowPaint);
    }
  }

  void _drawScanLine(Canvas canvas, Size size, Offset center) {
    final scanPaint = Paint()
      ..color = AppColors.cyan.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        colors: [
          AppColors.cyan.withOpacity(0.0),
          AppColors.cyan.withOpacity(0.6),
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
    // Bardzo delikatne pulsujące kółka
    final effectPaint = Paint()
      ..color = AppColors.cyan.withOpacity(0.15 * glowValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 2; i++) {
      final radius = 100 + (i * 20) + (glowValue * 10);
      canvas.drawCircle(center, radius, effectPaint);
    }

    // Bardzo delikatne cząsteczki energii
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi * 2 / 4) + (glowValue * math.pi * 2);
      final distance = 105 + (glowValue * 15);
      final particleCenter = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      canvas.drawCircle(
        particleCenter,
        1.5 + (glowValue * 0.5),
        Paint()..color = AppColors.cyan.withOpacity(0.4 * glowValue),
      );
    }
  }

  void _drawCornerIndicators(Canvas canvas, Offset center) {
    final cornerPaint = Paint()
      ..color = palmDetected
          ? Colors.green.withOpacity(0.7)
          : AppColors.cyan.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final handRect = Rect.fromCenter(center: center, width: 180, height: 240);
    final cornerLength = 15.0; // Mniejsze narożniki

    // Rogi ramki
    final corners = [
      handRect.topLeft,
      handRect.topRight,
      handRect.bottomLeft,
      handRect.bottomRight,
    ];

    final directions = [
      [Offset(cornerLength, 0), Offset(0, cornerLength)],
      [Offset(-cornerLength, 0), Offset(0, cornerLength)],
      [Offset(cornerLength, 0), Offset(0, -cornerLength)],
      [Offset(-cornerLength, 0), Offset(0, -cornerLength)],
    ];

    for (int i = 0; i < corners.length; i++) {
      canvas.drawLine(corners[i], corners[i] + directions[i][0], cornerPaint);
      canvas.drawLine(corners[i], corners[i] + directions[i][1], cornerPaint);
    }
  }

  Path _createHandPath(Offset center) {
    final path = Path();
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

    // Palce
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

    // Kciuk
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

// =======================================
// PODSUMOWANIE ZMIAN:
// =======================================

/*
1. NAPRAWIONA STABILIZACJA:
   - bool _isStable = true (domyślnie stabilna)
   - Nowa logika: różnica między ostatnimi 2 pomiarami < 0.15
   - Automatycznie stabilne jeśli światło > 0.7
   - Niestabilne tylko jeśli bardzo ciemno (< 0.1)

2. NAPRAWIONY OBRAZ KAMERY:
   - Dodane AspectRatio dla zachowania proporcji
   - Center() wrapper zapobiega rozciąganiu
   - Kamera nie będzie już zniekształcona

3. JESZCZE MNIEJSZE PRZYCIEMNIENIE:
   - Z 0.2 na 0.1 opacity
   - Lepiej widoczny podgląd kamery
   - Delikatniejsze efekty

4. BARDZIEJ ŁAGODNE PARAMETRY:
   - _lightThreshold = 0.15 (bardzo niski)
   - _stabilityThreshold = 0.15 (bardzo łagodny)
   - _requiredStabilityFrames = 2 (minimalne)
   - _requiredGoodStreak = 3 (bardzo mały)
   - sprawdzanie co 600ms (bardzo rzadko)

WYNIK: Kamera stabilna od razu, bez rozciągania obrazu!
*/
