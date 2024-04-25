import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tutorial_system/src/util/size_config.dart';
import 'package:tutorial_system/tutorial_system.dart';

class TutorialHandler {
  final Tutorial tutorial;
  final TutorialKeyRepository _tutorialKeyRepository;
  final TutorialBloc _tutorialBloc;

  OverlayEntry? overlayEntry;

  final Offset overlayOffset = const Offset(5.0, 5.0);
  final double buttonWidth = 100;
  final double buttonHeight = 50;

  final TextStyle tutorialTextStyle = const TextStyle(fontSize: 14.0, color: Colors.red, fontWeight: FontWeight.bold);

  TutorialHandler(this.tutorial, this._tutorialKeyRepository) : _tutorialBloc = TutorialBloc(tutorial);

  void startTutorial() {
    _tutorialBloc.stream.listen((event) {
      if (event.currentTutorialStep != null) {
        switch (event.currentTutorialStep.runtimeType) {
          case WidgetHighlightTutorialStep:
            createHighlightOverlay(
                tutorialStep: event.currentTutorialStep as WidgetHighlightTutorialStep, borderColor: Colors.red);
          case PlainTextTutorialStep:
            createTextOverlay(tutorialStep: event.currentTutorialStep as PlainTextTutorialStep);
        }
      } else {
        removeOverlayEntry();
      }
    }, onDone: () => dispose(), onError: (_) => dispose());
    _tutorialBloc.add(const TutorialStartEvent());
  }

  void nextTutorialElement() {
    removeOverlayEntry();
    _tutorialBloc.add(const TutorialNextStepEvent());
  }

  void dispose() {
    removeOverlayEntry();
  }

  (BuildContext, NavigatorState)? getCurrentContextAndState() {
    if (_tutorialKeyRepository.globalNavigatorKey.currentContext == null) {
      if (kDebugMode) {
        print("TUTORIAL SYSTEM WARNING: Could not find current context to create overlay!");
      }
      return null;
    }
    if (_tutorialKeyRepository.globalNavigatorKey.currentState == null) {
      if (kDebugMode) {
        print("TUTORIAL SYSTEM WARNING: Could not find current state to create overlay!");
      }
      return null;
    }
    BuildContext context = _tutorialKeyRepository.globalNavigatorKey.currentContext!;
    NavigatorState state = _tutorialKeyRepository.globalNavigatorKey.currentState!;
    return (context, state);
  }

