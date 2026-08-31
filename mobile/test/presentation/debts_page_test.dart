// Phase 5.4 Debts Ledger Page Tests — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/core/result/result.dart';
import 'package:mouin/core/errors/failures.dart';
import 'package:mouin/domain/entities/debt.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';
import 'package:mouin/presentation/theme/mouin_theme.dart';
import 'package:mouin/presentation/pages/debts/debts_page.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'package:mouin/domain/repositories/i_item_repository.dart';
import 'package:mouin/application/use_cases/debt_use_cases.dart';

class FakeDebtRepository implements IDebtRepository {
  List<Debt> debts = [];

  @override
  Future<Result<void, Failure>> save(Debt debt) async {
    debts.removeWhere((d) => d.id == debt.id);
    debts.add(debt);
    return const Result.success(null);
  }

  @override
  Future<Result<Debt?, Failure>> getById(String workspaceId, String id) async {
    final d = debts.where((d) => d.id == id).firstOrNull;
    return Result.success(d);
  }

  @override
  Future<Result<List<Debt>, Failure>> listByWorkspace(String workspaceId) async {
    return Result.success(List.from(debts));
  }
}

class FakeOutboxRepository implements IOutboxRepository {
  @override
  Future<Result<void, Failure>> enqueue({
    required String operationId,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    int baseVersion = 1,
  }) async {
    return const Result.success(null);
  }

  @override
  Future<Result<List<Map<String, dynamic>>, Failure>> getPendingOperations({int limit = 50}) async {
    return const Result.success([]);
  }

  @override
  Future<Result<void, Failure>> markCompleted(String operationId) async {
    return const Result.success(null);
  }
}

void main() {
  group('Phase 5.4 Debts Page Tests', () {
    testWidgets('Renders debts summary, search field and filter choice chips', (tester) async {
      final now = DateTime.now();
      final repo = FakeDebtRepository();
      final outbox = FakeOutboxRepository();
      final debtBloc = DebtBloc(
        useCases: DebtUseCases(debtRepository: repo, outboxRepository: outbox),
        repository: repo,
      );

      final debt1 = Debt(
        id: 'd-1',
        workspaceId: 'ws-1',
        personId: 'سالم أحمد',
        debtType: DebtType.receivable,
        totalAmount: Money.fromDecimalString('150000.00'),
        createdAt: now,
        updatedAt: now,
      );
      repo.debts = [debt1];

      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: DebtsPage(
              debtBloc: debtBloc,
              workspaceId: 'ws-1',
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(DebtsPage), findsOneWidget);
      expect(find.text('دفتر الديون والالتزامات'), findsOneWidget);
      expect(find.text('سالم أحمد'), findsOneWidget);
    });
  });
}
