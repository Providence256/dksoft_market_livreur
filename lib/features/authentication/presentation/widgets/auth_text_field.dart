import 'package:flutter/material.dart';

/// Champ de saisie utilisé sur les écrans de connexion/inscription : label
/// discret au-dessus de la valeur, bordure arrondie, préfixe/suffixe
/// optionnels — reproduit le style des champs "TÉLÉPHONE" / "MOT DE PASSE"
/// de la maquette.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    this.controller,
    this.prefix,
    this.suffix,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.autofillHints,
    this.focused = false,
  });

  final String label;
  final TextEditingController? controller;
  final Widget? prefix;
  final Widget? suffix;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;

  /// Purely visual: highlights the border like the phone field in the
  /// reference mockup, without needing an actual FocusNode wired up.
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focused
              ? theme.colorScheme.primary
              : Colors.grey.withValues(alpha: 0.3),
          width: focused ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          if (prefix != null) ...[prefix!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                TextFormField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  validator: validator,
                  autofillHints: autofillHints,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: hintText,
                    hintStyle: theme.textTheme.titleMedium!.copyWith(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );
  }
}
