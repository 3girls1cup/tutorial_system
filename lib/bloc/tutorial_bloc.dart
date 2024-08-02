import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tutorial_system/tutorial_system.dart';

import '../src/util/constants.dart';

abstract class TutorialEvent {
  const TutorialEvent();
}

class TutorialStartEvent extends TutorialEvent {
  const TutorialStartEvent();
}

class TutorialNextStepEvent extends TutorialEvent {
  const TutorialNextStepEvent();
}

class TutorialReplayStepEvent extends TutorialEvent {
  final TutorialStep? replayStep;

  const TutorialReplayStepEvent(this.replayStep);
}

class TutorialState extends Equatable {
  final int? _currentTutorialIndex;
  final TutorialStep? currentTutorialStep;
  final TutorialStatus status;

  const TutorialState(this.currentTutorialStep, this.status) : _currentTutorialIndex = null;

  const TutorialState.idle()
      : _currentTutorialIndex = null,
        currentTutorialStep = null,
        status = TutorialStatus.idle;

  const TutorialState.running(this._currentTutorialIndex, this.currentTutorialStep) : status = TutorialStatus.running;

  @override
  List<Object?> get props => [currentTutorialStep, status];
}

enum TutorialStatus { idle, running }

class TutorialBloc extends Bloc<TutorialEvent, TutorialState> {
  final TutorialRunner _tutorial;

  TutorialBloc(this._tutorial) : super(const TutorialState.idle()) {
    on<TutorialStartEvent>((event, emit) async {
      await progressTutorial(event, emit);
    });
    on<TutorialNextStepEvent>((event, emit) async {
      await progressTutorial(event, emit);
    });
    on<TutorialReplayStepEvent>((event, emit) async {
      TutorialStep? currentStep = state.currentTutorialStep;
      TutorialStep? replayStep = event.replayStep;

      if (replayStep != null) {
        if (currentStep != null) {
          _tutorial.registerStepForReplay(currentStep);
        }
        replayStep.execute(this);
        emit(TutorialState.running(state._currentTutorialIndex, replayStep));
      }
    });
  }

  Future<void> progressTutorial(var event, var emit) async {
    (TutorialStep?, int?) next = _tutorial.getNextStep(state._currentTutorialIndex);
    TutorialStep? nextStep = next.$1;
    int? nextIndex = next.$2;

    if (nextStep != null) {
      await Future.delayed(Constants.waitBetweenSteps);
      nextStep.execute(this);
      emit(TutorialState.running(nextIndex, nextStep));
    } else {
      emit(const TutorialState.idle());
    }
  }

  static void nextStep(TutorialBloc? tutorialBloc) {
    tutorialBloc?.add(const TutorialNextStepEvent());
  }

  static void triggerReplay(TutorialBloc? tutorialBloc, TutorialStep? replayStep) {
    tutorialBloc?.add(TutorialReplayStepEvent(replayStep));
  }
}
