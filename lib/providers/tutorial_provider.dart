import 'package:equatable/equatable.dart';
import 'package:tutorial_system/tutorial_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../src/util/constants.dart';

class TutorialState extends Equatable {
  final int? _currentTutorialIndex;
  final TutorialStep? currentTutorialStep;
  final TutorialStatus status;

  const TutorialState(this.currentTutorialStep, this.status)
      : _currentTutorialIndex = null;

  const TutorialState.idle()
      : _currentTutorialIndex = null,
        currentTutorialStep = null,
        status = TutorialStatus.idle;

  const TutorialState.running(
      this._currentTutorialIndex, this.currentTutorialStep)
      : status = TutorialStatus.running;

  @override
  List<Object?> get props => [currentTutorialStep, status];
}

enum TutorialStatus { idle, running }

class TutorialNotifier extends StateNotifier<TutorialState> {
  final TutorialRunner _tutorial;

  TutorialNotifier(this._tutorial) : super(const TutorialState.idle());

  void startTutorial() {
    _progressTutorial();
  }

  void nextStep() {
    _progressTutorial();
  }

  Future<void> replayStep(TutorialStep? replayStep) async {
    TutorialStep? currentStep = state.currentTutorialStep;

    if (replayStep != null) {
      if (currentStep != null) {
        _tutorial.registerStepForReplay(currentStep);
      }
      replayStep.execute(this);
      state = TutorialState.running(state._currentTutorialIndex, replayStep);
    }
  }

  void previousStep() {
    (TutorialStep?, int?) previous =
        _tutorial.getPreviousStep(state._currentTutorialIndex);
    TutorialStep? previousStep = previous.$1;
    int? previousIndex = previous.$2;

    if (previousStep != null) {
      previousStep.execute(this);
      state = TutorialState.running(previousIndex, previousStep);
    }
  }

  void _progressTutorial() {
    (TutorialStep?, int?) next =
        _tutorial.getNextStep(state._currentTutorialIndex);
    TutorialStep? nextStep = next.$1;
    int? nextIndex = next.$2;

    if (nextStep != null) {
      // await Future.delayed(Constants.waitBetweenSteps);
      nextStep.execute(this);
      state = TutorialState.running(nextIndex, nextStep);
    } else {
      state = const TutorialState.idle();
    }
  }
}

final tutorialProvider = StateNotifierProvider.family<TutorialNotifier,
    TutorialState, TutorialRunner>(
  (ref, runner) {
    return TutorialNotifier(runner);
  },
);
