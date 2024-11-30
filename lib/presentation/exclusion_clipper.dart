import 'package:flutter/material.dart';

class ExclusionClipper extends CustomClipper<Path> {
  final List<Rect> exclusionRects; // Liste des zones d'exclusion
  final double borderRadius; // Rayon des bordures arrondies
  final bool round;

  ExclusionClipper(this.exclusionRects, this.borderRadius, this.round);

  @override
  Path getClip(Size size) {
    // Path pour l'écran complet
    Path outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Créer un chemin combiné pour toutes les zones d'exclusion
    Path exclusionPaths = Path();

    for (final rect in exclusionRects) {
      if (round) {
        // Créer un chemin circulaire pour chaque zone d'exclusion
        exclusionPaths.addOval(Rect.fromCircle(
          center: rect.center,
          radius: rect.width / 2,
        ));
      } else {
        // Créer un chemin rectangulaire arrondi pour chaque zone d'exclusion
        exclusionPaths.addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
        );
      }
    }

    // Combiner les chemins pour exclure toutes les zones
    return Path.combine(PathOperation.difference, outerPath, exclusionPaths);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
