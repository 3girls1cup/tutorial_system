import 'package:flutter/material.dart';

enum Position {
  topCenter,
  topLeft,
  topRight,
  center,
  centerLeft,
  centerRight,
  bottomCenter,
  bottomLeft,
  bottomRight,
}

class OverlayConfig {
  OverlayConfig({
    this.widgetKey,
    bool nextOnTap = false,
    this.title,
    this.description,
    this.customWidget,
    this.nextButton,
    this.rounded = false,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.5),
    this.titleStyle,
    this.descriptionStyle,
    this.animateBreathing = false,
    this.breathingDuration = const Duration(microseconds: 300),
    this.breathingScale = 1.1,
    this.titlePosition = Position.topCenter,
    this.descriptionPosition = Position.bottomCenter,
    this.customWidgetPosition = Position.bottomCenter,
    Offset? titleOffset,
    Offset? descriptionOffset,
    Offset? customWidgetOffset,
    this.exclusionBorderRadius = 8.0,
  })  : nextOnTap = widgetKey == null ? true : nextOnTap,
        titleOffset = titleOffset ?? getDefaultOffset(titlePosition),
        descriptionOffset =
            descriptionOffset ?? getDefaultOffset(descriptionPosition),
        customWidgetOffset =
            customWidgetOffset ?? getDefaultOffset(customWidgetPosition);

  final bool rounded;
  final GlobalKey? widgetKey;
  final bool nextOnTap;
  final Widget? nextButton;
  final Color overlayColor;
  final bool animateBreathing;
  final double breathingScale;
  final Duration breathingDuration;
  final String? title;
  final String? description;

  /// Preferably use a Positioned widget, it will override the default Position
  final Widget? customWidget;
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final Position customWidgetPosition;
  final Position titlePosition;
  final Position descriptionPosition;
  final Offset customWidgetOffset;
  final Offset titleOffset;
  final Offset descriptionOffset;
  final double exclusionBorderRadius;

  Offset getPosition(Rect exclusionZone, Position position) {
    switch (position) {
      case Position.topCenter:
        return Offset(exclusionZone.center.dx, exclusionZone.top);
      case Position.topLeft:
        return Offset(exclusionZone.left, exclusionZone.top);
      case Position.topRight:
        return Offset(exclusionZone.right, exclusionZone.top);
      case Position.center:
        return Offset(exclusionZone.center.dx, exclusionZone.center.dy);
      case Position.centerLeft:
        return Offset(exclusionZone.left, exclusionZone.center.dy);
      case Position.centerRight:
        return Offset(exclusionZone.right, exclusionZone.center.dy);
      case Position.bottomCenter:
        return Offset(exclusionZone.center.dx, exclusionZone.bottom);
      case Position.bottomLeft:
        return Offset(exclusionZone.left, exclusionZone.bottom);
      case Position.bottomRight:
        return Offset(exclusionZone.right, exclusionZone.bottom);
    }
  }

  static Offset getDefaultOffset(Position position) {
    switch (position) {
      case Position.topCenter:
        return const Offset(0, -20);
      case Position.topLeft:
        return const Offset(20, -20);
      case Position.topRight:
        return const Offset(-20, -20);
      case Position.center:
        return const Offset(0, 0);
      case Position.centerLeft:
        return const Offset(20, 0);
      case Position.centerRight:
        return const Offset(-20, 0);
      case Position.bottomCenter:
        return const Offset(0, 20);
      case Position.bottomLeft:
        return const Offset(20, 20);
      case Position.bottomRight:
        return const Offset(-20, 20);
    }
  }

  OverlayConfig copyWith({
    OverlayConfig? other,
    String? title,
    String? description,
    String? imageUrl,
    Widget? customWidget,
    bool? rounded,
    GlobalKey? widgetKey,
  }) {
    if (other != null) {
      return OverlayConfig(
        title: other.title ?? this.title,
        description: other.description ?? this.description,
        customWidget: other.customWidget ?? this.customWidget,
        rounded: other.rounded,
        widgetKey: other.widgetKey,
      );
    }
    return OverlayConfig(
      title: title ?? this.title,
      description: description ?? this.description,
      customWidget: customWidget ?? this.customWidget,
      rounded: rounded ?? this.rounded,
      widgetKey: widgetKey ?? this.widgetKey,
    );
  }
}
