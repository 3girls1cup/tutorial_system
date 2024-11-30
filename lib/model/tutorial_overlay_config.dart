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
    this.widgetKeys = const [],
    this.nextOnTap = false,
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
  })  : titleOffset = titleOffset ?? getDefaultOffset(titlePosition),
        descriptionOffset =
            descriptionOffset ?? getDefaultOffset(descriptionPosition),
        customWidgetOffset =
            customWidgetOffset ?? getDefaultOffset(customWidgetPosition);

  final bool rounded;
  final List<GlobalKey> widgetKeys;
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
    OverlayConfig?
        other, // Une autre instance d'OverlayConfig à utiliser comme base
    List<GlobalKey>? widgetKey,
    bool? nextOnTap,
    String? title,
    String? description,
    Widget? customWidget,
    Widget? nextButton,
    bool? rounded,
    Color? overlayColor,
    TextStyle? titleStyle,
    TextStyle? descriptionStyle,
    bool? animateBreathing,
    Duration? breathingDuration,
    double? breathingScale,
    Position? titlePosition,
    Position? descriptionPosition,
    Position? customWidgetPosition,
    Offset? titleOffset,
    Offset? descriptionOffset,
    Offset? customWidgetOffset,
    double? exclusionBorderRadius,
  }) {
    return OverlayConfig(
      widgetKeys: widgetKey ?? other?.widgetKeys ?? this.widgetKeys,
      nextOnTap: nextOnTap ?? other?.nextOnTap ?? this.nextOnTap,
      title: title ?? other?.title ?? this.title,
      description: description ?? other?.description ?? this.description,
      customWidget: customWidget ?? other?.customWidget ?? this.customWidget,
      nextButton: nextButton ?? other?.nextButton ?? this.nextButton,
      rounded: rounded ?? other?.rounded ?? this.rounded,
      overlayColor: overlayColor ?? other?.overlayColor ?? this.overlayColor,
      titleStyle: titleStyle ?? other?.titleStyle ?? this.titleStyle,
      descriptionStyle:
          descriptionStyle ?? other?.descriptionStyle ?? this.descriptionStyle,
      animateBreathing:
          animateBreathing ?? other?.animateBreathing ?? this.animateBreathing,
      breathingDuration: breathingDuration ??
          other?.breathingDuration ??
          this.breathingDuration,
      breathingScale:
          breathingScale ?? other?.breathingScale ?? this.breathingScale,
      titlePosition:
          titlePosition ?? other?.titlePosition ?? this.titlePosition,
      descriptionPosition: descriptionPosition ??
          other?.descriptionPosition ??
          this.descriptionPosition,
      customWidgetPosition: customWidgetPosition ??
          other?.customWidgetPosition ??
          this.customWidgetPosition,
      titleOffset: titleOffset ?? other?.titleOffset ?? this.titleOffset,
      descriptionOffset: descriptionOffset ??
          other?.descriptionOffset ??
          this.descriptionOffset,
      customWidgetOffset: customWidgetOffset ??
          other?.customWidgetOffset ??
          this.customWidgetOffset,
      exclusionBorderRadius: exclusionBorderRadius ??
          other?.exclusionBorderRadius ??
          this.exclusionBorderRadius,
    );
  }
}
