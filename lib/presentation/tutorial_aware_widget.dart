import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tutorial_system/tutorial_system.dart';

/// A widget that automatically registers its key and context with the [TutorialRepository].
///
/// This widget is used to wrap other widgets that need to be referenced in tutorials.
/// It simplifies the process of registering keys and contexts for tutorial steps.
///
/// The [TutorialAwareWidget] will register:
/// - A [GlobalKey] for one or more [TutorialID]s specified in [tutorialKeyIDs].
/// - A [BuildContext] for one or more [TutorialID]s specified in [tutorialContextIDs].
///
/// If you want to use a previously created [globalKey], you can hand it to the globalKey parameter, but do not use
/// it in the key argument of the child widget, because this will throw an error (because then multiple widgets will
/// be using the same key).
///
/// Example usage:
/// ```dart
/// TutorialAwareWidget(
///   tutorialKeyIDs: [ExampleTutorialID.floatingButtonKey],
///   child: FloatingActionButton(
///     onPressed: _incrementCounter,
///     tooltip: 'Increment',
///     child: const Icon(Icons.add),
///   ),
/// )
/// ```
class TutorialAwareWidget extends StatelessWidget {
  /// The list of [TutorialID]s to register the widget's [GlobalKey] with.
  final List<TutorialID>? tutorialKeyIDs;

  /// The list of [TutorialID]s to register the widget's [BuildContext] with.
  final List<TutorialID>? tutorialContextIDs;

  /// The child widget to be wrapped by this [TutorialAwareWidget].
  final Widget child;

  /// Creates a [TutorialAwareWidget].
  ///
  /// The [child] parameter is required.
  /// If [globalKey] is not provided, a new [GlobalKey] will be created.
  /// [tutorialKeyIDs] and [tutorialContextIDs] are optional lists of [TutorialID]s
  /// to register the widget's key and context, respectively.
  TutorialAwareWidget({
    GlobalKey? globalKey,
    this.tutorialKeyIDs,
    this.tutorialContextIDs,
    required this.child,
  }) : super(key: globalKey ?? GlobalKey());

  @override
  Widget build(BuildContext context) {
    final globKey = key as GlobalKey;

    TutorialRepository tutorialRepository = context.read<TutorialRepository>();

    if (tutorialKeyIDs != null) {
      tutorialRepository.registerKeys(Map.fromEntries(tutorialKeyIDs!.map((keyID) => MapEntry(keyID, globKey))));
    }

    if (tutorialContextIDs != null) {
      tutorialRepository
          .registerContexts(Map.fromEntries(tutorialContextIDs!.map((contextID) => MapEntry(contextID, context))));
    }

    return child;
  }
}
