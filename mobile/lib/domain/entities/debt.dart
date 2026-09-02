// Debt Aggregate — مشروع «مُعين» (Mouin)
import '../value_objects/types.dart';
import '../value_objects/money.dart';

class DebtTransaction {
  final String id;
  final String debtId;
  final String workspaceId;
  final DebtTransactionType transactionType;
  final Money amount;
  final DateTime transactionDate;
  final String? notes;
  final DateTime createdAt;

  DebtTransaction({
    required this.id,
    required this.debtId,
    required this.workspaceId,
    required this.transactionType,
    required this.amount,
    required this.transactionDate,
    this.notes,
    required this.createdAt,
  });
}

class Debt {
  final String id;
  final String workspaceId;
  final String personId;
  final DebtType debtType;
  final Money totalAmount;
  final DebtStatus status;
  final DateTime? dueDate;
  final List<DebtTransaction> transactions;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Debt({
    required this.id,
    required this.workspaceId,
    required this.personId,
    required this.debtType,
    required this.totalAmount,
    this.status = DebtStatus.active,
    this.dueDate,
    List<DebtTransaction>? transactions,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  }) : transactions = transactions ?? [];

  Money calculateRemainingAmount() {
    var remaining = totalAmount;
    for (final tx in transactions) {
      if (tx.transactionType == DebtTransactionType.payment) {
        remaining = remaining.subtract(tx.amount);
      } else if (tx.transactionType == DebtTransactionType.adjustment) {
        remaining = remaining.add(tx.amount);
      }
    }
    return remaining;
  }

  bool isSettled() => status == DebtStatus.settled || calculateRemainingAmount().isZero;

  Debt copyWith({
    String? personId,
    DebtType? debtType,
    Money? totalAmount,
    DebtStatus? status,
    DateTime? dueDate,
    List<DebtTransaction>? transactions,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) {
    return Debt(
      id: id,
      workspaceId: workspaceId,
      personId: personId ?? this.personId,
      debtType: debtType ?? this.debtType,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      transactions: transactions ?? this.transactions,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
    );
  }
}
