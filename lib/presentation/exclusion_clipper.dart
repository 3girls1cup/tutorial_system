import 'package:flutter/material.dart';

class ExclusionClipper extends CustomClipper<Path> {
  final Rect exclusionRect;
  final double borderRadius; // Rayon des bordures arrondies

  ExclusionClipper(this.exclusionRect, this.borderRadius);

  @override
  Path getClip(Size size) {
    // Path pour l'écran complet
    Path outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Path pour la zone d'exclusion arrondie
    Path exclusionPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        exclusionRect,
        Radius.circular(borderRadius),
      ));

    // Combinaison des chemins pour exclure la zone arrondie
    return Path.combine(PathOperation.difference, outerPath, exclusionPath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
