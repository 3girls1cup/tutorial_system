import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tutorial_system/tutorial_system.dart';

import '../src/util/constants.dart';

/// An abstract class representing a single step in a tutorial.
///
/// This class serves as the base for all tutorial steps and defines
/// the common interface for executing a step.
abstract class TutorialStep {
  /// Executes the tutorial step.
  ///
  /// This method is called when the tutorial step should be performed.
  /// [tutorialNotifier] is the current state of the tutorial, which can be
  /// used to update the tutorial's progress or state.
  Future<void> execute(TutorialNotifier? notifier) async {}
}

/// A tutorial step that is associated with a specific [TutorialID].
///
/// This class extends [TutorialStep] and adds the concept of a tutorial
/// identifier and a method to load data from a repository.
/// This is required for highlighting or waiting for conditions.
abstract class TutorialStepWithID extends TutorialStep {
  /// The unique enum identifier for this tutorial step.
  final TutorialID tutorialID;
  final String? tutorialText;
  final Widget? tutorialWidgetContent;

  /// A function to load data from a repository
  final TutorialRegistration? Function()? loadFromRepository;

  /// Creates a [TutorialStepWithID] with the given [tutorialID] and
  /// optional [loadFromRepository] function.
  TutorialStepWithID(
      {required this.tutorialID,
      this.loadFromRepository,
      this.tutorialText,
      this.tutorialWidgetContent});

  /// Sets the loading function for this step using the provided [tutorialRepository].
  ///
  /// This method should be implemented to define how data is loaded for this step.
  TutorialStepWithID setLoadingFunction(
      {required TutorialRepository tutorialRepository});
}

/// A tutorial step that involves waiting for a condition to be met.
///
/// This class extends [TutorialStepWithID] and adds functionality for
/// waiting for a condition with a timeout, and optionally replaying a step
/// if the condition is not met.
abstract class TutorialStepWithWaiting extends TutorialStepWithID {
  /// The maximum duration to wait for the condition to be met.
  final Duration timeout;

  /// An optional step to replay if the condition is not met within the timeout.
  final TutorialStep? replayStep;

  /// A function to call when the step is finished successfully.
  final void Function(TutorialNotifier? notifier) onFinished;

  /// Creates a [TutorialStepWithWaiting] with the given parameters.
  ///
  /// If [duration] is not provided, it defaults to [Constants.defaultConditionTimeout].
  /// If [onFinished] is not provided, it defaults to [TutorialNotifier.nextStep].
  TutorialStepWithWaiting(
      {required super.tutorialID,
      super.loadFromRepository,
      super.tutorialText,
      super.tutorialWidgetContent,
      Duration? duration,
      this.replayStep,
      void Function(TutorialNotifier?)? onFinished})
      : onFinished = onFinished ?? _defaultNextStep,
        timeout = duration ?? Constants.defaultConditionTimeout;

  static void _defaultNextStep(TutorialNotifier? notifier) {
    notifier?.nextStep();
  }

  /// Performs the condition check for this waiting step.
  ///
  /// This method should be implemented to define the specific condition
  /// that needs to be met for this step to be considered complete.
  Future<bool> performConditionCheck();

  /// Waits for a condition to be met using a [StreamSubscription], with a timeout.
  ///
  /// This utility function is especially useful if you need to wait for something to happen on a stream, for example
  /// for a certain event to happen on an event bus.
  ///
  /// This method sets up a timer that will complete the [completer] with `false`
  /// if the [timeout] is reached before the condition is met. The [subscription]
  /// is expected to complete the [completer] with `true` when the condition is met.
  ///
  /// Returns a [Future<bool>] that completes with the result of the condition check.
  ///
  /// The [subscription] and timer are automatically cancelled when the future completes.
  static Future<bool> conditionWithSubscription(Duration timeout,
      Completer<bool> completer, StreamSubscription subscription) {
    // Set a timeout to complete with false if the event doesn't occur
    final timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    return completer.future.then((value) {
      subscription.cancel(); // Cancel the subscription
      timeoutTimer.cancel(); // Cancel the timer
      return value;
    });
  }

