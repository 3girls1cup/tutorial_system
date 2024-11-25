import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tutorial_system/presentation/exclusion_clipper.dart';

class AnimatedExclusionZone extends StatefulWidget {
  final Rect exclusionRect;
  final double breathingScale;
  final double borderRadius;
  final Duration breathingDuration;

  const AnimatedExclusionZone({
    super.key,
    required this.exclusionRect,
    this.borderRadius = 8.0,
    this.breathingScale = 1.1,
    required this.breathingDuration,
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
        final scaledRect = Rect.fromCenter(
          center: widget.exclusionRect.center,
          width: widget.exclusionRect.width * _animation.value,
          height: widget.exclusionRect.height * _animation.value,
        );

        return ClipPath(
          clipper: ExclusionClipper(scaledRect, widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        );
      },
    );
  }
}
