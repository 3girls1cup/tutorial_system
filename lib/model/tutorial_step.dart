import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tutorial_system/tutorial_system.dart';

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
  final Duration duration;
  final TutorialStep? replayStep;
  final void Function(TutorialBloc?) onFinished;

  TutorialStepWithWaiting({required super.tutorialID,
    super.loadFromRepository,
    Duration? duration,
    this.replayStep,
    void Function(TutorialBloc?)? onFinished})
      : onFinished = onFinished ?? TutorialBloc.nextStep,
        duration = duration ?? const Duration(seconds: 20);

  bool performConditionCheck();

  @override
  Future<void> execute(TutorialBloc? tutorialBloc) async {
    const int stepSize = 1;
    for (int second = 0; second < duration.inSeconds; second += stepSize) {
      await Future.delayed(const Duration(seconds: stepSize));
      if (performConditionCheck()) {
        onFinished(tutorialBloc);
        return;
      }
    }
    // Duration exceeded, trigger replay if set
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
  bool performConditionCheck() {
    BuildContext? buildContext = loadFromRepository?.call();
    if (buildContext == null) {
      return false;
    }
    return ModalRoute
        .of(buildContext)
        ?.isCurrent ?? false;
  }

  @override
  WaitForContextTutorialStep setLoadingFunction({required TutorialKeyRepository tutorialKeyRepository}) {
    return WaitForContextTutorialStep(
        tutorialID: tutorialID,
        loadFromRepository: () => tutorialKeyRepository.get(tutorialID),
        duration: duration,
        replayStep: replayStep,
        onFinished: onFinished);
  }
}

class WaitForConditionTutorialStep extends TutorialStepWithWaiting {
  WaitForConditionTutorialStep(
      {required super.tutorialID, super.loadFromRepository, super.duration, super.replayStep, super.onFinished});

  @override
  bool performConditionCheck() {
    bool Function()? conditionFunction = loadFromRepository?.call();
    if (conditionFunction != null && conditionFunction()) {
      return true;
    }
    return false;
  }

  @override
  TutorialStepWithID setLoadingFunction({required TutorialKeyRepository tutorialKeyRepository}) {
    return WaitForConditionTutorialStep(
        tutorialID: tutorialID,
        loadFromRepository: () => tutorialKeyRepository.get(tutorialID),
        duration: duration,
        replayStep: replayStep,
        onFinished: onFinished);
  }
}

class WaitForVisibleWidgetStep extends TutorialStepWithWaiting {
  WaitForVisibleWidgetStep(
      {required super.tutorialID, super.loadFromRepository, super.duration, super.replayStep, super.onFinished});

  @override
  bool performConditionCheck() {
    GlobalKey? widgetKey = loadFromRepository?.call();
    if (widgetKey != null && widgetKey.currentContext != null) {
      return true;
    }
    return false;
  }

  @override
  TutorialStepWithID setLoadingFunction({required TutorialKeyRepository tutorialKeyRepository}) {
    return WaitForVisibleWidgetStep(
        tutorialID: tutorialID,
        loadFromRepository: () => tutorialKeyRepository.get(tutorialID),
        duration: duration,
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
