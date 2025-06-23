// lib/utils/responsive_utils.dart
// Narzędzia do responsywnego designu i zapobiegania overflow

import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Breakpointy dla różnych rozmiarów ekranów
  static const double breakpointSmall = 360.0;
  static const double breakpointMedium = 768.0;
  static const double breakpointLarge = 1024.0;
  static const double breakpointXLarge = 1440.0;

  // Pobiera rozmiar ekranu
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.sizeOf(context);
  }

  // Sprawdza typ urządzenia
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < breakpointSmall) {
      return DeviceType.smallPhone;
    } else if (width < breakpointMedium) {
      return DeviceType.phone;
    } else if (width < breakpointLarge) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  // Zwraca responsywną wartość na podstawie rozmiaru ekranu
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T smallPhone,
    required T phone,
    required T tablet,
    required T desktop,
  }) {
    switch (getDeviceType(context)) {
      case DeviceType.smallPhone:
        return smallPhone;
      case DeviceType.phone:
        return phone;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
    }
  }

  // Zwraca responsywny padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return getResponsiveValue(
      context,
      smallPhone: const EdgeInsets.all(12.0),
      phone: const EdgeInsets.all(16.0),
      tablet: const EdgeInsets.all(24.0),
      desktop: const EdgeInsets.all(32.0),
    );
  }

  // Zwraca responsywny rozmiar tekstu
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final scaleFactor = getResponsiveValue(
      context,
      smallPhone: 0.85,
      phone: 1.0,
      tablet: 1.15,
      desktop: 1.3,
    );
    return baseSize * scaleFactor;
  }

  // Zwraca responsywną szerokość kontenera
  static double getResponsiveWidth(
    BuildContext context, {
    double? maxWidth,
    double widthFactor = 0.9,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final calculatedWidth = screenWidth * widthFactor;

    if (maxWidth != null && calculatedWidth > maxWidth) {
      return maxWidth;
    }

    return calculatedWidth;
  }

  // Sprawdza orientację
  static bool isPortrait(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.portrait;
  }

  // Sprawdza czy jest ciemny motyw
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // Zwraca bezpieczną wysokość (minus status bar i navigation bar)
  static double getSafeHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;
  }

  // Zwraca bezpieczną szerokość
  static double getSafeWidth(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width -
        mediaQuery.padding.left -
        mediaQuery.padding.right;
  }
}

enum DeviceType {
  smallPhone,
  phone,
  tablet,
  desktop,
}

// Widget do responsywnego tekstu z automatyczną skalą
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double baseFontSize;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.baseFontSize = 16.0,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveFontSize = ResponsiveUtils.getResponsiveFontSize(
      context,
      baseFontSize,
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: responsiveFontSize,
      ),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }
}

// Widget do responsywnego kontenera
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final double widthFactor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Decoration? decoration;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.widthFactor = 0.9,
    this.padding,
    this.margin,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveWidth = ResponsiveUtils.getResponsiveWidth(
      context,
      maxWidth: maxWidth,
      widthFactor: widthFactor,
    );

    return Container(
      width: responsiveWidth,
      padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }
}

// Widget do responsywnego Row z automatycznym wrap
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final WrapAlignment wrapAlignment;
  final double spacing;
  final double runSpacing;
  final bool forceWrap;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.wrapAlignment = WrapAlignment.start,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.forceWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    // Na małych ekranach lub gdy forceWrap = true, użyj Wrap
    if (forceWrap ||
        ResponsiveUtils.getDeviceType(context) == DeviceType.smallPhone) {
      return Wrap(
        alignment: wrapAlignment,
        spacing: spacing,
        runSpacing: runSpacing,
        children: children,
      );
    }

    // Na większych ekranach użyj Row z Flexible
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children.map((child) {
        return Flexible(child: child);
      }).toList(),
    );
  }
}

// Rozszerzenie BuildContext dla łatwiejszego dostępu
extension ResponsiveExtension on BuildContext {
  // Szybki dostęp do rozmiaru ekranu
  Size get screenSize => MediaQuery.sizeOf(this);

  // Szybki dostęp do szerokości
  double get screenWidth => MediaQuery.sizeOf(this).width;

  // Szybki dostęp do wysokości
  double get screenHeight => MediaQuery.sizeOf(this).height;

  // Sprawdza czy to mały ekran
  bool get isSmallScreen =>
      ResponsiveUtils.getDeviceType(this) == DeviceType.smallPhone;

  // Sprawdza czy to tablet lub większy
  bool get isTabletOrLarger =>
      ResponsiveUtils.getDeviceType(this) == DeviceType.tablet ||
      ResponsiveUtils.getDeviceType(this) == DeviceType.desktop;

  // Zwraca responsywny padding
  EdgeInsets get responsivePadding =>
      ResponsiveUtils.getResponsivePadding(this);

  // Zwraca responsywną szerokość
  double responsiveWidth({double? maxWidth, double widthFactor = 0.9}) {
    return ResponsiveUtils.getResponsiveWidth(this,
        maxWidth: maxWidth, widthFactor: widthFactor);
  }
}

// Builder do responsywnych layoutów
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    return builder(context, deviceType);
  }
}

// Widget do adaptacyjnych kolumn
class AdaptiveColumns extends StatelessWidget {
  final List<Widget> children;
  final int columnsOnTablet;
  final int columnsOnDesktop;
  final double spacing;
  final double runSpacing;

  const AdaptiveColumns({
    super.key,
    required this.children,
    this.columnsOnTablet = 2,
    this.columnsOnDesktop = 3,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);

    // Na małych ekranach jedna kolumna
    if (deviceType == DeviceType.smallPhone || deviceType == DeviceType.phone) {
      return Column(children: children);
    }

    // Na tabletach i desktopach siatka
    final columns =
        deviceType == DeviceType.tablet ? columnsOnTablet : columnsOnDesktop;

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) {
        return SizedBox(
          width: (context.screenWidth - (spacing * (columns - 1))) / columns,
          child: child,
        );
      }).toList(),
    );
  }
}
