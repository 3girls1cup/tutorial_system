import 'package:tutorial_system/tutorial_system.dart';

class TutorialRunner {
  final List<TutorialStep> tutorialSteps;

  final List<TutorialStep> _registeredStepsForReplay = [];

  TutorialRunner._internal(this.tutorialSteps);

  factory TutorialRunner(
      Tutorial tutorialContainer, TutorialRepository tutorialKeyRepository) {
    List<TutorialStep> tutorialSteps = tutorialContainer.tutorialSteps;
      List<TutorialStep> tutorialStepsWithLoadingFunction = [];

      for (TutorialStep tutorialStep in tutorialSteps) {
        if (tutorialStep is TutorialStepWithID) {
          tutorialStepsWithLoadingFunction.add(tutorialStep.setLoadingFunction(tutorialKeyRepository: tutorialKeyRepository));
          continue;
        }
        tutorialStepsWithLoadingFunction.add(tutorialStep);
      }
      return TutorialRunner._internal(tutorialStepsWithLoadingFunction);
  }

  (TutorialStep?, int?) getNextStep(int? previousIndex) {
    (TutorialStep?, int?) next = _nextStep(previousIndex);
    TutorialStep? nextStep = next.$1;
    int? nextIndex = next.$2;
    return (nextStep, nextIndex);
  }

  (TutorialStep?, int?) _nextStep(int? previousIndex) {
    if (_registeredStepsForReplay.isNotEmpty) {
      TutorialStep nextStep = _registeredStepsForReplay.first;
      _registeredStepsForReplay.clear();
      return (nextStep, previousIndex);
    }
    if (previousIndex == null) {
      return (tutorialSteps.first, 0);
    }
    int nextIndex = previousIndex + 1;
    if (nextIndex >= tutorialSteps.length) {
      return (null, null);
    }

    return (tutorialSteps[nextIndex], nextIndex);
  }

  void registerStepForReplay(TutorialStep stepToReplay) {
    // TODO: Currently only one stepToReplay allowed
    _registeredStepsForReplay.clear();
    _registeredStepsForReplay.add(stepToReplay);
  }
}
