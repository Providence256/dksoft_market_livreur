import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppNavItem {
  const AppNavItem({required this.icon, required this.label, this.badge = 0});

  final AppIconData icon;
  final String label;
  final int badge;
}

/// Barre de navigation flottante : capsule blanche posée au-dessus du
/// contenu, l'onglet actif s'ouvre en pilule bleu clair avec son nom.
///
/// À utiliser avec `Scaffold(extendBody: true)` pour que le contenu passe
/// dessous.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelected,
  });

  final List<AppNavItem> items;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Sizes.p16,
        0,
        Sizes.p16,
        bottom > 0 ? bottom - 6 : Sizes.p12,
      ),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: context.palette.border),
          boxShadow: [
            BoxShadow(
              color: context.palette.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            for (final (i, item) in items.indexed)
              Expanded(
                // L'onglet actif prend un peu plus de place pour son nom.
                flex: i == index ? 19 : 10,
                child: _NavButton(
                  item: item,
                  selected: i == index,
                  onTap: () {
                    if (i != index) HapticFeedback.selectionClick();
                    onSelected(i);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget icon = AppIcon(
      item.icon,
      size: 23,
      color: selected ? context.palette.primary : context.palette.textMuted,
      strokeWidth: selected ? 1.9 : 1.6,
    );
    if (item.badge > 0) {
      icon = Badge.count(
        count: item.badge,
        backgroundColor: AppColors.secondary,
        child: icon,
      );
    }

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: Pressable(
        onTap: onTap,
        haptic: false,
        scale: 0.9,
        child: Center(
          child: AnimatedContainer(
            duration: Motion.medium,
            curve: Motion.emphasized,
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 6),
            decoration: BoxDecoration(
              color: selected
                  ? context.palette.primarySoft
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                Flexible(
                  child: AnimatedSize(
                    duration: Motion.medium,
                    curve: Motion.emphasized,
                    child: selected
                        ? Padding(
                            padding: const EdgeInsets.only(left: 7),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(
                                color: context.palette.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
