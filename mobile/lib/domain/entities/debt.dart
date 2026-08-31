// Debt & Debt Transaction Aggregate — مشروع «مُعين» (Mouin)
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';

class DebtTransaction {
  final String id;
  final String debtId;
  final String workspaceId;
  final DebtTransactionType transactionType;
  final Money amount;
  final DateTime transactionDate;
  final String? notes;
  final String? referenceTransactionId;
  final DateTime createdAt;

  DebtTransaction({
    required this.id,
    required this.debtId,
    required this.workspaceId,
    required this.transactionType,
    required this.amount,
    required this.transactionDate,
    this.notes,
    this.referenceTransactionId,
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int entityVersion;

  Debt({
    required this.id,
    required this.workspaceId,
    required this.personId,
    required this.debtType,
    required this.totalAmount,
    this.status = DebtStatus.active,
    this.dueDate,
    List<DebtTransaction>? transactions,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.entityVersion = 1,
  }) : transactions = transactions ?? [];

  Money calculateRemainingAmount() {
    var paid = Money.zero(currency: totalAmount.currency);
    for (final tx in transactions) {
      if (tx.transactionType == DebtTransactionType.payment) {
        paid = paid.add(tx.amount);
      } else if (tx.transactionType == DebtTransactionType.reversal) {
        paid = paid.subtract(tx.amount);
      }
    }
    return totalAmount.subtract(paid);
  }

  bool isSettled() {
    return status == DebtStatus.settled || calculateRemainingAmount().minorUnits <= BigInt.zero;
  }
}
