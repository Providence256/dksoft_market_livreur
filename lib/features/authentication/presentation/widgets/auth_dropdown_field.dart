import 'package:flutter/material.dart';

/// Liste déroulante au même style que [AuthTextField] (label discret au
/// dessus, bordure arrondie).
class AuthDropdownField extends StatelessWidget {
  const AuthDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.prefix,
    this.hintText,
    this.validator,
  });

  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final Widget? prefix;
  final String? hintText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
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
                DropdownButtonFormField<String>(
                  initialValue: value,
                  isExpanded: true,
                  isDense: true,
                  validator: validator,
                  onChanged: onChanged,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
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
                  items: [
                    for (final item in items)
                      DropdownMenuItem(value: item, child: Text(item)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
