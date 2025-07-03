// lib/screens/palm_intro_screen.dart
// NAPRAWIONA WERSJA - dodany przycisk wstecz i naprawione błędy

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../utils/constants.dart';
import 'palm_scan_screen.dart';
import '../utils/responsive_utils.dart';
import '../services/user_preferences_service.dart';
import '../models/user_data.dart';
import '../services/haptic_service.dart';
import '../services/candle_manager_service.dart';
import '../utils/logger.dart';

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

  UserData? _userData;
  bool _loadingUserData = true;

  final HapticService _hapticService = HapticService();

  @override
  void initState() {
    super.initState();
    _loadUserData();

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _loadingUserData = true;
    });
    final userData = await UserPreferencesService.getUserData();
    setState(() {
      _userData = userData;
      _loadingUserData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUserData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              child: Padding(
                padding: EdgeInsets.only(
                  top: context.isSmallScreen ? 18 : 24,
                  left: context.isSmallScreen ? 18 : 24,
                ),
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await _hapticService.trigger(HapticType.light);
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: context.isSmallScreen ? 44 : 48,
                            height: context.isSmallScreen ? 44 : 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.cyan.withOpacity(0.5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cyan.withOpacity(0.12),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: context.isSmallScreen ? 20 : 24,
                              ),
                            ),
                          ),
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
                                  child: Text(
                                    _personalizedMessage(context),
                                    style: AppTextStyles.bodyText,
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
        onPressed: () async {
          await _hapticService.trigger(HapticType.medium);

          // ✅ UNIWERSALNA METODA PŁATNOŚCI!
          final success = await CandleManagerService.showPaymentDialog(
            context,
            'palm_reading',
          );

          if (success) {
            _startPalmScan();
          }
        },
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppColors.cyan,
              size: context.isSmallScreen ? 20 : 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Rozpocznij',
              style: AppTextStyles.buttonText,
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

  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () async {
          await _hapticService.trigger(HapticType.light);
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back_ios,
              color: Colors.white70,
              size: context.isSmallScreen ? 14 : 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Wróć do menu',
              style: AppTextStyles.bodyText.copyWith(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _personalizedMessage(BuildContext context) {
    final user = _userData;
    final userName = user?.name ?? widget.userName;
    final userGender = user?.gender ?? widget.userGender;
    final isFemale = userGender == 'female';
    final genderSuffix = isFemale ? 'aś' : 'eś';
    final sameSelf = isFemale ? 'sama' : 'sam';

    if (context.isSmallScreen) {
      return '''$userName,

Wkraczas w świat, który może zmienić Twoje życie. W liniach dłoni kryją się sekrety, które czekają na odkrycie.

Twoja dłoń to mapa przeznaczenia. Znajdziemy w niej ślady predyspozycji i tajemnice serca.

Przygotuj się na podróż w głąb siebie. Pozwól mistycznej energii objawić Ci prawdy, na które czekał$genderSuffix.''';
    }

    return '''$userName,

Wkraczasz teraz w świat, który może na zawsze zmienić Twoje życie. W liniach Twojej dłoni kryją się historie, które czekają, by zostać opowiedziane - sekrety o Tobie $sameSelf, których być może jeszcze nie odkrył$genderSuffix.

Twoja dłoń to mapa Twojego przeznaczenia. Znajdziemy w niej ślady Twoich predyspozycji, odkryjemy tajemnice Twojego serca i miłości, a także poznamy ścieżki, które prowadzą do Twojego szczęścia.

Każda linia, każdy wzgórek, każda drobna kreska ma swoje znaczenie. To starożytna sztuka, która łączy Cię z tysiącami lat ludzkiej mądrości.

Przygotuj się na podróż w głąb siebie. Pozwól, by mistyczna energia popłynęła przez Twoją dłoń i objawi Ci prawdy, na które czekał$genderSuffix.''';
  }

  Future<void> _startPalmScan() async {
    Logger.debug('_startPalmScan() wywołana');

    try {
      final candleService = CandleManagerService();
      await candleService.initialize();

      // Wykonaj płatność
      final result = await candleService.usePalmReading();

      if (result.success) {
        Logger.success('Płatność udana, przechodzę do PalmScanScreen...');
        // Przejdź do skanu
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PalmScanScreen(
              userName: widget.userName,
              userGender: widget.userGender,
              dominantHand: widget.dominantHand,
              birthDate: widget.birthDate,
            ),
          ),
        );
      } else {
        Logger.warning('Płatność nieudana: ${result.message}');
        _showErrorDialog(result.message);
      }
    } catch (e) {
      Logger.error('Exception w _startPalmScan(): $e');
      _showErrorDialog('Wystąpił błąd podczas przetwarzania płatności');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBlue,
        title: Text('Błąd',
            style: GoogleFonts.cinzelDecorative(color: Colors.red)),
        content: Text(message,
            style: GoogleFonts.cinzelDecorative(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: GoogleFonts.cinzelDecorative(color: Colors.orange)),
          ),
        ],
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
      Logger.error('Błąd w MysticParticlesPainter: $e');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
