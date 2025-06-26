// lib/widgets/haptic_button.dart
// 🔘 HAPTIC BUTTON WIDGETS - zgodne z wytycznymi projektu AI Wróżka
// OBOWIĄZKOWE wibracje dla wszystkich przycisków

import 'package:flutter/material.dart';
import '../services/haptic_service.dart';
import '../utils/constants.dart';
import '../utils/responsive_utils.dart';

/// 🔘 HAPTIC BUTTON - główny przycisk z wibracją
/// OBOWIĄZKOWY dla wszystkich przycisków w aplikacji zgodnie z wytycznymi
class HapticButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final HapticType hapticType;
  final ButtonStyle? style;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;

  const HapticButton({
    super.key,
    this.text,
    this.child,
    required this.onPressed,
    this.hapticType = HapticType.light,
    this.style,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
  }) : assert(text != null || child != null,
            'Either text or child must be provided');

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    return SizedBox(
      width: width,
      height: height ?? 48, // Minimalny rozmiar 48px zgodnie z Material Design
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () async {
                // ⚡ OBOWIĄZKOWA WIBRACJA zgodnie z wytycznymi
                await hapticService.trigger(hapticType);
                onPressed?.call();
              },
        style: style ?? _getDefaultStyle(context),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    foregroundColor ?? Colors.white,
                  ),
                ),
              )
            : child ??
                ResponsiveText(
                  text!,
                  style: TextStyle(
                    color: foregroundColor ?? Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  baseFontSize: 16,
                ),
      ),
    );
  }

  /// 🎨 Domyślny styl przycisku zgodny z Material Design
  ButtonStyle _getDefaultStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.cyan,
      foregroundColor: foregroundColor ?? Colors.white,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ??
            BorderRadius.circular(10), // 8-12px zgodnie z wytycznymi
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withOpacity(0.1);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withOpacity(0.05);
          }
          return null;
        },
      ),
    );
  }
}

/// 🔘 HAPTIC ICON BUTTON - przycisk z ikoną i wibracją
/// OBOWIĄZKOWY dla wszystkich przycisków z ikonami
class HapticIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final HapticType hapticType;
  final Color? color;
  final double? size;
  final EdgeInsets? padding;
  final String? tooltip;
  final BoxConstraints? constraints;

  const HapticIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.hapticType = HapticType.light,
    this.color,
    this.size,
    this.padding,
    this.tooltip,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    return IconButton(
      onPressed: onPressed == null
          ? null
          : () async {
              // ⚡ OBOWIĄZKOWA WIBRACJA zgodnie z wytycznymi
              await hapticService.trigger(hapticType);
              onPressed!.call();
            },
      icon: Icon(icon),
      color: color ?? AppColors.cyan,
      iconSize: size ?? 24,
      padding: padding ?? const EdgeInsets.all(8),
      constraints: constraints ??
          const BoxConstraints(
            minWidth: 48, // Minimalny rozmiar 48x48px zgodnie z Material Design
            minHeight: 48,
          ),
      tooltip: tooltip,
    );
  }
}

/// 🔘 HAPTIC FLOATING ACTION BUTTON - FAB z wibracją
class HapticFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final HapticType hapticType;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final bool isExtended;
  final String? label;

  const HapticFloatingActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.hapticType = HapticType.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.isExtended = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    if (isExtended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed == null
            ? null
            : () async {
                await hapticService.trigger(hapticType);
                onPressed!.call();
              },
        icon: Icon(icon),
        label: ResponsiveText(
          label!,
          style: TextStyle(
            color: foregroundColor ?? Colors.white,
            fontWeight: FontWeight.w600,
          ),
          baseFontSize: 16,
        ),
        backgroundColor: backgroundColor ?? AppColors.cyan,
        foregroundColor: foregroundColor ?? Colors.white,
        tooltip: tooltip,
      );
    }

    return FloatingActionButton(
      onPressed: onPressed == null
          ? null
          : () async {
              await hapticService.trigger(hapticType);
              onPressed!.call();
            },
      backgroundColor: backgroundColor ?? AppColors.cyan,
      foregroundColor: foregroundColor ?? Colors.white,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}

/// 🔘 HAPTIC TEXT BUTTON - przycisk tekstowy z wibracją
class HapticTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final HapticType hapticType;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsets? padding;

  const HapticTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.hapticType = HapticType.light,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    return TextButton(
      onPressed: onPressed == null
          ? null
          : () async {
              await hapticService.trigger(hapticType);
              onPressed!.call();
            },
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppColors.cyan,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize:
            const Size(48, 48), // Minimalny rozmiar zgodnie z Material Design
      ),
      child: ResponsiveText(
        text,
        style: TextStyle(
          color: color ?? AppColors.cyan,
          fontSize: fontSize,
          fontWeight: fontWeight ?? FontWeight.w500,
        ),
        baseFontSize: fontSize ?? 14,
      ),
    );
  }
}

