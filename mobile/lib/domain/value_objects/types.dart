// Domain Types & Enums — مشروع «مُعين» (Mouin)
enum ItemType { task, appointment, note, document, debt, shopping }
enum PrivacyClassification { public, internal, sensitive, private }
enum Priority { low, medium, high, urgent }
enum TaskStatus { pending, in_progress, completed, cancelled }
enum DebtType { payable, receivable }
enum DebtStatus { active, settled, forgiven, disputed }
enum DebtTransactionType { payment, reversal, adjustment }
enum ReminderTriggerType { relative, absolute, recurring }
enum ReminderStatus { pending, triggered, snoozed, dismissed, cancelled }
enum SyncStatus { idle, syncing, error, requires_bootstrap }
