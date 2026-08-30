import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/application/use_cases/task_use_cases.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';
import 'package:mouin/infrastructure/repositories/local_item_repository.dart';
import 'package:mouin/infrastructure/network/remote_sync_api.dart';
import 'package:mouin/infrastructure/sync/sync_engine.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';
import 'package:mouin/presentation/bloc/sync_bloc.dart';

void main() {
  late LocalSqliteDb db;
  late LocalItemRepository itemRepo;
  late LocalOutboxRepository outboxRepo;
  late TaskUseCases taskUseCases;
  late TaskBloc taskBloc;
  late SyncEngine syncEngine;
  late SyncBloc syncBloc;

  setUp(() {
    db = LocalSqliteDb();
    itemRepo = LocalItemRepository(db);
    outboxRepo = LocalOutboxRepository(db);
    taskUseCases = TaskUseCases(itemRepository: itemRepo, outboxRepository: outboxRepo);
    taskBloc = TaskBloc(useCases: taskUseCases, repository: itemRepo);
    syncEngine = SyncEngine(
      localDb: db,
      outboxRepository: outboxRepo,
      itemRepository: itemRepo,
      remoteSyncApi: RemoteSyncApi(),
    );
    syncBloc = SyncBloc(syncEngine: syncEngine);
  });

  tearDown(() {
    taskBloc.dispose();
    syncBloc.dispose();
  });

  group('Presentation Layer BLoCs', () {
    test('TaskBloc loads empty state when no tasks exist', () async {
      await taskBloc.loadTasks('018e3a2b-0002-7000-8000-000000000002');
      expect(taskBloc.currentState, isA<TaskEmpty>());
    });

    test('TaskBloc creates task and transitions to TaskLoaded', () async {
      final workspaceId = '018e3a2b-0002-7000-8000-000000000002';
      await taskBloc.createTask(workspaceId, 'مهمة جديدة', priority: Priority.high);

      expect(taskBloc.currentState, isA<TaskLoaded>());
      final loaded = taskBloc.currentState as TaskLoaded;
      expect(loaded.tasks.length, equals(1));
      expect(loaded.tasks.first.title, equals('مهمة جديدة'));
    });

    test('SyncBloc triggers bidirectional synchronization and reaches SyncIdle', () async {
      final workspaceId = '018e3a2b-0002-7000-8000-000000000002';
      await syncBloc.triggerSync(workspaceId);
      expect(syncBloc.currentState, isA<SyncIdle>());
    });
  });
}
