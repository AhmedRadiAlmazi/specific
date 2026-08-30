import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/domain/value_objects/money.dart';

void main() {
  group('Money Value Object (Exact Minor Units Decimal)', () {
    test('parses decimal string to exact minor units', () {
      final m = Money.fromDecimalString('1250.50', currency: 'YER');
      expect(m.minorUnits, equals(BigInt.from(125050)));
      expect(m.toDecimalString(), equals('1250.50'));
    });

    test('performs exact addition and subtraction without floating point error', () {
      final m1 = Money.fromDecimalString('0.10');
      final m2 = Money.fromDecimalString('0.20');
      final sum = m1.add(m2);
      expect(sum.toDecimalString(), equals('0.30'));

      final diff = sum.subtract(m1);
      expect(diff.toDecimalString(), equals('0.20'));
    });

    test('throws ArgumentError on currency mismatch', () {
      final m1 = Money.fromDecimalString('100.00', currency: 'YER');
      final m2 = Money.fromDecimalString('50.00', currency: 'USD');
      expect(() => m1.add(m2), throwsArgumentError);
    });
  });
}
