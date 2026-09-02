import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/core/utils/arabic_search_normalizer.dart';

void main() {
  group('ArabicSearchNormalizer Tests', () {
    test('removes Tashkeel and Tatweel correctly', () {
      const raw = 'مُعَيْنٌ — مُسَاعِدُكَ الشَّخْصِيُّ';
      expect(ArabicSearchNormalizer.normalize(raw), 'معين — مساعدك الشخصي');

      const tatweel = 'مــــعـــــيــــن';
      expect(ArabicSearchNormalizer.normalize(tatweel), 'معين');
    });

    test('normalizes Hamzas, Alif Maqsura, and Taa Marbuta', () {
      const rawHamzas = 'إدارة الأعمال والإنتاج والآمال';
      expect(ArabicSearchNormalizer.normalize(rawHamzas), 'اداره الاعمال والانتاج والامال');

      const rawWords = 'مستشفى المدينة';
      expect(ArabicSearchNormalizer.normalize(rawWords), 'مستشفي المدينه');
    });

    test('matches query against target text tolerantly', () {
      expect(
        ArabicSearchNormalizer.matches('ادارة', 'إدارة المشاريع والتخطيط'),
        isTrue,
      );
      expect(
        ArabicSearchNormalizer.matches('مستشفي', 'مستشفى الأمل التخصصي'),
        isTrue,
      );
      expect(
        ArabicSearchNormalizer.matches('معين', 'مُعَيْنٌ'),
        isTrue,
      );
      expect(
        ArabicSearchNormalizer.matches('سيارة', 'شراء سيارة جديدة'),
        isTrue,
      );
    });
  });
}
