// lib/widgets/animated_hand.dart
// SKOPIUJ DO TEGO PLIKU:

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/constants.dart';

class AnimatedHand extends StatefulWidget {
  const AnimatedHand({super.key});

  @override
  State<AnimatedHand> createState() => _AnimatedHandState();
}

class _AnimatedHandState extends State<AnimatedHand>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _symbolController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _symbolAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _symbolController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _symbolAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_symbolController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _symbolAnimation]),
      builder: (context, child) {
        return SizedBox(
          width: 300,
          height: 400,
          child: CustomPaint(
            painter: HandPainter(
              pulseValue: _pulseAnimation.value,
              symbolRotation: _symbolAnimation.value,
            ),
          ),
        );
      },
    );
  }
}

class HandPainter extends CustomPainter {
  final double pulseValue;
  final double symbolRotation;

  HandPainter({required this.pulseValue, required this.symbolRotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Rysowanie dłoni
    _drawHand(canvas, size, center);

    // Rysowanie symboli nad palcami
    _drawSymbols(canvas, size, center);

    // Rysowanie świecących punktów
    _drawGlowingDots(canvas, size, center);
  }

  void _drawHand(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..color = AppColors.cyan.withAlpha((0.6 * 255).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * pulseValue
      ..strokeCap = StrokeCap.round;

    // Prosty kształt dłoni
    const handWidth = 80.0;
    const handHeight = 120.0;
    const fingerHeight = 60.0;

    // Dłoń (prostokąt z zaokrąglonymi rogami)
    final handRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 40),
        width: handWidth,
        height: handHeight,
      ),
      const Radius.circular(15),
    );

    canvas.drawRRect(handRect, paint);

    // Palce
    const fingerWidth = 12.0;
    final fingerPositions = [
      -30.0, -10.0, 10.0, 30.0, // pozycje X dla palców
    ];

    for (int i = 0; i < fingerPositions.length; i++) {
      final fingerX = center.dx + fingerPositions[i];
      final fingerRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          fingerX - fingerWidth / 2,
          center.dy - 40,
          fingerWidth,
          fingerHeight,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(fingerRect, paint);
    }

    // Kciuk
    final thumbRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx - 50, center.dy + 10, 12, 40),
      const Radius.circular(6),
    );
    canvas.drawRRect(thumbRect, paint);
  }

  void _drawSymbols(Canvas canvas, Size size, Offset center) {
    final symbolPaint = Paint()
      ..color = AppColors.cyan.withAlpha((0.8 * 255).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final symbolPositions = [
      Offset(center.dx - 30, center.dy - 80), // nad pierwszym palcem
      Offset(center.dx - 10, center.dy - 90), // nad drugim palcem
      Offset(center.dx + 10, center.dy - 85), // nad trzecim palcem
      Offset(center.dx + 30, center.dy - 80), // nad czwartym palcem
    ];

    for (int i = 0; i < symbolPositions.length; i++) {
      canvas.save();
      canvas.translate(symbolPositions[i].dx, symbolPositions[i].dy);
      canvas.rotate(symbolRotation * 2 * math.pi);

      // Rysowanie trójkątów (symbole)
      final symbolPath = Path();
      symbolPath.moveTo(0, -15);
      symbolPath.lineTo(-10, 10);
      symbolPath.lineTo(10, 10);
      symbolPath.close();

      canvas.drawPath(symbolPath, symbolPaint);
      canvas.restore();
    }
  }

  void _drawGlowingDots(Canvas canvas, Size size, Offset center) {
    final glowPaint = Paint()
      ..color = AppColors.cyan
      ..style = PaintingStyle.fill;

    // Losowe punkty świetlne na dłoni
    final dotPositions = [
      Offset(center.dx - 20, center.dy),
      Offset(center.dx + 15, center.dy + 20),
      Offset(center.dx - 10, center.dy + 30),
      Offset(center.dx + 25, center.dy - 10),
    ];

    for (final dotPos in dotPositions) {
      canvas.drawCircle(dotPos, 2.0 * pulseValue, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
