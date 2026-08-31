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
  final bool allDay;
  final String timezone;

  AppointmentDetail({
    required this.startTime,
    this.endTime,
    this.location,
    this.calendarEventId,
    this.allDay = false,
    this.timezone = 'Asia/Aden',
  });
}

class NoteDetail {
  final String content;
  final String contentFormat;
  final int? wordCount;

  NoteDetail({
    required this.content,
    this.contentFormat = 'plain_text',
    this.wordCount,
  });
}

class DocumentDetail {
  final String documentType;
  final String? documentNumber;
  final String? issuingAuthority;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? storagePath;
  final String? mimeType;
  final int? fileSizeBytes;

  DocumentDetail({
    required this.documentType,
    this.documentNumber,
    this.issuingAuthority,
    this.issueDate,
    this.expiryDate,
    this.storagePath,
    this.mimeType,
    this.fileSizeBytes,
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

  // 1. Task Factory
  factory Item.createTask({
    required String id,
    required String workspaceId,
    required String title,
    DateTime? dueDate,
    Priority priority = Priority.medium,
    String? summary,
    String? categoryId,
    PrivacyClassification privacy = PrivacyClassification.private,
  }) {
    final now = DateTime.now().toUtc();
    return Item(
      id: id,
      workspaceId: workspaceId,
      itemType: ItemType.task,
      title: title,
      summary: summary,
      categoryId: categoryId,
      privacy: privacy,
      taskDetail: TaskDetail(dueDate: dueDate, priority: priority),
      createdAt: now,
      updatedAt: now,
    );
  }

  // 2. Note Factory
  factory Item.createNote({
    required String id,
    required String workspaceId,
    required String title,
    required String content,
    String contentFormat = 'plain_text',
    String? summary,
    String? categoryId,
    PrivacyClassification privacy = PrivacyClassification.private,
  }) {
    final now = DateTime.now().toUtc();
    return Item(
      id: id,
      workspaceId: workspaceId,
      itemType: ItemType.note,
      title: title,
      summary: summary,
      categoryId: categoryId,
      privacy: privacy,
      noteDetail: NoteDetail(content: content, contentFormat: contentFormat),
      createdAt: now,
      updatedAt: now,
    );
  }

  // 3. Appointment Factory
  factory Item.createAppointment({
    required String id,
    required String workspaceId,
    required String title,
    required DateTime startTime,
    DateTime? endTime,
    String? location,
    bool allDay = false,
    String timezone = 'Asia/Aden',
    String? summary,
    String? categoryId,
    PrivacyClassification privacy = PrivacyClassification.private,
  }) {
    final now = DateTime.now().toUtc();
    return Item(
      id: id,
      workspaceId: workspaceId,
      itemType: ItemType.appointment,
      title: title,
      summary: summary,
      categoryId: categoryId,
      privacy: privacy,
      appointmentDetail: AppointmentDetail(
        startTime: startTime,
        endTime: endTime,
        location: location,
        allDay: allDay,
        timezone: timezone,
      ),
      createdAt: now,
      updatedAt: now,
    );
  }

  // 4. Document Factory
  factory Item.createDocument({
    required String id,
    required String workspaceId,
    required String title,
    required String documentType,
    String? documentNumber,
    String? issuingAuthority,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? summary,
    String? categoryId,
    PrivacyClassification privacy = PrivacyClassification.private,
  }) {
    final now = DateTime.now().toUtc();
    return Item(
      id: id,
      workspaceId: workspaceId,
      itemType: ItemType.document,
      title: title,
      summary: summary,
      categoryId: categoryId,
      privacy: privacy,
      documentDetail: DocumentDetail(
        documentType: documentType,
        documentNumber: documentNumber,
        issuingAuthority: issuingAuthority,
        issueDate: issueDate,
        expiryDate: expiryDate,
      ),
      createdAt: now,
      updatedAt: now,
    );
  }

  // 5. Generic Unified Item Factory
  factory Item.createUnified({
    required String id,
    required String workspaceId,
    required ItemType itemType,
    required String title,
    String? summary,
    String? categoryId,
    PrivacyClassification privacy = PrivacyClassification.private,
    TaskDetail? taskDetail,
    NoteDetail? noteDetail,
    AppointmentDetail? appointmentDetail,
    DocumentDetail? documentDetail,
    ShoppingListDetail? shoppingListDetail,
  }) {
    final now = DateTime.now().toUtc();
    return Item(
      id: id,
      workspaceId: workspaceId,
      itemType: itemType,
      title: title,
      summary: summary,
      categoryId: categoryId,
      privacy: privacy,
      taskDetail: taskDetail,
      noteDetail: noteDetail,
      appointmentDetail: appointmentDetail,
      documentDetail: documentDetail,
      shoppingListDetail: shoppingListDetail,
      createdAt: now,
      updatedAt: now,
    );
  }

  bool get isDeleted => deletedAt != null;
  bool get isTask => itemType == ItemType.task;
  bool get isNote => itemType == ItemType.note;
  bool get isAppointment => itemType == ItemType.appointment;
  bool get isDocument => itemType == ItemType.document;
  bool get isDebt => itemType == ItemType.debt;
  bool get isShopping => itemType == ItemType.shopping;

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
