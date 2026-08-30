// Task BLoC / State Management — مشروع «مُعين» (Mouin)
import 'dart:async';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/repositories/i_item_repository.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/application/commands/item_commands.dart';
import 'package:mouin/application/use_cases/task_use_cases.dart';

abstract class TaskState {}

class TaskInitial extends TaskState {}
class TaskLoading extends TaskState {}
class TaskEmpty extends TaskState {}
class TaskLoaded extends TaskState {
  final List<Item> tasks;
  TaskLoaded(this.tasks);
}
class TaskError extends TaskState {
  final String message;
  TaskError(this.message);
}

class TaskBloc {
  final TaskUseCases useCases;
  final IItemRepository repository;

  final _stateController = StreamController<TaskState>.broadcast();
  Stream<TaskState> get state => _stateController.stream;
  TaskState _currentState = TaskInitial();
  TaskState get currentState => _currentState;

  TaskBloc({required this.useCases, required this.repository});

  void _emit(TaskState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  Future<void> loadTasks(String workspaceId) async {
    _emit(TaskLoading());
    final res = await repository.listByWorkspace(workspaceId);
    if (res.isSuccess) {
      final tasks = res.value.where((i) => !i.isDeleted).toList();
      if (tasks.isEmpty) {
        _emit(TaskEmpty());
      } else {
        _emit(TaskLoaded(tasks));
      }
    } else {
      _emit(TaskError(res.failure.message));
    }
  }

  Future<void> createTask(String workspaceId, String title, {Priority priority = Priority.medium, DateTime? dueDate}) async {
    final cmd = CreateTaskCommand(workspaceId: workspaceId, title: title, priority: priority, dueDate: dueDate);
    final res = await useCases.createTask(cmd);
    if (res.isSuccess) {
      await loadTasks(workspaceId);
    } else {
      _emit(TaskError(res.failure.message));
    }
  }

  Future<void> completeTask(String workspaceId, String itemId) async {
    final cmd = CompleteTaskCommand(workspaceId: workspaceId, itemId: itemId);
    final res = await useCases.completeTask(cmd);
    if (res.isSuccess) {
      await loadTasks(workspaceId);
    } else {
      _emit(TaskError(res.failure.message));
    }
  }

  Future<void> deleteTask(String workspaceId, String itemId) async {
    final cmd = SoftDeleteItemCommand(workspaceId: workspaceId, itemId: itemId);
    final res = await useCases.softDelete(cmd);
    if (res.isSuccess) {
      await loadTasks(workspaceId);
    } else {
      _emit(TaskError(res.failure.message));
    }
  }

  Future<void> searchTasks(String workspaceId, String query) async {
    if (query.trim().isEmpty) {
      await loadTasks(workspaceId);
      return;
    }
    _emit(TaskLoading());
    final res = await repository.searchArabic(workspaceId, query);
    if (res.isSuccess) {
      final tasks = res.value.where((i) => !i.isDeleted).toList();
      if (tasks.isEmpty) {
        _emit(TaskEmpty());
      } else {
        _emit(TaskLoaded(tasks));
      }
    } else {
      _emit(TaskError(res.failure.message));
    }
  }

  void dispose() {
    _stateController.close();
  }
}
