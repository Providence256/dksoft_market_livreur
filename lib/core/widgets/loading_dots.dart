import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Trois points qui s'allument tour à tour : l'attente d'une action
/// (bouton qui envoie, interrupteur qui se met à jour). Les écrans en
/// chargement utilisent plutôt un squelette (skeleton.dart).
class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key, this.color, this.size = 7});

  /// Couleur des points ; celle du texte ambiant par défaut (ex. dans un
  /// bouton).
  final Color? color;
  final double size;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ??
        DefaultTextStyle.of(context).style.color ??
        IconTheme.of(context).color ??
        Colors.white;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: widget.size * 0.7,
        children: [
          for (var i = 0; i < 3; i++)
            Builder(
              builder: (context) {
                // Chaque point suit une vague décalée d'un tiers de cycle.
                final t = (_controller.value - i / 3) % 1;
                final wave = (math.sin(t * 2 * math.pi) + 1) / 2;
                return Transform.translate(
                  offset: Offset(0, -wave * widget.size * 0.5),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.35 + wave * 0.65),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
