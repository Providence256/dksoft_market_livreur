import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badge;
}

/// Barre de navigation du bas : l'onglet actif s'élargit en pilule marine
/// avec son nom, les autres restent de simples icônes.
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: Row(
            children: [
              for (final (i, item) in items.indexed)
                Expanded(
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
    Widget icon = Icon(
      selected ? item.selectedIcon : item.icon,
      size: 24,
      color: selected ? Colors.white : AppColors.textSecondaryLight,
    );
    if (item.badge > 0) {
      icon = Badge.count(count: item.badge, child: icon);
    }

    return Pressable(
      onTap: onTap,
      haptic: false,
      scale: 0.9,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Motion.emphasized,
          height: 46,
          padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(23),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              AnimatedSize(
                duration: const Duration(milliseconds: 450),
                curve: Motion.emphasized,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
