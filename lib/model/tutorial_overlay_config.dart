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

class ExclusionZone {
  final GlobalKey widgetKey;
  final bool? rounded;
  final double? exclusionBorderRadius;
  final Widget? top;
  final Widget? bottom;
  final Widget? right;
  final Widget? left;
  final Widget? center;
  final double? breathingScale;
  final bool? animate;
  final Duration? breathingDuration;
  final Rect? rect;

  ExclusionZone({
    required this.widgetKey,
    this.rounded,
    this.exclusionBorderRadius,
    this.top,
    this.bottom,
    this.right,
    this.left,
    this.center,
    this.breathingScale,
    this.animate,
    this.breathingDuration,
    this.rect,
  });

  /// Define to general (OverlayConfig) values if not specifics defined
  ExclusionZone copyWith({
    bool? rounded,
    double? exclusionBorderRadius,
    double? breathingScale,
    bool? animate,
    Duration? breathingDuration,
    Rect? rect,
  }) {
    return ExclusionZone(
      widgetKey: widgetKey,
      rounded: this.rounded ?? rounded,
      exclusionBorderRadius:
          this.exclusionBorderRadius ?? exclusionBorderRadius,
      top: top,
      bottom: bottom,
      right: right,
      left: left,
      center: center,
      breathingScale: this.breathingScale ?? breathingScale,
      animate: this.animate ?? animate,
      breathingDuration: this.breathingDuration ?? breathingDuration,
      rect: rect ?? this.rect,
    );
  }
}

class OverlayConfig {
  OverlayConfig({
    List<ExclusionZone> exclusionZones = const [],
    this.nextOnTap = false,
    this.rounded = false,
    this.customWidget,
    this.nextButton,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.7),
    this.animate = false,
    this.breathingDuration = const Duration(seconds: 2),
    this.breathingScale = 1.1,
    this.delayBeforeNextButtonActive = 0,
    this.exclusionBorderRadius = 8.0,
    this.displaySkipButton = true,
    this.displayNextButton = true,
    this.displayPreviousButton = false,
  }) : exclusionZones = exclusionZones
            .map((zone) => zone.copyWith(
                  rounded: rounded,
                  exclusionBorderRadius: exclusionBorderRadius,
                  breathingScale: breathingScale,
                  animate: animate,
                  breathingDuration: breathingDuration,
                ))
            .toList();

  final bool rounded;
  final List<ExclusionZone> exclusionZones;
  final bool nextOnTap;
  final Widget? nextButton;
  final Color overlayColor;
  final bool animate;
  final double breathingScale;
  final Duration breathingDuration;
  final Widget? customWidget;
  final double exclusionBorderRadius;
  final int delayBeforeNextButtonActive;
  final bool displayNextButton;
  final bool displayPreviousButton;
  final bool displaySkipButton;

  OverlayConfig copyWith({
    OverlayConfig?
        other, // Une autre instance d'OverlayConfig à utiliser comme base
    List<ExclusionZone>? exclusionZones,
    bool? nextOnTap,
    Widget? customWidget,
    Widget? nextButton,
    bool? rounded,
    Color? overlayColor,
    bool? animate,
    Duration? breathingDuration,
    double? breathingScale,
    double? exclusionBorderRadius,
    int? delayBeforeNextButtonActive,
    bool? displayNextButton,
    bool? displayPreviousButton,
    bool? displaySkipButton,
  }) {
    return OverlayConfig(
      exclusionZones:
          exclusionZones ?? other?.exclusionZones ?? this.exclusionZones,
      nextOnTap: nextOnTap ?? other?.nextOnTap ?? this.nextOnTap,
      customWidget: customWidget ?? other?.customWidget ?? this.customWidget,
      nextButton: nextButton ?? other?.nextButton ?? this.nextButton,
      rounded: rounded ?? other?.rounded ?? this.rounded,
      overlayColor: overlayColor ?? other?.overlayColor ?? this.overlayColor,
      animate: animate ?? other?.animate ?? this.animate,
      breathingDuration: breathingDuration ??
          other?.breathingDuration ??
          this.breathingDuration,
      breathingScale:
          breathingScale ?? other?.breathingScale ?? this.breathingScale,
      exclusionBorderRadius: exclusionBorderRadius ??
          other?.exclusionBorderRadius ??
          this.exclusionBorderRadius,
      delayBeforeNextButtonActive: delayBeforeNextButtonActive ??
          other?.delayBeforeNextButtonActive ??
          this.delayBeforeNextButtonActive,
      displayNextButton: displayNextButton ??
          other?.displayNextButton ??
          this.displayNextButton,
      displayPreviousButton: displayPreviousButton ??
          other?.displayPreviousButton ??
          this.displayPreviousButton,
      displaySkipButton: displaySkipButton ??
          other?.displaySkipButton ??
          this.displaySkipButton,
    );
  }
}
