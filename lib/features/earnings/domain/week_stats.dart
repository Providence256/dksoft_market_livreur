import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';

/// Résultats de la semaine en cours (du lundi au dimanche), comparés à la
/// semaine précédente. Calculés à partir des courses terminées.
class WeekStats {
  const WeekStats({
    required this.weekStart,
    required this.dailyEarnings,
    required this.dailyCounts,
    required this.previousEarnings,
    required this.previousCount,
  });

  /// Lundi 00:00 de la semaine.
  final DateTime weekStart;

  /// Gains par jour, du lundi (0) au dimanche (6).
  final List<double> dailyEarnings;
  final List<int> dailyCounts;

  final double previousEarnings;
  final int previousCount;

  double get totalEarnings => dailyEarnings.fold(0, (a, b) => a + b);
  int get totalCount => dailyCounts.fold(0, (a, b) => a + b);

  /// Évolution en % par rapport à la semaine précédente (null si on n'a
  /// rien à comparer).
  double? get earningsDelta => previousEarnings > 0
      ? (totalEarnings - previousEarnings) / previousEarnings * 100
      : null;

  double? get countDelta => previousCount > 0
      ? (totalCount - previousCount) / previousCount * 100
      : null;

  double get maxDaily => dailyEarnings.fold(0, (a, b) => a > b ? a : b);

  bool get isEmpty => totalCount == 0;

  static WeekStats compute(List<DeliveryModel> deliveries, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      today.year,
      today.month,
      today.day - (now.weekday - 1),
    );
    final previousStart = DateTime(start.year, start.month, start.day - 7);
    final nextStart = DateTime(start.year, start.month, start.day + 7);

    final earnings = List<double>.filled(7, 0);
    final counts = List<int>.filled(7, 0);
    var previousEarnings = 0.0;
    var previousCount = 0;

    for (final delivery in deliveries) {
      if (delivery.status != DeliveryStatus.delivered) continue;
      final date = delivery.completedOn;
      if (date == null) continue;

      if (!date.isBefore(start) && date.isBefore(nextStart)) {
        final day = date.difference(start).inDays.clamp(0, 6);
        earnings[day] += delivery.deliveryFee;
        counts[day] += 1;
      } else if (!date.isBefore(previousStart) && date.isBefore(start)) {
        previousEarnings += delivery.deliveryFee;
        previousCount += 1;
      }
    }

    return WeekStats(
      weekStart: start,
      dailyEarnings: earnings,
      dailyCounts: counts,
      previousEarnings: previousEarnings,
      previousCount: previousCount,
    );
  }
}
