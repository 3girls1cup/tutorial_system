import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tutorial_system/presentation/exclusion_clipper.dart';

class AnimatedExclusionZone extends StatefulWidget {
  final List<Rect> exclusionRects; // Liste des zones d'exclusion
  final double breathingScale;
  final double borderRadius;
  final Duration breathingDuration;
  final Color overlayColor;
  final bool round;

  const AnimatedExclusionZone({
    super.key,
    required this.exclusionRects,
    this.borderRadius = 8.0,
    this.breathingScale = 1.1,
    required this.breathingDuration,
    required this.overlayColor,
    required this.round,
  });

  @override
  State<AnimatedExclusionZone> createState() => _AnimatedExclusionZoneState();
}

class _AnimatedExclusionZoneState extends State<AnimatedExclusionZone>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.breathingDuration,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: widget.breathingScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Calculer les rectangles agrandis pour chaque zone
        final scaledRects = widget.exclusionRects.map((rect) {
          return Rect.fromCenter(
            center: rect.center,
            width: rect.width * _animation.value,
            height: rect.height * _animation.value,
          );
        }).toList();

        return ClipPath(
          clipper:
              ExclusionClipper(scaledRects, widget.borderRadius, widget.round),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: widget.overlayColor,
            ),
          ),
        );
      },
    );
  }
}
