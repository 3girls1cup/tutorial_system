import 'package:flutter/material.dart';
import 'package:tutorial_system/tutorial_system.dart';

/// An abstract class representing a tutorial.
///
/// This class defines the structure for creating tutorials in the application.
/// Subclasses must implement [getName], [tutorialSteps], and optionally override
/// [registrationFunction] to define the specific behavior of a tutorial.
abstract class Tutorial {
  /// Returns the name of the tutorial.
  ///
  /// This method should be implemented to provide a unique identifier for the tutorial.
  String getName();

  /// Registers the necessary components for the tutorial.
  ///
  /// This method is called to set up the required keys, conditions, or contexts
  /// for the tutorial steps. By default, it throws an [UnimplementedError].
  /// By using it, tutorial logic can be almost entirely defined inside of this object.
  ///
  /// Example:
  /// ```dart
  /// switch(caller) {
  ///      case _MyHomePageState myHomePageState: {
  ///         tutorialRepository.registerKey(ExampleTutorialID.floatingButtonKey, myHomePageState._floatingActionButtonKey);
  ///         tutorialRepository.registerCondition(ExampleTutorialID.counterWasIncreased, (timeout) {
  ///           return TutorialStepWithWaiting.conditionWithTimeout(timeout, () => myHomePageState._counter > 0);
  ///         });
  ///         break;
  ///       }
  /// ```
  /// Parameters:
  ///   [tutorialRepository]: The repository to register keys, conditions, and contexts.
  ///   [caller]: The object calling the registration function.
  ///   [state]: Optional state object, typically a [State] from a [StatefulWidget].
  void registrationFunction(TutorialRepository tutorialRepository, dynamic caller, {State? state}) =>
      throw UnimplementedError();

  /// Returns the list of tutorial steps.
  ///
  /// This getter should be implemented to define the sequence of steps
  /// that make up the tutorial.
  List<TutorialStep> get tutorialSteps;
}
