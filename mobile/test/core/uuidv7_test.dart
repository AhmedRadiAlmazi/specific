import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/core/utils/uuidv7.dart';

void main() {
  group('UUIDv7 Generator (RFC 9562)', () {
    test('generates valid UUIDv7 format', () {
      final id = UuidV7.generate();
      expect(UuidV7.isValid(id), isTrue);
      expect(id[14], equals('7')); // Version 7 check
      expect(['8', '9', 'a', 'b'].contains(id[19].toLowerCase()), isTrue); // Variant check
    });

    test('generates strictly unique IDs across iterations', () {
      final set = <String>{};
      for (int i = 0; i < 500; i++) {
        final id = UuidV7.generate();
        expect(set.contains(id), isFalse);
        set.add(id);
      }
      expect(set.length, equals(500));
    });
  });
}
