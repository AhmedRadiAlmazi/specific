// Arabic Search & NLP Normalizer — مشروع «مُعين» (Mouin)
class ArabicSearchNormalizer {
  static final RegExp _tashkeelRegex = RegExp(r'[\u0617-\u061A\u064B-\u0652\u0670]');
  static const String _tatweel = '\u0640';

  /// Normalizes Arabic text for tolerant and precise fuzzy matching
  static String normalize(String text) {
    if (text.isEmpty) return '';

    // 1. Remove Tashkeel (diacritics)
    var result = text.replaceAll(_tashkeelRegex, '');

    // 2. Remove Tatweel (Kashida)
    result = result.replaceAll(_tatweel, '');

    // 3. Normalize Hamzas
    result = result
        .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
        .replaceAll(RegExp(r'[ؤ]'), 'و')
        .replaceAll(RegExp(r'[ئ]'), 'ي');

    // 4. Normalize Alif Maqsura to Yaa
    result = result.replaceAll('ى', 'ي');

    // 5. Normalize Taa Marbuta to Haa
    result = result.replaceAll('ة', 'ه');

    // 6. Whitespace cleanup
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result.toLowerCase();
  }

  /// Checks whether [query] matches [target] using normalized Arabic comparison
  static bool matches(String query, String target) {
    if (query.trim().isEmpty) return true;
    final normQuery = normalize(query);
    final normTarget = normalize(target);
    return normTarget.contains(normQuery);
  }
}