  /// Periodically checks a condition until it is met or a timeout occurs.
  ///
  /// This method immediately returns `true` if the [condition] is already met.
  /// Otherwise, it sets up a periodic timer that checks the [condition] at
  /// regular intervals defined by [Constants.repeatConditionCheckInterval].
  ///
  /// If the [condition] is met within the [timeout] duration, the method
  /// returns `true`. If the [timeout] is reached before the condition is met,
  /// it returns `false`.
  ///
  /// Returns a [Future<bool>] that completes with the result of the condition check.
  ///
  /// All timers are automatically cancelled when the future completes.
  static Future<bool> conditionWithTimeout(
      Duration timeout, bool Function() condition) async {
    final completer = Completer<bool>();

    // Immediately return true if the condition is already met
    if (condition()) {
      return true;
    }

    // Set up a periodic timer to check for the condition
    final timer = Timer.periodic(Constants.repeatConditionCheckInterval, (_) {
      if (condition()) {
        completer.complete(true);
      }
    });

    // Set a timeout timer
    final timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    return completer.future.then((value) {
      timeoutTimer.cancel(); // Cancel the subscription
      timer.cancel(); // Cancel the timer
      return value;
    });
  }

  /// Executes the waiting step.
  ///
  /// This method waits for the condition to be met within the specified timeout.
  /// If the condition is met, it calls [onFinished]. If not, it triggers a replay
  /// if [replayStep] is set, or logs a warning in debug mode.
  @override
  Future<void> execute(TutorialNotifier? tutorialNotifier) async {
    if (tutorialText != null || tutorialWidgetContent != null) {
      GlobalKey? widgetKey = loadFromRepository?.call()?.key;
      if (widgetKey == null) {
        if (kDebugMode) {
          print(
              "TUTORIAL WARNING: Highlight step invoked without widget key registered: Widget $tutorialID");
        }
      }
    }
    if (await performConditionCheck()) {
      onFinished(tutorialNotifier);
    } else {
      // Duration exceeded and condition is not met, trigger replay if set
      if (replayStep != null) {
        tutorialNotifier?.replayStep(replayStep);
      } else {
        if (kDebugMode) {
          print("TUTORIAL WARNING: "
              "TutorialStepWithWaiting duration exceeded without replay, tutorial cannot be finished.");
        }
      }
    }
  }
}

/// A tutorial step that highlights a specific widget and displays text.
class WidgetHighlightTutorialStep extends TutorialStepWithID {
  /// The text to be displayed on screen during this tutorial step.

  /// Creates a [WidgetHighlightTutorialStep] with the given [tutorialText] and [tutorialID].
  WidgetHighlightTutorialStep(
      {super.tutorialText,
      super.tutorialWidgetContent,
      required super.tutorialID,
      super.loadFromRepository});

  /// Executes the widget highlight step.
  ///
  /// Attempts to load the widget key from the repository. If the key is not found,
  /// a warning is printed in debug mode.
  @override
  Future<void> execute(TutorialNotifier? tutorialNotifier) async {
    GlobalKey? widgetKey = loadFromRepository?.call()?.key;
    if (widgetKey == null) {
      if (kDebugMode) {
        print(
            "TUTORIAL WARNING: Highlight step invoked without widget key registered: Widget $tutorialID");
      }
    }
  }

  /// Sets the loading function for this step using the provided [tutorialRepository].
  @override
  WidgetHighlightTutorialStep setLoadingFunction(
      {required TutorialRepository tutorialRepository}) {
    if (tutorialText == null && tutorialWidgetContent == null) {
      throw Exception("Tutorial text or widget content must be provided.");
    }
    return WidgetHighlightTutorialStep(
        tutorialText: tutorialText,
        tutorialWidgetContent: tutorialWidgetContent,
        tutorialID: tutorialID,
        loadFromRepository: () => tutorialRepository.get(tutorialID));
  }
}

/// A tutorial step that waits for a specific [BuildContext] to become current.
///
/// For example, useful for checking if a dialog has been opened.
class WaitForContextTutorialStep extends TutorialStepWithWaiting {
  /// Creates a [WaitForContextTutorialStep] with the given parameters.
  WaitForContextTutorialStep({
    required super.tutorialID,
    super.loadFromRepository,
    super.duration,
    super.replayStep,
    super.onFinished,
  });

  /// Performs the condition check for this waiting step.
  ///
  /// Checks if the loaded [BuildContext] is currently active.
  @override
  Future<bool> performConditionCheck() async {
    return TutorialStepWithWaiting.conditionWithTimeout(timeout, () {
      BuildContext? buildContext = loadFromRepository?.call()?.context;
      if (buildContext == null) {
        return false;
      }
      return ModalRoute.of(buildContext)?.isCurrent ?? false;
    });
  }

  /// Sets the loading function for this step using the provided [tutorialRepository].
  @override
  WaitForContextTutorialStep setLoadingFunction(
      {required TutorialRepository tutorialRepository}) {
    return WaitForContextTutorialStep(
        tutorialID: tutorialID,
        loadFromRepository: () => tutorialRepository.get(tutorialID),
        duration: timeout,
        replayStep: replayStep,
        onFinished: onFinished);
  }
}

