# Tutorial System Documentation

This document describes the various ways in which to leverage the power of the tutorial_system package.

## Overall concept

The `tutorial_system` is designed to create tutorials *declaratively*, which comes with the huge advantage of being
able to separate tutorial logic from the rest of the production code entirely.

For this to work, you have to declare a list of `TutorialStep` objects, each with a unique `TutorialID`. This tutorial
id is later used to find the associated widget key/condition/context for the tutorial step to be actually executed.
The key/condition/context(s) must be stored in a `TutorialRepository` (using bloc repository provider). 
This can be done in various ways that vary in how much manual coding must be done and how much tutorial logic separation
is pursued ([see the section below](#creating-tutorial-logic)).
Finally, the tutorial can be started by using a `TutorialRunner` and `TutorialHandler`, or simply creating a 
`TutorialStartButton`.

## Creating tutorials

To create a tutorial, you must at least create two classes:
1. An `Enum` that extends `TutorialID`:
```dart
enum ExampleTutorialID implements TutorialID {
  // Keys
  floatingButtonKey,
  // Conditions
  counterWasIncreased,
  // Contexts
} 
```

2. Your tutorial class that extends or implements `Tutorial`:
```dart
class ExampleTutorial extends Tutorial {
  @override
  String getName() => "Example tutorial";

  @override
  List<TutorialStep> get tutorialSteps => [
    WidgetHighlightTutorialStep(
        tutorialText: "Click here to increase the counter", tutorialID: ExampleTutorialID.floatingButtonKey),
    WaitForConditionTutorialStep(tutorialID: ExampleTutorialID.counterWasIncreased),
    PlainTextTutorialStep(tutorialText: "You successfully pressed the button! Tutorial finished..")
  ];
} 
```

## Creating tutorial logic

After declaring the individual tutorial steps, you need to register the required key/condition/context(s) for your
tutorial in a `TutorialRepository`. To do this, you have a few different options, each with individual pros and cons,
that are detailed in this section.

### Registering in widget states

+ Simple
- Not possible to declare all logic in the same place

This is a simple approach that just registers your components in the `initState` function of the widget that holds
the required components.

```dart
 @override
void initState() {
  super.initState();
  final TutorialRepository tutorialRepository = context.read<TutorialRepository>();
  // Register key
  tutorialRepository.registerKey(ExampleTutorialID.floatingButtonKey, _floatingActionButtonKey);
  // Register condition
  tutorialRepository.registerCondition(ExampleTutorialID.counterWasIncreased, (timeout) {
    return TutorialStepWithWaiting.conditionWithTimeout(timeout, () => _counter > 0);
  });
}
```

If the key of your widget (in our example `_floatingActionButtonKey`) is only required for the tutorial, you can
use a `TutorialAwareWidget` as wrapper around your widget, that does the registration automatically for you:

```dart
floatingActionButton: TutorialAwareWidget(
        // If you have multiple tutorials that use the same widget key, you can define them here all at once
        tutorialKeyIDs: const [ExampleTutorialID.floatingButtonKey],
        child: FloatingActionButton(
          // Note: No key parameter must be provided here!
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
```

### Registering in extensions on widget states

+ Better separation of tutorial code and production code
- Small overhead
- Not possible to declare all logic in the same place

This approach is very similar to registering in the `initState` method, but uses an extension on the state of the widget
to do the actual registering. By naming the extensions in a clever way, all tutorial-related registration code can
be found and refactored easily, if necessary.

Example extension code:

```dart
extension _ExampleTutorialExt on _MyHomePageState {
  void registerExampleTutorial() {
    final tutorialRepository tutorialRepository = context.read<tutorialRepository>();
    tutorialRepository.registerKey(ExampleTutorialID.floatingButtonKey, _floatingActionButtonKey);
    tutorialRepository.registerCondition(ExampleTutorialID.counterWasIncreased, (timeout) {
      return TutorialStepWithWaiting.conditionWithTimeout(timeout, () => _counter > 0);
    });
  }
}
```

Call the extension method in the `initState` function of `_MyHomePageState`:
```dart
@override
void initState() {
  super.initState();
  registerExampleTutorial();
} 
```

### Using registrationFunction of the Tutorial class

+ Possible to declare complete logic of your tutorial in one file
+ Only very little code overhead in your production classes
- Slightly more complicated
- May require some boilerplate code

In order to be able to declare all tutorial logic in one place, we need to have access to all required states that hold
the keys and conditions. For this, we can use a `registrationFunction` in our `Tutorial`, that is called dynamically
from the `TutorialRepository`:

```dart
class ExampleTutorial extends Tutorial {
  @override
  String getName() => "Example tutorial";

  @override
  void registrationFunction(TutorialRepository tutorialRepository, caller, {State<StatefulWidget>? state}) {
    switch(caller) {
      case _MyHomePageState myHomePageState: {
        tutorialRepository.registerKey(ExampleTutorialID.floatingButtonKey, myHomePageState._floatingActionButtonKey);
        tutorialRepository.registerCondition(ExampleTutorialID.counterWasIncreased, (timeout) {
          return TutorialStepWithWaiting.conditionWithTimeout(timeout, () => myHomePageState._counter > 0);
        });
        break;
      }
      // Add other states or widget cases here as your tutorial grows
    }
  }

  @override
  List<TutorialStep> get tutorialSteps => [
        WidgetHighlightTutorialStep(
            tutorialText: "Click here to increase the counter", tutorialID: ExampleTutorialID.floatingButtonKey),
        WaitForConditionTutorialStep(tutorialID: ExampleTutorialID.counterWasIncreased),
        PlainTextTutorialStep(tutorialText: "You successfully pressed the button! Tutorial finished..")
      ];
}
```

Call the registration function via the `TutorialRegistrationMixin`:

```dart
class _MyHomePageState extends State<MyHomePage> with TutorialRegistrationMixin {
  final GlobalKey _floatingActionButtonKey = GlobalKey();
  final ExampleTutorial exampleTutorial = ExampleTutorial();

  int _counter = 0;

  @override
  void initState() {
    super.initState();
    // Set list of tutorial classes as types
    registerForTutorials([ExampleTutorial]);
  }
// Rest of the class
}
```

Now we have our whole tutorial logic in one place, with only one extra line of code in our production class!

Our approach only has one problem left at the moment:

Usually, states are private in flutter, indicated by the prefix `_`. So we cannot access them in our tutorial
class (unless we declare them in the same file, which is not desirable). 
To circumvent this, we have two options:

1. **Make the state public**. We can always change `_MyHomePageState` to `MyHomePageState`. 
This, of course, weakens `encapsulation`, but does not require boilerplate code. If you can make somewhat sure that
your state is only used in the context of the tutorial, this can be an easy solution.

2. **Use the StatefulWidget instead of its state**. This keeps encapsulation intact, however we need some boilerplate
code in our widget classes:

```dart
extension TutorialExtMyHomePage on MyHomePage {
  GlobalKey? getFloatingButtonKey(dynamic state) {
    if (state is _MyHomePageState) {
      return state._floatingActionButtonKey;
    }
    return null;
  }

  int? getCounterValue(dynamic state) {
    if (state is _MyHomePageState) {
      return state._counter;
    }
    return null;
  }
}
```

Our `registrationFunction` now needs to look like this:

```dart
  @override
void registrationFunction(TutorialRepository tutorialRepository, caller, {State<StatefulWidget>? state}) {
  switch (caller) {
    case MyHomePage myHomePage:
      {
        tutorialRepository.registerKey(ExampleTutorialID.floatingButtonKey, myHomePage.getFloatingButtonKey(state));
        tutorialRepository.registerCondition(ExampleTutorialID.counterWasIncreased, (timeout) {
          return TutorialStepWithWaiting.conditionWithTimeout(
              timeout, () => (myHomePage.getCounterValue(state) ?? 0) > 0);
        });
        break;
      }
  }
}
```

