Interactive tutorials for flutter apps, without messing up your code.

## Features

Using this package enables you to:

* 📜 Separate your tutorial logic and code from the rest of your application
* 🧙‍♀️ Create complex interactive tutorials, that go beyond highlighting important widgets of your app
    (although that is possible as well, of course!)
* ⏫ Add more than one tutorial to your app

## Usage

Find extensive information on how to use this package in the [example](example/counter_app_tutorial_example.dart) and 
[documentation](doc/tutorial_system_doc.md).

These are the basic steps to get you started:

1. Create the enum that provides your tutorial IDs:
```dart
enum ExampleTutorialID implements TutorialID {
  // Keys
  floatingButtonKey,
  // Conditions
  counterWasIncreased,
  // Contexts
}
```

2. Create your tutorial class that extends or implements `TutorialContainer` and define the tutorial steps:
```dart
class ExampleTutorial extends TutorialContainer {

  @override
  String getName() => "Example tutorial";

  @override
  List<TutorialStep> get tutorialSteps => [
        WidgetHighlightTutorialStep(
            tutorialText: "Click here to increase the counter",
            tutorialID: ExampleTutorialID.floatingButtonKey),
        WaitForConditionTutorialStep(tutorialID: ExampleTutorialID.counterWasIncreased),
        PlainTextTutorialStep(tutorialText: "You successfully pressed the button! Tutorial finished..")
      ];
}
```

3. Create a tutorial key repository and add a global navigator key:
```dart
class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> _globalNavigatorKey = GlobalKey<NavigatorState>();

  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
        create: (_) => tutorialRepository(_globalNavigatorKey),
    child: MaterialApp(
    navigatorKey: _globalNavigatorKey,
    title: 'Flutter Demo',
    theme: ThemeData(...))); 
```

4. In the `MyHomePage` widget, add a floatingActionButton key:
```dart
final GlobalKey _floatingActionButtonKey = GlobalKey();

(...)

floatingActionButton: FloatingActionButton(
        key: _floatingActionButtonKey,
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
),
```

5. Create an extension for the `_MyHomePageState` to separate the tutorial registration: 
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

6. Call the extension method in the `initState` function of `_MyHomePageState`:
```dart
@override
void initState() {
  super.initState();
  registerExampleTutorial();
} 
```

7. Add a `TutorialStartButton` in the build method to start the tutorial:
```dart
final ExampleTutorial exampleTutorial = ExampleTutorial();

(...)

TutorialStartButton(
  buttonBuilder: (onPressed) =>
  ElevatedButton(onPressed: onPressed, child: Text("Start Tutorial: ${exampleTutorial.getName()}")),
  tutorial: exampleTutorial,
) 
```
