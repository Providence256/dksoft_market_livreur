import 'package:dksoft_market_livreur/features/earnings/domain/week_stats.dart';
import 'package:flutter_test/flutter_test.dart';

import 'delivery_fixtures.dart';

void main() {
  // Mercredi 28 octobre 2026, 15 h : la semaine va du lundi 26 au dimanche 1er.
  final now = DateTime(2026, 10, 28, 15);

  test('répartit les gains de la semaine par jour', () {
    final stats = WeekStats.compute([
      delivery(id: 'a', fee: 4, deliveredAt: DateTime(2026, 10, 26, 9)),
      delivery(id: 'b', fee: 6, deliveredAt: DateTime(2026, 10, 28, 8)),
      delivery(id: 'c', fee: 5, deliveredAt: DateTime(2026, 10, 28, 12)),
    ], now);

    expect(stats.weekStart, DateTime(2026, 10, 26));
    expect(stats.dailyEarnings, [4, 0, 11, 0, 0, 0, 0]);
    expect(stats.totalEarnings, 15);
    expect(stats.totalCount, 3);
  });

  test("ne compte que les courses livrées", () {
    final stats = WeekStats.compute([
      delivery(id: 'a', status: 'enRoute', deliveredAt: DateTime(2026, 10, 27)),
      delivery(
        id: 'b',
        status: 'dealerAbsent',
        deliveredAt: DateTime(2026, 10, 27),
      ),
    ], now);
    expect(stats.totalEarnings, 0);
    expect(stats.isEmpty, isTrue);
  });

  test('compare à la semaine précédente', () {
    final stats = WeekStats.compute([
      delivery(id: 'old', fee: 10, deliveredAt: DateTime(2026, 10, 20)),
      delivery(id: 'new', fee: 15, deliveredAt: DateTime(2026, 10, 27)),
    ], now);
    expect(stats.previousEarnings, 10);
    expect(stats.earningsDelta, 50);
  });

  test("pas d'évolution sans semaine précédente", () {
    final stats = WeekStats.compute([], now);
    expect(stats.earningsDelta, isNull);
  });

  test('cumul du lundi à aujourd’hui', () {
    final stats = WeekStats.compute([
      delivery(id: 'a', fee: 4, deliveredAt: DateTime(2026, 10, 26)),
      delivery(id: 'b', fee: 6, deliveredAt: DateTime(2026, 10, 28)),
    ], now);
    expect(stats.cumulativeEarnings(now), [4, 4, 10]);
  });
}
