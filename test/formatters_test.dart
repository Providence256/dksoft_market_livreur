import 'package:dksoft_market_livreur/utils/formatters/currency_formatter.dart';
import 'package:dksoft_market_livreur/utils/helpers/distance_format.dart';
import 'package:dksoft_market_livreur/utils/helpers/duration_format.dart';
import 'package:dksoft_market_livreur/utils/helpers/phone_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeCongoPhone', () {
    test("toutes les écritures d'un même numéro donnent le même compte", () {
      for (final input in [
        '991234567',
        '0991234567',
        '991 234 567',
        '+243 991 234 567',
        '243991234567',
      ]) {
        expect(normalizeCongoPhone(input), '+243991234567', reason: input);
      }
    });

    test('refuse un numéro incomplet ou trop long', () {
      expect(normalizeCongoPhone('99123'), isNull);
      expect(normalizeCongoPhone('9912345678'), isNull);
      expect(normalizeCongoPhone(''), isNull);
    });

    test("s'affiche lisiblement", () {
      expect(formatPhoneDisplay('+243991234567'), '+243 99 123 4567');
    });
  });

  group('montants', () {
    test('format complet', () {
      expect(CurrencyFormatter.formatUsd(4), '4,00 USD');
      expect(CurrencyFormatter.formatUsd(1234.5), '1.234,50 USD');
    });

    test('format court', () {
      expect(CurrencyFormatter.shortUsd(230), '230 USD');
      expect(CurrencyFormatter.shortUsd(12.5), '12,5 USD');
    });
  });

  group('distances et durées', () {
    test('distance', () {
      expect(formatDistance(5), 'Moins de 10 m');
      expect(formatDistance(847), '850 m');
      expect(formatDistance(3240), '3,2 km');
      expect(formatDistance(12400), '12 km');
    });

    test('durée', () {
      expect(formatDuration(20), '1 min');
      expect(formatDuration(12 * 60), '12 min');
      expect(formatDuration(65 * 60), '1 h 05');
    });
  });
}