/// A tutorial step that waits for a specific condition to be met.
class WaitForConditionTutorialStep extends TutorialStepWithWaiting {
  WaitForConditionTutorialStep(
      {required super.tutorialID,
      super.tutorialText,
      super.tutorialWidgetContent,
      super.loadFromRepository,
      super.duration,
      super.replayStep,
      super.onFinished});

  /// Performs the condition check for this waiting step.
  ///
  /// Loads and executes a condition function from the repository.
  @override
  Future<bool> performConditionCheck() async {
    Stream<bool> Function()? conditionStreamFunction =
        loadFromRepository?.call()?.streamCondition;
    print(conditionStreamFunction);
    if (conditionStreamFunction != null) {
      final completer = Completer<bool>();
      final subscription = conditionStreamFunction().listen((event) {
        if (event) {
          completer.complete(true);
        }
      });

      return TutorialStepWithWaiting.conditionWithSubscription(
          timeout, completer, subscription);
    } else {
      Future<bool> Function(Duration)? conditionFunction =
          loadFromRepository?.call()?.condition;
      if (conditionFunction != null && await conditionFunction(timeout)) {
        return true;
      }
      return false;
    }
  }

  /// Sets the loading function for this step using the provided [tutorialRepository].
  @override
  TutorialStepWithID setLoadingFunction(
      {required TutorialRepository tutorialRepository}) {
    return WaitForConditionTutorialStep(
        tutorialID: tutorialID,
        tutorialText: tutorialText,
        tutorialWidgetContent: tutorialWidgetContent,
        loadFromRepository: () => tutorialRepository.get(tutorialID),
        duration: timeout,
        replayStep: replayStep,
        onFinished: onFinished);
  }
}

/// A tutorial step that waits for a specific widget to become visible.
class WaitForVisibleWidgetStep extends TutorialStepWithWaiting {
  /// Creates a [WaitForVisibleWidgetStep] with the given parameters.
  WaitForVisibleWidgetStep(
      {required super.tutorialID,
      super.loadFromRepository,
      super.duration,
      super.replayStep,
      super.onFinished});

  /// Performs the condition check for this waiting step.
  ///
  /// Checks if the loaded widget key has a current context, indicating visibility.
  @override
  Future<bool> performConditionCheck() async {
    return TutorialStepWithWaiting.conditionWithTimeout(timeout, () {
      GlobalKey? widgetKey = loadFromRepository?.call()?.key;
      if (widgetKey == null) {
        return false;
      }
      return widgetKey.currentContext != null;
    });
  }

  /// Sets the loading function for this step using the provided [tutorialRepository].
  @override
  TutorialStepWithID setLoadingFunction(
      {required TutorialRepository tutorialRepository}) {
    return WaitForVisibleWidgetStep(
        tutorialID: tutorialID,
        loadFromRepository: () => tutorialRepository.get(tutorialID),
        duration: timeout,
        replayStep: replayStep,
        onFinished: onFinished);
  }
}

/// A tutorial step that plays an audio file.
class AudioTutorialStep implements TutorialStep {
  /// The asset path of the audio file to be played.
  final String assetPath;

  /// A function to be called when the audio playback is finished.
  final void Function(TutorialNotifier?) onFinished;

  /// Creates an [AudioTutorialStep] with the given [assetPath] and optional [onFinished] function.
  AudioTutorialStep(
      {required this.assetPath, void Function(TutorialNotifier?)? onFinished})
      : onFinished = onFinished ?? _defaultNextStep;

  static void _defaultNextStep(TutorialNotifier? notifier) {
    notifier?.nextStep();
  }

  /// Executes the audio tutorial step.
  ///
  /// Plays the audio file and calls [onFinished] when playback is complete.
  @override
  Future<void> execute(TutorialNotifier? tutorialNotifier) async {
    final player = AudioPlayer();
    Duration? duration = await player.setAsset(assetPath);
    if (duration == null) {
      player.dispose();
      onFinished(tutorialNotifier);
      return;
    }
    player.play();
    // TODO Get correct Duration value from Audio Source
    await Future.delayed(const Duration(seconds: 2)).then((value) {
      player.dispose();
      onFinished(tutorialNotifier);
    });
  }
}

/// A tutorial step that displays plain text.
class PlainTextTutorialStep implements TutorialStep {
  /// The text to be displayed during this tutorial step.
  final String tutorialText;

  /// Creates a [PlainTextTutorialStep] with the given [tutorialText].
  PlainTextTutorialStep({required this.tutorialText});

  /// Executes the plain text tutorial step.
  ///
  /// This method is currently empty and does not perform any action.
  @override
  Future<void> execute(TutorialNotifier? tutorialNotifier) async {}
}
