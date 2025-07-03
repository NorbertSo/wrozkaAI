// lib/widgets/responsive_container.dart
// Responsywny kontener z ograniczeniami szerokości

import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final double widthFactor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Decoration? decoration;
  final bool centerContent;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 600.0, // Domyślna maksymalna szerokość dla contentu
    this.widthFactor = 1.0,
    this.padding,
    this.margin,
    this.decoration,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding =
        padding ?? ResponsiveUtils.getResponsivePadding(context);
    final containerWidth = ResponsiveUtils.getResponsiveWidth(
      context,
      maxWidth: maxWidth,
      widthFactor: widthFactor,
    );

    Widget container = Container(
      width: containerWidth,
      padding: responsivePadding,
      margin: margin,
      decoration: decoration,
      child: child,
    );

    if (centerContent) {
      return Center(child: container);
    }

    return container;
  }
}

// Specjalna wersja dla content na całej szerokości z ograniczeniem maksymalnym
class ResponsiveContentWrapper extends StatelessWidget {
  final Widget child;
  final double maxContentWidth;
  final EdgeInsets? padding;

  const ResponsiveContentWrapper({
    super.key,
    required this.child,
    this.maxContentWidth = 800.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
          child: child,
        ),
      ),
    );
  }
}
