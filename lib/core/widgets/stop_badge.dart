import 'package:flutter/material.dart';

/// Pastille ronde d'un arrêt : numéro ou icône sur fond coloré.
class StopBadge extends StatelessWidget {
  const StopBadge({
    super.key,
    required this.color,
    this.label,
    this.icon,
    this.size = 30,
  }) : assert(label != null || icon != null);

  final Color color;
  final String? label;
  final IconData? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: icon != null
          ? Icon(icon, size: size * 0.55, color: Colors.white)
          : Text(
              label!,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.43,
              ),
            ),
    );
  }
}
