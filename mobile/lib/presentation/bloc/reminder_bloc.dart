// Reminder BLoC — مشروع «مُعين» (Mouin)
import 'dart:async';
import 'package:mouin/domain/entities/reminder.dart';
import 'package:mouin/domain/repositories/i_item_repository.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/application/commands/item_commands.dart';
import 'package:mouin/application/use_cases/reminder_use_cases.dart';

abstract class ReminderState {}
class ReminderInitial extends ReminderState {}
class ReminderLoading extends ReminderState {}
class ReminderSaved extends ReminderState {
  final ReminderRule rule;
  ReminderSaved(this.rule);
}
class ReminderError extends ReminderState {
  final String message;
  ReminderError(this.message);
}

class ReminderBloc {
  final ReminderUseCases useCases;
  final IReminderRepository repository;

  final _stateController = StreamController<ReminderState>.broadcast();
  Stream<ReminderState> get state => _stateController.stream;
  ReminderState _currentState = ReminderInitial();
  ReminderState get currentState => _currentState;

  ReminderBloc({required this.useCases, required this.repository});

  void _emit(ReminderState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  Future<void> createRule(
    String workspaceId,
    String itemId,
    ReminderTriggerType triggerType, {
    DateTime? triggerTime,
    int? offsetMinutes,
    String? rrule,
  }) async {
    _emit(ReminderLoading());
    final cmd = CreateReminderRuleCommand(
      workspaceId: workspaceId,
      itemId: itemId,
      triggerType: triggerType,
      triggerTime: triggerTime,
      offsetMinutes: offsetMinutes,
      rrule: rrule,
    );
    final res = await useCases.createRule(cmd);
    if (res.isSuccess) {
      _emit(ReminderSaved(res.value));
    } else {
      _emit(ReminderError(res.failure.message));
    }
  }

  void dispose() {
    _stateController.close();
  }
}
