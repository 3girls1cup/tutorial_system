import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_system/src/util/size_config.dart';
import 'package:tutorial_system/tutorial_system.dart';

class TutorialHandler {
  final TutorialRepository _tutorialRepository;
  final TutorialNotifier tutorialNotifier;

  OverlayEntry? overlayEntry;

  final Offset overlayOffset = const Offset(5.0, 5.0);
  final double buttonWidth = 100;
  final double buttonHeight = 50;

  final TextStyle tutorialTextStyle = const TextStyle(
      fontSize: 14.0, color: Colors.white, fontWeight: FontWeight.bold);

  TutorialHandler(
      TutorialRunner tutorialRunner, this._tutorialRepository, dynamic ref)
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

  Widget buildFullOverlayContent(
      BuildContext context, OverlayContent content, OverlayConfig config) {
    return GestureDetector(
      onTap: config.nextOnTap ? nextTutorialElement : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              width: SizeConfig.screenWidth(context),
              height: SizeConfig.screenHeight(context),
              color: config.overlayColor,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (config.title != null)
                DefaultTextStyle(
                  style: config.titleStyle ??
                      const TextStyle(fontSize: 18, color: Colors.white),
                  child: Text(config.title!),
                ),
              if (config.customWidget != null) config.customWidget!
            ],
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
          _buildNextButton(content, child: config.nextButton),
        ],
      ),
    );
  }

  Widget buildOverlayContent(
      BuildContext context, OverlayContent content, OverlayConfig config) {
    if (kIsWeb) {
      //TODO : Web will not work very well probably
    }

    if (content.exclusionRects == null) {
      return buildFullOverlayContent(context, content, config);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (config.animateBreathing == true)
          AnimatedExclusionZone(
            exclusionRects: content.exclusionRects!,
            borderRadius: content.exclusionBorderRadius,
            breathingDuration: config.breathingDuration,
            breathingScale: config.breathingScale,
            overlayColor: config.overlayColor,
            round: config.rounded,
          )
        else
          ClipPath(
            clipper: ExclusionClipper(
              content.exclusionRects!,
              content.exclusionBorderRadius,
              config.rounded,
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
      exclusionRects: null, // No exclusion rect for full-screen overlay
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

    if (config.widgetKeys.isEmpty) {
      return createFullScreenOverlayContent(context, tutorialStep);
    }

    // Obtenir toutes les positions et tailles des widgets
    List<RenderBox> widgetRenderBoxes = config.widgetKeys
        .map((key) => key.currentContext!.findRenderObject() as RenderBox)
        .toList();

    List<Rect> exclusionRects = widgetRenderBoxes.map((renderBox) {
      Offset widgetPosition = renderBox.localToGlobal(Offset.zero);
      return Rect.fromLTWH(
        widgetPosition.dx - overlayOffset.dx,
        widgetPosition.dy - overlayOffset.dy,
        renderBox.size.width + overlayOffset.dx * 2,
        renderBox.size.height + overlayOffset.dy * 2,
      );
    }).toList();

    // Calcul du premier widget pour positionner le texte et d'autres éléments
    RenderBox firstRenderBox = widgetRenderBoxes.first;
    Offset widgetPosition = firstRenderBox.localToGlobal(Offset.zero);
    double widgetCenterX = widgetPosition.dx + firstRenderBox.size.width / 2;

    // Calcul des tailles de texte pour titre et description
    Size tutorialTitleTextSize = config.title != null
        ? _calculateTextSize(context, config.title!)
        : Size.zero;
    Size tutorialDescriptionTextSize = config.description != null
        ? _calculateTextSize(context, config.description!)
        : Size.zero;

    return OverlayContent(
      exclusionRects: exclusionRects, // Liste des zones d'exclusion
      titlePosition: Offset(
        widgetCenterX - tutorialTitleTextSize.width / 2,
        widgetPosition.dy - tutorialTitleTextSize.height - overlayOffset.dy,
      ),
      descriptionPosition: Offset(
        widgetCenterX - tutorialDescriptionTextSize.width / 2,
        widgetPosition.dy + firstRenderBox.size.height + overlayOffset.dy,
      ),
      customWidgetPosition: Offset(
        widgetCenterX,
        widgetPosition.dy + firstRenderBox.size.height / 2,
      ),
      buttonPosition: Offset(
        widgetCenterX - buttonWidth / 2,
        widgetPosition.dy + firstRenderBox.size.height + overlayOffset.dy * 2,
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
  final List<Rect>? exclusionRects;
  final Offset titlePosition;
  final Offset descriptionPosition;
  final Offset customWidgetPosition;
  final Offset buttonPosition;
  final double exclusionBorderRadius;

  OverlayContent({
    required this.exclusionRects,
    required this.titlePosition,
    required this.descriptionPosition,
    required this.customWidgetPosition,
    required this.buttonPosition,
    required this.exclusionBorderRadius,
  });
}
