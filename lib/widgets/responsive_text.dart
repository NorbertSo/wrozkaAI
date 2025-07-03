// lib/widgets/responsive_text.dart
// Responsywny widget tekstu

import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final double? baseFontSize;
  final FontWeight? fontWeight;
  final Color? color;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.baseFontSize,
    this.fontWeight,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveStyle = style?.copyWith(
          fontSize: baseFontSize != null
              ? ResponsiveUtils.getResponsiveFontSize(context, baseFontSize!)
              : style?.fontSize != null
                  ? ResponsiveUtils.getResponsiveFontSize(
                      context, style!.fontSize!)
                  : null,
          fontWeight: fontWeight ?? style?.fontWeight,
          color: color ?? style?.color,
        ) ??
        TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(
              context, baseFontSize ?? 14.0),
          fontWeight: fontWeight,
          color: color,
        );

    return Text(
      text,
      style: responsiveStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
