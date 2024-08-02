import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/tutorial_repository.dart';

mixin TutorialRegistrationMixin<T extends StatefulWidget> on State<T> {

  void registerForTutorials(List<Type> tutorials) {
    TutorialRepository tutorialKeyRepository = context.read<TutorialRepository>();
    for(Type tutorial in tutorials) {
      tutorialKeyRepository.callRegistrationFunction(tutorialType: tutorial, caller: widget, state: this);
      tutorialKeyRepository.callRegistrationFunction(tutorialType: tutorial, caller: this, state: this);
    }
  }
}