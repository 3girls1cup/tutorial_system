import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tutorial_system/tutorial_system.dart';

import '../src/util/constants.dart';

abstract class TutorialStep {
  Future<void> execute(TutorialBloc? tutorialBloc) async {}
}

abstract class TutorialStepWithID extends TutorialStep {
  final TutorialID tutorialID;
  final dynamic Function()? loadFromRepository;

  TutorialStepWithID({required this.tutorialID, this.loadFromRepository});

  TutorialStepWithID setLoadingFunction({required TutorialKeyRepository tutorialKeyRepository});
}

abstract class TutorialStepWithWaiting extends TutorialStepWithID {
  final Duration timeout;
  final TutorialStep? replayStep;
  final void Function(TutorialBloc?) onFinished;

  TutorialStepWithWaiting(
      {required super.tutorialID,
      super.loadFromRepository,
      Duration? duration,
      this.replayStep,
      void Function(TutorialBloc?)? onFinished})
      : onFinished = onFinished ?? TutorialBloc.nextStep,
        timeout = duration ?? Constants.defaultConditionTimeout;

  Future<bool> performConditionCheck();

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
  WidgetHighlightTutorialStep setLoadingFunction({required TutorialKeyRepository tutorialKeyRepository}) {
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
  WaitForContextTutorialStep setLoadingFunction({required TutorialKeyRepository tutorialKeyRepository}) {
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
  TutorialStepWithID setLoadingFunction({required TutorialKeyRepository tutorialKeyRepository}) {
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
  TutorialStepWithID setLoadingFunction({required TutorialKeyRepository tutorialKeyRepository}) {
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
