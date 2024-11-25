import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tutorial_repository.dart';

mixin TutorialRegistrationMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  void registerForTutorials(List<Type> tutorials) {
    TutorialRepository tutorialRepository =
        ref.read(tutorialRepositoryProvider);
    for (Type tutorial in tutorials) {
      tutorialRepository.callRegistrationFunction(
          tutorialType: tutorial, caller: widget, state: this);
      tutorialRepository.callRegistrationFunction(
          tutorialType: tutorial, caller: this, state: this);
    }
  }
}
