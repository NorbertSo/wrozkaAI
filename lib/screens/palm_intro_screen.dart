import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import '../utils/constants.dart';
import 'palm_scan_screen.dart';

class PalmIntroScreen extends StatefulWidget {
  final String userName;
  final String userGender;

  const PalmIntroScreen({
    super.key,
    required this.userName,
    required this.userGender,
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

  String get _personalizedMessage {
    final genderSuffix = widget.userGender == 'female' ? 'aś' : 'eś';

    return '''Drogi${widget.userGender == 'female' ? 'a' : ''} ${widget.userName},

Wkraczasz teraz w świat, który może na zawsze zmienić Twoje życie. W liniach Twojej dłoni kryją się historie, które czekają, by zostać opowiedziane - sekrety o Tobie samej/samym, których być może jeszcze nie odkrył$genderSuffix.

Twoja dłoń to mapa Twojego przeznaczenia. Znajdziemy w niej ślady Twoich predyspozycji, odkryjemy tajemnice Twojego serca i miłości, a także poznamy ścieżki, które prowadzą do Twojego szczęścia.

Każda linia, każdy wzgórek, każda drobna kreska ma swoje znaczenie. To starożytna sztuka, która łączy Cię z tysiącami lat ludzkiej mądrości.

Przygotuj się na podróż w głąb siebie. Pozwól, by mistyczna energia popłynęła przez Twoją dłoń i objawi Ci prawdy, na które czekał$genderSuffix.''';
  }

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

            // Główna zawartość
            SafeArea(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),

                          // Mistyczna ikona
                          AnimatedBuilder(
                            animation: _textAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _textAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.cyan.withOpacity(0.5),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.cyan.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.pan_tool_outlined,
                                    size: 64,
                                    color: AppColors.cyan,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 60),

                          // Główny tekst
                          AnimatedBuilder(
                            animation: _textAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _textAnimation.value,
                                child: Transform.translate(
                                  offset: Offset(
                                    0,
                                    50 * (1 - _textAnimation.value),
                                  ),
                                  child: Text(
                                    _personalizedMessage,
                                    style: GoogleFonts.cinzelDecorative(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                      height: 1.6,
                                      letterSpacing: 0.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 80),

                          // Przycisk rozpoczęcia rytuału
                          AnimatedBuilder(
                            animation: _buttonAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _buttonAnimation.value,
                                child: _buildRitualButton(),
                              );
                            },
                          ),

                          const SizedBox(height: 40),
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
            side: BorderSide(color: AppColors.cyan.withOpacity(0.8), width: 2),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.cyan, size: 24),
            const SizedBox(width: 12),
            Text(
              'Rozpocznij rytuał',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.auto_awesome, color: AppColors.cyan, size: 24),
          ],
        ),
      ),
    );
  }

  void _startRitual() {
    // Dodaj efekt drgania/vibracji
    // HapticFeedback.mediumImpact();

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PalmScanScreen(
          userName: widget.userName,
          userGender: widget.userGender,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
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
    final paint = Paint()
      ..color = AppColors.cyan.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Rysowanie cząsteczek w różnych miejscach
    for (int i = 0; i < 20; i++) {
      final x = (size.width * 0.1) + (i * size.width * 0.04);
      final y =
          size.height * 0.3 +
          (50 * math.sin((animationValue * 2 * math.pi) + i * 0.5));

      final radius = 1.5 + (math.sin(animationValue * 4 * math.pi + i) * 0.8);

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint
          ..color = AppColors.cyan.withOpacity(
            0.2 + (0.3 * math.sin(animationValue * 3 * math.pi + i)),
          ),
      );
    }

    // Dodatkowe cząsteczki po prawej stronie
    for (int i = 0; i < 15; i++) {
      final x = size.width * 0.7 + (i * size.width * 0.02);
      final y =
          size.height * 0.6 +
          (30 * math.cos((animationValue * 1.5 * math.pi) + i * 0.8));

      final radius = 1.0 + (math.cos(animationValue * 3 * math.pi + i) * 0.5);

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint
          ..color = AppColors.lightCyan.withOpacity(
            0.15 + (0.25 * math.cos(animationValue * 2.5 * math.pi + i)),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
