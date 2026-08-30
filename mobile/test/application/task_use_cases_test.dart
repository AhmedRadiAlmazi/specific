import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/application/commands/item_commands.dart';
import 'package:mouin/application/use_cases/task_use_cases.dart';
import 'package:mouin/application/use_cases/debt_use_cases.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';
import 'package:mouin/infrastructure/repositories/local_item_repository.dart';

void main() {
  late LocalSqliteDb db;
  late LocalItemRepository itemRepo;
  late LocalDebtRepository debtRepo;
  late LocalOutboxRepository outboxRepo;
  late TaskUseCases taskUseCases;
  late DebtUseCases debtUseCases;

  setUp(() {
    db = LocalSqliteDb();
    itemRepo = LocalItemRepository(db);
    debtRepo = LocalDebtRepository(db);
    outboxRepo = LocalOutboxRepository(db);
    taskUseCases = TaskUseCases(itemRepository: itemRepo, outboxRepository: outboxRepo);
    debtUseCases = DebtUseCases(debtRepository: debtRepo, outboxRepository: outboxRepo);
  });

  group('Application Use Cases & Outbox Atomicity', () {
    test('createTask saves locally and enqueues Outbox insert operation', () async {
      final res = await taskUseCases.createTask(
        CreateTaskCommand(
          workspaceId: '018e3a2b-0002-7000-8000-000000000002',
          title: 'تصميم الواجهة الأمامية',
          priority: Priority.urgent,
        ),
      );

      expect(res.isSuccess, isTrue);
      final item = res.value;
      expect(db.items.containsKey(item.id), isTrue);

      final pendingOutbox = await outboxRepo.getPendingOperations();
      expect(pendingOutbox.value.length, equals(1));
      expect(pendingOutbox.value.first['entity_type'], equals('item'));
      expect(pendingOutbox.value.first['operation'], equals('insert'));
    });

    test('completeTask updates entity version and enqueues Outbox update', () async {
      final createRes = await taskUseCases.createTask(
        CreateTaskCommand(
          workspaceId: '018e3a2b-0002-7000-8000-000000000002',
          title: 'مراجعة الكود',
        ),
      );
      final item = createRes.value;

      final completeRes = await taskUseCases.completeTask(
        CompleteTaskCommand(
          workspaceId: '018e3a2b-0002-7000-8000-000000000002',
          itemId: item.id,
        ),
      );

      expect(completeRes.isSuccess, isTrue);
      expect(completeRes.value.entityVersion, equals(2));
      expect(completeRes.value.taskDetail?.status, equals(TaskStatus.completed));
    });

    test('createDebt and recordPayment updates balance and outbox', () async {
      final debtRes = await debtUseCases.createDebt(
        CreateDebtCommand(
          workspaceId: '018e3a2b-0002-7000-8000-000000000002',
          personId: 'محمد أحمد',
          debtType: DebtType.receivable,
          totalAmount: Money.fromDecimalString('5000.00'),
        ),
      );

      expect(debtRes.isSuccess, isTrue);
      final debt = debtRes.value;

      final payRes = await debtUseCases.recordPayment(
        RecordPaymentCommand(
          workspaceId: '018e3a2b-0002-7000-8000-000000000002',
          debtId: debt.id,
          amount: Money.fromDecimalString('2000.00'),
          transactionDate: DateTime.now().toUtc(),
        ),
      );

      expect(payRes.isSuccess, isTrue);
      expect(payRes.value.calculateRemainingAmount().toDecimalString(), equals('3000.00'));
    });
  });
}
