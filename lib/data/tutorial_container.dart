import 'package:flutter/material.dart';
import 'package:tutorial_system/tutorial_system.dart';

abstract class TutorialContainer {

  String getName();

  void registrationFunction(TutorialKeyRepository tutorialKeyRepository, dynamic caller, {State? state});

  List<TutorialStep> get tutorialSteps => throw UnimplementedError();
}