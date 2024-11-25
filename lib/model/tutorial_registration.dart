import 'package:flutter/material.dart';
import 'package:tutorial_system/model/tutorial_overlay_config.dart';

class TutorialRegistration {
  final OverlayConfig? overlayConfig;
  final Future<bool> Function(Duration)? condition;
  final BuildContext? context;
  final Stream<bool> Function()? streamCondition;

  TutorialRegistration(
      {this.overlayConfig, this.condition, this.context, this.streamCondition});
}
