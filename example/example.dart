import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_system/tutorial_system.dart';

import 'stream.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorKey: navKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage>
    with TutorialRegistrationMixin {
  final GlobalKey _floatingActionButtonKey = GlobalKey();
  final GlobalKey _biteKey = GlobalKey();
  final ExampleTutorial exampleTutorial = ExampleTutorial();

  int _counter = 0;

  @override
  void initState() {
    super.initState();
    registerForTutorials([ExampleTutorial]);
    registerExampleTutorial();
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(streamMockProvider);
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TutorialStartButton(
              key: _biteKey,
              buttonBuilder: (onPressed) => ElevatedButton(
                  onPressed: onPressed,
                  child: Text("Start Tutorial: ${exampleTutorial.getName()}")),
              tutorial: exampleTutorial,
            ),
            const SizedBox(
              height: 20,
            ),
            // OutlinedButton(
            //   key: _floatingActionButtonKey,
            //   onPressed: _incrementCounter,
            //   child: const Icon(Icons.add),
            // )
          ],
        ),
      ),
// This trailing comma makes auto-formatting nicer for build methods.
      floatingActionButton: FloatingActionButton(
        key: _floatingActionButtonKey,
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

extension _ExampleTutorialExt on _MyHomePageState {
  void registerExampleTutorial() {
    streamCondition() {
      return ref.watch(streamMockProvider.future).asStream();
    }

    final overlayConfig = OverlayConfig(
      overlayColor: Colors.black.withOpacity(0.6),
      customWidget: const Icon(Icons.star,
          size: 50, color: Colors.yellow), // Widget personnalisé
      animate: true,
      breathingDuration: const Duration(milliseconds: 300),
      exclusionBorderRadius: 12.0, // Bordures arrondies
    );

    final TutorialRepository tutorialRepository =
        ref.read(tutorialRepositoryProvider);
    tutorialRepository.registerAllConfigs({
      ExampleTutorialID.floatingButtonKey: overlayConfig,
      ExampleTutorialID.bite: overlayConfig.copyWith(),
    });
  }
}

enum ExampleTutorialID implements TutorialID {
  // Keys
  floatingButtonKey,

  bite,
  // Conditions
  counterWasIncreased,
  // Contexts
  currentContext,
}

class ExampleTutorial extends Tutorial {
  @override
  String getName() => "Example tutorial";

  @override
  void registrationFunction(TutorialRepository tutorialRepository, caller,
      {ConsumerState<ConsumerStatefulWidget>? state}) {
    switch (caller) {
      case MyHomePage myHomePage:
        {
          // tutorialRepository.registerKey(ExampleTutorialID.floatingButtonKey,
          //     myHomePage.getFloatingButtonKey(state));
          // if (state != null) {
          //   print("state is not null");
          //   tutorialRepository.registerConditionStream(
          //     ExampleTutorialID.floatingButtonKey,
          //     () => state.ref.watch(streamMockProvider.future).asStream(),
          //   );
          // } else {
          //   print("state is null");
          // }
          // tutorialRepository.registerFutureCondition(
          //     ExampleTutorialID.floatingButtonKey, (timeout) {
          //   return TutorialStepWithWaiting.conditionWithTimeout(
          //       timeout, () => (myHomePage.getCounterValue(state) ?? 0) > 0);
          // });
          break;
        }
    }
  }

  @override
  List<TutorialStep> get tutorialSteps => [
        WaitForConditionTutorialStep(
            tutorialID: ExampleTutorialID.floatingButtonKey),
        WaitForConditionTutorialStep(tutorialID: ExampleTutorialID.bite),
        PlainTextTutorialStep(
            tutorialText:
                "You successfully pressed the button! Tutorial finished..")
      ];
}

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
