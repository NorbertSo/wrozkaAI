// lib/screens/fortune_loading_screen.dart
// POPRAWIONA WERSJA - bez Lottie, z czystymi animacjami Flutter

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../services/ai_palm_analysis_service.dart';
import '../models/user_data.dart';
import 'palm_analysis_result_screen.dart';
import 'package:camera/camera.dart';

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
  late AnimationController _orbController;
  late AnimationController _textController;
  late AnimationController _runeController;
  late AnimationController _progressController;
  late AnimationController _pulseController;

  late Animation<double> _orbAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _runeAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  int _currentMessageIndex = 0;
  Timer? _messageTimer;
  bool _isAnalyzing = true;

  final List<String> _loadingMessages = [
    'Łączę się z mistycznymi mocami...',
    'Analizuję linie Twojej dłoni...',
    'Odczytuję znaki starożytnych...',
    'Interpretuję wzgórki energii...',
    'Konsultuję się z gwiazdami...',
    'Przygotowuję Twoją przepowiednię...',
    'Finalizuję wróżbę...',
  ];

  @override
  void initState() {
    super.initState();
    print('🔮 FortuneLoadingScreen - START dla: ${widget.userData.name}');
    _initializeAnimations();
    _startAnimations();
    _startMessageCycle();
    _startAnalysis();
  }

  void _initializeAnimations() {
    _orbController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _runeController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _progressController = AnimationController(
      duration: const Duration(seconds: 20), // Długość całego procesu
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _orbAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _orbController, curve: Curves.linear),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _runeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _runeController, curve: Curves.linear),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _textController.forward();
    _progressController.forward();
  }

  void _startMessageCycle() {
    _messageTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted && _isAnalyzing) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
        });
        _textController.reset();
        _textController.forward();
      }
    });
  }

  void _startAnalysis() async {
    try {
      print('🔮 Rozpoczynam analizę AI w FortuneLoadingScreen');
      print('📸 Zdjęcie dłoni: ${widget.palmPhoto?.path ?? "BRAK"}');

      final aiService = SimpleAIPalmService();
      final result = await aiService.analyzePalm(
        userData: widget.userData,
        handType: widget.handType,
        palmPhoto: widget.palmPhoto,
      );

      if (mounted) {
        print('✅ Analiza AI zakończona');
        _isAnalyzing = false;
        _messageTimer?.cancel();

        // Pokazuj "Wróżba gotowa!" przez 2 sekundy
        setState(() {
          _currentMessageIndex = -1; // Specjalny indeks dla wiadomości końcowej
        });

        _textController.reset();
        _textController.forward();

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          _navigateToResults(result);
        }
      }
    } catch (e) {
      print('❌ Błąd analizy w FortuneLoadingScreen: $e');

      if (mounted) {
        _isAnalyzing = false;
        _messageTimer?.cancel();

        // Pokazuj błąd
        setState(() {
          _currentMessageIndex = -2; // Specjalny indeks dla błędu
        });

        _textController.reset();
        _textController.forward();

        await Future.delayed(const Duration(seconds: 3));

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _navigateToResults(PalmAnalysisResult result) {
    print('🚀 Nawigacja do wyników dla: ${widget.userData.name}');

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PalmAnalysisScreen(
          userName: widget.userData.name,
          userGender: widget.userData.genderForMessages,
          analysisResult: result,
          palmData: null,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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

  @override
  void dispose() {
    print('🗑️ FortuneLoadingScreen dispose');
    _messageTimer?.cancel();
    _orbController.dispose();
    _textController.dispose();
    _runeController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
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
        child: Stack(
          children: [
            _buildMysticalBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildCenterContent(),
                  ),
                  _buildProgressSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMysticalBackground() {
    return AnimatedBuilder(
      animation: _orbAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: LoadingBackgroundPainter(_orbAnimation.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
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
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Text(
            'PRZYGOTOWUJĘ WRÓŻBĘ',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 20,
              color: AppColors.cyan,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _runeAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_runeAnimation.value * 2 * math.pi,
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.cyan,
                  size: 24,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Główna animowana sfera
        _buildMainOrb(),
        const SizedBox(height: 40),

        // Komunikat ładowania
        _buildLoadingMessage(),
        const SizedBox(height: 30),

        // Dodatkowe informacje
        _buildUserInfo(),
      ],
    );
  }

  Widget _buildMainOrb() {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_orbAnimation, _progressAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Container(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Zewnętrzne kręgi energii
              for (int i = 0; i < 3; i++)
                Transform.scale(
                  scale: 1.0 + (i * 0.3) + (_pulseAnimation.value * 0.1),
                  child: Container(
                    width: 160 + (i * 20),
                    height: 160 + (i * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.cyan.withOpacity(0.3 - (i * 0.1)),
                        width: 2,
                      ),
                    ),
                  ),
                ),

              // Główna sfera
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.cyan.withOpacity(0.4),
                        AppColors.cyan.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.cyan.withOpacity(0.8),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ikona dłoni w centrum
                      Icon(
                        Icons.pan_tool_outlined,
                        size: 60,
                        color: AppColors.cyan.withOpacity(0.9),
                      ),

                      // Obracające się symbole
                      ...List.generate(6, (index) {
                        final angle = (index * math.pi / 3) +
                            (_orbAnimation.value * 2 * math.pi);
                        final radius = 50.0;
                        return Transform.translate(
                          offset: Offset(
                            radius * math.cos(angle),
                            radius * math.sin(angle),
                          ),
                          child: Transform.rotate(
                            angle: angle,
                            child: Icon(
                              _getSymbolIcon(index),
                              size: 16,
                              color: AppColors.cyan.withOpacity(0.7),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Pasek postępu (okrągły)
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: _progressAnimation.value,
                  strokeWidth: 4,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.cyan.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getSymbolIcon(int index) {
    final icons = [
      Icons.star,
      Icons.favorite,
      Icons.diamond,
      Icons.local_fire_department,
      Icons.water_drop,
      Icons.air,
    ];
    return icons[index % icons.length];
  }

  Widget _buildLoadingMessage() {
    return AnimatedBuilder(
      animation: _textAnimation,
      builder: (context, child) {
        String message;
        Color messageColor = Colors.white;
        IconData? messageIcon;

        if (_currentMessageIndex == -1) {
          message = 'Wróżba gotowa!';
          messageColor = Colors.green;
          messageIcon = Icons.check_circle;
        } else if (_currentMessageIndex == -2) {
          message = 'Wystąpił błąd podczas analizy';
          messageColor = Colors.red;
          messageIcon = Icons.error;
        } else {
          message = _loadingMessages[_currentMessageIndex];
          messageIcon = Icons.auto_awesome;
        }

        return Opacity(
          opacity: _textAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _textAnimation.value)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Colors.black.withOpacity(0.7),
                border: Border.all(
                  color: messageColor.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  if (_currentMessageIndex == -1)
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (messageIcon != null) ...[
                    Icon(
                      messageIcon,
                      color: messageColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      message,
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 16,
                        color: messageColor,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.black.withOpacity(0.5),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Analizuję dla: ${widget.userData.name}',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              color: AppColors.cyan,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoItem(
                'Wiek',
                '${widget.userData.age} lat',
              ),
              _buildInfoItem(
                'Znak',
                widget.userData.zodiacSign,
              ),
              _buildInfoItem(
                'Dłoń',
                widget.handType == 'left' ? 'Lewa' : 'Prawa',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.cinzelDecorative(
            fontSize: 12,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cinzelDecorative(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Pasek postępu liniowy
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white10,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cyan,
                          AppColors.cyan.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Procentowy postęp
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              final percentage = (_progressAnimation.value * 100).round();
              return Text(
                '$percentage%',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Dekoracyjne elementy
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return AnimatedBuilder(
                animation: _orbAnimation,
                builder: (context, child) {
                  final delay = index * 0.2;
                  final animValue = (_orbAnimation.value + delay) % 1.0;
                  final opacity =
                      0.3 + (0.4 * math.sin(animValue * 2 * math.pi));

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          AppColors.cyan.withOpacity(opacity.clamp(0.1, 0.7)),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// Custom painter dla mistycznego tła
class LoadingBackgroundPainter extends CustomPainter {
  final double animationValue;

  LoadingBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    try {
      // Mystical aura circles
      for (int i = 0; i < 4; i++) {
        final centerX = size.width * 0.5;
        final centerY = size.height * 0.5;
        final baseRadius = 80.0 + (i * 60.0);
        final animatedRadius = baseRadius *
            (1 + 0.05 * math.sin(animationValue * 2 * math.pi + i));

        if (animatedRadius > 0 && animatedRadius < size.width * 1.2) {
          final opacityValue = 0.03 - i * 0.005;
          final safeOpacity = opacityValue.clamp(0.002, 0.05);

          paint.color = AppColors.cyan.withOpacity(safeOpacity);
          canvas.drawCircle(Offset(centerX, centerY), animatedRadius, paint);
        }
      }

      // Floating energy particles
      for (int i = 0; i < 25; i++) {
        final angle = (animationValue * 2 * math.pi) + (i * 2 * math.pi / 25);
        final radius = 100.0 + (i % 5) * 40.0;
        final x = size.width * 0.5 +
            radius * math.cos(angle + animationValue * math.pi);
        final y = size.height * 0.5 +
            radius * math.sin(angle * 0.8 + animationValue * math.pi);

        if (x >= -15 &&
            x <= size.width + 15 &&
            y >= -15 &&
            y <= size.height + 15) {
          final particleSize =
              0.8 + math.sin(animationValue * 4 * math.pi + i) * 0.4;

          if (particleSize > 0) {
            final opacityBase =
                0.08 + math.sin(animationValue * 3 * math.pi + i * 0.3) * 0.04;
            final safeOpacity = opacityBase.clamp(0.02, 0.12);

            paint.color = AppColors.cyan.withOpacity(safeOpacity);
            canvas.drawCircle(Offset(x, y), particleSize.abs(), paint);
          }
        }
      }

      // Corner mystical symbols
      _drawCornerSymbols(canvas, size, paint);
    } catch (e) {
      print('❌ Błąd w LoadingBackgroundPainter: $e');
    }
  }

  void _drawCornerSymbols(Canvas canvas, Size size, Paint paint) {
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.cyan.withOpacity(0.1);

    // Simple geometric shapes in corners
    if (size.width > 100 && size.height > 100) {
      // Top left
      canvas.drawArc(
        Rect.fromLTWH(20, 20, 30, 30),
        -math.pi,
        math.pi / 2,
        false,
        paint,
      );

      // Top right
      canvas.drawArc(
        Rect.fromLTWH(size.width - 50, 20, 30, 30),
        -math.pi / 2,
        math.pi / 2,
        false,
        paint,
      );

      // Bottom corners
      canvas.drawArc(
        Rect.fromLTWH(20, size.height - 50, 30, 30),
        math.pi / 2,
        math.pi / 2,
        false,
        paint,
      );

      canvas.drawArc(
        Rect.fromLTWH(size.width - 50, size.height - 50, 30, 30),
        0,
        math.pi / 2,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
