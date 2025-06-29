// lib/screens/onboarding/data_intro_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/haptic_button.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_utils.dart';
import '../../services/logging_service.dart';
import '../../services/haptic_service.dart';
import '../onboarding_screen.dart';

class DataIntroScreen extends StatefulWidget {
  final String selectedMusic;

  const DataIntroScreen({
    super.key,
    required this.selectedMusic,
  });

  @override
  State<DataIntroScreen> createState() => _DataIntroScreenState();
}

class _DataIntroScreenState extends State<DataIntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _shieldController;
  late AnimationController _textController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _shieldAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
    LoggingService().logToConsole(
        '🔒 Data Intro Screen - Wprowadzenie do bezpieczeństwa danych',
        tag: 'ONBOARDING');
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shieldController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _shieldAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shieldController,
      curve: Curves.elasticOut,
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _shieldController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();
  }

  void _navigateToUserData() {
    LoggingService().logToConsole(
        '➡️ Przejście do formularza danych użytkownika',
        tag: 'NAVIGATION');

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OnboardingScreen(
          selectedMusic: widget.selectedMusic,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shieldController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1426),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A2332),
                Color(0xFF0B1426),
                Color(0xFF1A1A2E),
              ],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.isTabletOrLarger ? 60.0 : 20.0,
                      vertical: 20.0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom -
                            40,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Security Shield Animation
                          AnimatedBuilder(
                            animation: _shieldAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _shieldAnimation.value,
                                child: Container(
                                  width: context.isTabletOrLarger ? 120 : 100,
                                  height: context.isTabletOrLarger ? 120 : 100,
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
                                    Icons.security,
                                    size: context.isTabletOrLarger ? 50 : 40,
                                    color: AppColors.cyan,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Title
                          AnimatedBuilder(
                            animation: _textAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset:
                                    Offset(0, 20 * (1 - _textAnimation.value)),
                                child: Opacity(
                                  opacity: _textAnimation.value,
                                  child: ResponsiveText(
                                    'Twoje dane są świętością',
                                    baseFontSize:
                                        context.isTabletOrLarger ? 28 : 24,
                                    style: GoogleFonts.cinzelDecorative(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 1.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Main Storytelling Content
                          AnimatedBuilder(
                            animation: _textAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset:
                                    Offset(0, 30 * (1 - _textAnimation.value)),
                                child: Opacity(
                                  opacity: _textAnimation.value,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.deepBlue.withOpacity(0.2),
                                          AppColors.darkBlue.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.cyan.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        ResponsiveText(
                                          'W mistycznych praktykach, Twoja prywatność to fundament zaufania. Informacje pozostaną tylko między nami - chronione jak najcenniejsze sekrety.',
                                          baseFontSize: context.isTabletOrLarger
                                              ? 16
                                              : 14,
                                          style: GoogleFonts.openSans(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            height: 1.5,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),

                                        const SizedBox(height: 20),

                                        // Security Features
                                        _buildSecurityFeature(
                                          icon: Icons.lock_outline,
                                          title: 'Szyfrowanie lokalnie',
                                          description:
                                              'Dane nie opuszczają Twojego urządzenia',
                                        ),

                                        const SizedBox(height: 12),

                                        _buildSecurityFeature(
                                          icon: Icons.delete_outline,
                                          title: 'Pełna kontrola',
                                          description:
                                              'Możesz usunąć dane w każdej chwili',
                                        ),

                                        const SizedBox(height: 12),

                                        _buildSecurityFeature(
                                          icon: Icons.visibility_off_outlined,
                                          title: 'Bez śledzenia',
                                          description:
                                              'Żadnych zewnętrznych analityk',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Trust Message
                          AnimatedBuilder(
                            animation: _textAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _textAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.amber.withOpacity(0.3),
                                      width: 1,
                                    ),
                                    color: Colors.amber.withOpacity(0.05),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.favorite,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ResponsiveText(
                                          'Zaufanie to podstawa duchowej podróży. Jestem tu, by Ci pomóc.',
                                          baseFontSize: context.isTabletOrLarger
                                              ? 14
                                              : 13,
                                          style: GoogleFonts.openSans(
                                            color:
                                                Colors.amber.withOpacity(0.9),
                                            height: 1.3,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Continue Button
                          AnimatedBuilder(
                            animation: _textAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset:
                                    Offset(0, 20 * (1 - _textAnimation.value)),
                                child: Opacity(
                                  opacity: _textAnimation.value,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: HapticButton(
                                      text: 'Rozumiem i ufam',
                                      onPressed: _navigateToUserData,
                                      hapticType: HapticType.medium,
                                      isLoading: false,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyan.withOpacity(0.2),
            border: Border.all(
              color: AppColors.cyan.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.cyan,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                title,
                baseFontSize: 14,
                style: GoogleFonts.cinzelDecorative(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              ResponsiveText(
                description,
                baseFontSize: 12,
                style: GoogleFonts.openSans(
                  color: Colors.white.withOpacity(0.7),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
