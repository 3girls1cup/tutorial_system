import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_system/src/util/size_config.dart';
import 'package:tutorial_system/tutorial_system.dart';

class TutorialHandler {
  final TutorialRepository _tutorialRepository;
  final TutorialNotifier tutorialNotifier;
  final WidgetRef ref;

  OverlayEntry? overlayEntry;

  final Offset overlayOffset = const Offset(5.0, 5.0);
  final double buttonWidth = 100;
  final double buttonHeight = 50;

  final TextStyle tutorialTextStyle = const TextStyle(
      fontSize: 14.0, color: Colors.white, fontWeight: FontWeight.bold);

  TutorialHandler(
      TutorialRunner tutorialRunner, this._tutorialRepository, this.ref)
      : tutorialNotifier = ref.read(tutorialProvider(tutorialRunner).notifier);

  void startTutorial() {
    tutorialNotifier.stream.listen((event) {
      removeOverlayEntry();
      if (event.currentTutorialStep != null) {
        createOverlay(event.currentTutorialStep!);
      }
    }, onDone: () => dispose(), onError: (_) => dispose());
    tutorialNotifier.startTutorial();
  }

  void nextTutorialElement() {
    removeOverlayEntry();
    tutorialNotifier.nextStep();
  }

  void dispose() {
    removeOverlayEntry();
  }

  (BuildContext, NavigatorState)? getCurrentContextAndState() {
    if (_tutorialRepository.globalNavigatorKey.currentContext == null) {
      if (kDebugMode) {
        print(
            "TUTORIAL SYSTEM WARNING: Could not find current context to create overlay!");
      }
      return null;
    }
    if (_tutorialRepository.globalNavigatorKey.currentState == null) {
      if (kDebugMode) {
        print(
            "TUTORIAL SYSTEM WARNING: Could not find current state to create overlay!");
      }
      return null;
    }
    BuildContext context =
        _tutorialRepository.globalNavigatorKey.currentContext!;
    NavigatorState state = _tutorialRepository.globalNavigatorKey.currentState!;
    return (context, state);
  }

  void createOverlay(TutorialStep tutorialStep) {
    (BuildContext, NavigatorState)? contextAndState =
        getCurrentContextAndState();
    if (contextAndState == null) return;

    BuildContext context = contextAndState.$1;
    NavigatorState state = contextAndState.$2;

    OverlayContent? content = switch (tutorialStep) {
      WidgetHighlightTutorialStep whtStep =>
        createHighlightOverlayContent(context, whtStep),
      WaitForConditionTutorialStep whwtStep =>
        createHighlightOverlayContent(context, whwtStep),
      PlainTextTutorialStep pttStep =>
        createTextOverlayContent(context, pttStep),
      _ => null
    };

    if (content != null) {
      overlayEntry = OverlayEntry(
        builder: (BuildContext context) =>
            buildOverlayContent(context, content),
      );

      state.overlay?.insert(overlayEntry!);
    }
  }

