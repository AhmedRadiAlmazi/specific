// Arabic Text Normalizer — مشروع «مُعين» (Mouin)
class ArabicNormalizer {
  static String normalize(String text) {
    if (text.isEmpty) return '';
    var result = text;
    // 1. Remove Tashkeel (diacritics)
    result = result.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
    // 2. Normalize Alef variations (أ, إ, آ -> ا)
    result = result.replaceAll(RegExp(r'[إأآا]'), 'ا');
    // 3. Normalize Teh Marbuta (ة -> ه)
    result = result.replaceAll('ة', 'ه');
    // 4. Normalize Yeh variations (ى -> ي)
    result = result.replaceAll('ى', 'ي');
    return result.trim().toLowerCase();
  }
}
