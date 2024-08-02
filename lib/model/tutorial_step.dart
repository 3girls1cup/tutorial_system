import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  /// [tutorialBloc] is the current state of the tutorial, which can be
  /// used to update the tutorial's progress or state.
  Future<void> execute(TutorialBloc? tutorialBloc) async {}
}

/// A tutorial step that is associated with a specific [TutorialID].
///
/// This class extends [TutorialStep] and adds the concept of a tutorial
/// identifier and a method to load data from a repository.
/// This is required for highlighting or waiting for conditions.
abstract class TutorialStepWithID extends TutorialStep {
  /// The unique enum identifier for this tutorial step.
  final TutorialID tutorialID;

  /// A function to load data from a repository
  final dynamic Function()? loadFromRepository;

  /// Creates a [TutorialStepWithID] with the given [tutorialID] and
  /// optional [loadFromRepository] function.
  TutorialStepWithID({required this.tutorialID, this.loadFromRepository});

  /// Sets the loading function for this step using the provided [tutorialKeyRepository].
  ///
  /// This method should be implemented to define how data is loaded for this step.
  TutorialStepWithID setLoadingFunction({required TutorialRepository tutorialKeyRepository});
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
  final void Function(TutorialBloc?) onFinished;

  /// Creates a [TutorialStepWithWaiting] with the given parameters.
  ///
  /// If [duration] is not provided, it defaults to [Constants.defaultConditionTimeout].
  /// If [onFinished] is not provided, it defaults to [TutorialBloc.nextStep].
  TutorialStepWithWaiting(
      {required super.tutorialID,
      super.loadFromRepository,
      Duration? duration,
      this.replayStep,
      void Function(TutorialBloc?)? onFinished})
      : onFinished = onFinished ?? TutorialBloc.nextStep,
        timeout = duration ?? Constants.defaultConditionTimeout;

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
  static Future<bool> conditionWithSubscription(
      Duration timeout, Completer<bool> completer, StreamSubscription subscription) {
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
  static Future<bool> conditionWithTimeout(Duration timeout, bool Function() condition) async {
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
  Future<void> execute(TutorialBloc? tutorialBloc) async {
    if (await performConditionCheck()) {
      onFinished(tutorialBloc);
    } else {
      // Duration exceeded and condition is not met, trigger replay if set
      if (replayStep != null) {
        TutorialBloc.triggerReplay(tutorialBloc, replayStep);
      } else {
        if (kDebugMode) {
          print("TUTORIAL WARNING: "
              "TutorialStepWithWaiting duration exceeded without replay, tutorial cannot be finished.");
        }
      }
    }
  }
}

class WidgetHighlightTutorialStep extends TutorialStepWithID {
  final String tutorialText;

  WidgetHighlightTutorialStep({required this.tutorialText, required super.tutorialID, super.loadFromRepository});

  @override
  Future<void> execute(TutorialBloc? tutorialBloc) async {
    GlobalKey? widgetKey = loadFromRepository?.call();
    if (widgetKey == null) {
      if (kDebugMode) {
        print("TUTORIAL WARNING: Highlight step invoked without widget key registered: Widget $tutorialID");
      }
    }
  }

  @override
  WidgetHighlightTutorialStep setLoadingFunction({required TutorialRepository tutorialKeyRepository}) {
    return WidgetHighlightTutorialStep(
        tutorialText: tutorialText,
        tutorialID: tutorialID,
        loadFromRepository: () => tutorialKeyRepository.get(tutorialID));
  }
}

class WaitForStateTutorialStep extends TutorialStep {
  final Bloc bloc;
  final bool Function(Object?) finishStateCompare;
  final void Function(TutorialBloc?) onFinished;

  WaitForStateTutorialStep(
      {required this.bloc, required this.finishStateCompare, void Function(TutorialBloc?)? onFinished})
      : onFinished = onFinished ?? TutorialBloc.nextStep;

  @override
  Future<void> execute(TutorialBloc? tutorialBloc) async {
    await for (final Object? currentState in bloc.stream) {
      if (finishStateCompare(currentState)) {
        onFinished(tutorialBloc);
        break;
      }
    }
  }
}

class WaitForContextTutorialStep extends TutorialStepWithWaiting {
  WaitForContextTutorialStep({
    required super.tutorialID,
    super.loadFromRepository,
    super.duration,
    super.replayStep,
    super.onFinished,
  });

  @override
  Future<bool> performConditionCheck() async {
    return TutorialStepWithWaiting.conditionWithTimeout(timeout, () {
      BuildContext? buildContext = loadFromRepository?.call();
      if (buildContext == null) {
        return false;
      }
      return ModalRoute.of(buildContext)?.isCurrent ?? false;
    });
  }

  @override
  WaitForContextTutorialStep setLoadingFunction({required TutorialRepository tutorialKeyRepository}) {
    return WaitForContextTutorialStep(
        tutorialID: tutorialID,
        loadFromRepository: () => tutorialKeyRepository.get(tutorialID),
        duration: timeout,
        replayStep: replayStep,
        onFinished: onFinished);
  }
}

class WaitForConditionTutorialStep extends TutorialStepWithWaiting {
  WaitForConditionTutorialStep(
      {required super.tutorialID, super.loadFromRepository, super.duration, super.replayStep, super.onFinished});

  @override
  Future<bool> performConditionCheck() async {
    Future<bool> Function(Duration)? conditionFunction = loadFromRepository?.call();
    if (conditionFunction != null && await conditionFunction(timeout)) {
      return true;
    }
    return false;
  }

  @override
  TutorialStepWithID setLoadingFunction({required TutorialRepository tutorialKeyRepository}) {
    return WaitForConditionTutorialStep(
        tutorialID: tutorialID,
        loadFromRepository: () => tutorialKeyRepository.get(tutorialID),
        duration: timeout,
        replayStep: replayStep,
        onFinished: onFinished);
  }
}

class WaitForVisibleWidgetStep extends TutorialStepWithWaiting {
  WaitForVisibleWidgetStep(
      {required super.tutorialID, super.loadFromRepository, super.duration, super.replayStep, super.onFinished});

  @override
  Future<bool> performConditionCheck() async {
    return TutorialStepWithWaiting.conditionWithTimeout(timeout, () {
      GlobalKey? widgetKey = loadFromRepository?.call();
      if (widgetKey == null) {
        return false;
      }
      return widgetKey.currentContext != null;
    });
  }

  @override
  TutorialStepWithID setLoadingFunction({required TutorialRepository tutorialKeyRepository}) {
    return WaitForVisibleWidgetStep(
        tutorialID: tutorialID,
        loadFromRepository: () => tutorialKeyRepository.get(tutorialID),
        duration: timeout,
        replayStep: replayStep,
        onFinished: onFinished);
  }
}

class AudioTutorialStep implements TutorialStep {
  final String assetPath;
  final void Function(TutorialBloc?) onFinished;

  AudioTutorialStep({required this.assetPath, void Function(TutorialBloc?)? onFinished})
      : onFinished = onFinished ?? TutorialBloc.nextStep;

  @override
  Future<void> execute(TutorialBloc? tutorialBloc) async {
    final player = AudioPlayer();
    Duration? duration = await player.setAsset(assetPath);
    if (duration == null) {
      player.dispose();
      onFinished(tutorialBloc);
      return;
    }
    player.play();
    // TODO Get correct Duration value from Audio Source
    await Future.delayed(const Duration(seconds: 2)).then((value) {
      player.dispose();
      onFinished(tutorialBloc);
    });
  }
}

class PlainTextTutorialStep implements TutorialStep {
  final String tutorialText;

  PlainTextTutorialStep({required this.tutorialText});

  @override
  Future<void> execute(TutorialBloc? tutorialBloc) async {}
}
