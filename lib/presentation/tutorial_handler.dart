import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_system/presentation/animated_exclusion_zone.dart';
import 'package:tutorial_system/presentation/exclusion_clipper.dart';
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
      TutorialStepWithID whtStep =>
        createHighlightOverlayContent(context, whtStep),
      _ => null
    };

    if (content != null) {
      OverlayConfig? config = (tutorialStep as TutorialStepWithID)
          .loadFromRepository
          ?.call()
          ?.overlayConfig;
      if (config == null) {
        return;
      }
      overlayEntry = OverlayEntry(
        builder: (BuildContext context) =>
            buildOverlayContent(context, content, config),
      );

      state.overlay?.insert(overlayEntry!);
    }
  }

  Widget buildOverlayContent(
      BuildContext context, OverlayContent content, OverlayConfig config) {
    if (kIsWeb) {
      //TODO : Web will not work very well probably
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (content.exclusionRect == null)
          GestureDetector(
            onTap: config.nextOnTap ? () => nextTutorialElement : null,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: config.overlayColor,
            ),
          )
        else if (config.animateBreathing == true)
          AnimatedExclusionZone(
            exclusionRect: content.exclusionRect!,
            borderRadius: content.exclusionBorderRadius,
            breathingDuration: config.breathingDuration,
            breathingScale: config.breathingScale,
            overlayColor: config.overlayColor,
          )
        else
          ClipPath(
            clipper: ExclusionClipper(
              content.exclusionRect!,
              content.exclusionBorderRadius,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                width: SizeConfig.screenWidth(context),
                height: SizeConfig.screenHeight(context),
                color: config.overlayColor,
              ),
            ),
          ),
        if (config.customWidget != null)
          (config.customWidget is Positioned)
              ? config.customWidget!
              : Positioned(
                  left: content.customWidgetPosition.dx +
                      config.customWidgetOffset.dx,
                  top: content.customWidgetPosition.dy +
                      config.customWidgetOffset.dy,
                  child: config.customWidget!,
                ),
        // Texte du tutoriel
        if (config.title != null)
          Positioned(
            left: content.titlePosition.dx +
                (config.titleOffset.dx), // Décalage personnalisé
            top: content.titlePosition.dy +
                (config.titleOffset.dy), // Décalage personnalisé
            child: DefaultTextStyle(
              style: config.titleStyle ??
                  const TextStyle(fontSize: 18, color: Colors.white),
              child: Text(config.title!),
            ),
          ),
        if (config.description != null)
          Positioned(
            left: content.descriptionPosition.dx +
                (config.descriptionOffset.dx), // Décalage personnalisé
            top: content.descriptionPosition.dy +
                (config.descriptionOffset.dy), // Décalage personnalisé
            child: DefaultTextStyle(
              style: config.descriptionStyle ??
                  const TextStyle(fontSize: 14, color: Colors.white),
              child: Text(config.description!),
            ),
          ),
        if (config.nextButton != null)
          _buildNextButton(content, child: config.nextButton),
      ],
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

  OverlayContent? createFullScreenOverlayContent(
      BuildContext context, TutorialStepWithID tutorialStep) {
    Size screen = MediaQuery.of(context).size;

    OverlayConfig? config =
        tutorialStep.loadFromRepository?.call()?.overlayConfig;

    if (config == null) {
      return null;
    }

    // Calculate the centered positions for title, description, and custom widget
    Size tutorialTitleTextSize = config.title != null
        ? _calculateTextSize(context, config.title!)
        : Size.zero;
    Size tutorialDescriptionTextSize = config.description != null
        ? _calculateTextSize(context, config.description!)
        : Size.zero;

    Offset centerTitlePosition = Offset(
      (screen.width - tutorialTitleTextSize.width) / 2,
      (screen.height / 2) - tutorialTitleTextSize.height - 20, // Above center
    );

    Offset centerDescriptionPosition = Offset(
      (screen.width - tutorialDescriptionTextSize.width) / 2,
      (screen.height / 2) + 20, // Below center
    );

    Offset centerCustomWidgetPosition = Offset(
      screen.width / 2,
      screen.height / 2,
    );

    Offset centerButtonPosition = Offset(
      (screen.width - buttonWidth) / 2,
      (screen.height / 2) + 60, // Below description
    );

    return OverlayContent(
      exclusionRect: null, // No exclusion rect for full-screen overlay
      titlePosition: centerTitlePosition,
      descriptionPosition: centerDescriptionPosition,
      customWidgetPosition: centerCustomWidgetPosition,
      buttonPosition: centerButtonPosition,
      exclusionBorderRadius: 0, // No border radius needed
    );
  }

  OverlayContent? createHighlightOverlayContent(
    BuildContext context,
    TutorialStepWithID tutorialStep,
  ) {
    OverlayConfig? config =
        tutorialStep.loadFromRepository?.call()?.overlayConfig;

    if (config == null) {
      return null;
    }

    if (config.widgetKey == null) {
      return createFullScreenOverlayContent(context, tutorialStep);
    }

    RenderBox widgetRenderBox =
        config.widgetKey!.currentContext!.findRenderObject() as RenderBox;
    Offset widgetPosition = widgetRenderBox.localToGlobal(Offset.zero);
    double widgetCenterX = widgetPosition.dx + widgetRenderBox.size.width / 2;
    Size tutorialTitleTextSize = Size.zero;
    Size tutorialDescriptionTextSize = Size.zero;
    if (config.title != null) {
      tutorialTitleTextSize = _calculateTextSize(context, config.title!);
    }

    if (config.description != null) {
      tutorialDescriptionTextSize =
          _calculateTextSize(context, config.description!);
    }

    double clippingLeftPosition = widgetPosition.dx - overlayOffset.dx;
    double clippingTopPosition = widgetPosition.dy - overlayOffset.dy;
    double clippingWidth = widgetRenderBox.size.width + overlayOffset.dx * 2;
    double clippingHeight = widgetRenderBox.size.height + overlayOffset.dy * 2;

    return OverlayContent(
      exclusionRect: Rect.fromLTWH(
        clippingLeftPosition,
        clippingTopPosition,
        clippingWidth,
        clippingHeight,
      ),
      titlePosition: Offset(
        widgetCenterX - tutorialTitleTextSize.width / 2,
        clippingTopPosition - tutorialTitleTextSize.height,
      ),
      descriptionPosition: Offset(
        widgetCenterX - tutorialDescriptionTextSize.width / 2,
        clippingTopPosition + clippingHeight,
      ),
      customWidgetPosition: Offset(
        widgetCenterX,
        clippingTopPosition,
      ),
      buttonPosition: Offset(
        widgetCenterX - buttonWidth / 2,
        widgetPosition.dy + widgetRenderBox.size.height,
      ),

      exclusionBorderRadius: config.exclusionBorderRadius, // Bordures arrondies
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
  final Rect? exclusionRect;
  final Offset titlePosition;
  final Offset descriptionPosition;
  final Offset customWidgetPosition;
  final Offset buttonPosition;
  final double exclusionBorderRadius;

  OverlayContent({
    required this.exclusionRect,
    required this.titlePosition,
    required this.descriptionPosition,
    required this.customWidgetPosition,
    required this.buttonPosition,
    required this.exclusionBorderRadius,
  });
}