/// 🔘 HAPTIC OUTLINED BUTTON - przycisk z obramowaniem i wibracją
class HapticOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final HapticType hapticType;
  final Color? borderColor;
  final Color? textColor;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const HapticOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.hapticType = HapticType.light,
    this.borderColor,
    this.textColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    return OutlinedButton(
      onPressed: onPressed == null
          ? null
          : () async {
              await hapticService.trigger(hapticType);
              onPressed!.call();
            },
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor ?? AppColors.cyan,
        side: BorderSide(
          color: borderColor ?? AppColors.cyan,
          width: borderWidth ?? 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(10),
        ),
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize:
            const Size(48, 48), // Minimalny rozmiar zgodnie z Material Design
      ),
      child: ResponsiveText(
        text,
        style: TextStyle(
          color: textColor ?? AppColors.cyan,
          fontWeight: FontWeight.w600,
        ),
        baseFontSize: 16,
      ),
    );
  }
}

/// 🔘 HAPTIC CARD BUTTON - karta klikalna z wibracją
class HapticCardButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final HapticType hapticType;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final List<BoxShadow>? boxShadow;

  const HapticCardButton({
    super.key,
    required this.child,
    required this.onTap,
    this.hapticType = HapticType.light,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    return InkWell(
      onTap: onTap == null
          ? null
          : () async {
              await hapticService.trigger(hapticType);
              onTap!.call();
            },
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          border: borderColor != null
              ? Border.all(
                  color: borderColor!,
                  width: borderWidth ?? 1,
                )
              : null,
          boxShadow: boxShadow,
        ),
        child: child,
      ),
    );
  }
}

/// 🔘 HAPTIC SWITCH - przełącznik z wibracją
class HapticSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final HapticType hapticType;
  final Color? activeColor;
  final Color? inactiveColor;

  const HapticSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.hapticType = HapticType.light,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    return Switch(
      value: value,
      onChanged: onChanged == null
          ? null
          : (newValue) async {
              await hapticService.trigger(hapticType);
              onChanged!.call(newValue);
            },
      activeColor: activeColor ?? AppColors.cyan,
      inactiveThumbColor: inactiveColor ?? Colors.grey,
    );
  }
}

/// 🔘 HAPTIC CHIP - chip z wibracją
class HapticChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final HapticType hapticType;
  final bool isSelected;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? textColor;
  final IconData? icon;

  const HapticChip({
    super.key,
    required this.label,
    this.onTap,
    this.hapticType = HapticType.light,
    this.isSelected = false,
    this.selectedColor,
    this.unselectedColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    return GestureDetector(
      onTap: onTap == null
          ? null
          : () async {
              await hapticService.trigger(hapticType);
              onTap!.call();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (selectedColor ?? AppColors.cyan.withOpacity(0.2))
              : (unselectedColor ?? Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (selectedColor ?? AppColors.cyan)
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? (textColor ?? AppColors.cyan) : Colors.grey,
              ),
              const SizedBox(width: 6),
            ],
            ResponsiveText(
              label,
              style: TextStyle(
                color: isSelected ? (textColor ?? AppColors.cyan) : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              baseFontSize: 14,
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔘 HAPTIC RADIO BUTTON - radio button z wibracją
class HapticRadio<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final HapticType hapticType;
  final Color? activeColor;

  const HapticRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.hapticType = HapticType.light,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    return Radio<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged == null
          ? null
          : (newValue) async {
              await hapticService.trigger(hapticType);
              onChanged!.call(newValue);
            },
      activeColor: activeColor ?? AppColors.cyan,
    );
  }
}

/// 🔘 HAPTIC CHECKBOX - checkbox z wibracją
class HapticCheckbox extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final HapticType hapticType;
  final Color? activeColor;
  final Color? checkColor;

  const HapticCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.hapticType = HapticType.light,
    this.activeColor,
    this.checkColor,
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    return Checkbox(
      value: value,
      onChanged: onChanged == null
          ? null
          : (newValue) async {
              await hapticService.trigger(hapticType);
              onChanged!.call(newValue);
            },
      activeColor: activeColor ?? AppColors.cyan,
      checkColor: checkColor ?? Colors.white,
    );
  }
}
