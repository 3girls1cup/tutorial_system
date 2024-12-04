import 'package:flutter/material.dart';
import 'package:tutorial_system/model/tutorial_overlay_config.dart';

class ExclusionClipper extends CustomClipper<Path> {
  final List<ExclusionZone> exclusionZones; // Liste des zones d'exclusion

  ExclusionClipper(this.exclusionZones);

  @override
  Path getClip(Size size) {
    // Path pour l'écran complet
    Path outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Créer un chemin combiné pour toutes les zones d'exclusion
    Path exclusionPaths = Path();

    for (final zone in exclusionZones) {
      if (zone.rounded!) {
        // Créer un chemin circulaire pour chaque zone d'exclusion
        exclusionPaths.addOval(Rect.fromCircle(
          center: zone.rect!.center,
          radius: zone.rect!.width / 2,
        ));
      } else {
        // Créer un chemin rectangulaire arrondi pour chaque zone d'exclusion
        exclusionPaths.addRRect(
          RRect.fromRectAndRadius(
              zone.rect!, Radius.circular(zone.exclusionBorderRadius!)),
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
