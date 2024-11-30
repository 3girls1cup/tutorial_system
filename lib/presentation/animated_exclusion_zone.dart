import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tutorial_system/model/tutorial_overlay_config.dart';
import 'package:tutorial_system/presentation/exclusion_clipper.dart';

class AnimatedExclusionZone extends StatefulWidget {
  final List<ExclusionZone> zones; // Liste des zones d'exclusion
  final Color overlayColor;

  const AnimatedExclusionZone({
    super.key,
    required this.zones,
    required this.overlayColor,
  });

  @override
  State<AnimatedExclusionZone> createState() => _AnimatedExclusionZoneState();
}

class _AnimatedExclusionZoneState extends State<AnimatedExclusionZone>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    // Créer un AnimationController et une animation pour chaque zone
    _controllers = widget.zones.map((zone) {
      return AnimationController(
        vsync: this,
        duration: zone.breathingDuration ?? const Duration(seconds: 2),
      )..repeat(reverse: true);
    }).toList();

    _animations = List.generate(widget.zones.length, (index) {
      final zone = widget.zones[index];
      final controller = _controllers[index];
      return Tween<double>(
        begin: 1.0,
        end: zone.breathingScale ?? 1.1,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    });
  }

  @override
  void dispose() {
    // Nettoyer les contrôleurs
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.zones.length, (index) {
        final zone = widget.zones[index];
        final animation = _animations[index];

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final scaledRect = Rect.fromCenter(
              center: zone.rect!.center,
              width: zone.rect!.width * animation.value,
              height: zone.rect!.height * animation.value,
            );

            return ClipPath(
              clipper: ExclusionClipper(
                [scaledRect],
                zone.exclusionBorderRadius ?? 8.0,
                zone.rounded ?? false,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  color: widget.overlayColor,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
