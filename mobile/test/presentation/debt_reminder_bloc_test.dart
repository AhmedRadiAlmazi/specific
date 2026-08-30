import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/application/use_cases/debt_use_cases.dart';
import 'package:mouin/application/use_cases/reminder_use_cases.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';
import 'package:mouin/infrastructure/repositories/local_item_repository.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'package:mouin/presentation/bloc/reminder_bloc.dart';

void main() {
  late LocalSqliteDb db;
  late LocalDebtRepository debtRepo;
  late LocalReminderRepository reminderRepo;
  late LocalOutboxRepository outboxRepo;
  late DebtUseCases debtUseCases;
  late ReminderUseCases reminderUseCases;
  late DebtBloc debtBloc;
  late ReminderBloc reminderBloc;

  setUp(() {
    db = LocalSqliteDb();
    debtRepo = LocalDebtRepository(db);
    reminderRepo = LocalReminderRepository(db);
    outboxRepo = LocalOutboxRepository(db);
    debtUseCases = DebtUseCases(debtRepository: debtRepo, outboxRepository: outboxRepo);
    reminderUseCases = ReminderUseCases(reminderRepository: reminderRepo, outboxRepository: outboxRepo);
    debtBloc = DebtBloc(useCases: debtUseCases, repository: debtRepo);
    reminderBloc = ReminderBloc(useCases: reminderUseCases, repository: reminderRepo);
  });

  tearDown(() {
    debtBloc.dispose();
    reminderBloc.dispose();
  });

  group('DebtBloc & ReminderBloc Presentation Tests', () {
    test('DebtBloc loads empty state when no debts exist', () async {
      await debtBloc.loadDebts('018e3a2b-0002-7000-8000-000000000002');
      expect(debtBloc.currentState, isA<DebtEmpty>());
    });

    test('DebtBloc creates debt and reloads into DebtLoaded', () async {
      final workspaceId = '018e3a2b-0002-7000-8000-000000000002';
      await debtBloc.createDebt(
        workspaceId,
        'خالد المنصوري',
        DebtType.payable,
        Money.fromDecimalString('7500.00'),
      );

      expect(debtBloc.currentState, isA<DebtLoaded>());
      final loaded = debtBloc.currentState as DebtLoaded;
      expect(loaded.debts.length, equals(1));
      expect(loaded.debts.first.personId, equals('خالد المنصوري'));
      expect(loaded.debts.first.totalAmount.toDecimalString(), equals('7500.00'));
    });

    test('ReminderBloc creates reminder rule and emits ReminderSaved', () async {
      final workspaceId = '018e3a2b-0002-7000-8000-000000000002';
      await reminderBloc.createRule(
        workspaceId,
        '018e3a2b-0001-7000-8000-000000000001',
        ReminderTriggerType.relative,
        offsetMinutes: 15,
      );

      expect(reminderBloc.currentState, isA<ReminderSaved>());
      final saved = reminderBloc.currentState as ReminderSaved;
      expect(saved.rule.offsetMinutes, equals(15));
      expect(saved.rule.isActive, isTrue);
    });
  });
}
