import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Ligne « à choisir » avec chevron (pays, commune, marque, date…). Vide :
/// le libellé sert de texte. Remplie : petit libellé au dessus, valeur
/// dessous.
class StepSelectRow extends StatelessWidget {
  const StepSelectRow({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.enabled = true,
    this.trailing,
    this.underline = true,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool enabled;

  /// Remplace le chevron (ex. un cadenas pour une valeur imposée).
  final Widget? trailing;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null && value!.isNotEmpty;

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dividerLight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          spacing: 5,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasValue)
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  Text(
                    hasValue ? value! : label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: !enabled
                          ? AppColors.textHintLight
                          : hasValue
                          ? AppColors.textPrimaryLight
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 28,
                  color: enabled
                      ? AppColors.textPrimaryLight
                      : AppColors.textHintLight,
                ),
          ],
        ),
      ),
    );
  }
}

/// Liste de choix en bas d'écran. Renvoie l'option choisie, ou null si
/// l'utilisateur ferme sans choisir.
Future<String?> showOptionsSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) {
      final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    title: Text(
                      option,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: option == selected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(option),
                  );
                },
                separatorBuilder: (BuildContext context, int index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Divider(color: AppColors.dividerLight),
                ),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}
