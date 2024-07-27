import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/tutorial_key_repository.dart';

mixin TutorialRegistrationMixin<T extends StatefulWidget> on State<T> {

  void registerForTutorials(List<Type> tutorials) {
    TutorialKeyRepository tutorialKeyRepository = context.read<TutorialKeyRepository>();
    for(Type tutorial in tutorials) {
      tutorialKeyRepository.callRegistrationFunction(tutorialType: tutorial, caller: widget, state: this);
    }
  }
}