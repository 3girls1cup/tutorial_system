import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/tutorial_repository.dart';

mixin TutorialRegistrationMixin<T extends StatefulWidget> on State<T> {
  void registerForTutorials(List<Type> tutorials) {
    TutorialRepository tutorialRepository = context.read<TutorialRepository>();
    for (Type tutorial in tutorials) {
      tutorialRepository.callRegistrationFunction(tutorialType: tutorial, caller: widget, state: this);
      tutorialRepository.callRegistrationFunction(tutorialType: tutorial, caller: this, state: this);
    }
  }
}
