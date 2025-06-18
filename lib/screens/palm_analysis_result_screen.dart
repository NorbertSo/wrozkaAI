// lib/screens/palm_analysis_result_screen.dart
// Ekran wyników analizy dłoni

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../models/palm_analysis.dart';
import '../services/logging_service.dart';
import '../services/ai_palm_analysis_service.dart';

class PalmAnalysisResultScreen extends StatefulWidget {
  final String userName;
  final String userGender;
  final PalmAnalysis? palmData; // Opcjonalne - dla kompatybilności
  final PalmAnalysisResult? analysisResult; // Opcjonalne

  const PalmAnalysisResultScreen({
    super.key,
    required this.userName,
    required this.userGender,
    this.palmData,
    this.analysisResult,
  });

  @override
  State<PalmAnalysisResultScreen> createState() => _PalmAnalysisResultScreenState();
}

class _PalmAnalysisResultScreenState extends State<PalmAnalysisResultScreen>
    with TickerProviderStateMixin {
  final LoggingService _loggingService = LoggingService();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ===== ANIMACJE =====
  late AnimationController _fadeController;
  late AnimationController _mysticalController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _mysticalAnimation;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loggingService.logToConsole('Wyświetlenie wyników analizy',
        tag: 'RESULTS');
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _mysticalController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _mysticalAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mysticalController, curve: Curves.linear),
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    _mysticalController.repeat();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _cardController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _mysticalController.dispose();
    _cardController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ POPRAWKA: Sprawdź czy mamy jakiekolwiek dane
    if (widget.analysisResult != null) {
      return _buildTextAnalysisScreen();
    }

    if (widget.palmData != null) {
      return _buildOldFormatScreen();
    }

    // ✅ POPRAWKA: Fallback gdy brak danych
    return _buildNoDataScreen();
  }

  Widget _buildNoDataScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMysticalBackground(),
          SafeArea(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.2),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.orange,
                      size: 64,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Brak Danych Analizy',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 24,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nie otrzymano żadnych danych z analizy dłoni.\nSpróbuj ponownie wykonać skanowanie.',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Wróć do Głównego Ekranu',
                          style: GoogleFonts.cinzelDecorative(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ POPRAWKA: Bezpieczna wersja _buildTextAnalysisScreen
  Widget _buildTextAnalysisScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMysticalBackground(),
          SafeArea(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      _buildSimpleHeader(),
                      Expanded(
                        child: _buildScrollableText(),
                      ),
                      _buildActionButtons(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.85),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _mysticalAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _mysticalAnimation.value * 2 * math.pi,
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
            'TWOJA WRÓŻBA',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 24,
              color: AppColors.cyan,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 POPRAWKA: lib/screens/palm_analysis_result_screen.dart
// Problem: Null check operator used on a null value (linia 224)

// Znajdź metodę _buildScrollableText() i zamień na:

Widget _buildScrollableText() {
  // ✅ POPRAWKA: Sprawdź czy analysisResult nie jest null
  if (widget.analysisResult?.analysisText == null) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Brak danych analizy',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nie udało się wygenerować wróżby',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ POPRAWKA: Bezpieczne używanie analysisText
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
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
    child: SingleChildScrollView(
      child: Text(
        widget.analysisResult!.analysisText, // Teraz bezpieczne
        style: GoogleFonts.cinzelDecorative(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w300,
          height: 1.6,
        ),
      ),
    ),
  );
}

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMysticalBackground(),
          SafeArea(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.2),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.analysisResult!.errorMessage ?? 'Wystąpił błąd',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                      ),
                      child: Text(
                        'Spróbuj ponownie',
                        style: GoogleFonts.cinzelDecorative(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOldFormatScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMysticalBackground(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildMysticalBackground() {
    return AnimatedBuilder(
      animation: _mysticalAnimation,
      builder: (context, child) {
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
          child: CustomPaint(
            painter: MysticalResultsPainter(_mysticalAnimation.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildScrollableText(),
                ),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.85),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _mysticalAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _mysticalAnimation.value * 2 * math.pi,
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
                'TWOJA WRÓŻBA',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 24,
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: _mysticalAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_mysticalAnimation.value * 2 * math.pi,
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
          const SizedBox(height: 12),
          Text(
            'Drogi${widget.userGender == 'female' ? 'a' : (widget.userGender == 'other' || widget.userGender == 'inna' || widget.userGender == 'neutral') ? '/a' : ''} ${widget.userName}',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Oto co odkryły starożytne znaki w Twojej ${widget.palmData?.handType == 'left' ? 'lewej' : 'prawej'} dłoni',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: AppColors.cyan.withOpacity(0.8),
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              margin: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                onPressed: _shareResults,
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Udostępnij'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cyan,
                  side: BorderSide(color: AppColors.cyan.withOpacity(0.7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 48,
              margin: const EdgeInsets.only(left: 8),
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home, size: 20),
                label: const Text('Powrót'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareResults() {
    final shareText = '''
🔮 Moja wróżba z dłoni - AI Wróżka

👤 ${widget.userName}

Odkryj swoją przyszłość z AI Wróżka!
''';

    Share.share(shareText, subject: 'Moja wróżba z dłoni');
    _loggingService.logToConsole('Udostępniono wyniki wróżby', tag: 'SHARE');
  }
}

class MysticalResultsPainter extends CustomPainter {
  final double animationValue;

  MysticalResultsPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    try {
      // Mystical aura around the screen
      for (int i = 0; i < 5; i++) {
        final centerX = size.width * 0.5;
        final centerY = size.height * 0.5;
        final baseRadius = 100.0 + (i * 60.0);
        final animatedRadius = baseRadius *
            (1 + 0.05 * math.sin(animationValue * 2 * math.pi + i));

        if (animatedRadius > 0 && animatedRadius < size.width * 1.5) {
          // ✅ POPRAWKA: Bezpieczna wartość opacity
          final opacityValue = 0.02 - i * 0.003;
          final safeOpacity = opacityValue.clamp(0.001, 0.05);
          
          paint.color = AppColors.cyan.withOpacity(safeOpacity);
          canvas.drawCircle(Offset(centerX, centerY), animatedRadius, paint);
        }
      }

      // Floating mystical particles
      for (int i = 0; i < 30; i++) {
        final angle = (animationValue * math.pi) + (i * 2 * math.pi / 30);
        final radius = 120.0 + (i % 4) * 40.0;
        final x = size.width * 0.5 +
            radius * math.cos(angle + animationValue * math.pi);
        final y = size.height * 0.5 +
            radius * math.sin(angle * 0.7 + animationValue * math.pi);

        if (x >= -20 &&
            x <= size.width + 20 &&
            y >= -20 &&
            y <= size.height + 20) {
          final particleSize =
              0.8 + math.sin(animationValue * 4 * math.pi + i) * 0.4;
          
          // ✅ POPRAWKA: Bezpieczna wartość opacity
          final opacityBase = 0.1 + math.sin(animationValue * 3 * math.pi + i * 0.5) * 0.05;
          final safeOpacity = opacityBase.clamp(0.02, 0.15);

          if (particleSize > 0) {
            paint.color = AppColors.cyan.withOpacity(safeOpacity);
            canvas.drawCircle(Offset(x, y), particleSize.abs(), paint);
          }
        }
      }

      // Subtle corner decorations
      final cornerPaint = Paint()
        ..color = AppColors.cyan.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      // Top corners - z zabezpieczeniem przed ujemnymi wartościami
      if (size.width > 120 && size.height > 120) {
        canvas.drawArc(
          Rect.fromLTWH(20, 20, 40, 40),
          -math.pi,
          math.pi / 2,
          false,
          cornerPaint,
        );

        canvas.drawArc(
          Rect.fromLTWH(size.width - 60, 20, 40, 40),
          -math.pi / 2,
          math.pi / 2,
          false,
          cornerPaint,
        );

        // Bottom corners
        canvas.drawArc(
          Rect.fromLTWH(20, size.height - 60, 40, 40),
          math.pi / 2,
          math.pi / 2,
          false,
          cornerPaint,
        );

        canvas.drawArc(
          Rect.fromLTWH(size.width - 60, size.height - 60, 40, 40),
          0,
          math.pi / 2,
          false,
          cornerPaint,
        );
      }
    } catch (e) {
      print('❌ Błąd w MysticalResultsPainter: $e');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
