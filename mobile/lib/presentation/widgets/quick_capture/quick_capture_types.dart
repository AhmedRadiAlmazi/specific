// Quick Capture Types & Enums — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';

enum QuickCaptureType { task, debt, reminder, document, note, shopping }

extension QuickCaptureTypeExt on QuickCaptureType {
  String get label {
    switch (this) {
      case QuickCaptureType.task: return 'مهمة';
      case QuickCaptureType.debt: return 'دين';
      case QuickCaptureType.reminder: return 'تذكير';
      case QuickCaptureType.document: return 'وثيقة';
      case QuickCaptureType.note: return 'ملاحظة';
      case QuickCaptureType.shopping: return 'قائمة';
    }
  }

  IconData get icon {
    switch (this) {
      case QuickCaptureType.task: return Icons.check_circle_outline;
      case QuickCaptureType.debt: return Icons.account_balance_wallet_outlined;
      case QuickCaptureType.reminder: return Icons.alarm;
      case QuickCaptureType.document: return Icons.description_outlined;
      case QuickCaptureType.note: return Icons.note_outlined;
      case QuickCaptureType.shopping: return Icons.checklist;
    }
  }

  String get placeholder {
    switch (this) {
      case QuickCaptureType.task: return 'مثال: إرسال التقرير المالي للمدير غداً 10:00 ص';
      case QuickCaptureType.debt: return 'مثال: لي عند سالم 150000 ريال يمني نهاية الشهر';
      case QuickCaptureType.reminder: return 'مثال: ذكرني بموعد المستشفى بعد غد العصر';
      case QuickCaptureType.document: return 'مثال: تجديد جواز السفر ينتهي في 2027/05/15';
      case QuickCaptureType.note: return 'مثال: رقم حساب البنك أو فكرة مشروع جديدة...';
      case QuickCaptureType.shopping: return 'مثال: حليب، خبز، بيض، جبن، قهوة...';
    }
  }
}
