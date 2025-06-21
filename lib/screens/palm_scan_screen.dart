// lib/screens/palm_scan_screen.dart
// NAPRAWIONA WERSJA - idealny przycisk + duża ikona dłoni

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../services/palm_detection_service.dart';
import '../services/logging_service.dart';
import '../models/user_data.dart';
import 'fortune_loading_screen.dart';

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
  bool _showCamera = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  List<CameraDescription> _cameras = [];

  // ===== FLAGI ZABEZPIECZAJĄCE =====
  bool _isDisposing = false;
  bool _hasCompletedScan = false;
  bool _isCameraLocked = false;
  bool _isAnalyzing = false;
  bool _isTakingPhoto = false;

  // ===== SERWISY =====
  final PalmDetectionService _palmDetectionService = PalmDetectionService();
  final LoggingService _loggingService = LoggingService();
  final ImagePicker _imagePicker = ImagePicker();

  // ===== WYKRYWANIE =====
  bool _palmDetected = false;
  String _detectionMessage = '';
  String _positionStatus = 'neutral'; // 'good', 'bad', 'neutral'

  // ===== ANIMACJE =====
  late AnimationController _pulseController;
  late AnimationController _contourController;
  late AnimationController _feedbackController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _contourAnimation;
  late Animation<double> _feedbackAnimation;

  // ===== TIMERY =====
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    print('🚀 NEW PalmScanScreen initState - userName: ${widget.userName}');
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializeDetectionMessage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposing) {
        if (widget.testMode) {
          print('🧪 Tryb testowy - inicjalizacja bez kamery');
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

      _contourController = AnimationController(
        duration: const Duration(milliseconds: 3000),
        vsync: this,
      )..repeat();

      _feedbackController = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );

      _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      );

      _contourAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _contourController, curve: Curves.linear),
      );

      _feedbackAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut),
      );

      print('✅ Animacje zainicjalizowane');
    } catch (e) {
      print('❌ Błąd inicjalizacji animacji: $e');
    }
  }

  void _initializeDetectionMessage() {
    final handType = _getTargetHandName();
    setState(() {
      _detectionMessage = 'Pokaż $handType dłoń';
      _positionStatus = 'neutral';
    });
  }

  void _initializeTestMode() {
    if (_isDisposing || _hasCompletedScan) return;

    print('🧪 Test mode initialized');
    setState(() {
      _isCameraInitialized = true;
      _showCamera = false;
      _detectionMessage = 'Tryb testowy - ${_getTargetHandName()} dłoń';
    });
    _startMockDetection();
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

  String get _targetHand {
    if (widget.userGender == 'other' ||
        widget.userGender == 'inna' ||
        widget.userGender == 'neutral') {
      return widget.dominantHand?.toLowerCase() ?? 'right';
    }
    return widget.userGender == 'female' ? 'left' : 'right';
  }

  Future<void> _initializeCamera() async {
    if (_isDisposing || _hasCompletedScan || _isCameraLocked) return;

    try {
      _isCameraLocked = true;
      print('📷 Inicjalizacja kamery...');

      await _safeDisposeCamera();
      if (_isDisposing || _hasCompletedScan) return;

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('no_cameras', 'Brak dostępnych kamer');
      }

      CameraDescription? frontCamera;
      CameraDescription? backCamera;

      for (var camera in _cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
        } else if (camera.lensDirection == CameraLensDirection.back) {
          backCamera = camera;
        }
      }

      final selectedCamera = _isFrontCamera
          ? (frontCamera ?? backCamera ?? _cameras[0])
          : (backCamera ?? frontCamera ?? _cameras[0]);

      _cameraController = CameraController(
        selectedCamera,
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
      });

      print('✅ Kamera zainicjalizowana');
      _startMockDetection();
    } catch (e) {
      print('❌ Camera Error: $e');
      if (mounted && !_isDisposing) {
        setState(() {
          _detectionMessage = 'Błąd kamery - sprawdź uprawnienia';
          _isCameraInitialized = false;
          _showCamera = false;
          _positionStatus = 'bad';
        });
        _showCameraErrorDialog();
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
            _isFlashOn = false;
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

  void _startMockDetection() {
    if (_hasCompletedScan || _isDisposing) return;

    print('🔍 START mock detection');
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || _hasCompletedScan || _isDisposing) {
        timer.cancel();
        return;
      }
      _simulateDetection();
    });
  }

  void _simulateDetection() {
    if (!mounted || _isDisposing || _hasCompletedScan) return;

    final random = math.Random();
    final detectionChance = random.nextDouble();

    if (detectionChance > 0.7) {
      setState(() {
        _palmDetected = true;
        _positionStatus = 'good';
        _detectionMessage = 'Doskonała pozycja! ✨';
      });
      _triggerSuccessFeedback();
    } else if (detectionChance > 0.4) {
      setState(() {
        _palmDetected = false;
        _positionStatus = 'neutral';
        _detectionMessage = _getRandomPositionHint();
      });
    } else {
      setState(() {
        _palmDetected = false;
        _positionStatus = 'bad';
        _detectionMessage = 'Brak dłoni w kadrze';
      });
    }
  }

  String _getRandomPositionHint() {
    final hints = [
      'Wyśrodkuj dłoń w konturze',
      'Przybliż dłoń do kamery',
      'Rozłóż palce szerzej',
      'Trzymaj dłoń nieruchomo',
      'Popraw oświetlenie',
    ];
    return hints[math.Random().nextInt(hints.length)];
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
    _detectionTimer?.cancel();
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

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });

      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );

      HapticFeedback.selectionClick();
      print('💡 Flash ${_isFlashOn ? "ON" : "OFF"}');
    } catch (e) {
      print('❌ Błąd flash: $e');
      setState(() {
        _isFlashOn = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isCameraLocked) return;

    try {
      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });

      await _initializeCamera();
      HapticFeedback.mediumImpact();
      print('🔄 Camera switched to ${_isFrontCamera ? "FRONT" : "BACK"}');
    } catch (e) {
      print('❌ Błąd przełączania kamery: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        print('📁 Wybrano zdjęcie z galerii: ${pickedFile.path}');
        HapticFeedback.mediumImpact();
        await _navigateToFortuneLoading(pickedFile);
      }
    } catch (e) {
      print('❌ Błąd wyboru zdjęcia: $e');
      _showErrorSnackBar('Nie udało się wybrać zdjęcia');
    }
  }

  Future<void> _takePicture() async {
    if (_isTakingPhoto ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isTakingPhoto = true;
    });

    try {
      print('📸 Robienie zdjęcia...');
      final XFile photo = await _cameraController!.takePicture();
      HapticFeedback.heavyImpact();
      print('✅ Zdjęcie wykonane: ${photo.path}');
      await _navigateToFortuneLoading(photo);
    } catch (e) {
      print('❌ Błąd wykonywania zdjęcia: $e');
      _showErrorSnackBar('Nie udało się wykonać zdjęcia');
    } finally {
      setState(() {
        _isTakingPhoto = false;
      });
    }
  }

  Future<void> _navigateToFortuneLoading(XFile photo) async {
    if (_hasCompletedScan || _isDisposing || _isAnalyzing) {
      print('⚠️ Nawigacja przerwana - już w toku');
      return;
    }

    print('🔮 === PRZEJŚCIE DO EKRANU ŁADOWANIA ===');
    _detectionTimer?.cancel();

    setState(() {
      _hasCompletedScan = true;
      _isAnalyzing = true;
      _detectionMessage = 'Przygotowuję mistyczną analizę...';
    });

    try {
      await _safeDisposeCamera();

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
              palmPhoto: photo,
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
      }
    } catch (e) {
      print('❌ Błąd nawigacji: $e');
      if (mounted && !_isDisposing) {
        setState(() {
          _detectionMessage = 'Błąd - spróbuj ponownie';
          _isAnalyzing = false;
          _hasCompletedScan = false;
          _positionStatus = 'bad';
        });
        _showErrorSnackBar('Wystąpił błąd podczas analizy');
      }
    }
  }

  void _triggerSuccessFeedback() {
    try {
      HapticFeedback.mediumImpact();
      _feedbackController.forward().then((_) => _feedbackController.reverse());
    } catch (e) {
      print('❌ Błąd haptic feedback: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cinzelDecorative(color: Colors.white),
        ),
        backgroundColor: Colors.red.withOpacity(0.8),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCameraErrorDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red.withOpacity(0.5), width: 1),
        ),
        title: Text(
          'Kamera niedostępna',
          style: GoogleFonts.cinzelDecorative(
            color: Colors.red,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Nie mogę wykonać wróżby z dłoni.\nSprawdź uprawnienia do kamery lub wybierz zdjęcie z galerii.',
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
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
              'Wróć',
              style: GoogleFonts.cinzelDecorative(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImageFromGallery();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Wybierz zdjęcie',
              style: GoogleFonts.cinzelDecorative(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print('🗑️ DISPOSE - START');
    _isDisposing = true;
    _hasCompletedScan = true;

    WidgetsBinding.instance.removeObserver(this);
    _detectionTimer?.cancel();

    try {
      _pulseController.dispose();
      _contourController.dispose();
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
              _cameraController!.value.isInitialized)
            _buildCameraPreview(),
          _buildOverlay(),
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
        animation: _contourAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: ScanBackgroundPainter(_contourAnimation.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Positioned.fill(
      child: ClipRRect(
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  Widget _buildOverlay() {
    return SafeArea(
      child: Column(
        children: [
          _buildTopInstructions(),
          Expanded(
            child: _buildCenterFrame(),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildTopInstructions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                iconSize: 20,
              ),
              Expanded(
                child: Text(
                  'SKAN DŁONI',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 18,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _targetHand == 'left' ? '🤚' : '🖐️',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Pokaż ${_getTargetHandName().toUpperCase()} DŁOŃ',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCenterFrame() {
    return Stack(
      children: [
        // ✅ NAPRAWKA: DUŻA IKONA DŁONI NA CAŁYM EKRANIE
        Positioned.fill(
          child: Center(
            child: AnimatedBuilder(
              animation: _feedbackAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _palmDetected ? _feedbackAnimation.value : 1.0,
                  child: _buildFullScreenPalmIcon(),
                );
              },
            ),
          ),
        ),

        // Status bubble z komunikatem
        if (_detectionMessage.isNotEmpty)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: _buildStatusBubble(),
          ),
      ],
    );
  }

  // ✅ NAPRAWKA: DUŻA IKONA DŁONI
  Widget _buildFullScreenPalmIcon() {
    Color frameColor;
    switch (_positionStatus) {
      case 'good':
        frameColor = Colors.green;
        break;
      case 'bad':
        frameColor = Colors.red;
        break;
      default:
        frameColor = AppColors.cyan;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: MediaQuery.of(context).size.width *
                0.8, // 80% szerokości ekranu
            height: MediaQuery.of(context).size.height *
                0.5, // 50% wysokości ekranu
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: frameColor.withOpacity(0.6),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: frameColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                // ✅ GŁÓWNA IKONA DŁONI - DUŻA I NA ŚRODKU
                Center(
                  child: Icon(
                    Icons.pan_tool_outlined,
                    size: 200, // ✅ WIELKA IKONA!
                    color: frameColor.withOpacity(0.4),
                  ),
                ),

                // Subtelne linie dłoni jako overlay
                CustomPaint(
                  painter: PalmContourPainter(
                    animationValue: _contourAnimation.value,
                    frameColor: frameColor,
                    positionStatus: _positionStatus,
                  ),
                  size: Size.infinite,
                ),

                // Narożne wskaźniki
                _buildCornerIndicators(frameColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBubble() {
    Color bubbleColor;
    IconData bubbleIcon;

    switch (_positionStatus) {
      case 'good':
        bubbleColor = Colors.green;
        bubbleIcon = Icons.check_circle;
        break;
      case 'bad':
        bubbleColor = Colors.red;
        bubbleIcon = Icons.warning;
        break;
      default:
        bubbleColor = AppColors.cyan;
        bubbleIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bubbleColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: bubbleColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: bubbleColor.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            bubbleIcon,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _detectionMessage,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerIndicators(Color frameColor) {
    return Stack(
      children: [
        // Top-left corner
        Positioned(
          top: 10,
          left: 10,
          child: _buildCornerWidget(frameColor),
        ),
        // Top-right corner
        Positioned(
          top: 10,
          right: 10,
          child: _buildCornerWidget(frameColor),
        ),
        // Bottom-left corner
        Positioned(
          bottom: 10,
          left: 10,
          child: _buildCornerWidget(frameColor),
        ),
        // Bottom-right corner
        Positioned(
          bottom: 10,
          right: 10,
          child: _buildCornerWidget(frameColor),
        ),
      ],
    );
  }

  Widget _buildCornerWidget(Color color) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.8), width: 3),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // ✅ GALERIA - KOMPAKTOWY PRZYCISK
          Expanded(
            flex: 1,
            child: _buildSideControlButton(
              icon: Icons.photo_library,
              label: 'Galeria',
              onTap: _pickImageFromGallery,
              isEnabled: true,
            ),
          ),

          // ✅ SPACER DLA CENTRALNEGO PRZYCISKU
          const SizedBox(width: 24),

          // ✅ CENTRALNY PRZYCISK ZDJĘCIA - IDEALNIE NA ŚRODKU
          _buildMainCaptureButton(),

          // ✅ SPACER DLA CENTRALNEGO PRZYCISKU
          const SizedBox(width: 24),

          // ✅ LATARKA I PRZEŁĄCZNIK - KOMPAKTOWE
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildSideControlButton(
                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  label: 'Latarka',
                  onTap: _toggleFlash,
                  isActive: _isFlashOn,
                  isEnabled: _showCamera,
                ),
                const SizedBox(height: 12),
                _buildSideControlButton(
                  icon: Icons.flip_camera_ios,
                  label: 'Przełącz',
                  onTap: _switchCamera,
                  isEnabled: _showCamera && _cameras.length > 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NAPRAWKA: BOCZNE PRZYCISKI - KOMPAKTOWE
  Widget _buildSideControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isEnabled = true,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? AppColors.cyan.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                border: Border.all(
                  color:
                      isActive ? AppColors.cyan : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: isActive ? AppColors.cyan : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 11,
                color: isActive ? AppColors.cyan : Colors.white70,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NAPRAWKA: GŁÓWNY PRZYCISK - IDEALNIE NA ŚRODKU
  Widget _buildMainCaptureButton() {
    return Center(
      // ✅ WYŚRODKOWANIE!
      child: GestureDetector(
        onTap: _isTakingPhoto ? null : _takePicture,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isTakingPhoto ? 0.9 : _pulseAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.cyan,
                      AppColors.cyan.withOpacity(0.8),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: _isTakingPhoto
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      )
                    : Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Custom painter dla konturu dłoni - UPROSZCZONY
class PalmContourPainter extends CustomPainter {
  final double animationValue;
  final Color frameColor;
  final String positionStatus;

  PalmContourPainter({
    required this.animationValue,
    required this.frameColor,
    required this.positionStatus,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = frameColor.withOpacity(0.3);

    try {
      // ✅ TYLKO SUBTELNE LINIE DŁONI
      _drawPalmLines(canvas, size, paint);

      // Dodatkowe wskaźniki dla dobrej pozycji
      if (positionStatus == 'good') {
        _drawSuccessIndicators(canvas, size);
      }
    } catch (e) {
      print('❌ Błąd w PalmContourPainter: $e');
    }
  }

  void _drawPalmLines(Canvas canvas, Size size, Paint paint) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // ✅ SUBTELNE LINIE DŁONI
    paint.strokeWidth = 1.5;
    paint.color = frameColor
        .withOpacity(0.15 + (0.1 * math.sin(animationValue * 2 * math.pi)));

    // Linia życia
    final lifeLinePath = Path();
    lifeLinePath.moveTo(centerX - 60, centerY - 30);
    lifeLinePath.quadraticBezierTo(
        centerX - 40, centerY + 10, centerX - 20, centerY + 50);
    lifeLinePath.quadraticBezierTo(
        centerX, centerY + 70, centerX + 20, centerY + 80);
    canvas.drawPath(lifeLinePath, paint);

    // Linia serca
    final heartLinePath = Path();
    heartLinePath.moveTo(centerX - 50, centerY - 30);
    heartLinePath.quadraticBezierTo(
        centerX - 20, centerY - 50, centerX + 30, centerY - 40);
    canvas.drawPath(heartLinePath, paint);

    // Linia głowy
    final headLinePath = Path();
    headLinePath.moveTo(centerX - 50, centerY - 10);
    headLinePath.quadraticBezierTo(
        centerX - 10, centerY + 10, centerX + 40, centerY + 15);
    canvas.drawPath(headLinePath, paint);
  }

  void _drawSuccessIndicators(Canvas canvas, Size size) {
    final successPaint = Paint()
      ..color = Colors.green.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Małe kropki wskazujące dobre pozycjonowanie
    final points = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.8, size.height * 0.7),
    ];

    for (final point in points) {
      canvas.drawCircle(point, 3, successPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter dla tła
class ScanBackgroundPainter extends CustomPainter {
  final double animationValue;

  ScanBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    try {
      // Subtelne cząsteczki w tle
      for (int i = 0; i < 15; i++) {
        final angle = (animationValue * math.pi) + (i * 2 * math.pi / 15);
        final radius = 80.0 + (i % 3) * 40.0;
        final x = size.width * 0.5 + radius * math.cos(angle * 0.3);
        final y = size.height * 0.5 + radius * math.sin(angle * 0.4);

        if (x >= -20 &&
            x <= size.width + 20 &&
            y >= -20 &&
            y <= size.height + 20) {
          final particleSize =
              1.0 + math.sin(animationValue * 3 * math.pi + i) * 0.5;
          final opacity =
              0.05 + math.sin(animationValue * 2 * math.pi + i * 0.5) * 0.03;

          if (particleSize > 0) {
            paint.color = AppColors.cyan.withOpacity(opacity.clamp(0.01, 0.08));
            canvas.drawCircle(Offset(x, y), particleSize.abs(), paint);
          }
        }
      }
    } catch (e) {
      print('❌ Błąd w ScanBackgroundPainter: $e');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
