import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/core/utils/uuidv7.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';
import 'package:mouin/infrastructure/repositories/local_item_repository.dart';
import 'package:mouin/infrastructure/network/remote_sync_api.dart';
import 'package:mouin/infrastructure/sync/sync_engine.dart';

void main() {
  late LocalSqliteDb db;
  late LocalItemRepository itemRepo;
  late LocalOutboxRepository outboxRepo;
  late RemoteSyncApi remoteApi;
  late SyncEngine syncEngine;

  setUp(() {
    db = LocalSqliteDb();
    itemRepo = LocalItemRepository(db);
    outboxRepo = LocalOutboxRepository(db);
    remoteApi = RemoteSyncApi();
    syncEngine = SyncEngine(
      localDb: db,
      outboxRepository: outboxRepo,
      itemRepository: itemRepo,
      remoteSyncApi: remoteApi,
    );
  });

  group('Infrastructure Local Persistence & Sync Engine', () {
    test('LocalItemRepository stores and searches items with Arabic Normalization', () async {
      final workspaceId = '018e3a2b-0002-7000-8000-000000000002';
      final item = Item.createTask(
        id: UuidV7.generate(),
        workspaceId: workspaceId,
        title: 'شِراءُ كُتُبٍ إسلاميَّة',
      );

      await itemRepo.save(item);

      // Search with different diacritics / Alef / Teh Marbuta form
      final results = await itemRepo.searchArabic(workspaceId, 'شراء كتب اسلاميه');
      expect(results.isSuccess, isTrue);
      expect(results.value.length, equals(1));
      expect(results.value.first.id, equals(item.id));
    });

    test('SyncEngine push sends outbox operations and clears them upon ACK', () async {
      final workspaceId = '018e3a2b-0002-7000-8000-000000000002';
      final opId = UuidV7.generate();
      await outboxRepo.enqueue(
        operationId: opId,
        entityType: 'item',
        entityId: UuidV7.generate(),
        operation: 'insert',
        payload: {'title': 'اختبار'},
      );

      final pushRes = await syncEngine.push(workspaceId);
      expect(pushRes.isSuccess, isTrue);
      expect(pushRes.value, equals(1));

      final pending = await outboxRepo.getPendingOperations();
      expect(pending.value.isEmpty, isTrue);
    });

    test('SyncEngine bootstrap downloads snapshot items and advances sequence cursor', () async {
      final workspaceId = '018e3a2b-0002-7000-8000-000000000002';
      final res = await syncEngine.bootstrap(workspaceId);
      expect(res.isSuccess, isTrue);
      expect(db.syncState[workspaceId], equals(1));
    });
  });
}
