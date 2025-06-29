// lib/screens/welcome_screen.dart
// Zaktualizowany - teraz prowadzi do onboardingu, a potem do menu

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../widgets/magic_hand_widget.dart';
import '../utils/constants.dart';
import 'onboarding_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _handController;
  late AnimationController _buttonController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _handAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    // Kontrolery animacji
    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _handController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Animacje
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _handAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _handController, curve: Curves.elasticOut),
    );

    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.bounceOut),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Start animacji
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    _handController.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _handController.dispose();
    _buttonController.dispose();
    super.dispose();
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
            // Gwiezdne tło
            SizedBox.expand(
              child: Lottie.asset(
                'assets/animations/star_bg.json',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // Główna zawartość
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Animowana dłoń z symbolami
                  AnimatedBuilder(
                    animation: _handAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _handAnimation.value,
                        child: const MagicHandWidget(),
                      );
                    },
                  ),

                  const Spacer(flex: 1),

                  // Tekst główny
                  AnimatedBuilder(
                    animation: _textAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, 50 * (1 - _textAnimation.value)),
                          child: Column(
                            children: [
                              Text(
                                'Dotyk gwiazd,',
                                style: AppTextStyles.welcomeTitle,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'by odkryć swoją przyszłość',
                                style: AppTextStyles.welcomeSubtitle,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 2),

                  // Przycisk główny
                  AnimatedBuilder(
                    animation: _buttonAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _buttonAnimation.value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: MysticButton(
                            text: 'Rozpocznij swoją podróż',
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  // --- WYŁĄCZONY EKRAN WYBORU MUZYKI ---
                                  // builder: (context) => MusicSelectionScreen(
                                  //     userName: '', userGender: ''),
                                  // Zamiast tego przekieruj np. do OnboardingScreen lub innego ekranu:
                                  builder: (context) => OnboardingScreen(),
                                  // --- KONIEC WYŁĄCZENIA ---
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Przycisk mistyczny
class MysticButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const MysticButton({super.key, required this.text, required this.onPressed});

  @override
  State<MysticButton> createState() => _MysticButtonState();
}

class _MysticButtonState extends State<MysticButton>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withOpacity(_glowAnimation.value),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: AppColors.cyan.withOpacity(0.8),
                  width: 2,
                ),
              ),
              elevation: 0,
            ),
            child: Center(
              child: Text(
                widget.text,
                style: AppTextStyles.buttonText,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
