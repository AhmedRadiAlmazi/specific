// Task BLoC — مشروع «مُعين» (Mouin)
import 'dart:async';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';

abstract class TaskState {}
class TaskLoading extends TaskState {}
class TaskLoaded extends TaskState {
  final List<Item> tasks;
  TaskLoaded(this.tasks);
}
class TaskError extends TaskState {
  final String message;
  TaskError(this.message);
}

class TaskBloc {
  final LocalSqliteDb localDb;
  final _stateController = StreamController<TaskState>.broadcast();
  TaskState _currentState = TaskLoaded([]);

  TaskBloc({required this.localDb});

  Stream<TaskState> get state => _stateController.stream;
  TaskState get currentState => _currentState;

  void _emit(TaskState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  Future<void> loadTasks(String workspaceId) async {
    final list = localDb.items.values
        .where((i) => i['workspace_id'] == workspaceId)
        .map((i) => Item(
              id: i['id'],
              workspaceId: i['workspace_id'],
              itemType: ItemType.values.firstWhere((t) => t.name == (i['item_type'] ?? 'task'), orElse: () => ItemType.task),
              title: i['title'] ?? '',
              summary: i['summary'],
              priority: Priority.values.firstWhere((p) => p.name == (i['priority'] ?? 'medium'), orElse: () => Priority.medium),
              isCompleted: i['is_completed'] == 1 || i['is_completed'] == true,
              dueDate: i['due_date'] != null ? DateTime.tryParse(i['due_date']) : null,
              voiceFilePath: i['voice_file_path'],
              voiceDurationMs: i['voice_duration_ms'],
              createdAt: DateTime.tryParse(i['created_at'] ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(i['updated_at'] ?? '') ?? DateTime.now(),
            ))
        .toList();
    _emit(TaskLoaded(list));
  }

  Future<void> createTask(
    String workspaceId,
    String title, {
    Priority priority = Priority.medium,
    DateTime? dueDate,
    String? voiceFilePath,
    int? voiceDurationMs,
  }) async {
    final id = 'task_${DateTime.now().millisecondsSinceEpoch}';
    localDb.items[id] = {
      'id': id,
      'workspace_id': workspaceId,
      'item_type': 'task',
      'title': title,
      'priority': priority.name,
      'is_completed': 0,
      'due_date': dueDate?.toIso8601String(),
      'voice_file_path': voiceFilePath,
      'voice_duration_ms': voiceDurationMs,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    await loadTasks(workspaceId);
  }

  Future<void> completeTask(String workspaceId, String id) async {
    if (localDb.items.containsKey(id)) {
      final current = localDb.items[id]!['is_completed'];
      localDb.items[id]!['is_completed'] = (current == 1 || current == true) ? 0 : 1;
      await loadTasks(workspaceId);
    }
  }

  Future<void> updateTask(String workspaceId, Item task) async {
    if (localDb.items.containsKey(task.id)) {
      localDb.items[task.id] = {
        'id': task.id,
        'workspace_id': workspaceId,
        'item_type': task.itemType.name,
        'title': task.title,
        'summary': task.summary,
        'priority': task.priority.name,
        'is_completed': task.isCompleted ? 1 : 0,
        'due_date': task.dueDate?.toIso8601String(),
        'voice_file_path': task.voiceFilePath,
        'voice_duration_ms': task.voiceDurationMs,
        'created_at': task.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      await loadTasks(workspaceId);
    }
  }

  Future<void> deleteTask(String workspaceId, String id) async {
    localDb.items.remove(id);
    await loadTasks(workspaceId);
  }

  void dispose() {
    _stateController.close();
  }
}
