// Debt BLoC — مشروع «مُعين» (Mouin)
import 'dart:async';
import 'package:mouin/domain/entities/debt.dart';
import 'package:mouin/domain/repositories/i_item_repository.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';
import 'package:mouin/application/commands/item_commands.dart';
import 'package:mouin/application/use_cases/debt_use_cases.dart';

abstract class DebtState {}
class DebtInitial extends DebtState {}
class DebtLoading extends DebtState {}
class DebtEmpty extends DebtState {}
class DebtLoaded extends DebtState {
  final List<Debt> debts;
  DebtLoaded(this.debts);
}
class DebtError extends DebtState {
  final String message;
  DebtError(this.message);
}

class DebtBloc {
  final DebtUseCases useCases;
  final IDebtRepository repository;

  final _stateController = StreamController<DebtState>.broadcast();
  Stream<DebtState> get state => _stateController.stream;
  DebtState _currentState = DebtInitial();
  DebtState get currentState => _currentState;

  DebtBloc({required this.useCases, required this.repository});

  void _emit(DebtState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  Future<void> loadDebts(String workspaceId) async {
    _emit(DebtLoading());
    final res = await repository.listByWorkspace(workspaceId);
    if (res.isSuccess) {
      if (res.value.isEmpty) {
        _emit(DebtEmpty());
      } else {
        _emit(DebtLoaded(res.value));
      }
    } else {
      _emit(DebtError(res.failure.message));
    }
  }

  Future<void> createDebt(
    String workspaceId,
    String personId,
    DebtType debtType,
    Money amount, {
    DateTime? dueDate,
  }) async {
    final cmd = CreateDebtCommand(
      workspaceId: workspaceId,
      personId: personId,
      debtType: debtType,
      totalAmount: amount,
      dueDate: dueDate,
    );
    final res = await useCases.createDebt(cmd);
    if (res.isSuccess) {
      await loadDebts(workspaceId);
    } else {
      _emit(DebtError(res.failure.message));
    }
  }

  Future<void> recordPayment(
    String workspaceId,
    String debtId,
    Money amount,
    DateTime date, {
    String? notes,
  }) async {
    final cmd = RecordPaymentCommand(
      workspaceId: workspaceId,
      debtId: debtId,
      amount: amount,
      transactionDate: date,
      notes: notes,
    );
    final res = await useCases.recordPayment(cmd);
    if (res.isSuccess) {
      await loadDebts(workspaceId);
    } else {
      _emit(DebtError(res.failure.message));
    }
  }

  void dispose() {
    _stateController.close();
  }
}