  Widget buildOverlayContent(BuildContext context, OverlayContent content,
      {Widget? nextButton}) {
    if (kIsWeb) {
      return _buildOverlayContentWeb(context, content);
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: ExclusionClipper(content.exclusionRect),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              width: SizeConfig.screenWidth(context),
              height: SizeConfig.screenHeight(context),
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
        // Texte ou autres éléments au-dessus
        _buildTutorialText(content),
        if (nextButton != null) _buildNextButton(content, child: nextButton),
      ],
    );
  }

  Widget _buildOverlayContentWeb(BuildContext context, OverlayContent content,
      {Widget? nextButton}) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: AbsorbPointer(
              child: Container(color: Colors.transparent),
            ),
          ),
          // Highlight border
          Positioned(
            left: content.exclusionRect.left,
            top: content.exclusionRect.top,
            width: content.exclusionRect.width,
            height: content.exclusionRect.height,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          _buildTutorialText(content),
          _buildNextButton(content, child: nextButton),
        ],
      ),
    );
  }

  Widget _buildTutorialText(OverlayContent content) {
    return Positioned(
      left: content.textPosition.dx,
      top: content.textPosition.dy,
      child: Container(
        color: Colors.black,
        child: DefaultTextStyle(
          style: tutorialTextStyle,
          child: Text(content.tutorialText),
        ),
      ),
    );
  }

  Widget _buildNextButton(OverlayContent content, {Widget? child}) {
    return Positioned(
      left: content.buttonPosition.dx,
      top: content.buttonPosition.dy,
      child: child ??
          SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: nextTutorialElement,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: Text("Next", style: tutorialTextStyle),
            ),
          ),
    );
  }

  OverlayContent? createHighlightOverlayContent(
      BuildContext context, TutorialStepWithID tutorialStep) {
    if (tutorialStep.tutorialText == null) {
      return null;
    }
    GlobalKey? widgetKey = tutorialStep.loadFromRepository?.call()?.key;
    if (widgetKey == null || widgetKey.currentContext == null) {
      throw Exception("Widget key not found for highlight overlay");
    }

    RenderBox widgetRenderBox =
        widgetKey.currentContext!.findRenderObject() as RenderBox;
    Offset widgetPosition = widgetRenderBox.localToGlobal(Offset.zero);
    double widgetCenterX = widgetPosition.dx + widgetRenderBox.size.width / 2;

    Size tutorialTextSize =
        _calculateTextSize(context, tutorialStep.tutorialText!);

    double clippingLeftPosition = widgetPosition.dx - overlayOffset.dx;
    double clippingTopPosition =
        widgetPosition.dy - widgetRenderBox.size.height / 2 - overlayOffset.dy;
    double clippingWidth = widgetRenderBox.size.width + overlayOffset.dx * 2;
    double clippingHeight =
        widgetRenderBox.size.height * 1.5 + overlayOffset.dy * 2;

    return OverlayContent(
      exclusionRect: Rect.fromLTWH(clippingLeftPosition, clippingTopPosition,
          clippingWidth, clippingHeight),
      textPosition: Offset(widgetCenterX - tutorialTextSize.width / 1.75,
          clippingTopPosition - tutorialTextSize.height),
      buttonPosition: Offset(widgetCenterX - buttonWidth / 2,
          widgetPosition.dy + widgetRenderBox.size.height),
      tutorialText: tutorialStep.tutorialText!,
    );
  }

  OverlayContent createTextOverlayContent(
      BuildContext context, PlainTextTutorialStep tutorialStep) {
    Size tutorialTextSize =
        _calculateTextSize(context, tutorialStep.tutorialText);

    double overlayPositionLeft =
        SizeConfig.screenWidth(context) / 2 - tutorialTextSize.width / 1.75;
    double overlayPositionTop =
        SizeConfig.screenHeight(context) / 2 + tutorialTextSize.height;

    return OverlayContent(
      exclusionRect: Rect.fromLTWH(overlayPositionLeft, overlayPositionTop,
          tutorialTextSize.width, tutorialTextSize.height + 100),
      textPosition: Offset(overlayPositionLeft, overlayPositionTop + 50),
      buttonPosition: Offset(
          overlayPositionLeft + tutorialTextSize.width / 2 - buttonWidth / 2,
          overlayPositionTop + 100),
      tutorialText: tutorialStep.tutorialText,
    );
  }

  Size _calculateTextSize(BuildContext context, String text) {
    return (TextPainter(
      text: TextSpan(text: text, style: tutorialTextStyle),
      maxLines: 1,
      textScaler: MediaQuery.of(context).textScaler,
      textDirection: TextDirection.ltr,
    )..layout())
        .size;
  }

  void removeOverlayEntry() {
    overlayEntry?.remove();
    overlayEntry?.dispose();
    overlayEntry = null;
  }
}

class OverlayContent {
  final Rect exclusionRect;
  final Offset textPosition;
  final Offset buttonPosition;
  final String tutorialText;

  OverlayContent({
    required this.exclusionRect,
    required this.textPosition,
    required this.buttonPosition,
    required this.tutorialText,
  });
}

class ExclusionClipper extends CustomClipper<Path> {
  final Rect exclusionRect;

  ExclusionClipper(this.exclusionRect);

  @override
  Path getClip(Size size) {
    // Path for the entire screen
    Path outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

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
