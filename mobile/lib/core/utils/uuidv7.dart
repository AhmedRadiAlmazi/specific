// UUIDv7 Generator (RFC 9562) — مشروع «مُعين» (Mouin)
import 'dart:math';

class UuidV7 {
  static final Random _random = Random.secure();
  static int _lastTimestamp = -1;
  static int _sequence = 0;

  static String generate() {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    if (now == _lastTimestamp) {
      _sequence = (_sequence + 1) & 0x0FFF;
    } else {
      _sequence = _random.nextInt(0x0FFF);
      _lastTimestamp = now;
    }

    final randA = _sequence;
    final randB1 = _random.nextInt(0x3FFF) | 0x8000; // variant 10xx
    final randB2 = _random.nextInt(0xFFFF);
    final randB3 = _random.nextInt(0xFFFF);
    final randB4 = _random.nextInt(0xFFFF);

    final timeHex = now.toRadixString(16).padLeft(12, '0');
    final timeHigh = timeHex.substring(0, 8);
    final timeMid = timeHex.substring(8, 12);
    final verRandA = ((0x7000) | (randA & 0x0FFF)).toRadixString(16).padLeft(4, '0');
    final varRandB1 = randB1.toRadixString(16).padLeft(4, '0');
    final randLow = (randB2.toRadixString(16).padLeft(4, '0')) +
        (randB3.toRadixString(16).padLeft(4, '0')) +
        (randB4.toRadixString(16).padLeft(4, '0'));

    return '$timeHigh-$timeMid-$verRandA-$varRandB1-$randLow';
  }

  static bool isValid(String uuid) {
    final regex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false);
    return regex.hasMatch(uuid);
  }
}
