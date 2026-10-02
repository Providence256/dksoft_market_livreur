import 'package:intl/intl.dart';

/// Consistent `$X,XXX.XX` formatting for money values shown in the app.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _format = NumberFormat.currency(
    symbol: '\$ ',
    decimalDigits: 2,
  );

  static String format(num amount) => _format.format(amount);

  /// Matches the dealer wallet style used on the dashboard: `150,00 USD`
  /// — comma decimal separator, currency code suffix, dot thousands
  /// separator.
  static String formatUsd(num amount) {
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final wholePart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return '$wholePart,${parts[1]} USD';
  }
}
