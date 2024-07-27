import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tutorial_system/tutorial_system.dart';

class TutorialAwareWidget extends StatelessWidget {
  final List<TutorialID>? tutorialKeyIDs;
  final List<TutorialID>? tutorialContextIDs;

  final Widget child;

  TutorialAwareWidget({
    GlobalKey? globalKey,
    this.tutorialKeyIDs,
    this.tutorialContextIDs,
    required this.child,
  }) : super(key: globalKey ?? GlobalKey());

  @override
  Widget build(BuildContext context) {
    final globKey = key as GlobalKey;

    TutorialKeyRepository tutorialKeyRepository = context.read<TutorialKeyRepository>();

    if (tutorialKeyIDs != null) {
      tutorialKeyRepository.registerKeys(Map.fromEntries(tutorialKeyIDs!.map((keyID) => MapEntry(keyID, globKey))));
    }

    if (tutorialContextIDs != null) {
      tutorialKeyRepository
          .registerContexts(Map.fromEntries(tutorialContextIDs!.map((contextID) => MapEntry(contextID, context))));
    }

    return child;
  }
}
