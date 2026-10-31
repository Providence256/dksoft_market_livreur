import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// Messages courts et non bloquants, affichés en haut de l'écran
/// (Toastification), aux couleurs du thème actif.
abstract final class Toast {
  static void success(BuildContext context, String message, {String? title}) =>
      _show(context, message, title, AppColors.success, AppIcons.checkCircle);

  static void info(BuildContext context, String message, {String? title}) =>
      _show(context, message, title, context.palette.primary, AppIcons.info);

  static void error(BuildContext context, Object error, {String? title}) =>
      _show(context, '$error', title, AppColors.error, AppIcons.alert);

  static void _show(
    BuildContext context,
    String message,
    String? title,
    Color color,
    AppIconData icon,
  ) {
    final palette = context.palette;
    toastification.show(
      context: context,
      style: ToastificationStyle.flat,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: false,
      dragToClose: true,
      primaryColor: color,
      backgroundColor: palette.surface,
      foregroundColor: palette.textPrimary,
      borderSide: BorderSide(color: palette.border),
      borderRadius: BorderRadius.circular(16),
      icon: AppIcon(icon, color: color, size: 22),
      title: Text(
        title ?? message,
        maxLines: 2,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      description: title == null ? null : Text(message, maxLines: 3),
    );
  }
}
