// lib/widgets/star_field.dart
// SKOPIUJ DO TEGO PLIKU:

import 'package:flutter/material.dart';
import 'dart:math' as math;

class StarField extends StatefulWidget {
  const StarField({super.key});

  @override
  State<StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<StarField> with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Star> stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    stars = _generateStars(50);
  }

  List<Star> _generateStars(int count) {
    final random = math.Random();
    return List.generate(count, (index) {
      return Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 3 + 1,
        speed: random.nextDouble() * 0.5 + 0.1,
        opacity: random.nextDouble() * 0.8 + 0.2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: StarFieldPainter(
            stars: stars,
            animationValue: _controller.value,
          ),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class Star {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class StarFieldPainter extends CustomPainter {
  final List<Star> stars;
  final double animationValue;

  StarFieldPainter({required this.stars, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final star in stars) {
      final opacity =
          (math.sin(animationValue * 2 * math.pi * star.speed) + 1) / 2;
      paint.color =
          Colors.white.withAlpha((star.opacity * opacity * 255).toInt());

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
