import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Surface blanche à bords arrondis, avec une ombre très légère.
/// Brique de base de tous les écrans.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Sizes.p16),
    this.onTap,
    this.color = Colors.white,
    this.borderColor = AppColors.dividerLight,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Ink(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: borderColor),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
