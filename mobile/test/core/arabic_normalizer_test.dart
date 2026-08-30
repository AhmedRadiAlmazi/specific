import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/core/utils/arabic_normalizer.dart';

void main() {
  group('Arabic Text Normalizer', () {
    test('removes tashkeel / diacritics', () {
      final input = 'مُعَيْنٌ لِلْمَهَامّ';
      final normalized = ArabicNormalizer.normalize(input);
      expect(normalized, equals('معين للمهام'));
    });

    test('normalizes Alef forms (أ, إ, آ -> ا)', () {
      final input = 'أحمد إبراهيم آمنة';
      final normalized = ArabicNormalizer.normalize(input);
      expect(normalized, equals('احمد ابراهيم امنه'));
    });

    test('normalizes Teh Marbuta and Yeh forms', () {
      final input = 'مكتبة المستشفى';
      final normalized = ArabicNormalizer.normalize(input);
      expect(normalized, equals('مكتبه المستشفي'));
    });
  });
}
