// lib/screens/palm_scan_screen.dart
// Naprawiony ekran skanowania z proper lifecycle management

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import '../utils/constants.dart';
import '../services/logging_service.dart';
import '../services/ai_vision_service.dart';
import 'ai_results_screen.dart';


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
  List<CameraDescription>? _cameras;

  // ===== FLAGI ZABEZPIECZAJĄCE =====
  bool _isDisposing = false;
  bool _hasCompletedScan = false;
  bool _isCameraLocked = false;
  bool _isAnalyzingWithAI = false;
  bool _isCameraDisposed = false;

  // ===== SERWISY =====
  final LoggingService _loggingService = LoggingService();
  final AIVisionService _aiVisionService = AIVisionService();

  // ===== DANE WYKRYWANIA =====
  int _scanAttempts = 0;
  int _goodChecks = 0;
  bool _palmDetected = false;
  double _lightLevel = 0.0;
  
  // Stałe konfiguracyjne zgodne z constants
  static const int _maxScanAttempts = AppConfig.maxScanAttempts;
  static const int _requiredGoodChecks = AppConfig.requiredGoodStreak;
  static const double _minLightLevel = AppConfig.minLightLevel;

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
  Timer? _stabilityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializeCamera();
  }

  void _initializeAnimations() {
    // Animacje zgodne z wytycznymi czasowymi (150-300ms)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _orbController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _orbAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _orbController, curve: Curves.easeInOut),
    );

    _runeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _runeAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _runeController, curve: Curves.linear),
    );

    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _feedbackAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut),
    );

    // Start continuous animations
    _pulseController.repeat(reverse: true);
    _orbController.repeat();
    _runeController.repeat();
  }

  Future<void> _initializeCamera() async {
    if (_isDisposing || _hasCompletedScan || _isCameraLocked) {
      return;
    }

    _isCameraLocked = true;

    try {
      _loggingService.logCameraActivity('Inicjalizacja kamery - START');

      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('Brak dostępnych kamer');
      }

      // Prefer back camera for palm scanning
      CameraDescription selectedCamera = _cameras!.first;
      for (final camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }

      if (_isDisposing || _hasCompletedScan || !mounted) {
        return;
      }

      // Initialize camera controller
      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // Double check for disposal
      if (_isDisposing || _hasCompletedScan || !mounted || _isCameraDisposed) {
        await _safeDisposeCamera();
        return;
      }

      setState(() {
        _isCameraInitialized = true;
        _detectionStatus = _getHandInstruction();
      });

      _loggingService.logCameraActivity('Kamera zainicjalizowana POMYŚLNIE');
      _startPalmDetection();
      _startForceCloseTimer();

    } catch (e) {
      _loggingService.logToConsole('Camera Error: $e', tag: 'ERROR');
      if (mounted && !_isDisposing) {
        setState(() {
          _detectionStatus = 'Błąd kamery - przywołaj energię ponownie';
          _isCameraInitialized = false;
        });
      }
    } finally {
      _isCameraLocked = false;
    }
  }

  Future<void> _safeDisposeCamera() async {
    if (_isCameraDisposed || _cameraController == null) {
      return;
    }

    try {
      _loggingService.logCameraActivity('Dispose kamery - START');
      
      _isCameraDisposed = true;
      final controller = _cameraController;
      _cameraController = null;
      _isCameraInitialized = false;
      
      if (controller != null) {
        await controller.dispose();
      }
      
      _loggingService.logCameraActivity('Dispose kamery - ZAKOŃCZONE');
    } catch (e) {
      _loggingService.logToConsole('Błąd dispose kamery: $e', tag: 'ERROR');
    }
  }

  void _startPalmDetection() {
    if (_detectionTimer?.isActive == true) {
      _detectionTimer?.cancel();
    }

    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) => _checkPalmPosition(),
    );

    _loggingService.logToConsole('Wykrywanie dłoni uruchomione', tag: 'DETECTION');
  }

  void _startForceCloseTimer() {
    _forceCloseTimer?.cancel();
    _forceCloseTimer = Timer(AppConfig.cameraTimeout, () {
      if (!_hasCompletedScan && mounted) {
        _loggingService.logToConsole(
          'Timeout kamery - automatyczne zamknięcie',
          tag: 'TIMEOUT',
        );
        Navigator.of(context).pop();
      }
    });
  }

  void _checkPalmPosition() {
    if (_hasCompletedScan || _isAnalyzingWithAI || !mounted || _isDisposing) {
      return;
    }

    try {
      _scanAttempts++;
      
      // Symulacja warunków (w rzeczywistości użyj ML/Computer Vision)
      final random = math.Random();
      final mockPalmDetected = random.nextDouble() > 0.4;
      final mockLightLevel = 0.3 + (random.nextDouble() * 0.7);
      final mockHandStability = random.nextDouble() > 0.3;

      _lightLevel = mockLightLevel;

      _loggingService.logScanningDetails(
        palmDetected: mockPalmDetected,
        detectionStatus: _detectionStatus,
        lightLevel: _lightLevel,
        detectedHand: widget.dominantHand,
        additionalData: {
          'attempt': _scanAttempts,
          'goodChecks': _goodChecks,
          'stability': mockHandStability,
        },
      );

      if (_scanAttempts >= _maxScanAttempts) {
        _loggingService.logToConsole(
          'Maksymalna liczba prób osiągnięta',
          tag: 'LIMIT',
        );
        _showMaxAttemptsDialog();
        return;
      }

      // Check all conditions
      bool allConditionsMet = mockPalmDetected && 
                             mockLightLevel >= _minLightLevel && 
                             mockHandStability;

      if (allConditionsMet) {
        _goodChecks++;
        
        setState(() {
          _palmDetected = true;
          if (_goodChecks >= _requiredGoodChecks) {
            _detectionStatus = 'Doskonale! Uwieczniam wizję...';
            _triggerSuccessFeedback();
          } else {
            _detectionStatus = 'Świetnie! Trzymaj spokojnie... $_goodChecks/$_requiredGoodChecks';
          }
        });

        _loggingService.logToConsole(
          'DOBRE WARUNKI: $_goodChecks/$_requiredGoodChecks',
          tag: 'DETECTION',
        );

        if (_goodChecks >= _requiredGoodChecks && 
            !_isAnalyzingWithAI && 
            !_hasCompletedScan) {
          _loggingService.logToConsole(
            'WSZYSTKIE WARUNKI SPEŁNIONE - WYKONUJĘ ZDJĘCIE!',
            tag: 'CAPTURE',
          );
          _cancelAllTimers();
          
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted && !_hasCompletedScan && !_isAnalyzingWithAI) {
              _capturePalmData();
            }
          });
        }
      } else {
        if (_goodChecks > 0) {
          _loggingService.logToConsole('WARUNKI ZŁAMANE - RESET', tag: 'DETECTION');
        }
        _goodChecks = 0;

        setState(() {
          _palmDetected = false;
          _detectionStatus = _getPositioningMessage();
        });
        _triggerErrorFeedback();
      }
    } catch (e) {
      _loggingService.logToConsole(
        'Błąd sprawdzania pozycji: $e',
        tag: 'ERROR',
      );
      _goodChecks = 0;
      setState(() {
        _palmDetected = false;
        _detectionStatus = 'Przeszkoda w energii - spróbuj ponownie';
      });
    }
  }

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
      _detectionStatus = 'Uwieczniam sekretną mapę Twojej duszy...';
    });

    try {
      if (_cameraController == null || 
          !_cameraController!.value.isInitialized ||
          _isCameraDisposed) {
        throw Exception('Kamera niedostępna podczas robienia zdjęcia');
      }

      final XFile palmPhoto = await _cameraController!.takePicture();
      _loggingService.logToConsole(
        'Zdjęcie wykonane pomyślnie: ${palmPhoto.path}',
        tag: 'CAPTURE',
      );

      // Safely dispose camera before analysis
      await _safeDisposeCamera();

      setState(() {
        _detectionStatus = 'Przesyłanie do świata duchów na analizę...';
      });

      // Analyze with unified AI service
      final analysisResult = await _aiVisionService.analyzePalmWithAI(
        palmImage: palmPhoto,
        userName: widget.userName,
        userGender: widget.userGender,
        dominantHand: widget.dominantHand,
        birthDate: widget.birthDate,
      );

      // Save logs
      await _loggingService.saveDetectionLogsToFile(widget.userName);

      if (mounted) {
        _navigateToResults(analysisResult, File(palmPhoto.path));
      }
    } catch (e) {
      _loggingService.logToConsole(
        'Błąd analizy: $e',
        tag: 'AI_ERROR',
      );

      if (mounted) {
        setState(() {
          _detectionStatus = 'Zakłócenia w przepływie energii - spróbuj ponownie';
          _isAnalyzingWithAI = false;
          _hasCompletedScan = false;
        });
        
        _showErrorDialog(e.toString());
        _restartScanning();
      }
    }
  }

  void _navigateToResults(String analysisResult, File palmImage) {
    if (!mounted) return;

    _loggingService.logToConsole('Nawigacja do wyników', tag: 'NAVIGATE');

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AIResultsScreen(
          userName: widget.userName,
          userGender: widget.userGender,
          birthDate: widget.birthDate,
          dominantHand: widget.dominantHand,
          analysisResult: analysisResult,
          palmImage: palmImage,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _cancelAllTimers() {
    _detectionTimer?.cancel();
    _forceCloseTimer?.cancel();
    _stabilityTimer?.cancel();
    
    _loggingService.logToConsole('Wszystkie timery anulowane', tag: 'TIMERS');
  }

  void _triggerSuccessFeedback() {
    _feedbackController.reset();
    _feedbackController.forward();
    HapticFeedback.lightImpact();
  }

  void _triggerErrorFeedback() {
    HapticFeedback.selectionClick();
  }

  String _getHandInstruction() {
    final handType = widget.dominantHand ?? 'prawą';
    return 'Umieść $handType dłoń w mistycznym kręgu';
  }

  String _getTargetHandName() {
    return widget.dominantHand ?? 'prawą';
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

  Future<void> _restartScanning() async {
    _cancelAllTimers();
    await _safeDisposeCamera();

    if (!mounted) return;

    setState(() {
      _hasCompletedScan = false;
      _isAnalyzingWithAI = false;
      _isCameraInitialized = false;
      _isCameraDisposed = false;
      _scanAttempts = 0;
      _goodChecks = 0;
      _palmDetected = false;
      _detectionStatus = 'Wzywam mistyczną energię...';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    await _initializeCamera();
  }

  // UI Dialog methods
  void _showMaxAttemptsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Zbyt wiele prób',
          style: GoogleFonts.cinzelDecorative(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Energie są dzisiaj niespokojne. Spróbuj ponownie za chwilę lub w lepszym oświetleniu.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Wyjdź',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartScanning();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Spróbuj ponownie'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Błąd energii',
          style: GoogleFonts.cinzelDecorative(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Wystąpił problem podczas analizy: ${error.length > 100 ? error.substring(0, 100) + "..." : error}',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartScanning();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Spróbuj ponownie'),
          ),
        ],
      ),
    );
  }

  // Lifecycle methods
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.testMode || _hasCompletedScan) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _loggingService.logToConsole('App paused/detached - disposing camera', tag: 'LIFECYCLE');
        _safeDisposeCamera();
        break;
      case AppLifecycleState.resumed:
        _loggingService.logToConsole('App resumed', tag: 'LIFECYCLE');
        if (_isCameraDisposed && !_hasCompletedScan && mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _initializeCamera();
          });
        }
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _loggingService.logToConsole('DISPOSE - START', tag: 'DISPOSE');
    _isDisposing = true;
    _hasCompletedScan = true;

    WidgetsBinding.instance.removeObserver(this);
    _cancelAllTimers();

    // Dispose animations
    try {
      _pulseController.dispose();
      _orbController.dispose();
      _runeController.dispose();
      _feedbackController.dispose();
    } catch (e) {
      _loggingService.logToConsole('Błąd dispose animacji: $e', tag: 'ERROR');
    }

    // Dispose camera
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
          _buildMysticalBackground(),
          
          if (_isCameraInitialized) 
            _buildCameraPreview(),
          
          _buildOverlayUI(),
          
          if (widget.testMode)
            _buildTestModeOverlay(),
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
            Color(0xFF1A0033),
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
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  Widget _buildOverlayUI() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildScanningArea()),
          _buildStatusArea(),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(
              minWidth: 44, // Minimum 44x44 px
              minHeight: 44,
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              iconSize: 24,
            ),
          ),
          Expanded(
            child: Text(
              'Mistyczne Skanowanie',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 24, // 24-32pt dla nagłówków
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 44), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildScanningArea() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mystical scanning circle
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _palmDetected ? Colors.green : Colors.amber,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_palmDetected ? Colors.green : Colors.amber).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Hand guide
          AnimatedBuilder(
            animation: _feedbackAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * _feedbackAnimation.value),
                child: Icon(
                  Icons.pan_tool,
                  size: 100,
                  color: _palmDetected 
                    ? Colors.green.withOpacity(0.8)
                    : Colors.white.withOpacity(0.6),
                ),
              );
            },
          ),
          
          // Runes rotation
          AnimatedBuilder(
            animation: _runeAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _runeAnimation.value,
                child: CustomPaint(
                  painter: RunesPainter(),
                  size: const Size(320, 320),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Status text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Text(
              _detectionStatus,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 16, // 16-18pt dla tekstu głównego
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Progress indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProgressIndicator(
                'Światło',
                _lightLevel,
                _lightLevel >= _minLightLevel,
              ),
              _buildProgressIndicator(
                'Pozycja',
                _palmDetected ? 1.0 : 0.0,
                _palmDetected,
              ),
              _buildProgressIndicator(
                'Stabilność',
                _goodChecks / _requiredGoodChecks,
                _goodChecks >= _requiredGoodChecks,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String label, double value, bool isGood) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        CircularProgressIndicator(
          value: value.clamp(0.0, 1.0),
          backgroundColor: Colors.grey.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            isGood ? Colors.green : Colors.orange,
          ),
          strokeWidth: 3,
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            child: Container(
              height: 48, // Optimal button height
              margin: const EdgeInsets.only(right: 8),
              child: OutlinedButton(
                onPressed: _isAnalyzingWithAI ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Anuluj',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
          
          // Manual capture (for testing)
          if (widget.testMode)
            Expanded(
              child: Container(
                height: 48,
                margin: const EdgeInsets.only(left: 8),
                child: ElevatedButton(
                  onPressed: _isAnalyzingWithAI ? null : _capturePalmData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Testuj',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTestModeOverlay() {
    return Positioned(
      top: 100,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'TEST MODE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// Custom painters for mystical effects
class MysticalBackgroundPainter extends CustomPainter {
  final double animationValue;
  
  MysticalBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 20; i++) {
      final x = (size.width * 0.1) + (size.width * 0.8 * ((i * 0.618) % 1.0));
      final y = (size.height * 0.1) + (size.height * 0.8 * ((i * 0.382) % 1.0));
      final radius = 2 + (3 * math.sin(animationValue * 2 * math.pi + i));
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = Colors.purple.withOpacity(0.3 + 0.2 * math.sin(animationValue * 2 * math.pi + i)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RunesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw mystical symbols around the circle
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * math.pi) / 8;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      // Simple rune-like symbols
      canvas.drawLine(
        Offset(x - 10, y - 10),
        Offset(x + 10, y + 10),
        paint,
      );
      canvas.drawLine(
        Offset(x - 10, y + 10),
        Offset(x + 10, y - 10),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}