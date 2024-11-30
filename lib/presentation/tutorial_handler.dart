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
              ...content.widgets,
            ],
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
            zones: content.exclusionRects,
            overlayColor: config.overlayColor,
          )
        else
          ClipPath(
            clipper: ExclusionClipper(
              content.exclusionRects.map((zone) => zone.rect!).toList(),
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
        ...content.widgets,
        if (config.nextButton != null)
          _buildNextButton(content, child: config.nextButton),
      ],
    );
  }

  Widget _buildNextButton(OverlayContent content, {Widget? child}) {
    return Positioned(
      right: 40,
      bottom: 40,
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
    OverlayConfig? config =
        tutorialStep.loadFromRepository?.call()?.overlayConfig;

    if (config == null || config.customWidget == null) {
      return null;
    }

    return OverlayContent(
      widgets: [config.customWidget!],
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

    if (config.exclusionZones.isEmpty) {
      return createFullScreenOverlayContent(context, tutorialStep);
    }

    // Obtenir toutes les positions et tailles des widgets
    List<ExclusionZone> exclusionZonesWithRect =
        config.exclusionZones.map((zone) {
      final RenderBox box =
          (zone.widgetKey.currentContext!.findRenderObject() as RenderBox);
      Offset widgetPosition = box.localToGlobal(Offset.zero);
      final Rect rect = Rect.fromLTWH(
        widgetPosition.dx - overlayOffset.dx,
        widgetPosition.dy - overlayOffset.dy,
        box.size.width + overlayOffset.dx * 2,
        box.size.height + overlayOffset.dy * 2,
      );
      return zone.copyWith(rect: rect);
    }).toList();

    final Size screen = MediaQuery.of(context).size;

    // Créer une liste de Positioned pour chaque widget
    final List<Positioned> widgets = exclusionZonesWithRect.expand((zone) {
      List<Positioned> positionedWidgets = [];

      if (zone.rect == null) {
        throw Exception("Rect not defined for exclusion zone");
      }

      final Rect rect = zone.rect!;

      // Ajouter un widget "top" si défini
      if (zone.top != null) {
        positionedWidgets.add(
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: rect.top,
            child: zone.top!,
          ),
        );
      }

      // Ajouter un widget "bottom" si défini
      if (zone.bottom != null) {
        positionedWidgets.add(
          Positioned(
            top: zone.rect!.bottom,
            left: 0,
            right: 0,
            height: screen.height - rect.bottom,
            child: zone.bottom!,
          ),
        );
      }

      // Ajouter un widget "center" si défini
      if (zone.center != null) {
        positionedWidgets.add(
          Positioned(
            top: rect.center.dy - (rect.height / 2),
            left: rect.center.dx - (rect.width / 2),
            width: rect.width,
            height: rect.height,
            child: zone.center!,
          ),
        );
      }

      // Ajouter un widget "left" si défini
      if (zone.left != null) {
        positionedWidgets.add(
          Positioned(
            top: 0,
            left: 0,
            width: rect.left,
            height: screen.height,
            child: zone.left!,
          ),
        );
      }

      // Ajouter un widget "right" si défini
      if (zone.right != null) {
        positionedWidgets.add(
          Positioned(
            top: 0,
            left: rect.right,
            width: screen.width - rect.right,
            height: screen.height,
            child: zone.right!,
          ),
        );
      }

      return positionedWidgets;
    }).toList();

    return OverlayContent(
      exclusionRects: exclusionZonesWithRect,
      widgets: widgets,
      exclusionBorderRadius: config.exclusionBorderRadius,
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
  final List<ExclusionZone> exclusionRects;
  final List<Widget> widgets;
  final double exclusionBorderRadius;

  OverlayContent({
    this.exclusionRects = const [],
    this.widgets = const [],
    required this.exclusionBorderRadius,
  });
}
