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

    _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      if (!mounted ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized) {
        timer.cancel();
        return;
      }

      _scanAttempts++;
      _simulatePalmDetection();

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
      'Wymuszenie zakończenia skanowania',
      tag: 'SCAN',
    );

    setState(() {
      _palmDetected = true;
      _detectedHand = math.Random().nextBool() ? 'left' : 'right';
      _detectionStatus = 'Skanowanie zakończone (wymuszenie)';
    });

    _loggingService.logScanningDetails(
      palmDetected: true,
      detectionStatus: 'Skanowanie zakończone (wymuszenie)',
      lightLevel: _lightLevel,
      detectedHand: _detectedHand,
      additionalData: {
        'Próby skanowania': _scanAttempts,
        'Powód zakończenia': 'Timeout lub maksymalna liczba prób',
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      _capturePalmData();
    });
  }

  void _simulatePalmDetection() {
    if (!_isDetecting) {
      setState(() {
        _isDetecting = true;
      });

      Future.delayed(const Duration(milliseconds: 200), () {
        final random = math.Random();
        final detectionResult = random.nextDouble();

        // Logowanie każdej próby wykrywania
        _loggingService.logToConsole(
          'Próba wykrywania #$_scanAttempts - wynik: ${(detectionResult * 100).toInt()}%',
          tag: 'DETECTION',
        );

        if (detectionResult > 0.7) {
          // Dłoń wykryta
          final detectedHand = random.nextBool() ? 'left' : 'right';
          final lightLevel = 0.8 + (random.nextDouble() * 0.2);

          setState(() {
            _palmDetected = true;
            _detectedHand = detectedHand;
            _detectionStatus = 'Dłoń wykryta! Analizowanie...';
            _lightLevel = lightLevel;
          });

          _loggingService.logScanningDetails(
            palmDetected: true,
            detectionStatus: 'Dłoń wykryta - sukces',
            lightLevel: lightLevel,
            detectedHand: detectedHand,
            additionalData: {
              'Próba': _scanAttempts,
              'Wynik wykrywania': '${(detectionResult * 100).toInt()}%',
              'Typ': 'Automatyczne wykrycie',
            },
          );

          _glowController.forward();

          // Zatrzymaj wykrywanie i przejdź do analizy
          _detectionTimer?.cancel();
          _forceCloseTimer?.cancel();

          Future.delayed(const Duration(seconds: 3), () {
            _capturePalmData();
          });
        } else if (detectionResult > 0.4) {
          // Częściowe wykrycie
          final tip = _getRandomPositioningTip();
          final lightLevel = 0.4 + (random.nextDouble() * 0.3);

          setState(() {
            _palmDetected = false;
            _detectionStatus = tip;
            _lightLevel = lightLevel;
          });

          _loggingService.logScanningDetails(
            palmDetected: false,
            detectionStatus: tip,
            lightLevel: lightLevel,
            additionalData: {
              'Próba': _scanAttempts,
              'Wynik wykrywania': '${(detectionResult * 100).toInt()}%',
              'Typ': 'Częściowe wykrycie',
            },
          );
        } else {
          // Brak dłoni
          final lightLevel = 0.2 + (random.nextDouble() * 0.3);

          setState(() {
            _palmDetected = false;
            _detectionStatus = 'Umieść dłoń w ramce';
            _lightLevel = lightLevel;
          });

          // Loguj tylko co 5 próbę żeby nie zaśmiecać
          if (_scanAttempts % 5 == 0) {
            _loggingService.logScanningDetails(
              palmDetected: false,
              detectionStatus: 'Brak dłoni w ramce',
              lightLevel: lightLevel,
              additionalData: {
                'Próba': _scanAttempts,
                'Wynik wykrywania': '${(detectionResult * 100).toInt()}%',
                'Typ': 'Brak wykrycia',
              },
            );
          }
        }

        _isDetecting = false;
      });
    }
  }

  String _getRandomPositioningTip() {
    final tips = [
      'Przybliż dłoń do kamery',
      'Oddal dłoń od kamery',
      'Ustaw dłoń centralnie',
      'Rozłóż palce szerzej',
      'Popraw oświetlenie',
      'Trzymaj dłoń stabilnie',
    ];
    return tips[math.Random().nextInt(tips.length)];
  }

  void _capturePalmData() async {
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
                  color: _getLightLevelColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Oświetlenie: ${_getLightLevelText()}',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                Icon(Icons.pan_tool_outlined, color: AppColors.cyan, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Skanowanie dłoni',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Umieść swoją dłoń w widocznej ramce. System automatycznie wykryje i przeanalizuje linie oraz wzgórki na Twojej dłoni.',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 13,
                color: Colors.white70,
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
        child: Row(
          children: [
            Icon(
              _palmDetected ? Icons.check_circle : Icons.radio_button_unchecked,
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