  void createHighlightOverlay({required WidgetHighlightTutorialStep tutorialStep, required Color borderColor}) {
    (BuildContext, NavigatorState)? contextAndState = getCurrentContextAndState();
    if(contextAndState == null) {
      return;
    }
    BuildContext context = contextAndState.$1;
    NavigatorState state = contextAndState.$2;

    GlobalKey? widgetKey = tutorialStep.loadFromRepository?.call();
    if (widgetKey == null || widgetKey.currentContext == null) {
      return;
    }
    BuildContext currentContext = widgetKey.currentContext!;
    RenderBox widgetRenderBox = currentContext.findRenderObject() as RenderBox;
    Offset widgetPosition = widgetRenderBox.localToGlobal(Offset.zero);
    double widgetCenterX = widgetPosition.dx + widgetRenderBox.size.width / 2;

    // Pre-Render Text to get expected size
    final Size tutorialTextSize = (TextPainter(
            text: TextSpan(text: tutorialStep.tutorialText, style: tutorialTextStyle),
            maxLines: 1,
            //textScaler: MediaQuery.of(context).textScaler, TODO ?
            textDirection: TextDirection.ltr)
          ..layout())
        .size;

    // Next-Button
    double buttonPositionLeft = widgetCenterX - buttonWidth / 2;
    double buttonPositionTop = widgetPosition.dy + widgetRenderBox.size.height;

    // Clipping around widget
    double clippingLeftPosition = widgetPosition.dx - overlayOffset.dx;
    double clippingTopPosition = widgetPosition.dy - widgetRenderBox.size.height / 2 - overlayOffset.dy;
    double clippingWidth = widgetRenderBox.size.width + overlayOffset.dx * 2;
    double clippingHeight = widgetRenderBox.size.height * 1.5 + overlayOffset.dy * 2;

    // Text
    double textPositionLeft = widgetCenterX - tutorialTextSize.width / 1.75; // 1.75 looks better than 2
    double textPositionTop = clippingTopPosition - tutorialTextSize.height;

    overlayEntry = OverlayEntry(
      // Create a new OverlayEntry.
      builder: (BuildContext context) {
        // Align is used to position the highlight overlay
        // relative to the NavigationBar destination.
        return Stack(
          children: [
            ClipPath(
                clipper: ExclusionClipper(
                  Rect.fromLTWH(clippingLeftPosition, clippingTopPosition, clippingWidth, clippingHeight),
                ),
                child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 5.0,
                      sigmaY: 5.0,
                    ),
                    child: Container(
                      width: SizeConfig.screenWidth(context),
                      height: SizeConfig.screenHeight(context),
                      color: Colors.black.withOpacity(0.5),
                    ))),
            Positioned(
              left: textPositionLeft,
              top: textPositionTop,
              child: Container(
                  color: Colors.black,
                  child: DefaultTextStyle(style: tutorialTextStyle, child: Text(tutorialStep.tutorialText))),
            ),
            Positioned(
                left: buttonPositionLeft,
                top: buttonPositionTop,
                child: SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: ElevatedButton(
                        onPressed: nextTutorialElement,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                        child: Text(
                          "Next",
                          style: tutorialTextStyle,
                        ))))
          ],
        );
      },
    );
    state.overlay?.insert(overlayEntry!);
  }

  void createTextOverlay({required PlainTextTutorialStep tutorialStep}) {
    (BuildContext, NavigatorState)? contextAndState = getCurrentContextAndState();
    if(contextAndState == null) {
      return;
    }
    BuildContext context = contextAndState.$1;
    NavigatorState state = contextAndState.$2;

    // Pre-Render Text to get expected size
    final Size tutorialTextSize = (TextPainter(
            text: TextSpan(text: tutorialStep.tutorialText, style: tutorialTextStyle),
            maxLines: 1,
            textScaler: MediaQuery.of(context).textScaler,
            textDirection: TextDirection.ltr)
          ..layout())
        .size;

    var overlayPositionLeft = SizeConfig.screenWidth(context) / 2 - tutorialTextSize.width / 1.75;
    var overlayPositionTop = SizeConfig.screenHeight(context) / 2 + tutorialTextSize.height;

    var textPositionLeft = overlayPositionLeft;
    var textPositionTop = overlayPositionTop + 50;
    var buttonPositionLeft = textPositionLeft + tutorialTextSize.width / 2 - buttonWidth / 2;
    var buttonPositionTop = textPositionTop + 50;

    overlayEntry = OverlayEntry(
      // Create a new OverlayEntry.
      builder: (BuildContext context) {
        // Align is used to position the highlight overlay
        // relative to the NavigationBar destination.
        return Stack(
          children: [
            ClipPath(
                clipper: ExclusionClipper(
                  Rect.fromLTWH(
                      overlayPositionLeft, overlayPositionTop, tutorialTextSize.width, tutorialTextSize.height + 100),
                ),
                child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 5.0,
                      sigmaY: 5.0,
                    ),
                    child: Container(
                      width: SizeConfig.screenWidth(context),
                      height: SizeConfig.screenHeight(context),
                      color: Colors.black.withOpacity(0.5),
                    ))),
            Positioned(
              left: textPositionLeft,
              top: textPositionTop,
              child: Container(
                  color: Colors.black,
                  child: DefaultTextStyle(style: tutorialTextStyle, child: Text(tutorialStep.tutorialText))),
            ),
            Positioned(
                left: buttonPositionLeft,
                top: buttonPositionTop,
                child: SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: ElevatedButton(
                        onPressed: nextTutorialElement,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                        child: Text(
                          "Next",
                          style: tutorialTextStyle,
                        ))))
          ],
        );
      },
    );
    state.overlay?.insert(overlayEntry!);
  }

  void removeOverlayEntry() {
    overlayEntry?.remove();
    overlayEntry?.dispose();
    overlayEntry = null;
  }
}

class ExclusionClipper extends CustomClipper<Path> {
  final Rect exclusionRect;

  ExclusionClipper(this.exclusionRect);

  @override
  Path getClip(Size size) {
    // Path for the entire screen
    Path outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Path for the exclusion area
    Path exclusionPath = Path()..addRect(exclusionRect);

    // Combining the paths to exclude the rectangle area
    return Path.combine(PathOperation.difference, outerPath, exclusionPath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
