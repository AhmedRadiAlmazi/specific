// Quick Capture Domain Types & Suggestion Heuristics — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';

enum QuickCaptureType {
  task,
  debt,
  reminder,
  document,
  note,
  shopping,
}

extension QuickCaptureTypeExt on QuickCaptureType {
  String get label {
    switch (this) {
      case QuickCaptureType.task:
        return 'مهمة';
      case QuickCaptureType.debt:
        return 'دين';
      case QuickCaptureType.reminder:
        return 'تذكير';
      case QuickCaptureType.document:
        return 'وثيقة';
      case QuickCaptureType.note:
        return 'ملاحظة';
      case QuickCaptureType.shopping:
        return 'قائمة';
    }
  }

  IconData get icon {
    switch (this) {
      case QuickCaptureType.task:
        return Icons.check_circle_outline;
      case QuickCaptureType.debt:
        return Icons.account_balance_wallet_outlined;
      case QuickCaptureType.reminder:
        return Icons.alarm;
      case QuickCaptureType.document:
        return Icons.description_outlined;
      case QuickCaptureType.note:
        return Icons.note_outlined;
      case QuickCaptureType.shopping:
        return Icons.checklist;
    }
  }

  String get placeholder {
    switch (this) {
      case QuickCaptureType.task:
        return 'مثال: إرسال التقرير المالي للمدير غداً الساعة 10:00 ص';
      case QuickCaptureType.debt:
        return 'مثال: لي عند سالم 150000 ريال يمني نهاية الشهر';
      case QuickCaptureType.reminder:
        return 'مثال: ذكرني بموعد المستشفى بعد غد العصر';
      case QuickCaptureType.document:
        return 'مثال: تجديد جواز السفر ينتهي في 2027/05/15';
      case QuickCaptureType.note:
        return 'مثال: رقم حساب البنك أو فكرة مشروع جديدة...';
      case QuickCaptureType.shopping:
        return 'مثال: حليب، خبز، بيض، جبن، قهوة...';
    }
  }
}

class QuickCaptureSuggestor {
  static QuickCaptureType suggestType(String text) {
    final lower = text.trim();
    if (lower.isEmpty) return QuickCaptureType.task;

    if (lower.contains('دين') ||
        lower.contains('لي عند') ||
        lower.contains('عليّ ل') ||
        lower.contains('سلف') ||
        lower.contains('سدد') ||
        lower.contains('مبلغ')) {
      return QuickCaptureType.debt;
    }

    if (lower.contains('ذكرني') ||
        lower.contains('تنبيه') ||
        lower.contains('موعد') ||
        lower.contains('الساعة')) {
      return QuickCaptureType.reminder;
    }

    if (lower.contains('جواز') ||
        lower.contains('هوية') ||
        lower.contains('رخصة') ||
        lower.contains('وثيقة') ||
        lower.contains('عقد') ||
        lower.contains('استمارة') ||
        lower.contains('ضمان')) {
      return QuickCaptureType.document;
    }

    if (lower.contains('قائمة') ||
        lower.contains('أغراض') ||
        lower.contains('سوبرماركت') ||
        lower.contains('مشتريات') ||
        lower.contains('سوق')) {
      return QuickCaptureType.shopping;
    }

    if (lower.contains('ملاحظة') ||
        lower.contains('فكرة') ||
        lower.contains('رقم') ||
        lower.contains('عنوان')) {
      return QuickCaptureType.note;
    }

    return QuickCaptureType.task;
  }
}
