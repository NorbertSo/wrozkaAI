// lib/screens/palm_scan_screen.dart
// POPRAWIONA WERSJA z przejściem do ekranu ładowania

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../services/palm_detection_service.dart';
import '../services/logging_service.dart';
import '../models/palm_analysis.dart';
import '../models/user_data.dart';
import 'fortune_loading_screen.dart'; // ✅ NOWY IMPORT

class PalmScanScreen extends StatefulWidget {
  final String userName;
  final String userGender;
  final String? dominantHand;
  final DateTime? birthDate;
  final bool testMode;

  const PalmScanScreen({
    super.key,
    required this.userName,
    required this.userGender,
    this.dominantHand,
    this.birthDate,
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
  String _detectionStatus = 'Inicjalizacja mistycznej energii...';
  bool _showCamera = false;

  // ===== FLAGI ZABEZPIECZAJĄCE =====
  bool _isDisposing = false;
  bool _hasCompletedScan = false;
  bool _isCameraLocked = false;
  bool _isAnalyzing = false;

  // ===== SERWISY =====
  final PalmDetectionService _palmDetectionService = PalmDetectionService();
  final LoggingService _loggingService = LoggingService();

  // ===== WYKRYWANIE =====
  int _scanAttempts = 0;
  int _goodChecks = 0;
  final int _requiredGoodChecks = 3;
  bool _palmDetected = false;

  // ===== ANIMACJE =====
  late AnimationController _pulseController;
  late AnimationController _orbController;
  late AnimationController _runeController;
  late AnimationController _feedbackController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _orbAnimation;
  late Animation<double> _runeAnimation;
  late Animation<double> _feedbackAnimation;

  // ===== TIMERY =====
  Timer? _detectionTimer;
  Timer? _forceCloseTimer;

  @override
  void initState() {
    super.initState();
    print('🚀 PalmScanScreen initState - userName: ${widget.userName}');
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposing) {
        if (widget.testMode) {
          print('🧪 Tryb testowy - inicjalizacja');
          _initializeTestMode();
        } else {
          print('📷 Tryb kamery - inicjalizacja');
          _initializeCamera();
        }
      }
    });
  }

  void _initializeAnimations() {
    try {
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      )..repeat(reverse: true);

      _orbController = AnimationController(
        duration: const Duration(milliseconds: 4000),
        vsync: this,
      )..repeat();

      _runeController = AnimationController(
        duration: const Duration(milliseconds: 6000),
        vsync: this,
      )..repeat();

      _feedbackController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );

      _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      );

      _orbAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _orbController, curve: Curves.linear),
      );

      _runeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _runeController, curve: Curves.linear),
      );

      _feedbackAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut),
      );

      print('✅ Animacje zainicjalizowane');
    } catch (e) {
      print('❌ Błąd inicjalizacji animacji: $e');
    }
  }

  void _initializeTestMode() {
    if (_isDisposing || _hasCompletedScan) return;

    print('🧪 Test mode initialized');
    setState(() {
      _isCameraInitialized = true;
      _showCamera = false;
      _detectionStatus = _getHandInstruction();
    });
    _startPalmDetection();
  }

  String _getHandInstruction() {
    if (widget.userGender == 'other' ||
        widget.userGender == 'inna' ||
        widget.userGender == 'neutral') {
      final dominantHand = widget.dominantHand?.toLowerCase() ?? 'right';
      final handName = dominantHand == 'left' ? 'lewą' : 'prawą';
      return 'Przygotuj $handName dłoń - dominującą energię';
    } else {
      final handType = widget.userGender == 'female' ? 'lewą' : 'prawą';
      final energyType = widget.userGender == 'female' ? 'kobiecą' : 'męską';
      return 'Przygotuj $handType dłoń - $energyType energię';
    }
  }

  String get _targetHand {
    if (widget.userGender == 'other' ||
        widget.userGender == 'inna' ||
        widget.userGender == 'neutral') {
      return widget.dominantHand?.toLowerCase() ?? 'right';
    }
    return widget.userGender == 'female' ? 'left' : 'right';
  }

  String _getTargetHandName() {
    if (widget.userGender == 'other' ||
        widget.userGender == 'inna' ||
        widget.userGender == 'neutral') {
      final dominantHand = widget.dominantHand?.toLowerCase() ?? 'right';
      return dominantHand == 'left' ? 'lewą' : 'prawą';
    }
    return widget.userGender == 'female' ? 'lewą' : 'prawą';
  }

  Future<void> _initializeCamera() async {
    if (_isDisposing || _hasCompletedScan || _isCameraLocked) return;

    try {
      _isCameraLocked = true;
      print('📷 Inicjalizacja kamery...');

      await _safeDisposeCamera();
      if (_isDisposing || _hasCompletedScan) return;

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no_cameras', 'Brak dostępnych kamer');
      }

      CameraDescription? frontCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      _cameraController = CameraController(
        frontCamera ?? cameras[0],
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
        _showCamera = true;
        _detectionStatus = _getHandInstruction();
      });

      print('✅ Kamera zainicjalizowana');
      _startPalmDetection();
      _startForceCloseTimer();
    } catch (e) {
      print('❌ Camera Error: $e');
      if (mounted && !_isDisposing) {
        setState(() {
          _detectionStatus = 'Błąd kamery - przywołaj energię ponownie';
          _isCameraInitialized = false;
          _showCamera = false;
        });
      }
    } finally {
      _isCameraLocked = false;
    }
  }

  Future<void> _safeDisposeCamera() async {
    if (_cameraController != null) {
      try {
        print('🗑️ Dispose kamery...');
        final controller = _cameraController;
        _cameraController = null;

        if (mounted) {
          setState(() {
            _isCameraInitialized = false;
            _showCamera = false;
          });
        }

        await Future.delayed(const Duration(milliseconds: 100));
        await controller?.dispose();
        print('✅ Kamera disposed');
      } catch (e) {
        print('❌ Błąd dispose kamery: $e');
      }
    }
  }

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

  void _cancelAllTimers() {
    print('⏹️ Anulowanie timerów');
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
        print('⏰ TIMEOUT: Automatyczne zakończenie');
        _forceCompleteScan();
      }
    });
  }

  void _startPalmDetection() {
    if (_hasCompletedScan || _isDisposing) return;

    print('🔍 START wykrywania dłoni');

    _detectionTimer?.cancel();
    _detectionTimer =
        Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted || _hasCompletedScan || _isDisposing) {
        timer.cancel();
        return;
      }

      _scanAttempts++;
      _checkPalmPosition();

      if (_scanAttempts % 3 == 0) {
        print(
            '🔍 Skanowanie - próba $_scanAttempts, dobre: $_goodChecks/$_requiredGoodChecks');
      }
    });
  }

  Future<void> _checkPalmPosition() async {
    if (!mounted || _isDisposing || _hasCompletedScan || _isAnalyzing) {
      return;
    }

    try {
      final detectionResult = await _palmDetectionService.validatePalmDetection(
        handType: _targetHand,
        userName: widget.userName,
        isTestMode: widget.testMode,
      );

      if (detectionResult) {
        _goodChecks++;
        print('✅ DOBRE WARUNKI: $_goodChecks/$_requiredGoodChecks');

        setState(() {
          _palmDetected = true;
          int remaining = _requiredGoodChecks - _goodChecks;
          if (remaining > 0) {
            _detectionStatus =
                'Energia się koncentruje... jeszcze $remaining sprawdzeń';
            _triggerHapticFeedback();
          } else {
            _detectionStatus = 'Mistyczne moce są z Tobą! Uwieczniam wizję...';
            _triggerSuccessFeedback();
          }
        });

        if (_goodChecks >= _requiredGoodChecks &&
            !_isAnalyzing &&
            !_hasCompletedScan) {
          print('🎯 WSZYSTKIE WARUNKI SPEŁNIONE - PRZECHODZĘ DO ANALIZY!');
          _cancelAllTimers();

          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted && !_hasCompletedScan && !_isAnalyzing) {
              _navigateToFortuneLoading();
            }
          });
        }
      } else {
        if (_goodChecks > 0) {
          print('❌ WARUNKI ZŁAMANE - RESET');
        }
        _goodChecks = 0;

        setState(() {
          _palmDetected = false;
          _detectionStatus = _getPositioningMessage();
        });
        _triggerErrorFeedback();
      }
    } catch (e) {
      print('❌ Błąd sprawdzania pozycji: $e');
      _goodChecks = 0;
      setState(() {
        _palmDetected = false;
        _detectionStatus = 'Przeszkoda w energii - spróbuj ponownie';
      });
    }
  }

  String _getPositioningMessage() {
    final handType = _getTargetHandName();
    List<String> messages = [
      'Umieść $handType dłoń w mistycznym kręgu',
      'Pokaż wnętrze dłoni - niech energie płyną',
      'Wycentruj dłoń w portalu wiedzy',
      'Ustabilizuj aurę - trzymaj spokojnie',
      'Wpuść światło na linię życia',
    ];
    return messages[_scanAttempts % messages.length];
  }

  // ✅ POPRAWIONA METODA - teraz przechodzi do ekranu ładowania
  Future<void> _navigateToFortuneLoading() async {
    if (_hasCompletedScan || _isDisposing || _isAnalyzing) {
      print('⚠️ Nawigacja przerwana - już w toku');
      return;
    }

    print('🔮 === ROZPOCZYNAM PRZEJŚCIE DO EKRANU ŁADOWANIA ===');
    _cancelAllTimers();

    setState(() {
      _hasCompletedScan = true;
      _isAnalyzing = true;
      _detectionStatus = 'Przygotowuję mistyczną analizę...';
    });

    try {
      // ✅ WYKONANIE ZDJĘCIA PRZED ZAMKNIĘCIEM KAMERY
      XFile? palmPhoto;
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        try {
          palmPhoto = await _cameraController!.takePicture();
          print('📸 Zdjęcie wykonane: ${palmPhoto.path}');
        } catch (photoError) {
          print('❌ Błąd zdjęcia: $photoError');
        }
      }

      // ✅ BEZPIECZNE ZAMKNIĘCIE KAMERY
      await _safeDisposeCamera();

      // ✅ TWORZENIE UserData
      final userData = UserData(
        name: widget.userName,
        birthDate: widget.birthDate ?? DateTime(2000, 1, 1),
        gender: widget.userGender,
        dominantHand: widget.dominantHand ?? 'right',
        registrationDate: DateTime.now(),
      );

      if (mounted && !_isDisposing) {
        print('🚀 Nawigacja do FortuneLoadingScreen...');

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                FortuneLoadingScreen(
              userData: userData,
              handType: _targetHand,
              palmPhoto: palmPhoto, // ✅ Przekaż prawdziwe zdjęcie!
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      } else {
        print('⚠️ Widget nie jest mounted - pomijam nawigację');
      }
    } catch (e) {
      print('❌ Błąd nawigacji: $e');

      if (mounted && !_isDisposing) {
        setState(() {
          _detectionStatus =
              'Zakłócenia w przepływie energii - spróbuj ponownie';
          _isAnalyzing = false;
          _hasCompletedScan = false;
        });

        _showErrorDialog(e.toString());
      }
    }
  }

  void _triggerHapticFeedback() {
    try {
      HapticFeedback.selectionClick();
      _feedbackController.forward().then((_) => _feedbackController.reverse());
    } catch (e) {
      print('❌ Błąd haptic feedback: $e');
    }
  }

  void _triggerSuccessFeedback() {
    try {
      HapticFeedback.mediumImpact();
      _feedbackController.forward().then((_) => _feedbackController.reverse());
    } catch (e) {
      print('❌ Błąd success feedback: $e');
    }
  }

  void _triggerErrorFeedback() {
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      print('❌ Błąd error feedback: $e');
    }
  }

  String get _topPanelTitle {
    return 'Drogi/a ${widget.userName}';
  }

  @override
  void dispose() {
    print('🗑️ DISPOSE - START');
    _isDisposing = true;
    _hasCompletedScan = true;

    WidgetsBinding.instance.removeObserver(this);
    _cancelAllTimers();

    try {
      _pulseController.dispose();
      _orbController.dispose();
      _runeController.dispose();
      _feedbackController.dispose();
      print('✅ Animacje disposed');
    } catch (e) {
      print('❌ Błąd dispose animacji: $e');
    }

    _safeDisposeCamera();

    print('✅ DISPOSE - ZAKOŃCZONE');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMysticalBackground(),
          if (_showCamera &&
              _cameraController != null &&
              _cameraController!.value.isInitialized &&
              !_isDisposing &&
              !_hasCompletedScan)
            _buildCameraPreview(),
          _buildMysticalOverlay(),
        ],
      ),
    );
  }

  Widget _buildMysticalBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Color(0xFF0D1B2A),
            Color(0xFF1B263B),
            Color(0xFF000000),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _orbAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: MysticalBackgroundPainter(_orbAnimation.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildMysticalOverlay() {
    return SafeArea(
      child: Column(
        children: [
          _buildTopMysticalPanel(),
          Expanded(
            child: Center(
              child: _buildScanningFrame(),
            ),
          ),
          _buildBottomMysticalPanel(),
        ],
      ),
    );
  }

  Widget _buildTopMysticalPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.85),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.cyan.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    print('🔙 Powrót do poprzedniego ekranu');
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  iconSize: 20,
                ),
              ),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _runeAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _runeAnimation.value * 2 * math.pi,
                            child: Icon(
                              Icons.auto_awesome,
                              color: AppColors.cyan,
                              size: 20,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'MISTYCZNY RYTUAŁ',
                          style: GoogleFonts.cinzelDecorative(
                            fontSize: 16,
                            color: AppColors.cyan,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _runeAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: -_runeAnimation.value * 2 * math.pi,
                            child: Icon(
                              Icons.auto_awesome,
                              color: AppColors.cyan,
                              size: 20,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _topPanelTitle,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getHandInstruction(),
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: AppColors.cyan.withOpacity(0.8),
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScanningFrame() {
    return AnimatedBuilder(
      animation: _feedbackAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _palmDetected ? _feedbackAnimation.value : 1.0,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 300,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _palmDetected
                        ? Colors.green.withOpacity(0.9)
                        : AppColors.cyan.withOpacity(0.7),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_palmDetected ? Colors.green : AppColors.cyan)
                          .withOpacity(0.3 * _pulseAnimation.value),
                      blurRadius: 25,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    _buildMysticalCorners(),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _palmDetected
                                    ? Colors.green
                                    : AppColors.cyan,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_palmDetected
                                          ? Colors.green
                                          : AppColors.cyan)
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              _palmDetected
                                  ? Icons.check_circle_outline
                                  : Icons.pan_tool_outlined,
                              color:
                                  _palmDetected ? Colors.green : AppColors.cyan,
                              size: 32,
                              semanticLabel: _palmDetected
                                  ? 'Dłoń wykryta'
                                  : 'Umieść dłoń w ramce',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _palmDetected
                                ? 'ENERGIA WYKRYTA'
                                : 'POKAŻ ${_getTargetHandName().toUpperCase()} DŁOŃ',
                            style: GoogleFonts.cinzelDecorative(
                              color:
                                  _palmDetected ? Colors.green : AppColors.cyan,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_palmDetected && _goodChecks > 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.green.withOpacity(0.15),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.6),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '$_goodChecks / $_requiredGoodChecks',
                                style: GoogleFonts.cinzelDecorative(
                                  color: Colors.green,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                semanticsLabel:
                                    'Postęp: $_goodChecks z $_requiredGoodChecks sprawdzeń',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMysticalCorners() {
    return Stack(
      children: [
        Positioned(
          top: 5,
          left: 5,
          child: AnimatedBuilder(
            animation: _runeAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _runeAnimation.value * math.pi / 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.cyan.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.star_border,
                    color: AppColors.cyan,
                    size: 16,
                  ),
                ),
              );
            },
          ),
        ),
        // [pozostałe rogi...]
      ],
    );
  }

  Widget _buildBottomMysticalPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status detection
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _palmDetected
                  ? Colors.green.withOpacity(0.12)
                  : Colors.black.withOpacity(0.7),
              border: Border.all(
                color: _palmDetected
                    ? Colors.green.withOpacity(0.4)
                    : AppColors.cyan.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Text(
              _detectionStatus,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 16,
                color: _palmDetected
                    ? Colors.green.withOpacity(0.95)
                    : Colors.white,
                fontWeight: FontWeight.w400,
                height: 1.4,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Test mode button
          if (widget.testMode) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isAnalyzing
                    ? null
                    : () {
                        print('🧪 RĘCZNE WYWOŁANIE ANALIZY - TEST MODE');
                        _navigateToFortuneLoading();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.cyan.withOpacity(0.5),
                ),
                child: Text(
                  _isAnalyzing ? 'Analizuję...' : 'Testuj Analizę',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _restartScanning() {
    if (_isDisposing || _hasCompletedScan) return;

    print('🔄 Restart skanowania');

    setState(() {
      _hasCompletedScan = false;
      _isAnalyzing = false;
      _scanAttempts = 0;
      _goodChecks = 0;
      _palmDetected = false;
      _detectionStatus = _getHandInstruction();
    });

    _cancelAllTimers();

    if (widget.testMode) {
      _initializeTestMode();
    } else {
      _initializeCamera();
    }
  }

  void _showErrorDialog(String error) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red.withOpacity(0.5), width: 1),
        ),
        title: Text(
          'Błąd Analizy',
          style: GoogleFonts.cinzelDecorative(
            color: Colors.red,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Wystąpił błąd podczas analizy dłoni:\n\n$error',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Spróbuj ponownie',
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _forceCompleteScan() {
    if (_hasCompletedScan || _isDisposing) return;

    print('⏰ TIMEOUT: Wymuszone zakończenie skanowania');

    setState(() {
      _detectionStatus = 'Czas skanowania upłynął - wykonuję analizę...';
      _hasCompletedScan = true;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && !_isDisposing) {
        _navigateToFortuneLoading();
      }
    });
  }
}

// Custom painter dla mistycznego tła
class MysticalBackgroundPainter extends CustomPainter {
  final double animationValue;

  MysticalBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    try {
      // Mystical circles
      for (int i = 0; i < 3; i++) {
        final centerX = size.width * 0.5;
        final centerY = size.height * 0.5;
        final baseRadius = 50.0 + (i * 40.0);
        final animatedRadius =
            baseRadius * (1 + 0.1 * math.sin(animationValue * 2 * math.pi + i));

        if (animatedRadius > 0 && animatedRadius < size.width) {
          final opacityValue = 0.03 - i * 0.005;
          final safeOpacity = opacityValue.clamp(0.0, 1.0);

          paint.color = AppColors.cyan.withOpacity(safeOpacity);
          canvas.drawCircle(Offset(centerX, centerY), animatedRadius, paint);
        }
      }

      // Floating particles
      for (int i = 0; i < 20; i++) {
        final angle = (animationValue * 2 * math.pi) + (i * 2 * math.pi / 20);
        final radius = 80.0 + (i % 3) * 30.0;
        final x = size.width * 0.5 + radius * math.cos(angle);
        final y = size.height * 0.5 + radius * math.sin(angle);

        if (x >= -10 &&
            x <= size.width + 10 &&
            y >= -10 &&
            y <= size.height + 10) {
          final particleSize =
              1.0 + math.sin(animationValue * 3 * math.pi + i) * 0.5;

          if (particleSize > 0) {
            paint.color = AppColors.cyan.withOpacity(0.1);
            canvas.drawCircle(Offset(x, y), particleSize.abs(), paint);
          }
        }
      }
    } catch (e) {
      print('❌ Błąd w MysticalBackgroundPainter: $e');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
