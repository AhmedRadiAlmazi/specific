// Offline Arabic Natural Language Parser — مشروع «مُعين» (Mouin)
import 'package:mouin/core/utils/arabic_search_normalizer.dart';

class ParsedItemProposal {
  final String itemType;
  final String title;
  final DateTime? dueDate;
  final String priority;
  final String? amount;
  final String currency;
  final String? personName;
  final String? debtType;
  final double confidenceScore;

  const ParsedItemProposal({
    required this.itemType,
    required this.title,
    this.dueDate,
    this.priority = 'medium',
    this.amount,
    this.currency = 'YER',
    this.personName,
    this.debtType,
    this.confidenceScore = 0.85,
  });
}

class ArabicTextParser {
  /// Parses raw natural Arabic text and extracts domain entities offline
  static ParsedItemProposal parse(String rawText, {DateTime? referenceTime}) {
    final now = referenceTime ?? DateTime.now();
    final normalized = ArabicSearchNormalizer.normalize(rawText);

    // 1. Item Type
    final itemType = _detectType(normalized);

    // 2. Priority
    final priority = _detectPriority(normalized);

    // 3. Financial Amount & Currency
    final money = _extractMoney(normalized);

    // 4. Debt Direction & Person
    final debtInfo = _extractDebtInfo(normalized);

    // 5. Date and Time
    final dueDate = _extractDateTime(normalized, now);

    return ParsedItemProposal(
      itemType: itemType,
      title: rawText.trim(),
      dueDate: dueDate,
      priority: priority,
      amount: money['amount'],
      currency: money['currency'] ?? 'YER',
      personName: debtInfo['personName'],
      debtType: debtInfo['debtType'],
      confidenceScore: (money['amount'] != null || dueDate != null) ? 0.90 : 0.75,
    );
  }

  static String _detectType(String text) {
    if (text.contains('دين') || text.contains('سلف') || text.contains('سدد') ||
        text.contains('لي عند') || text.contains('علي ل') || text.contains('مبلغ')) {
      return 'debt';
    }
    if (text.contains('شراء') || text.contains('سوق') || text.contains('خضار') ||
        text.contains('فواكه') || text.contains('حليب') || text.contains('قائمه')) {
      return 'shopping';
    }
    if (text.contains('جواز') || text.contains('هويه') || text.contains('رخصه') ||
        text.contains('عقد') || text.contains('وثيقه') || text.contains('شهاده')) {
      return 'document';
    }
    if (text.contains('ذكرني') || text.contains('تنبيه') || text.contains('منبه') ||
        text.contains('موعد') || text.contains('الساعه')) {
      return 'reminder';
    }
    if (text.contains('فكره') || text.contains('ملاحظه') || text.contains('حساب') ||
        text.contains('عنوان') || text.contains('رقم')) {
      return 'note';
    }
    return 'task';
  }

  static String _detectPriority(String text) {
    if (text.contains('عاجل جدا') || text.contains('طارئ') || text.contains('ضروري جدا')) {
      return 'urgent';
    }
    if (text.contains('عاجل') || text.contains('مهم') || text.contains('ضروري') || text.contains('هام')) {
      return 'high';
    }
    if (text.contains('منخفض') || text.contains('غير مهم') || text.contains('وقت لاحق')) {
      return 'low';
    }
    return 'medium';
  }

  static Map<String, String?> _extractMoney(String text) {
    var currency = 'YER';
    if (text.contains('دولار') || text.contains(r'$')) {
      currency = 'USD';
    } else if (text.contains('سعودي') || text.contains('sar')) {
      currency = 'SAR';
    }

    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text);
    return {
      'amount': match?.group(1),
      'currency': currency,
    };
  }

  static Map<String, String?> _extractDebtInfo(String text) {
    var debtType = 'payable';
    String? personName;

    if (text.contains('لي عند') || text.contains('سلفته')) {
      debtType = 'receivable';
    } else if (text.contains('علي ل') || text.contains('استلفت')) {
      debtType = 'payable';
    }

    final words = text.split(RegExp(r'\s+'));
    for (final w in words) {
      if (w.startsWith('ل') && w.length > 2) {
        final stem = w.substring(1);
        if (!['شراء', 'دفع', 'سداد', 'تذكير', 'غدا', 'اليوم', 'مواد', 'المواد', 'المستشفي', 'العمل'].contains(stem)) {
          personName = stem;
          break;
        }
      } else if (['من', 'عند', 'مع'].contains(w)) {
        final idx = words.indexOf(w);
        if (idx + 1 < words.length) {
          final candidate = words[idx + 1];
          if (!['شراء', 'دفع', 'سداد', 'تذكير', 'غدا', 'اليوم'].contains(candidate)) {
            personName = candidate;
            break;
          }
        }
      }
    }

    return {
      'personName': personName,
      'debtType': debtType,
    };
  }

  static DateTime? _extractDateTime(String text, DateTime now) {
    var hour = 9;
    var minute = 0;

    final timeMatch = RegExp(r'الساعه\s+(\d{1,2})(?::(\d{2}))?\s*(صباحا|مساء|ص|م)?').firstMatch(text);
    if (timeMatch != null) {
      var h = int.parse(timeMatch.group(1)!);
      final m = timeMatch.group(2) != null ? int.parse(timeMatch.group(2)!) : 0;
      final period = timeMatch.group(3);
      if ((period == 'مساء' || period == 'م') && h < 12) {
        h += 12;
      } else if ((period == 'صباحا' || period == 'ص') && h == 12) {
        h = 0;
      }
      hour = h;
      minute = m;
    }

    if (text.contains('غدا') || text.contains('بكره')) {
      final target = now.add(const Duration(days: 1));
      return DateTime(target.year, target.month, target.day, hour, minute);
    } else if (text.contains('بعد غد')) {
      final target = now.add(const Duration(days: 2));
      return DateTime(target.year, target.month, target.day, hour, minute);
    } else if (text.contains('اليوم')) {
      return DateTime(now.year, now.month, now.day, hour, minute);
    } else if (text.contains('بعد ساعتين')) {
      return now.add(const Duration(hours: 2));
    } else if (text.contains('بعد ساعه')) {
      return now.add(const Duration(hours: 1));
    }

    return null;
  }
}
