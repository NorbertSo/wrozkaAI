// lib/screens/fortune_detail_screen.dart
// Ekran szczegółów wróżby

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../models/fortune_history.dart'; // ✅ POPRAWIONY IMPORT

class FortuneDetailScreen extends StatefulWidget {
  final FortuneHistory fortune;

  const FortuneDetailScreen({
    super.key,
    required this.fortune,
  });

  @override
  State<FortuneDetailScreen> createState() => _FortuneDetailScreenState();
}

class _FortuneDetailScreenState extends State<FortuneDetailScreen>
    with TickerProviderStateMixin {
  // ===== ANIMACJE =====
  late AnimationController _fadeController;
  late AnimationController _mysticalController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _mysticalAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _mysticalController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _mysticalAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mysticalController, curve: Curves.linear),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _mysticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      child: AnimatedBuilder(
        animation: _mysticalAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: DetailBackgroundPainter(_mysticalAnimation.value),
            size: Size.infinite,
          );
        },
      ),
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
                  child: _buildFortuneContent(),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
          // Top row with back button and title
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.cyan.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  iconSize: 20,
                ),
              ),
              Expanded(
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
                        fontSize: 20,
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),

          const SizedBox(height: 16),

          // Fortune info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.cyan.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.fortune.handIcon,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.fortune.handTypeName,
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 14,
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.fortune.formattedDate,
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFortuneContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Drogi${widget.fortune.userGender == 'female' ? 'a' : (widget.fortune.userGender == 'other' ? '/a' : '')} ${widget.fortune.userName},',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                color: AppColors.cyan,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 20),

            // Fortune text
            Text(
              widget.fortune.fortuneText,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w300,
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),

            const SizedBox(height: 24),

            // Decorative divider
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.cyan.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Footer message
            Center(
              child: Text(
                'Niech mistyczne moce będą z Tobą! ✨',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 16,
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
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
                onPressed: _shareFortune,
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
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text('Wróć'),
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

  void _shareFortune() {
    final shareText = '''
🔮 Moja wróżba z dłoni - AI Wróżka

👤 ${widget.fortune.userName}
${widget.fortune.handIcon} ${widget.fortune.handTypeName}
📅 ${widget.fortune.formattedDate}

${widget.fortune.fortuneText}

✨ Odkryj swoją przyszłość z AI Wróżka! ✨
''';

    Share.share(shareText, subject: 'Moja wróżba z dłoni');
  }
}

// Custom painter dla tła szczegółów
class DetailBackgroundPainter extends CustomPainter {
  final double animationValue;

  DetailBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    try {
      // Mystical aura around the screen
      for (int i = 0; i < 4; i++) {
        final centerX = size.width * 0.5;
        final centerY = size.height * 0.5;
        final baseRadius = 80.0 + (i * 50.0);
        final animatedRadius = baseRadius *
            (1 + 0.08 * math.sin(animationValue * 2 * math.pi + i));

        if (animatedRadius > 0 && animatedRadius < size.width * 1.2) {
          final opacityValue = 0.03 - i * 0.005;
          final safeOpacity = opacityValue.clamp(0.001, 0.03);

          paint.color = AppColors.cyan.withOpacity(safeOpacity);
          canvas.drawCircle(Offset(centerX, centerY), animatedRadius, paint);
        }
      }

      // Floating particles
      for (int i = 0; i < 15; i++) {
        final angle = (animationValue * math.pi) + (i * 2 * math.pi / 15);
        final radius = 60.0 + (i % 3) * 30.0;
        final x = size.width * 0.5 + radius * math.cos(angle * 0.4);
        final y = size.height * 0.5 + radius * math.sin(angle * 0.6);

        if (x >= -15 &&
            x <= size.width + 15 &&
            y >= -15 &&
            y <= size.height + 15) {
          final particleSize =
              0.5 + math.sin(animationValue * 3 * math.pi + i) * 0.3;
          final opacity =
              0.08 + math.sin(animationValue * 2 * math.pi + i * 0.3) * 0.04;

          if (particleSize > 0) {
            paint.color = AppColors.cyan.withOpacity(opacity.clamp(0.02, 0.12));
            canvas.drawCircle(Offset(x, y), particleSize.abs(), paint);
          }
        }
      }

      // Corner decorations
      final cornerPaint = Paint()
        ..color = AppColors.cyan.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      if (size.width > 80 && size.height > 80) {
        // Top decorative corners
        canvas.drawArc(
          Rect.fromLTWH(15, 15, 30, 30),
          -math.pi,
          math.pi / 2,
          false,
          cornerPaint,
        );

        canvas.drawArc(
          Rect.fromLTWH(size.width - 45, 15, 30, 30),
          -math.pi / 2,
          math.pi / 2,
          false,
          cornerPaint,
        );

        // Bottom decorative corners
        canvas.drawArc(
          Rect.fromLTWH(15, size.height - 45, 30, 30),
          math.pi / 2,
          math.pi / 2,
          false,
          cornerPaint,
        );

        canvas.drawArc(
          Rect.fromLTWH(size.width - 45, size.height - 45, 30, 30),
          0,
          math.pi / 2,
          false,
          cornerPaint,
        );
      }
    } catch (e) {
      print('❌ Błąd w DetailBackgroundPainter: $e');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
