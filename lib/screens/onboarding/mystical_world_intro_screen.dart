// lib/screens/onboarding/mystical_world_intro_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:lottie/lottie.dart'; // Usunięty nieużywany import
import '../../widgets/haptic_button.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_utils.dart';
import '../../services/logging_service.dart';
import '../../models/user_data.dart';
import '../main_menu_screen.dart';
import '../../services/haptic_service.dart';

class MysticalWorldIntroScreen extends StatefulWidget {
  final UserData userData;

  const MysticalWorldIntroScreen({
    super.key,
    required this.userData,
  });

  @override
  State<MysticalWorldIntroScreen> createState() =>
      _MysticalWorldIntroScreenState();
}

class _MysticalWorldIntroScreenState extends State<MysticalWorldIntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _mysticalController;
  late AnimationController _textRevealController;
  late AnimationController _energyController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _mysticalAnimation;
  late Animation<double> _textRevealAnimation;
  late Animation<double> _energyAnimation;

  int _currentTextStep = 0;
  final List<String> _mysticalTexts = [
    'Witaj w krainie, gdzie czas przestaje mieć znaczenie...',
    'Tutaj linie Twoich dłoni łączą się z mapą gwiazd...',
    'Energia, którą niosisz, już od wieków czeka na ten moment...',
    'Razem odkryjemy sekrety, które Wszechświat ma dla Ciebie.',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
    LoggingService().logToConsole(
        '✨ Mystical World Intro - Powitanie ${widget.userData.name} w świecie ezoteryki',
        tag: 'ONBOARDING');
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _mysticalController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _textRevealController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _energyController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _mysticalAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mysticalController,
      curve: Curves.easeInOutSine,
    ));

    _textRevealAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textRevealController,
      curve: Curves.easeInOut,
    ));

    _energyAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _energyController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() async {
    // Initial fade in
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();

    // Start mystical background animation
    await Future.delayed(const Duration(milliseconds: 500));
    _mysticalController.repeat(reverse: true);

    // Start energy flow
    await Future.delayed(const Duration(milliseconds: 800));
    _energyController.repeat();

    // Start text reveal sequence
    await Future.delayed(const Duration(milliseconds: 1200));
    _startTextRevealSequence();
  }

  void _startTextRevealSequence() async {
    for (int i = 0; i < _mysticalTexts.length; i++) {
      if (!mounted) return;

      setState(() {
        _currentTextStep = i;
      });

      _textRevealController.reset();
      _textRevealController.forward();

      // Wait for text to be read
      await Future.delayed(const Duration(milliseconds: 2500));
    }

    // Final pause before showing continue button
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {
      _currentTextStep = _mysticalTexts.length; // Show continue button
    });
  }

  void _navigateToMainMenu() {
    LoggingService().logToConsole('🎯 Przejście do głównego menu aplikacji',
        tag: 'NAVIGATION');
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MainMenuScreen(
          userName: widget.userData.name,
          userGender: widget.userData.genderForMessages,
          dominantHand: widget.userData.dominantHand,
          birthDate: widget.userData.birthDate,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  String _getPersonalizedGreeting() {
    final hour = DateTime.now().hour;
    final name = widget.userData.name;

    if (hour >= 5 && hour < 12) {
      return 'Dzień dobry, $name';
    } else if (hour >= 12 && hour < 18) {
      return 'Miłego popołudnia, $name';
    } else if (hour >= 18 && hour < 22) {
      return 'Dobry wieczór, $name';
    } else {
      return 'Dobranoc, $name';
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _mysticalController.dispose();
    _textRevealController.dispose();
    _energyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1426),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A2332),
                const Color(0xFF0B1426),
                const Color(0xFF1A1A2E),
                AppColors.deepBlue.withOpacity(0.3),
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Stack(
                    children: [
                      // Animated Background Elements
                      AnimatedBuilder(
                        animation: _energyAnimation,
                        builder: (context, child) {
                          return Positioned.fill(
                            child: CustomPaint(
                              painter: EnergyFlowPainter(
                                animationValue: _energyAnimation.value,
                                mysticalValue: _mysticalAnimation.value,
                              ),
                            ),
                          );
                        },
                      ),

                      // Main Content
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.isTabletOrLarger ? 60.0 : 24.0,
                        ),
                        child: Column(
                          children: [
                            const Spacer(flex: 2),

                            // Mystical Animation Center
                            AnimatedBuilder(
                              animation: _mysticalAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: context.isTabletOrLarger ? 200 : 160,
                                  height: context.isTabletOrLarger ? 200 : 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.cyan.withOpacity(
                                            0.4 * _mysticalAnimation.value),
                                        AppColors.purple.withOpacity(
                                            0.3 * _mysticalAnimation.value),
                                        Colors.amber.withOpacity(
                                            0.2 * _mysticalAnimation.value),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Transform.rotate(
                                      angle:
                                          _energyAnimation.value * 2 * 3.14159,
                                      child: Icon(
                                        Icons.auto_awesome,
                                        size:
                                            context.isTabletOrLarger ? 80 : 60,
                                        color: Colors.amber.withOpacity(0.8 +
                                            0.2 * _mysticalAnimation.value),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 40),

                            // Personalized Greeting
                            AnimatedBuilder(
                              animation: _mysticalAnimation,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(
                                            0.3 * _mysticalAnimation.value),
                                        blurRadius: 20 +
                                            (10 * _mysticalAnimation.value),
                                        spreadRadius:
                                            2 + (3 * _mysticalAnimation.value),
                                      ),
                                    ],
                                  ),
                                  child: ResponsiveText(
                                    _getPersonalizedGreeting(),
                                    baseFontSize:
                                        context.isTabletOrLarger ? 32 : 28,
                                    style: GoogleFonts.cinzelDecorative(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 1.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 32),

                            // Storytelling Text Area
                            Container(
                              height: context.isTabletOrLarger ? 200 : 160,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.deepBlue.withOpacity(0.2),
                                    AppColors.darkBlue.withOpacity(0.1),
                                    AppColors.purple.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.cyan.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: _currentTextStep < _mysticalTexts.length
                                    ? AnimatedBuilder(
                                        animation: _textRevealAnimation,
                                        builder: (context, child) {
                                          return Transform.translate(
                                            offset: Offset(
                                                0,
                                                20 *
                                                    (1 -
                                                        _textRevealAnimation
                                                            .value)),
                                            child: Opacity(
                                              opacity:
                                                  _textRevealAnimation.value,
                                              child: ResponsiveText(
                                                _mysticalTexts[
                                                    _currentTextStep],
                                                baseFontSize:
                                                    context.isTabletOrLarger
                                                        ? 20
                                                        : 18,
                                                style: GoogleFonts.openSans(
                                                  color: AppColors.cyan
                                                      .withOpacity(0.9),
                                                  height: 1.6,
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ResponsiveText(
                                            'Twoja duchowa podróż oficjalnie się rozpoczyna.',
                                            baseFontSize:
                                                context.isTabletOrLarger
                                                    ? 20
                                                    : 18,
                                            style: GoogleFonts.openSans(
                                              color:
                                                  Colors.amber.withOpacity(0.9),
                                              height: 1.6,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 16),
                                          ResponsiveText(
                                            'Wybierz, którą ścieżką chcesz podążyć pierwszą.',
                                            baseFontSize:
                                                context.isTabletOrLarger
                                                    ? 18
                                                    : 16,
                                            style: GoogleFonts.openSans(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              height: 1.4,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const Spacer(flex: 2),

                            // Continue Button (only show when text sequence is complete)
                            if (_currentTextStep >= _mysticalTexts.length)
                              AnimatedBuilder(
                                animation: _mysticalAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.amber.withOpacity(
                                              0.4 * _mysticalAnimation.value),
                                          blurRadius: 20 +
                                              (15 * _mysticalAnimation.value),
                                          spreadRadius: 2 +
                                              (4 * _mysticalAnimation.value),
                                        ),
                                      ],
                                    ),
                                    child: HapticButton(
                                      text: 'Rozpocznij przygodę',
                                      onPressed: _navigateToMainMenu,
                                      hapticType: HapticType.medium,
                                      isLoading: false,
                                    ),
                                  );
                                },
                              ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Energy Flow Effects
class EnergyFlowPainter extends CustomPainter {
  final double animationValue;
  final double mysticalValue;

  EnergyFlowPainter({
    required this.animationValue,
    required this.mysticalValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw flowing energy lines
    for (int i = 0; i < 8; i++) {
      final angle = (i * 3.14159 / 4) + (animationValue * 2 * 3.14159);
      final startRadius = 50 + (20 * mysticalValue);
      final endRadius = 120 + (30 * mysticalValue);

      final start = Offset(
        center.dx + startRadius * cos(angle),
        center.dy + startRadius * sin(angle),
      );

      final end = Offset(
        center.dx + endRadius * cos(angle),
        center.dy + endRadius * sin(angle),
      );

      paint.color = AppColors.cyan.withOpacity(0.3 * mysticalValue);
      canvas.drawLine(start, end, paint);

      // Draw small circles at the end points
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(end, 2, paint);
      paint.style = PaintingStyle.stroke;
    }

    // Draw mystical particles
    for (int i = 0; i < 12; i++) {
      final particleAngle = (i * 3.14159 / 6) + (animationValue * 3.14159);
      final particleRadius = 80 + (40 * sin(animationValue * 3.14159 + i));

      final particlePos = Offset(
        center.dx + particleRadius * cos(particleAngle),
        center.dy + particleRadius * sin(particleAngle),
      );

      paint.color = Colors.amber.withOpacity(0.4 * mysticalValue);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(particlePos, 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Helper function for trigonometric calculations
double cos(double radians) => math.cos(radians);
double sin(double radians) => math.sin(radians);
