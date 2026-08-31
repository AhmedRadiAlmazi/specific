// Search Category Enum — مشروع «مُعين» (Mouin)
// Presentation-only enum used to group unified search results.
import 'package:flutter/material.dart';

enum SearchCategory {
  all,
  tasks,
  debts,
  reminders,
  documents,
  notes,
  shopping;

  String get label {
    switch (this) {
      case SearchCategory.all:
        return 'كل النتائج';
      case SearchCategory.tasks:
        return 'المهام';
      case SearchCategory.debts:
        return 'الديون';
      case SearchCategory.reminders:
        return 'التذكيرات';
      case SearchCategory.documents:
        return 'الوثائق';
      case SearchCategory.notes:
        return 'الملاحظات';
      case SearchCategory.shopping:
        return 'قوائم التسوق';
    }
  }

  String get iconLabel {
    switch (this) {
      case SearchCategory.all:
        return '🔍';
      case SearchCategory.tasks:
        return '✅';
      case SearchCategory.debts:
        return '💰';
      case SearchCategory.reminders:
        return '⏰';
      case SearchCategory.documents:
        return '📄';
      case SearchCategory.notes:
        return '📝';
      case SearchCategory.shopping:
        return '🛒';
    }
  }

  /// Material icon used in category chips
  IconData get icon {
    switch (this) {
      case SearchCategory.all:
        return Icons.search;
      case SearchCategory.tasks:
        return Icons.check_circle_outline;
      case SearchCategory.debts:
        return Icons.account_balance_wallet_outlined;
      case SearchCategory.reminders:
        return Icons.access_time_outlined;
      case SearchCategory.documents:
        return Icons.description_outlined;
      case SearchCategory.notes:
        return Icons.note_outlined;
      case SearchCategory.shopping:
        return Icons.shopping_cart_outlined;
    }
  }

  /// Maps a SearchCategory to a quick item-subtype keyword for filtering
  String? get itemTypeKeyword {
    switch (this) {
      case SearchCategory.tasks:
        return 'task';
      case SearchCategory.notes:
        return 'note';
      case SearchCategory.documents:
        return 'document';
      case SearchCategory.shopping:
        return 'shopping';
      default:
        return null;
    }
  }
}
