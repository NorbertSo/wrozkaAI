// lib/screens/fortune_loading_screen.dart
// NOWY INTERAKTYWNY KONCEPT - przytrzymaj ekran

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../services/ai_palm_analysis_service.dart';
import '../services/haptic_service.dart';
import '../models/user_data.dart';
import 'palm_analysis_result_screen.dart';
import 'package:camera/camera.dart';
import 'package:lottie/lottie.dart';

class FortuneLoadingScreen extends StatefulWidget {
  final UserData userData;
  final String handType;
  final XFile? palmPhoto;

  const FortuneLoadingScreen({
    super.key,
    required this.userData,
    required this.handType,
    this.palmPhoto,
  });

  @override
  State<FortuneLoadingScreen> createState() => _FortuneLoadingScreenState();
}

class _FortuneLoadingScreenState extends State<FortuneLoadingScreen>
    with TickerProviderStateMixin {
  // ===== KONTROLERY ANIMACJI =====
  late AnimationController _backgroundController;
  late AnimationController _loading1Controller;
  late AnimationController _loading2Controller;
  late AnimationController _glowController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _loading1Animation;
  late Animation<double> _loading2Animation;
  late Animation<double> _glowAnimation;

  // ===== STAN INTERAKCJI =====
  bool _isHolding = false;
  bool _hasStartedLoading2 = false;
  bool _isAnalysisComplete = false;
  double _totalProgress = 0.0; // 0.0 - 1.0 (10 sekund)

  // ===== TIMERY I SERWISY =====
  Timer? _progressTimer;
  Timer? _vibrationTimer;
  final HapticService _hapticService = HapticService();

  // ===== ANALIZA AI =====
  bool _isAnalyzing = true;
  PalmAnalysisResult? _analysisResult;

  // ===== KOLORY TŁA =====
  final List<Color> _backgroundColors = [
    const Color(0xFF0D1B2A), // Ciemny niebieski
    const Color(0xFF1B263B), // Średni niebieski
    const Color(0xFF2D1B3B), // Fioletowy
    const Color(0xFF3B1B2D), // Ciemny fiolet
    const Color(0xFF3B2D1B), // Brązowy
    const Color(0xFF1B3B2D), // Ciemny zielony
    const Color(0xFF1B2D3B), // Powrót do niebieskiego
  ];

  @override
  void initState() {
    super.initState();
    print('🔮 Nowy Fortune Loading Screen - START');
    _initializeAnimations();
    _startRealAnalysis();
  }

  void _initializeAnimations() {
    // Animacja tła (12 sekund)
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );

    // Animacja loading1 (ciągła)
    _loading1Controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Animacja loading2 (fade-in od 3-8 sekundy) - 5 sekund
    _loading2Controller = AnimationController(
      duration: const Duration(seconds: 5), // 3s-8s
      vsync: this,
    );

    // Animacja poświaty
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Konfiguracja animacji
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _loading1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loading1Controller, curve: Curves.easeInOut),
    );

    _loading2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loading2Controller, curve: Curves.easeIn),
    );

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  // ===== INTERAKCJA - PRZYTRZYMYWANIE =====
  void _startHolding() {
    if (_isHolding) return;

    print('👆 START HOLDING');
    setState(() {
      _isHolding = true;
    });

    // Start animacji loading1
    _loading1Controller.repeat();

    // Start progressu
    _startProgressTimer();

    // Start wibracji
    _startVibrationPattern();

    // Start animacji tła
    _backgroundController.forward();
  }

  void _stopHolding() {
    if (!_isHolding) return;

    print('👆 STOP HOLDING');
    setState(() {
      _isHolding = false;
    });

    // Zatrzymaj wszystkie animacje
    _loading1Controller.stop();
    _backgroundController.stop();

    // Zatrzymaj timery
    _progressTimer?.cancel();
    _vibrationTimer?.cancel();

    // Jeśli loading2 się już rozpoczął, zatrzymaj go też
    if (_hasStartedLoading2) {
      _loading2Controller.stop();
    }
  }

  void _resumeHolding() {
    if (_isHolding) return;

    print('👆 RESUME HOLDING');
    setState(() {
      _isHolding = true;
    });

    // Wznów animacje od miejsca gdzie były
    _loading1Controller.repeat();
    _backgroundController.forward();

    if (_hasStartedLoading2) {
      _loading2Controller.forward();
    }

    // Wznów timery
    _startProgressTimer();
    _startVibrationPattern();
  }

  // ===== TIMER POSTĘPU =====
  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isHolding) {
        timer.cancel();
        return;
      }

      setState(() {
        _totalProgress += 0.0083; // +0.83% co 100ms = 12 sekund total
      });

      // Po 3 sekundach start loading2
      if (_totalProgress >= 0.25 && !_hasStartedLoading2) {
        print('🎯 3s - START LOADING2');
        _hasStartedLoading2 = true;
        _loading2Controller.forward();
      }

      // Po pełnych 12 sekundach (niezależnie od analizy)
      if (_totalProgress >= 1.0) {
        print('✅ LOADING COMPLETE - TRANSITION');
        timer.cancel();
        _onLoadingComplete();
      }
    });
  }

  // ===== PROGRESYWNE WIBRACJE =====
  void _startVibrationPattern() {
    _vibrationTimer?.cancel();
    _vibrationTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isHolding) {
        timer.cancel();
        return;
      }

      // Progresywna siła wibracji
      HapticType hapticType;
      if (_totalProgress < 0.7) {
        hapticType = HapticType.light; // Bardzo delikatne
      } else if (_totalProgress < 0.9) {
        hapticType = HapticType.medium; // Średnie
      } else {
        hapticType = HapticType.heavy; // Mocne na końcu
      }

      _hapticService.trigger(hapticType);
    });
  }

  // ===== PRAWDZIWA ANALIZA AI =====
  void _startRealAnalysis() async {
    try {
      print('🤖 START Real AI Analysis');
      final aiService = SimpleAIPalmService();
      final result = await aiService.analyzePalm(
        userData: widget.userData,
        handType: widget.handType,
        palmPhoto: widget.palmPhoto,
      );

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
          _isAnalysisComplete = true;
        });
        print('✅ AI Analysis COMPLETE');
      }
    } catch (e) {
      print('❌ AI Analysis ERROR: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _isAnalysisComplete = true;
          // Fallback result
          _analysisResult = PalmAnalysisResult.failure('Błąd analizy: $e');
        });
      }
    }
  }

  // ===== ZAKOŃCZENIE ŁADOWANIA =====
  void _onLoadingComplete() async {
    _progressTimer?.cancel();
    _vibrationTimer?.cancel();

    // Finalna mocna wibracja
    await _hapticService.trigger(HapticType.success);

    // Zawsze czekamy na pełne 10 sekund, niezależnie od tego kiedy analiza się skończy
    if (mounted) {
      // Jeśli analiza jeszcze się nie skończyła, czekamy na nią
      if (!_isAnalysisComplete || _analysisResult == null) {
        print('⏳ Waiting for analysis to complete...');
        await _waitForAnalysisCompletion();
      }

      if (_analysisResult != null) {
        _navigateToResults();
      }
    }
  }

  // ===== CZEKANIE NA ZAKOŃCZENIE ANALIZY =====
  Future<void> _waitForAnalysisCompletion() async {
    // Maksymalnie czekamy 5 sekund na zakończenie analizy
    int attempts = 0;
    while (!_isAnalysisComplete && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    // Jeśli nadal brak wyniku, tworzymy fallback
    if (_analysisResult == null) {
      print('⚠️ Analysis timeout - creating fallback result');
      _analysisResult = PalmAnalysisResult.failure('Analiza trwała zbyt długo');
    }
  }

  void _navigateToResults() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PalmAnalysisScreen(
          userName: widget.userData.name,
          userGender: widget.userData.genderForMessages,
          analysisResult: _analysisResult,
          palmData: null,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Efektowne przejście - kombinacja fade + scale + rotate
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.elasticOut),
              ),
              child: RotationTransition(
                turns: Tween<double>(begin: 0.1, end: 0.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  void dispose() {
    print('🗑️ Fortune Loading Screen dispose');
    _progressTimer?.cancel();
    _vibrationTimer?.cancel();
    _backgroundController.dispose();
    _loading1Controller.dispose();
    _loading2Controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanDown: (_) => _startHolding(),
        onPanEnd: (_) => _stopHolding(),
        onPanCancel: () => _stopHolding(),
        onTapDown: (_) => _startHolding(),
        onTapUp: (_) => _stopHolding(),
        onTapCancel: () => _stopHolding(),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              _buildAnimatedBackground(),
              _buildStarField(),
              _buildMainContent(),
              // Usunięte debug info
            ],
          ),
        ),
      ),
    );
  }

  // ===== TŁO Z ANIMOWANYMI KOLORAMI =====
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        // Interpolacja między kolorami
        final colorIndex =
            (_backgroundAnimation.value * (_backgroundColors.length - 1));
        final currentColorIndex = colorIndex.floor();
        final nextColorIndex =
            (currentColorIndex + 1).clamp(0, _backgroundColors.length - 1);
        final t = colorIndex - currentColorIndex;

        final currentColor = _backgroundColors[currentColorIndex];
        final nextColor = _backgroundColors[nextColorIndex];
        final interpolatedColor =
            Color.lerp(currentColor, nextColor, t) ?? currentColor;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                interpolatedColor,
                interpolatedColor.withOpacity(0.8),
                Colors.black,
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== POLE GWIAZD =====
  Widget _buildStarField() {
    return SizedBox.expand(
      child: Lottie.asset(
        'assets/animations/star_bg.json',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  // ===== GŁÓWNA ZAWARTOŚĆ =====
  Widget _buildMainContent() {
    return SafeArea(
      child: Column(
        children: [
          // Komunikat na górze
          const SizedBox(height: 20),
          _buildHoldMessage(),

          // Środek - animacje
          Expanded(
            child: Center(
              child: _buildLoadingAnimations(),
            ),
          ),

          // Informacje użytkownika
          _buildUserInfo(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===== ANIMACJE ŁADOWANIA =====
  Widget _buildLoadingAnimations() {
    return AnimatedBuilder(
      animation: _loading2Animation,
      builder: (context, child) {
        return SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Loading1 - zawsze widoczne, STATYCZNA gdy nie trzymamy
              SizedBox(
                width: 5500,
                height: 550,
                child: Lottie.asset(
                  'assets/animations/fortuneloading1.json',
                  fit: BoxFit.contain,
                  // KLUCZOWE: animuje TYLKO gdy trzymamy
                  animate: _isHolding,
                  repeat: _isHolding,
                ),
              ),

              // Efekt mgły przed loading2
              if (_hasStartedLoading2)
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Colors.white
                            .withOpacity(0.1 * _loading2Animation.value),
                        Colors.white
                            .withOpacity(0.05 * _loading2Animation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

              // Loading2 - pojawia się po 3 sekundach z efektem mgły
              if (_hasStartedLoading2)
                Opacity(
                  opacity: _loading2Animation.value,
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dodatkowy efekt blasku wokół loading2
                        Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cyan.withOpacity(
                                  0.3 * _loading2Animation.value,
                                ),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        // Sama animacja loading2
                        Lottie.asset(
                          'assets/animations/fortuneloading2.json',
                          fit: BoxFit.contain,
                          animate: true,
                          repeat: true,
                        ),
                      ],
                    ),
                  ),
                ),

              // Progress indicator
              Positioned(
                bottom: -30,
                child: Container(
                  width: 250,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _totalProgress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cyan,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===== KOMUNIKAT =====
  Widget _buildHoldMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isHolding ? AppColors.cyan : Colors.white.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: _isHolding
            ? [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isHolding ? Icons.touch_app : Icons.pan_tool,
                color: _isHolding ? AppColors.cyan : Colors.white70,
                size: 24,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  _isHolding ? 'Trzymaj dalej...' : 'Przytrzymaj ekran',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 18,
                    color: _isHolding ? AppColors.cyan : Colors.white70,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (_totalProgress > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${(_totalProgress * 100).round()}%',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 16,
                color: AppColors.cyan,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // ===== INFO UŻYTKOWNIKA - KOMPAKTOWE =====
  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.5),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.userData.name,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              color: AppColors.cyan,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildInfoItem('${widget.userData.age} lat')),
              Expanded(child: _buildInfoItem(widget.userData.zodiacSign)),
              Expanded(
                  child: _buildInfoItem(
                      widget.handType == 'left' ? 'Lewa' : 'Prawa')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String value) {
    return Text(
      value,
      style: GoogleFonts.cinzelDecorative(
        fontSize: 12,
        color: Colors.white,
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ===== POLE DO PRZYCISKANIA NA DOLE =====
  Widget _buildHoldArea() {
    return Container(
      width: double.infinity,
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _isHolding
            ? AppColors.cyan.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isHolding ? AppColors.cyan : Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: _isHolding
            ? [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isHolding ? Icons.fingerprint : Icons.touch_app,
              size: 40,
              color: _isHolding ? AppColors.cyan : Colors.white70,
            ),
            const SizedBox(height: 8),
            Text(
              _isHolding ? 'Aktywne' : 'Dotknij tutaj',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 16,
                color: _isHolding ? AppColors.cyan : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
