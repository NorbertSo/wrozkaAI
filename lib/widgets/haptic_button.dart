// lib/widgets/haptic_button.dart
// Widget przycisku z automatyczną wibracją

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/haptic_service.dart';
import '../utils/constants.dart';

class HapticButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final HapticType hapticType;
  final ButtonStyle? style;
  final bool enabled;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final Widget? loadingWidget;

  const HapticButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.hapticType = HapticType.light,
    this.style,
    this.enabled = true,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.isLoading = false,
    this.loadingWidget,
  });

  @override
  State<HapticButton> createState() => _HapticButtonState();
}

class _HapticButtonState extends State<HapticButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final HapticService _hapticService = HapticService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (!widget.enabled || widget.isLoading || widget.onPressed == null) {
      return;
    }

    // Animacja naciśnięcia
    await _animationController.forward();
    await _animationController.reverse();

    // Wibracja
    await _hapticService.trigger(widget.hapticType);

    // Wywołaj callback
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _buildButton(),
        );
      },
    );
  }

  Widget _buildButton() {
    return SizedBox(
      width: widget.width,
      height: widget.height ?? 48,
      child: ElevatedButton(
        onPressed: widget.enabled && !widget.isLoading ? _handleTap : null,
        style: widget.style ?? _getDefaultStyle(),
        child: widget.isLoading
            ? (widget.loadingWidget ??
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.foregroundColor ?? Colors.white,
                    ),
                  ),
                ))
            : _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            size: 20,
            color: widget.foregroundColor ?? Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: AppTextStyles.buttonText.copyWith(
              color: widget.foregroundColor ?? Colors.white,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: AppTextStyles.buttonText.copyWith(
        color: widget.foregroundColor ?? Colors.white,
      ),
    );
  }

  ButtonStyle _getDefaultStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: widget.backgroundColor ?? AppColors.cyan,
      foregroundColor: widget.foregroundColor ?? Colors.white,
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      ),
      elevation: widget.enabled ? 2 : 0,
      shadowColor: (widget.backgroundColor ?? AppColors.cyan).withOpacity(0.3),
    );
  }
}

// Specjalne przyciski z predefiniowanymi stylami

class HapticPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const HapticPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      hapticType: HapticType.impact,
      backgroundColor: AppColors.cyan,
      foregroundColor: Colors.black,
      isLoading: isLoading,
      width: width,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cyan,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 4,
        shadowColor: AppColors.cyan.withOpacity(0.4),
      ),
    );
  }
}

class HapticSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const HapticSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      hapticType: HapticType.light,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.cyan,
      isLoading: isLoading,
      width: width,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cyan,
        side: BorderSide(color: AppColors.cyan.withOpacity(0.7), width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }
}

class HapticIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final HapticType hapticType;
  final Color? color;
  final double size;
  final String? tooltip;
  final bool enabled;

  const HapticIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.hapticType = HapticType.selection,
    this.color,
    this.size = 24,
    this.tooltip,
    this.enabled = true,
  });

  @override
  State<HapticIconButton> createState() => _HapticIconButtonState();
}

class _HapticIconButtonState extends State<HapticIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final HapticService _hapticService = HapticService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (!widget.enabled || widget.onPressed == null) return;

    await _animationController.forward();
    await _animationController.reverse();

    await _hapticService.trigger(widget.hapticType);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: IconButton(
            onPressed: widget.enabled ? _handleTap : null,
            icon: Icon(
              widget.icon,
              color: widget.color ?? AppColors.cyan,
              size: widget.size,
            ),
            tooltip: widget.tooltip,
          ),
        );
      },
    );
  }
}

class HapticFloatingActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final HapticType hapticType;
  final Color? backgroundColor;
  final String? tooltip;
  final bool mini;

  const HapticFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.hapticType = HapticType.medium,
    this.backgroundColor,
    this.tooltip,
    this.mini = false,
  });

  @override
  State<HapticFloatingActionButton> createState() =>
      _HapticFloatingActionButtonState();
}

class _HapticFloatingActionButtonState extends State<HapticFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final HapticService _hapticService = HapticService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (widget.onPressed == null) return;

    await _animationController.forward();
    await _animationController.reverse();

    await _hapticService.trigger(widget.hapticType);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FloatingActionButton(
            onPressed: _handleTap,
            backgroundColor: widget.backgroundColor ?? AppColors.cyan,
            tooltip: widget.tooltip,
            mini: widget.mini,
            child: widget.child,
          ),
        );
      },
    );
  }
}
