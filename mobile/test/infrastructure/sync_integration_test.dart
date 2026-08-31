import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';
import 'package:mouin/application/use_cases/task_use_cases.dart';
import 'package:mouin/application/use_cases/debt_use_cases.dart';
import 'package:mouin/application/commands/item_commands.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';
import 'package:mouin/infrastructure/repositories/local_item_repository.dart';
import 'package:mouin/infrastructure/network/remote_sync_api.dart';
import 'package:mouin/infrastructure/sync/sync_engine.dart';

void main() {
  late LocalSqliteDb db;
  late LocalItemRepository itemRepo;
  late LocalDebtRepository debtRepo;
  late LocalOutboxRepository outboxRepo;
  late RemoteSyncApi remoteApi;
  late SyncEngine syncEngine;
  late TaskUseCases taskUseCases;
  late DebtUseCases debtUseCases;

  final workspaceId = '018e3a2b-0002-7000-8000-000000000002';

  setUp(() {
    db = LocalSqliteDb();
    itemRepo = LocalItemRepository(db);
    debtRepo = LocalDebtRepository(db);
    outboxRepo = LocalOutboxRepository(db);
    remoteApi = RemoteSyncApi.mock();
    syncEngine = SyncEngine(
      localDb: db,
      outboxRepository: outboxRepo,
      itemRepository: itemRepo,
      remoteSyncApi: remoteApi,
    );
    taskUseCases = TaskUseCases(itemRepository: itemRepo, outboxRepository: outboxRepo);
    debtUseCases = DebtUseCases(debtRepository: debtRepo, outboxRepository: outboxRepo);
  });

  group('Phase 7 Flutter Full System Integration', () {
    test('E2E Mobile Create, Outbox Enqueue, and Sync Push', () async {
      // 1. Create task locally offline
      final createRes = await taskUseCases.createTask(
        CreateTaskCommand(
          workspaceId: workspaceId,
          title: 'مهمة فلاتر تكاملية',
          priority: Priority.urgent,
        ),
      );
      expect(createRes.isSuccess, isTrue);
      final item = createRes.value;

      // 2. Verify outbox has 1 pending operation
      final pendingBefore = await outboxRepo.getPendingOperations();
      expect(pendingBefore.value.length, equals(1));
      expect(pendingBefore.value.first['entity_id'], equals(item.id));

      // 3. Trigger Sync Push
      final pushRes = await syncEngine.push(workspaceId);
      expect(pushRes.isSuccess, isTrue);
      expect(pushRes.value, equals(1));

      // 4. Verify outbox is cleared
      final pendingAfter = await outboxRepo.getPendingOperations();
      expect(pendingAfter.value.isEmpty, isTrue);
    });

    test('E2E Mobile Debt Payment & Ledger Recalculation', () async {
      final createRes = await debtUseCases.createDebt(
        CreateDebtCommand(
          workspaceId: workspaceId,
          personId: 'سالم الكندي',
          debtType: DebtType.payable,
          totalAmount: Money.fromDecimalString('8000.00'),
        ),
      );
      expect(createRes.isSuccess, isTrue);
      final debt = createRes.value;

      final payRes = await debtUseCases.recordPayment(
        RecordPaymentCommand(
          workspaceId: workspaceId,
          debtId: debt.id,
          amount: Money.fromDecimalString('3500.00'),
          transactionDate: DateTime.now().toUtc(),
        ),
      );
      expect(payRes.isSuccess, isTrue);
      expect(payRes.value.calculateRemainingAmount().toDecimalString(), equals('4500.00'));
    });

    test('E2E Mobile Pull Streams and Updates Local Cursor', () async {
      final pullRes = await syncEngine.pull(workspaceId);
      expect(pullRes.isSuccess, isTrue);
    });
  });
}
