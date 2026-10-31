import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Libellé au-dessus d'un champ.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.enabled = true});

  final String text;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: Sizes.p8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: enabled
              ? context.palette.textPrimary
              : context.palette.textMuted,
        ),
      ),
    );
  }
}

/// Champ de saisie : libellé au-dessus, champ gris clair arrondi qui se
/// borde de marine au focus. Le style vient de `inputDecorationTheme`.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.onChanged,
    this.hintText,
    this.prefix,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? hintText;

  /// Préfixe libre (ex. indicatif téléphonique).
  final Widget? prefix;
  final AppIconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FieldLabel(label, enabled: enabled),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: enabled
                ? context.palette.textPrimary
                : context.palette.textMuted,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefix != null
                ? Padding(
                    padding: const EdgeInsets.only(left: Sizes.p16, right: 10),
                    child: prefix,
                  )
                : prefixIcon != null
                ? Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: AppIcon(prefixIcon!, size: 20),
                  )
                : null,
            prefixIconConstraints: prefix != null
                ? const BoxConstraints(minHeight: 0)
                : null,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// Champ « à choisir » (pays, marque, date…) au même style qu'un
/// [AppTextField] : ouvre une liste ou un calendrier au toucher.
class AppSelectField extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.placeholder,
    this.trailingIcon = AppIcons.chevronDown,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final String? placeholder;
  final VoidCallback? onTap;
  final AppIconData trailingIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null && value!.isNotEmpty;
    final active = enabled && onTap != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FieldLabel(label, enabled: enabled),
        Material(
          color: context.palette.surfaceMuted,
          borderRadius: BorderRadius.circular(Radii.md),
          child: InkWell(
            onTap: active ? onTap : null,
            borderRadius: BorderRadius.circular(Radii.md),
            child: Container(
              height: Sizes.controlHeight,
              padding: const EdgeInsets.symmetric(horizontal: Sizes.p16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue ? value! : (placeholder ?? 'Choisir'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: hasValue ? FontWeight.w500 : null,
                        color: !enabled
                            ? context.palette.textMuted
                            : hasValue
                            ? context.palette.textPrimary
                            : context.palette.textMuted,
                      ),
                    ),
                  ),
                  AppIcon(
                    trailingIcon,
                    size: 22,
                    color: active
                        ? context.palette.textSecondary
                        : context.palette.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Indicatif « 🇨🇩 +243 » devant les champs téléphone.
class PhonePrefix extends StatelessWidget {
  const PhonePrefix({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🇨🇩', style: TextStyle(fontSize: 18)),
        gapW8,
        Text(
          '+243',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        gapW12,
        Container(width: 1, height: 22, color: context.palette.border),
      ],
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
    builder: (context) {
      final theme = Theme.of(context);
      final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Sizes.screenPadding,
                  0,
                  Sizes.screenPadding,
                  Sizes.p12,
                ),
                child: Text(title, style: theme.textTheme.titleLarge),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(
                    Sizes.p12,
                    0,
                    Sizes.p12,
                    Sizes.p12,
                  ),
                  children: [
                    for (final option in options)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Sizes.p12,
                        ),
                        selected: option == selected,
                        selectedTileColor: context.palette.primarySoft,
                        selectedColor: context.palette.primary,
                        title: Text(option),
                        trailing: option == selected
                            ? AppIcon(
                                AppIcons.check,
                                color: context.palette.primary,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(option),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
