// lib/screens/palm_intro_screen.dart
// NAPRAWIONA WERSJA - dodany przycisk wstecz

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import '../utils/constants.dart';
import 'palm_scan_screen.dart';
import '../utils/responsive_utils.dart';

class PalmIntroScreen extends StatefulWidget {
  final String userName;
  final String userGender;
  final String? dominantHand;
  final DateTime? birthDate;

  const PalmIntroScreen({
    super.key,
    required this.userName,
    required this.userGender,
    this.dominantHand,
    this.birthDate,
  });

  @override
  State<PalmIntroScreen> createState() => _PalmIntroScreenState();
}

class _PalmIntroScreenState extends State<PalmIntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _textController;
  late AnimationController _buttonController;
  late AnimationController _particleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 2000));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    _particleController.dispose();
    super.dispose();
  }

// 1. RESPONSYWNY build()
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
        child: Stack(
          children: [
            // Animowane tło z gwiazdami
            SizedBox.expand(
              child: Lottie.asset(
                'assets/animations/star_bg.json',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // Cząsteczki mistyczne
            AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: MysticParticlesPainter(_particleAnimation.value),
                  size: Size.infinite,
                );
              },
            ),

            // Responsywny przycisk wstecz
            SafeArea(
              child: Positioned(
                top: context.isSmallScreen ? 12 : 16,
                left: context.isSmallScreen ? 12 : 16,
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        width: context.isSmallScreen ? 40 : 44,
                        height: context.isSmallScreen ? 40 : 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.3),
                          border: Border.all(
                            color: AppColors.cyan.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {
                            print('🔙 Powrót z PalmIntroScreen');
                            Navigator.of(context).pop();
                          },
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: context.isSmallScreen ? 16 : 20,
                          ),
                          tooltip: 'Wróć',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Główna zawartość z responsywnym layoutem
            SafeArea(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: SingleChildScrollView(
                      padding: context.responsivePadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: context.isSmallScreen ? 30 : 40),

                          // Responsywna mistyczna ikona
                          AnimatedBuilder(
                            animation: _textAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _textAnimation.value,
                                child: Container(
                                  width: context.isSmallScreen ? 100 : 120,
                                  height: context.isSmallScreen ? 100 : 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.cyan.withOpacity(0.3),
                                        AppColors.cyan.withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                    ),
                                    border: Border.all(
                                      color: AppColors.cyan.withOpacity(0.5),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    size: context.isSmallScreen ? 50 : 60,
                                    color: AppColors.cyan,
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: context.isSmallScreen ? 30 : 40),

                          // Responsywny tekst
                          AnimatedBuilder(
                            animation: _textAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _textAnimation.value,
                                child: ResponsiveContainer(
                                  maxWidth: 600,
                                  child: ResponsiveText(
                                    _personalizedMessage(
                                        context), // ✅ Dodaj (context)
                                    baseFontSize: 16,
                                    style: AppTextStyles.introText,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: context.isSmallScreen ? 60 : 80),

                          // Responsywne przyciski
                          AnimatedBuilder(
                            animation: _buttonAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _buttonAnimation.value,
                                child: ResponsiveContainer(
                                  maxWidth: 400,
                                  child: Column(
                                    children: [
                                      _buildRitualButton(),
                                      const SizedBox(height: 16),
                                      _buildBackButton(),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: context.isSmallScreen ? 30 : 40),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

// 2. RESPONSYWNY _buildRitualButton
  Widget _buildRitualButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.4),
            blurRadius: 25,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _startRitual,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: context.isSmallScreen ? 14 : 16,
            horizontal: context.isSmallScreen ? 24 : 32,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
            side: BorderSide(color: AppColors.cyan.withOpacity(0.8), width: 2),
          ),
          elevation: 0,
        ),
        child: ResponsiveRow(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppColors.cyan,
              size: context.isSmallScreen ? 20 : 24,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: ResponsiveText(
                'Rozpocznij rytuał',
                baseFontSize: 16,
                style: AppTextStyles.buttonText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.auto_awesome,
              color: AppColors.cyan,
              size: context.isSmallScreen ? 20 : 24,
            ),
          ],
        ),
      ),
    );
  }

// 3. RESPONSYWNY _buildBackButton
  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          print('🔙 Powrót z PalmIntroScreen (przycisk)');
          Navigator.of(context).pop();
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: context.isSmallScreen ? 10 : 12,
            horizontal: context.isSmallScreen ? 20 : 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: ResponsiveRow(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_back_ios,
              color: Colors.white70,
              size: context.isSmallScreen ? 14 : 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: ResponsiveText(
                'Wróć do menu',
                baseFontSize: 14,
                style: AppTextStyles.bodyText.copyWith(
                  color: Colors.white70,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

// 4. RESPONSYWNY _personalizedMessage
  String _personalizedMessage(BuildContext context) {
    final genderSuffix = widget.userGender == 'female' ? 'aś' : 'eś';

    if (context.isSmallScreen) {
      return '''Drogi${widget.userGender == 'female' ? 'a' : ''} ${widget.userName},

Wkraczasz w świat, który może zmienić Twoje życie. W liniach dłoni kryją się sekrety, które czekają na odkrycie.

Twoja dłoń to mapa przeznaczenia. Znajdziemy w niej ślady predyspozycji i tajemnice serca.

Przygotuj się na podróż w głąb siebie. Pozwól mistycznej energii objawić Ci prawdy, na które czekał$genderSuffix.''';
    }

    return '''Drogi${widget.userGender == 'female' ? 'a' : ''} ${widget.userName},

Wkraczasz teraz w świat, który może na zawsze zmienić Twoje życie. W liniach Twojej dłoni kryją się historie, które czekają, by zostać opowiedziane - sekrety o Tobie samej/samym, których być może jeszcze nie odkrył$genderSuffix.

Twoja dłoń to mapa Twojego przeznaczenia. Znajdziemy w niej ślady Twoich predyspozycji, odkryjemy tajemnice Twojego serca i miłości, a także poznamy ścieżki, które prowadzą do Twojego szczęścia.

Każda linia, każdy wzgórek, każda drobna kreska ma swoje znaczenie. To starożytna sztuka, która łączy Cię z tysiącami lat ludzkiej mądrości.

Przygotuj się na podróż w głąb siebie. Pozwól, by mistyczna energia popłynęła przez Twoją dłoń i objawi Ci prawdy, na które czekał$genderSuffix.''';
  }

  void _startRitual() {
    print(
        '🚀 START RITUAL: userGender = ${widget.userGender}, dominantHand = ${widget.dominantHand}');

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PalmScanScreen(
          userName: widget.userName,
          userGender: widget.userGender,
          dominantHand: widget.dominantHand,
          birthDate: widget.birthDate,
          testMode: false, // Używa prawdziwej kamery
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
        transitionDuration: const Duration(milliseconds: 1200),
      ),
    );
  }
}

// Malarz mistycznych cząsteczek
class MysticParticlesPainter extends CustomPainter {
  final double animationValue;

  MysticParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    try {
      // Rysowanie cząsteczek w różnych miejscach
      for (int i = 0; i < 20; i++) {
        final x = (size.width * 0.1) + (i * size.width * 0.04);
        final y = size.height * 0.3 +
            (50 * math.sin((animationValue * 2 * math.pi) + i * 0.5));

        final radius = 1.5 + (math.sin(animationValue * 4 * math.pi + i) * 0.8);
        final opacityValue =
            0.2 + (0.3 * math.sin(animationValue * 3 * math.pi + i));
        final safeOpacity = opacityValue.clamp(0.0, 1.0);

        if (x >= -10 &&
            x <= size.width + 10 &&
            y >= -10 &&
            y <= size.height + 10) {
          canvas.drawCircle(
            Offset(x, y),
            radius.abs(),
            paint..color = AppColors.cyan.withOpacity(safeOpacity),
          );
        }
      }

      // Dodatkowe cząsteczki po prawej stronie
      for (int i = 0; i < 15; i++) {
        final x = size.width * 0.7 + (i * size.width * 0.02);
        final y = size.height * 0.6 +
            (30 * math.cos((animationValue * 1.5 * math.pi) + i * 0.8));

        final radius = 1.0 + (math.cos(animationValue * 3 * math.pi + i) * 0.5);
        final opacityValue =
            0.15 + (0.25 * math.cos(animationValue * 2.5 * math.pi + i));
        final safeOpacity = opacityValue.clamp(0.0, 1.0);

        if (x >= -10 &&
            x <= size.width + 10 &&
            y >= -10 &&
            y <= size.height + 10) {
          canvas.drawCircle(
            Offset(x, y),
            radius.abs(),
            paint..color = AppColors.cyan.withOpacity(safeOpacity),
          );
        }
      }
    } catch (e) {
      print('❌ Błąd w MysticParticlesPainter: $e');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
