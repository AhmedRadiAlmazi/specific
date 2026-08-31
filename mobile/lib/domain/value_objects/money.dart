// Exact Money & Decimal Representation — مشروع «مُعين» (Mouin)
class Money {
  final BigInt minorUnits; // Amount in minor units (cents / fils)
  final int precision;     // e.g. 2 decimals
  final String currency;

  const Money._(this.minorUnits, this.currency, {this.precision = 2});

  factory Money.fromDecimalString(String str, {String currency = 'YER', int precision = 2}) {
    final parts = str.trim().split('.');
    final whole = BigInt.parse(parts[0]);
    var fractionStr = parts.length > 1 ? parts[1] : '';
    if (fractionStr.length > precision) {
      fractionStr = fractionStr.substring(0, precision);
    } else {
      fractionStr = fractionStr.padRight(precision, '0');
    }
    final fraction = fractionStr.isEmpty ? BigInt.zero : BigInt.parse(fractionStr);
    final factor = BigInt.from(10).pow(precision);
    final totalMinor = (whole * factor) + (whole.isNegative ? -fraction : fraction);
    return Money._(totalMinor, currency, precision: precision);
  }

  factory Money.zero({String currency = 'YER'}) => Money._(BigInt.zero, currency);

  bool get isZero => minorUnits == BigInt.zero;
  bool get isPositive => minorUnits > BigInt.zero;
  bool get isNegative => minorUnits < BigInt.zero;

  Money add(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot add money of different currencies: $currency != ${other.currency}');
    }
    return Money._(minorUnits + other.minorUnits, currency, precision: precision);
  }

  Money subtract(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot subtract money of different currencies');
    }
    return Money._(minorUnits - other.minorUnits, currency, precision: precision);
  }

  String toDecimalString() {
    final factor = BigInt.from(10).pow(precision);
    final whole = minorUnits ~/ factor;
    final frac = (minorUnits.abs() % factor).toString().padLeft(precision, '0');
    return '$whole.$frac';
  }

  @override
  String toString() => '${toDecimalString()} $currency';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && minorUnits == other.minorUnits && currency == other.currency;

  @override
  int get hashCode => minorUnits.hashCode ^ currency.hashCode;
}
