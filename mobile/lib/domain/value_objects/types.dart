// Domain Value Types & Enums — مشروع «مُعين» (Mouin)
enum ItemType { task, note, appointment, document, shopping }

enum Priority { low, medium, high, urgent }

enum DebtType { receivable, payable }

enum DebtStatus { active, settled, forgiven, disputed }

enum DebtTransactionType { payment, reversal, adjustment }

enum ReminderTriggerType { absolute, relative, recurring }

enum PrivacyClassification { public, internal, private, restricted, sensitive }

enum TaskStatus { pending, inProgress, completed, cancelled }

extension PriorityExt on Priority {
  String get arabicLabel {
    switch (this) {
      case Priority.urgent: return 'عاجلة جداً';
      case Priority.high: return 'أولوية عالية';
      case Priority.medium: return 'متوسطة';
      case Priority.low: return 'منخفضة';
    }
  }

  int get colorValue {
    switch (this) {
      case Priority.urgent: return 0xFFDC2626;
      case Priority.high: return 0xFFEA580C;
      case Priority.medium: return 0xFF0D9488;
      case Priority.low: return 0xFF64748B;
    }
  }
}
