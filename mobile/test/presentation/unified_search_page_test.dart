// Unified Search Page Tests — Phase 5.5
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/application/use_cases/debt_use_cases.dart';
import 'package:mouin/application/use_cases/item_use_cases.dart';
import 'package:mouin/application/use_cases/task_use_cases.dart';
import 'package:mouin/core/utils/uuidv7.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/entities/debt.dart';
import 'package:mouin/domain/value_objects/money.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';
import 'package:mouin/infrastructure/repositories/local_item_repository.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'package:mouin/presentation/bloc/sync_bloc.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';
import 'package:mouin/presentation/pages/search/search_categories.dart';
import 'package:mouin/presentation/pages/search/search_result_model.dart';
import 'package:mouin/presentation/pages/search/unified_search_page.dart';
import 'package:mouin/infrastructure/sync/sync_engine.dart';
import 'package:mouin/infrastructure/network/remote_sync_api.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: child,
    ),
  );
}

void main() {
  late LocalSqliteDb db;
  late LocalItemRepository itemRepo;
  late LocalDebtRepository debtRepo;
  late LocalOutboxRepository outboxRepo;
  late ItemUseCases itemUseCases;
  late TaskUseCases taskUseCases;
  late DebtUseCases debtUseCases;
  late TaskBloc taskBloc;
  late DebtBloc debtBloc;
  late SyncBloc syncBloc;

  const workspaceId = '018e3a2b-0002-7000-8000-000000000002';

  setUp(() {
    db = LocalSqliteDb();
    itemRepo = LocalItemRepository(db);
    debtRepo = LocalDebtRepository(db);
    outboxRepo = LocalOutboxRepository(db);
    itemUseCases = ItemUseCases(itemRepository: itemRepo, outboxRepository: outboxRepo);
    taskUseCases = TaskUseCases(itemRepository: itemRepo, outboxRepository: outboxRepo);
    debtUseCases = DebtUseCases(debtRepository: debtRepo, outboxRepository: outboxRepo);
    taskBloc = TaskBloc(useCases: taskUseCases, repository: itemRepo);
    debtBloc = DebtBloc(useCases: debtUseCases, repository: debtRepo);
    final syncEngine = SyncEngine(
      localDb: db,
      outboxRepository: outboxRepo,
      itemRepository: itemRepo,
      remoteSyncApi: RemoteSyncApi(),
    );
    syncBloc = SyncBloc(syncEngine: syncEngine);
  });

  tearDown(() {
    taskBloc.dispose();
    debtBloc.dispose();
    syncBloc.dispose();
  });

  group('UnifiedSearchPage Widget Tests', () {
    testWidgets('renders initial state with search prompt and quick categories', (tester) async {
      await tester.pumpWidget(_wrap(
        UnifiedSearchPage(
          taskBloc: taskBloc,
          debtBloc: debtBloc,
          syncBloc: syncBloc,
          workspaceId: workspaceId,
          itemUseCases: itemUseCases,
        ),
      ));

      expect(find.text('البحث الموحد'), findsOneWidget);
      expect(find.text('ابحث في مُعين'), findsOneWidget);
      expect(find.text('بحث سريع حسب التصنيف'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('search field is present and RTL', (tester) async {
      await tester.pumpWidget(_wrap(
        UnifiedSearchPage(
          taskBloc: taskBloc,
          debtBloc: debtBloc,
          syncBloc: syncBloc,
          workspaceId: workspaceId,
          itemUseCases: itemUseCases,
        ),
      ));

      final directions = tester
          .widgetList<Directionality>(find.byType(Directionality))
          .map((d) => d.textDirection)
          .toList();
      expect(directions.contains(TextDirection.rtl), isTrue);
    });

    testWidgets('shows empty state when no results match', (tester) async {
      await tester.pumpWidget(_wrap(
        UnifiedSearchPage(
          taskBloc: taskBloc,
          debtBloc: debtBloc,
          syncBloc: syncBloc,
          workspaceId: workspaceId,
          itemUseCases: itemUseCases,
        ),
      ));

      final fieldFinder = find.byType(TextField);
      await tester.enterText(fieldFinder, 'ZZZNOFOUNDXXX');
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('لم نجد نتائج مطابقة'), findsOneWidget);
      expect(find.text('مسح البحث'), findsOneWidget);
    });

    testWidgets('search results appear when items match', (tester) async {
      final item = Item.createTask(
        id: UuidV7.generate(),
        workspaceId: workspaceId,
        title: 'مراجعة التقرير الشهري',
        priority: Priority.high,
      );
      await itemRepo.save(item);

      await tester.pumpWidget(_wrap(
        UnifiedSearchPage(
          taskBloc: taskBloc,
          debtBloc: debtBloc,
          syncBloc: syncBloc,
          workspaceId: workspaceId,
          itemUseCases: itemUseCases,
        ),
      ));

      final fieldFinder = find.byType(TextField);
      await tester.enterText(fieldFinder, 'تقرير');
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('مراجعة التقرير الشهري'), findsOneWidget);
    });

    testWidgets('searches documents, notes, and shopping items properly', (tester) async {
      final doc = Item.createDocument(
        id: UuidV7.generate(),
        workspaceId: workspaceId,
        title: 'جواز السفر اليمني',
        documentType: 'passport',
      );
      final note = Item.createNote(
        id: UuidV7.generate(),
        workspaceId: workspaceId,
        title: 'أفكار مشروع مُعين',
        content: 'ملاحظات وتفاصيل',
      );
      final shopping = Item.createUnified(
        id: UuidV7.generate(),
        workspaceId: workspaceId,
        itemType: ItemType.shopping,
        title: 'مشتريات البقالة الأسبوعية',
      );

      await itemRepo.save(doc);
      await itemRepo.save(note);
      await itemRepo.save(shopping);

      await tester.pumpWidget(_wrap(
        UnifiedSearchPage(
          taskBloc: taskBloc,
          debtBloc: debtBloc,
          syncBloc: syncBloc,
          workspaceId: workspaceId,
          itemUseCases: itemUseCases,
        ),
      ));

      final fieldFinder = find.byType(TextField);
      await tester.enterText(fieldFinder, 'م');
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('جواز السفر اليمني'), findsOneWidget);
      expect(find.text('أفكار مشروع مُعين'), findsOneWidget);
      expect(find.text('مشتريات البقالة الأسبوعية'), findsOneWidget);
    });

    testWidgets('searches debts from debtBloc loaded state', (tester) async {
      final debt = Debt(
        id: UuidV7.generate(),
        workspaceId: workspaceId,
        personId: 'سالم المحضار',
        debtType: DebtType.receivable,
        totalAmount: Money.fromDecimalString('50000', currency: 'YER'),
        transactions: [
          DebtTransaction(
            id: UuidV7.generate(),
            debtId: 'd1',
            workspaceId: workspaceId,
            transactionType: DebtTransactionType.payment,
            amount: Money.fromDecimalString('50000', currency: 'YER'),
            transactionDate: DateTime.now(),
            notes: 'دفعة أولى',
            createdAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await debtRepo.save(debt);
      await debtBloc.loadDebts(workspaceId);

      await tester.pumpWidget(_wrap(
        UnifiedSearchPage(
          taskBloc: taskBloc,
          debtBloc: debtBloc,
          syncBloc: syncBloc,
          workspaceId: workspaceId,
          itemUseCases: itemUseCases,
        ),
      ));

      final fieldFinder = find.byType(TextField);
      await tester.enterText(fieldFinder, 'سالم');
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('سالم المحضار'), findsOneWidget);
    });

    testWidgets('category chips appear after search and filter properly', (tester) async {
      final task = Item.createTask(
        id: UuidV7.generate(),
        workspaceId: workspaceId,
        title: 'مهمة خاصة',
      );
      final note = Item.createNote(
        id: UuidV7.generate(),
        workspaceId: workspaceId,
        title: 'ملاحظة خاصة',
        content: 'محتوى',
      );
      await itemRepo.save(task);
      await itemRepo.save(note);

      await tester.pumpWidget(_wrap(
        UnifiedSearchPage(
          taskBloc: taskBloc,
          debtBloc: debtBloc,
          syncBloc: syncBloc,
          workspaceId: workspaceId,
          itemUseCases: itemUseCases,
        ),
      ));

      final fieldFinder = find.byType(TextField);
      await tester.enterText(fieldFinder, 'خاصة');
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.widgetWithText(FilterChip, 'كل النتائج'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'المهام'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'الملاحظات'), findsOneWidget);
      expect(find.text('مهمة خاصة'), findsOneWidget);
      expect(find.text('ملاحظة خاصة'), findsOneWidget);

      // Tap 'المهام' chip
      await tester.tap(find.widgetWithText(FilterChip, 'المهام'));
      await tester.pumpAndSettle();

      expect(find.text('مهمة خاصة'), findsOneWidget);
      expect(find.text('ملاحظة خاصة'), findsNothing);
    });

    testWidgets('clear search resets back to initial prompt', (tester) async {
      await tester.pumpWidget(_wrap(
        UnifiedSearchPage(
          taskBloc: taskBloc,
          debtBloc: debtBloc,
          syncBloc: syncBloc,
          workspaceId: workspaceId,
          itemUseCases: itemUseCases,
        ),
      ));

      final fieldFinder = find.byType(TextField);
      await tester.enterText(fieldFinder, 'بحث عشوائي');
      await tester.pump(const Duration(milliseconds: 400));

      // Tap clear search button on empty state
      final clearAction = find.text('مسح البحث');
      if (clearAction.evaluate().isNotEmpty) {
        await tester.tap(clearAction);
        await tester.pumpAndSettle();
      }

      expect(find.text('ابحث في مُعين'), findsOneWidget);
    });

    testWidgets('back button is present with tooltip', (tester) async {
      await tester.pumpWidget(_wrap(
        UnifiedSearchPage(
          taskBloc: taskBloc,
          debtBloc: debtBloc,
          syncBloc: syncBloc,
          workspaceId: workspaceId,
          itemUseCases: itemUseCases,
        ),
      ));

      expect(find.byTooltip('رجوع'), findsOneWidget);
    });
  });

  group('SearchResultModel Tests', () {
    test('fromItem maps task to tasks category', () {
      final item = Item.createTask(
        id: '1',
        workspaceId: workspaceId,
        title: 'Test Task',
      );
      final result = SearchResultModel.fromItem(item);
      expect(result, isNotNull);
      expect(result!.category, SearchCategory.tasks);
      expect(result.title, 'Test Task');
    });

    test('fromItem maps note to notes category', () {
      final item = Item.createNote(
        id: '2',
        workspaceId: workspaceId,
        title: 'Test Note',
        content: 'Test content',
      );
      final result = SearchResultModel.fromItem(item);
      expect(result, isNotNull);
      expect(result!.category, SearchCategory.notes);
    });

    test('fromItem maps document to documents category', () {
      final item = Item.createDocument(
        id: '3',
        workspaceId: workspaceId,
        title: 'Test Document',
        documentType: 'passport',
      );
      final result = SearchResultModel.fromItem(item);
      expect(result, isNotNull);
      expect(result!.category, SearchCategory.documents);
    });

    test('fromItem maps shopping list to shopping category', () {
      final item = Item.createUnified(
        id: '4',
        workspaceId: workspaceId,
        itemType: ItemType.shopping,
        title: 'Shopping Checklist',
      );
      final result = SearchResultModel.fromItem(item);
      expect(result, isNotNull);
      expect(result!.category, SearchCategory.shopping);
    });
  });

  group('SearchCategory Tests', () {
    test('all categories have Arabic labels', () {
      for (final c in SearchCategory.values) {
        expect(c.label.isNotEmpty, isTrue);
        expect(c.icon, isA<IconData>());
      }
    });

    test('item type keyword mapping is correct', () {
      expect(SearchCategory.tasks.itemTypeKeyword, 'task');
      expect(SearchCategory.notes.itemTypeKeyword, 'note');
      expect(SearchCategory.documents.itemTypeKeyword, 'document');
      expect(SearchCategory.shopping.itemTypeKeyword, 'shopping');
      expect(SearchCategory.debts.itemTypeKeyword, isNull);
      expect(SearchCategory.all.itemTypeKeyword, isNull);
    });
  });
}
