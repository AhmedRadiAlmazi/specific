// Item Aggregate & Subtypes — مشروع «مُعين» (Mouin)
import '../value_objects/types.dart';

class TaskDetail {
  final Priority priority;
  final DateTime? dueDate;
  final TaskStatus status;
  final DateTime? completedAt;

  const TaskDetail({
    this.priority = Priority.medium,
    this.dueDate,
    this.status = TaskStatus.pending,
    this.completedAt,
  });

  TaskDetail copyWith({
    Priority? priority,
    DateTime? dueDate,
    TaskStatus? status,
    DateTime? completedAt,
  }) {
    return TaskDetail(
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class NoteDetail {
  final String content;
  final String contentFormat;

  const NoteDetail({
    required this.content,
    this.contentFormat = 'plain_text',
  });

  NoteDetail copyWith({
    String? content,
    String? contentFormat,
  }) {
    return NoteDetail(
      content: content ?? this.content,
      contentFormat: contentFormat ?? this.contentFormat,
    );
  }
}

class AppointmentDetail {
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final bool allDay;
  final String? timezone;

  const AppointmentDetail({
    required this.startTime,
    this.endTime,
    this.location,
    this.allDay = false,
    this.timezone,
  });

  AppointmentDetail copyWith({
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    bool? allDay,
    String? timezone,
  }) {
    return AppointmentDetail(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      allDay: allDay ?? this.allDay,
      timezone: timezone ?? this.timezone,
    );
  }
}

class DocumentDetail {
  final String? documentType;
  final String? documentNumber;
  final String? issuingAuthority;
  final DateTime? issueDate;
  final DateTime? expiryDate;

  const DocumentDetail({
    this.documentType,
    this.documentNumber,
    this.issuingAuthority,
    this.issueDate,
    this.expiryDate,
  });

  DocumentDetail copyWith({
    String? documentType,
    String? documentNumber,
    String? issuingAuthority,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) {
    return DocumentDetail(
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}

class ShoppingListDetail {
  final List<dynamic> items;

  const ShoppingListDetail({
    this.items = const [],
  });

  ShoppingListDetail copyWith({
    List<dynamic>? items,
  }) {
    return ShoppingListDetail(
      items: items ?? this.items,
    );
  }
}

class Item {
  final String id;
  final String workspaceId;
  final ItemType itemType;
  final String title;
  final String? summary;
  final PrivacyClassification? privacy;
  final String? categoryId;
  final String? voiceFilePath;
  final int? voiceDurationMs;
  final TaskDetail? taskDetail;
  final NoteDetail? noteDetail;
  final AppointmentDetail? appointmentDetail;
  final DocumentDetail? documentDetail;
  final ShoppingListDetail? shoppingListDetail;
  final int entityVersion;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.workspaceId,
    required this.itemType,
    required this.title,
    this.summary,
    this.privacy,
    this.categoryId,
    this.voiceFilePath,
    this.voiceDurationMs,
    TaskDetail? taskDetail,
    Priority? priority,
    bool? isCompleted,
    DateTime? dueDate,
    this.noteDetail,
    this.appointmentDetail,
    this.documentDetail,
    this.shoppingListDetail,
    this.entityVersion = 1,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  }) : taskDetail = taskDetail ??
            (itemType == ItemType.task || priority != null || isCompleted != null || dueDate != null
                ? TaskDetail(
                    priority: priority ?? Priority.medium,
                    dueDate: dueDate,
                    status: (isCompleted ?? false) ? TaskStatus.completed : TaskStatus.pending,
                  )
                : null);

  Priority get priority => taskDetail?.priority ?? Priority.medium;
  bool get isCompleted => taskDetail?.status == TaskStatus.completed;
  DateTime? get dueDate => taskDetail?.dueDate;
  bool get isDeleted => deletedAt != null;

  Item markDeleted({DateTime? at}) {
    final now = at ?? DateTime.now().toUtc();
    return copyWith(
      deletedAt: now,
      updatedAt: now,
      entityVersion: entityVersion + 1,
    );
  }

  factory Item.createTask({
    required String id,
    required String workspaceId,
    required String title,
    DateTime? dueDate,
    Priority priority = Priority.medium,
    String? summary,
    String? categoryId,
    PrivacyClassification? privacy,
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
      taskDetail: TaskDetail(
        priority: priority,
        dueDate: dueDate,
        status: TaskStatus.pending,
      ),
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Item.createNote({
    required String id,
    required String workspaceId,
    required String title,
    required String content,
    String contentFormat = 'plain_text',
    String? summary,
    String? categoryId,
    PrivacyClassification? privacy,
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
      noteDetail: NoteDetail(
        content: content,
        contentFormat: contentFormat,
      ),
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Item.createAppointment({
    required String id,
    required String workspaceId,
    required String title,
    required DateTime startTime,
    DateTime? endTime,
    String? location,
    bool allDay = false,
    String? timezone,
    String? summary,
    String? categoryId,
    PrivacyClassification? privacy,
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

  factory Item.createDocument({
    required String id,
    required String workspaceId,
    required String title,
    String? documentType,
    String? documentNumber,
    String? issuingAuthority,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? summary,
    String? categoryId,
    PrivacyClassification? privacy,
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

  factory Item.createUnified({
    required String id,
    required String workspaceId,
    required ItemType itemType,
    required String title,
    String? summary,
    String? categoryId,
    PrivacyClassification? privacy,
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

  Item copyWith({
    String? title,
    String? summary,
    Priority? priority,
    bool? isCompleted,
    DateTime? dueDate,
    PrivacyClassification? privacy,
    String? categoryId,
    String? voiceFilePath,
    int? voiceDurationMs,
    TaskDetail? taskDetail,
    NoteDetail? noteDetail,
    AppointmentDetail? appointmentDetail,
    DocumentDetail? documentDetail,
    ShoppingListDetail? shoppingListDetail,
    int? entityVersion,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) {
    TaskDetail? updatedTaskDetail = taskDetail ?? this.taskDetail;
    if (priority != null || isCompleted != null || dueDate != null) {
      updatedTaskDetail = (updatedTaskDetail ?? const TaskDetail()).copyWith(
        priority: priority,
        dueDate: dueDate,
        status: isCompleted != null
            ? (isCompleted ? TaskStatus.completed : TaskStatus.pending)
            : updatedTaskDetail?.status,
      );
    }

    return Item(
      id: id,
      workspaceId: workspaceId,
      itemType: itemType,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      privacy: privacy ?? this.privacy,
      categoryId: categoryId ?? this.categoryId,
      voiceFilePath: voiceFilePath ?? this.voiceFilePath,
      voiceDurationMs: voiceDurationMs ?? this.voiceDurationMs,
      taskDetail: updatedTaskDetail,
      noteDetail: noteDetail ?? this.noteDetail,
      appointmentDetail: appointmentDetail ?? this.appointmentDetail,
      documentDetail: documentDetail ?? this.documentDetail,
      shoppingListDetail: shoppingListDetail ?? this.shoppingListDetail,
      entityVersion: entityVersion ?? this.entityVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
    );
  }
}
