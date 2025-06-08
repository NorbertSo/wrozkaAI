import 'package:flutter/material.dart';
import '../utils/constants.dart';

class MagicHandWidget extends StatefulWidget {
  const MagicHandWidget({super.key});

  @override
  State<MagicHandWidget> createState() => _MagicHandWidgetState();
}

class _MagicHandWidgetState extends State<MagicHandWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(_animation.value * 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.cyan.withOpacity(_animation.value * 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/magic_hand.png',
            width: 128,
            height: 128,
          ),
        );
      },
    );
  }
}
