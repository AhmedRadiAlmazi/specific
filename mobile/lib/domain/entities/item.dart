// Item Aggregates & Subtype Details — مشروع «مُعين» (Mouin)
import 'package:mouin/domain/value_objects/types.dart';

class TaskDetail {
  final DateTime? dueDate;
  final Priority priority;
  final TaskStatus status;
  final DateTime? completedAt;
  final int? estimatedDurationMinutes;

  TaskDetail({
    this.dueDate,
    this.priority = Priority.medium,
    this.status = TaskStatus.pending,
    this.completedAt,
    this.estimatedDurationMinutes,
  });

  TaskDetail copyWith({
    DateTime? dueDate,
    Priority? priority,
    TaskStatus? status,
    DateTime? completedAt,
    int? estimatedDurationMinutes,
  }) {
    return TaskDetail(
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
    );
  }
}

class AppointmentDetail {
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final String? calendarEventId;

  AppointmentDetail({
    required this.startTime,
    this.endTime,
    this.location,
    this.calendarEventId,
  });
}

class NoteDetail {
  final String contentMarkdown;
  final int? wordCount;

  NoteDetail({
    required this.contentMarkdown,
    this.wordCount,
  });
}

class DocumentDetail {
  final String storagePath;
  final String mimeType;
  final int fileSizeBytes;
  final String? sha256Checksum;

  DocumentDetail({
    required this.storagePath,
    required this.mimeType,
    required this.fileSizeBytes,
    this.sha256Checksum,
  });
}

class ShoppingListItem {
  final String id;
  final String itemName;
  final double quantity;
  final String? unit;
  final bool isChecked;

  ShoppingListItem({
    required this.id,
    required this.itemName,
    this.quantity = 1.0,
    this.unit,
    this.isChecked = false,
  });
}

class ShoppingListDetail {
  final List<ShoppingListItem> items;
  final bool isCompleted;

  ShoppingListDetail({
    List<ShoppingListItem>? items,
    this.isCompleted = false,
  }) : items = items ?? [];
}

class Item {
  final String id;
  final String workspaceId;
  final ItemType itemType;
  final String title;
  final String? summary;
  final PrivacyClassification privacy;
  final String? categoryId;
  final TaskDetail? taskDetail;
  final AppointmentDetail? appointmentDetail;
  final NoteDetail? noteDetail;
  final DocumentDetail? documentDetail;
  final ShoppingListDetail? shoppingListDetail;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int entityVersion;

  Item({
    required this.id,
    required this.workspaceId,
    required this.itemType,
    required this.title,
    this.summary,
    this.privacy = PrivacyClassification.private,
    this.categoryId,
    this.taskDetail,
    this.appointmentDetail,
    this.noteDetail,
    this.documentDetail,
    this.shoppingListDetail,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.entityVersion = 1,
  });

  factory Item.createTask({
    required String id,
    required String workspaceId,
    required String title,
    DateTime? dueDate,
    Priority priority = Priority.medium,
    String? summary,
    String? categoryId,
  }) {
    final now = DateTime.now().toUtc();
    return Item(
      id: id,
      workspaceId: workspaceId,
      itemType: ItemType.task,
      title: title,
      summary: summary,
      categoryId: categoryId,
      taskDetail: TaskDetail(dueDate: dueDate, priority: priority),
      createdAt: now,
      updatedAt: now,
    );
  }

  bool get isDeleted => deletedAt != null;

  Item markDeleted() {
    return Item(
      id: id,
      workspaceId: workspaceId,
      itemType: itemType,
      title: title,
      summary: summary,
      privacy: privacy,
      categoryId: categoryId,
      taskDetail: taskDetail,
      appointmentDetail: appointmentDetail,
      noteDetail: noteDetail,
      documentDetail: documentDetail,
      shoppingListDetail: shoppingListDetail,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
      deletedAt: DateTime.now().toUtc(),
      entityVersion: entityVersion + 1,
    );
  }
}
