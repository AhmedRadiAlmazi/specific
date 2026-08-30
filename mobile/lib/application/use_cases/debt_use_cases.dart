// Debt Application Use Cases — مشروع «مُعين» (Mouin)
import 'package:mouin/core/result/result.dart';
import 'package:mouin/core/errors/failures.dart';
import 'package:mouin/core/utils/uuidv7.dart';
import 'package:mouin/domain/entities/debt.dart';
import 'package:mouin/domain/repositories/i_item_repository.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/application/commands/item_commands.dart';

class DebtUseCases {
  final IDebtRepository debtRepository;
  final IOutboxRepository outboxRepository;

  DebtUseCases({required this.debtRepository, required this.outboxRepository});

  Future<Result<Debt, Failure>> createDebt(CreateDebtCommand cmd) async {
    final debtId = UuidV7.generate();
    final now = DateTime.now().toUtc();
    final debt = Debt(
      id: debtId,
      workspaceId: cmd.workspaceId,
      personId: cmd.personId,
      debtType: cmd.debtType,
      totalAmount: cmd.totalAmount,
      dueDate: cmd.dueDate,
      createdAt: now,
      updatedAt: now,
    );

    final saveRes = await debtRepository.save(debt);
    if (!saveRes.isSuccess) return Result.failure(saveRes.failure);

    await outboxRepository.enqueue(
      operationId: UuidV7.generate(),
      entityType: 'debt',
      entityId: debtId,
      operation: 'insert',
      payload: {
        'id': debtId,
        'workspace_id': cmd.workspaceId,
        'person_id': cmd.personId,
        'debt_type': cmd.debtType.name,
        'total_amount': cmd.totalAmount.toDecimalString(),
        'currency': cmd.totalAmount.currency,
        'due_date': cmd.dueDate?.toIso8601String(),
      },
    );

    return Result.success(debt);
  }

  Future<Result<Debt, Failure>> recordPayment(RecordPaymentCommand cmd) async {
    final getRes = await debtRepository.getById(cmd.workspaceId, cmd.debtId);
    if (!getRes.isSuccess) return Result.failure(getRes.failure);
    final debt = getRes.value;
    if (debt == null || debt.deletedAt != null) {
      return const Result.failure(NotFoundFailure('Debt not found'));
    }

    final txId = UuidV7.generate();
    final now = DateTime.now().toUtc();
    final tx = DebtTransaction(
      id: txId,
      debtId: debt.id,
      workspaceId: cmd.workspaceId,
      transactionType: DebtTransactionType.payment,
      amount: cmd.amount,
      transactionDate: cmd.transactionDate,
      notes: cmd.notes,
      createdAt: now,
    );

    debt.transactions.add(tx);
    final saveRes = await debtRepository.save(debt);
    if (!saveRes.isSuccess) return Result.failure(saveRes.failure);

    await outboxRepository.enqueue(
      operationId: UuidV7.generate(),
      entityType: 'debt_transaction',
      entityId: txId,
      operation: 'insert',
      payload: {
        'id': txId,
        'debt_id': debt.id,
        'workspace_id': cmd.workspaceId,
        'transaction_type': 'payment',
        'amount': cmd.amount.toDecimalString(),
        'currency': cmd.amount.currency,
        'transaction_date': cmd.transactionDate.toIso8601String(),
        'notes': cmd.notes,
      },
    );

    return Result.success(debt);
  }
}
