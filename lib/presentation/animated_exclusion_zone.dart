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

    // Initialiser les AnimationController et les animations pour chaque zone
    _controllers = widget.zones.map((zone) {
      final duration = zone.breathingDuration!;
      return AnimationController(
        vsync: this,
        duration: duration, // Par défaut ou personnalisé
      )..repeat(reverse: true);
    }).toList();

    _animations = List.generate(widget.zones.length, (index) {
      final zone = widget.zones[index];
      final controller = _controllers[index];
      return Tween<double>(
        begin: 1.0,
        end: zone.breathingScale,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    });
  }

  @override
  void dispose() {
    // Nettoyer tous les AnimationController
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge(_controllers), // Merge all animations
          builder: (context, child) {
            // Calculer les rectangles agrandis pour chaque zone
            final scaledRects = widget.zones.asMap().entries.map((entry) {
              final index = entry.key;
              final zone = entry.value;
              final rect = zone.rect!;
              final animation = _animations[index];

              return Rect.fromCenter(
                center: rect.center,
                width: rect.width * animation.value,
                height: rect.height * animation.value,
              );
            }).toList();

            return ClipPath(
              clipper: ExclusionClipper(
                scaledRects,
                widget.zones.first.exclusionBorderRadius!,
                widget.zones.first.rounded!,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  color: widget.overlayColor,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
