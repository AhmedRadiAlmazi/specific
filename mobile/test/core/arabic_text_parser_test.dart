import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/core/ai/arabic_text_parser.dart';

void main() {
  group('ArabicTextParser Tests', () {
    final refTime = DateTime(2026, 9, 1, 8, 0, 0);

    test('parses debt with natural amount, currency, and direction', () {
      const text = 'دين 5000 ريال لسالم لشراء المواد عاجل';
      final parsed = ArabicTextParser.parse(text, referenceTime: refTime);

      expect(parsed.itemType, equals('debt'));
      expect(parsed.amount, equals('5000'));
      expect(parsed.currency, equals('YER'));
      expect(parsed.priority, equals('high'));
      expect(parsed.personName, equals('سالم'));
    });

    test('parses reminder with natural date, time, and urgent priority', () {
      const text = 'ذكرني غداً الساعة 10 صباحاً بموعد المستشفى عاجل جداً';
      final parsed = ArabicTextParser.parse(text, referenceTime: refTime);

      expect(parsed.itemType, equals('reminder'));
      expect(parsed.priority, equals('urgent'));
      expect(parsed.dueDate, isNotNull);
      expect(parsed.dueDate!.day, equals(2));
      expect(parsed.dueDate!.hour, equals(10));
    });

    test('parses shopping list items', () {
      const text = 'قائمة مشتريات: حليب وخبز وجبن من السوبرماركت';
      final parsed = ArabicTextParser.parse(text, referenceTime: refTime);

      expect(parsed.itemType, equals('shopping'));
      expect(parsed.priority, equals('medium'));
    });
  });
}
