import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Champ de saisie « liste » de l'inscription : libellé gris qui monte au
/// dessus quand on écrit, simple trait dessous.
///
/// [underline] à false : pas de trait (la ligne parente le dessine déjà,
/// voir [ProgressRow]).
class StepTextField extends StatelessWidget {
  const StepTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.hintText,
    this.prefixText,
    this.alwaysFloatLabel = false,
    this.enabled = true,
    this.underline = true,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;
  final String? prefixText;
  final bool alwaysFloatLabel;
  final bool enabled;
  final bool underline;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    InputBorder border(Color color, [double width = 1]) {
      return underline
          ? UnderlineInputBorder(
              borderSide: BorderSide(color: color, width: width),
            )
          : InputBorder.none;
    }

    return TextFormField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: theme.textTheme.bodySmall?.copyWith(
        color: enabled ? AppColors.textPrimaryLight : AppColors.textHintLight,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixText: prefixText,
        suffixIcon: suffix,
        floatingLabelBehavior: alwaysFloatLabel
            ? FloatingLabelBehavior.always
            : FloatingLabelBehavior.auto,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        labelStyle: theme.textTheme.bodyLarge?.copyWith(
          color: enabled
              ? AppColors.textSecondaryLight
              : AppColors.textHintLight,
        ),
        floatingLabelStyle: theme.textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        border: border(AppColors.dividerLight),
        enabledBorder: border(AppColors.dividerLight),
        disabledBorder: border(AppColors.dividerLight),
        focusedBorder: border(AppColors.primary, 1.5),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error, 1.5),
      ),
    );
  }
}
