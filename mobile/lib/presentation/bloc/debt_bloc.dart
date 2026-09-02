// Debt BLoC — مشروع «مُعين» (Mouin)
import 'dart:async';
import 'package:mouin/domain/entities/debt.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';

abstract class DebtState {}
class DebtLoading extends DebtState {}
class DebtLoaded extends DebtState {
  final List<Debt> debts;
  DebtLoaded(this.debts);
}
class DebtError extends DebtState {
  final String message;
  DebtError(this.message);
}

class DebtBloc {
  final LocalSqliteDb localDb;
  final _stateController = StreamController<DebtState>.broadcast();
  DebtState _currentState = DebtLoaded([]);

  DebtBloc({required this.localDb});

  Stream<DebtState> get state => _stateController.stream;
  DebtState get currentState => _currentState;

  void _emit(DebtState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  Future<void> loadDebts(String workspaceId) async {
    final list = localDb.debts.values
        .where((d) => d['workspace_id'] == workspaceId)
        .map((d) => Debt(
              id: d['id'],
              workspaceId: d['workspace_id'],
              personId: d['person_id'] ?? 'طرف المعاملة',
              debtType: d['debt_type'] == 'receivable' ? DebtType.receivable : DebtType.payable,
              totalAmount: Money.fromDecimalString(d['total_amount'] ?? '0.00', currency: d['currency'] ?? 'YER'),
              status: DebtStatus.values.firstWhere((s) => s.name == (d['status'] ?? 'active'), orElse: () => DebtStatus.active),
              dueDate: d['due_date'] != null ? DateTime.tryParse(d['due_date']) : null,
              createdAt: DateTime.tryParse(d['created_at'] ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(d['updated_at'] ?? '') ?? DateTime.now(),
            ))
        .toList();
    _emit(DebtLoaded(list));
  }

  Future<void> createDebt(
    String workspaceId,
    String personId,
    DebtType debtType,
    Money amount,
  ) async {
    final id = 'debt_${DateTime.now().millisecondsSinceEpoch}';
    localDb.debts[id] = {
      'id': id,
      'workspace_id': workspaceId,
      'person_id': personId,
      'debt_type': debtType == DebtType.receivable ? 'receivable' : 'payable',
      'total_amount': amount.toDecimalString(),
      'currency': amount.currency,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    await loadDebts(workspaceId);
  }

  Future<void> recordPayment(String workspaceId, String debtId, Money amount, DateTime date, {String? notes}) async {
    if (localDb.debts.containsKey(debtId)) {
      final current = Money.fromDecimalString(localDb.debts[debtId]!['total_amount'] ?? '0.00');
      final remaining = current.subtract(amount);
      if (remaining.minorUnits <= BigInt.zero) {
        localDb.debts[debtId]!['status'] = 'settled';
      }
      localDb.debts[debtId]!['total_amount'] = remaining.toDecimalString();
      await loadDebts(workspaceId);
    }
  }

  void dispose() {
    _stateController.close();
  }
}
