import 'package:flutter/material.dart';

class TutorialRegistration {
  final GlobalKey? key;
  final Future<bool> Function(Duration)? condition;
  final BuildContext? context;
  final Stream<bool> Function()? streamCondition;

  TutorialRegistration(
      {this.key, this.condition, this.context, this.streamCondition});
}
