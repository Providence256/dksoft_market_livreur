/// Lightweight French day-label formatter — e.g. `Mar. 12 août` — that
/// doesn't require `intl` locale-data initialisation.
class DateFormatterFr {
  DateFormatterFr._();

  static const _weekdays = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];

  static const _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  static String dayLabel(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    final month = _months[date.month - 1];
    return '$weekday ${date.day} $month';
  }
}
