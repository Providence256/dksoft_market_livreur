import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:flutter/material.dart';

/// Reflet qui balaie en continu les blocs [SkeletonBox] placés en dessous.
/// Un seul reflet par écran : tous les blocs brillent en même temps, comme
/// une seule surface, au lieu de clignoter chacun de leur côté.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  // De -0,6 à 1,6 : le reflet entre et sort complètement de l'écran.
  late final _controller = AnimationController(
    vsync: this,
    lowerBound: -0.6,
    upperBound: 1.6,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(state: this, child: widget.child);
  }
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.state, required super.child});

  final _ShimmerState state;

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) => false;
}

/// Décale le dégradé de gauche à droite au fil de l'animation.
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * percent, 0, 0);
}

/// Bloc gris arrondi qui tient la place d'un contenu en chargement.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = Radii.sm,
  });

  /// Ligne de texte : hauteur fine, bouts ronds.
  const SkeletonBox.line({super.key, this.width, this.height = 12})
    : radius = Radii.pill;

  const SkeletonBox.circle({super.key, required double size})
    : width = size,
      height = size,
      radius = Radii.pill;

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final base = Color.lerp(palette.surfaceMuted, palette.border, 0.55)!;
    final highlight = context.isDark
        ? Color.lerp(base, Colors.white, 0.08)!
        : palette.surfaceMuted;

    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    final shimmer = context
        .dependOnInheritedWidgetOfExactType<_ShimmerScope>()
        ?.state;
    if (shimmer == null) return box;

    return AnimatedBuilder(
      animation: shimmer._controller,
      child: box,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          // Le dégradé est calculé dans le repère du reflet, puis ramené à
          // la position de ce bloc : tous les blocs partagent le même
          // balayage.
          final shimmerBox = shimmer.context.findRenderObject() as RenderBox?;
          final self = context.findRenderObject() as RenderBox?;
          var rect = bounds;
          if (shimmerBox != null &&
              shimmerBox.hasSize &&
              self != null &&
              self.attached) {
            final offset = self.localToGlobal(
              Offset.zero,
              ancestor: shimmerBox,
            );
            rect = offset.scale(-1, -1) & shimmerBox.size;
          }
          return LinearGradient(
            begin: const Alignment(-1, -0.3),
            end: const Alignment(1, 0.3),
            colors: [base, highlight, base],
            stops: const [0.3, 0.5, 0.7],
            transform: _SlideGradient(shimmer._controller.value),
          ).createShader(rect);
        },
        child: child,
      ),
    );
  }
}

/// Carte vide aux couleurs de l'app, pour poser des blocs dedans.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Sizes.p16),
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

/// Ligne type liste : pastille d'icône, deux lignes de texte, valeur à
/// droite.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key, this.trailing = true});

  final bool trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.p16,
        vertical: Sizes.p12,
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 36, height: 36),
          gapW16,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: 0.6,
                  child: SkeletonBox.line(),
                ),
                gapH8,
                FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: 0.35,
                  child: SkeletonBox.line(height: 10),
                ),
              ],
            ),
          ),
          if (trailing) ...[gapW16, const SkeletonBox.line(width: 48)],
        ],
      ),
    );
  }
}

/// Squelette générique d'une page : grand bloc d'en-tête, puis une carte
/// de lignes. Sert quand l'écran exact n'est pas encore connu (vérification
/// du compte au démarrage, par exemple).
class PageSkeleton extends StatelessWidget {
  const PageSkeleton({super.key, this.rows = 4, this.heroHeight = 150});

  final int rows;
  final double heroHeight;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Sizes.screenPadding,
          Sizes.p4,
          Sizes.screenPadding,
          Sizes.p32,
        ),
        children: [
          SkeletonBox(height: heroHeight, radius: Radii.xl),
          gapH24,
          const SkeletonBox.line(width: 120, height: 14),
          gapH12,
          SkeletonCard(
            padding: const EdgeInsets.symmetric(vertical: Sizes.p4),
            child: Column(
              children: [for (var i = 0; i < rows; i++) const SkeletonRow()],
            ),
          ),
        ],
      ),
    );
  }
}
