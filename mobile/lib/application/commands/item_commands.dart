// Application Commands — مشروع «مُعين» (Mouin)
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';

// --- Item Commands ---
class CreateTaskCommand {
  final String workspaceId;
  final String title;
  final Priority priority;
  final DateTime? dueDate;
  final String? summary;
  final String? categoryId;

  CreateTaskCommand({
    required this.workspaceId,
    required this.title,
    this.priority = Priority.medium,
    this.dueDate,
    this.summary,
    this.categoryId,
  });
}

class CompleteTaskCommand {
  final String workspaceId;
  final String itemId;

  CompleteTaskCommand({
    required this.workspaceId,
    required this.itemId,
  });
}

class UpdateItemCommand {
  final String workspaceId;
  final String itemId;
  final String? title;
  final String? summary;
  final PrivacyClassification? privacy;

  UpdateItemCommand({
    required this.workspaceId,
    required this.itemId,
    this.title,
    this.summary,
    this.privacy,
  });
}

class SoftDeleteItemCommand {
  final String workspaceId;
  final String itemId;

  SoftDeleteItemCommand({
    required this.workspaceId,
    required this.itemId,
  });
}

class CreateNoteCommand {
  final String workspaceId;
  final String title;
  final String content;
  final String contentFormat;
  final String? summary;
  final String? categoryId;

  CreateNoteCommand({
    required this.workspaceId,
    required this.title,
    required this.content,
    this.contentFormat = 'plain_text',
    this.summary,
    this.categoryId,
  });
}

class CreateAppointmentCommand {
  final String workspaceId;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final bool allDay;
  final String? timezone;
  final String? summary;
  final String? categoryId;

  CreateAppointmentCommand({
    required this.workspaceId,
    required this.title,
    required this.startTime,
    this.endTime,
    this.location,
    this.allDay = false,
    this.timezone,
    this.summary,
    this.categoryId,
  });
}

class CreateDocumentCommand {
  final String workspaceId;
  final String title;
  final String? documentType;
  final String? documentNumber;
  final String? issuingAuthority;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? summary;
  final String? categoryId;

  CreateDocumentCommand({
    required this.workspaceId,
    required this.title,
    this.documentType,
    this.documentNumber,
    this.issuingAuthority,
    this.issueDate,
    this.expiryDate,
    this.summary,
    this.categoryId,
  });
}

class CreateUnifiedItemCommand {
  final String workspaceId;
  final ItemType itemType;
  final String title;
  final String? summary;
  final String? categoryId;
  final PrivacyClassification? privacy;
  final dynamic taskDetail;
  final dynamic noteDetail;
  final dynamic appointmentDetail;
  final dynamic documentDetail;

  CreateUnifiedItemCommand({
    required this.workspaceId,
    required this.itemType,
    required this.title,
    this.summary,
    this.categoryId,
    this.privacy,
    this.taskDetail,
    this.noteDetail,
    this.appointmentDetail,
    this.documentDetail,
  });
}

// --- Reminder Commands ---
class CreateReminderRuleCommand {
  final String workspaceId;
  final String itemId;
  final ReminderTriggerType triggerType;
  final DateTime? triggerTime;
  final int? offsetMinutes;
  final String? rrule;

  CreateReminderRuleCommand({
    required this.workspaceId,
    required this.itemId,
    required this.triggerType,
    this.triggerTime,
    this.offsetMinutes,
    this.rrule,
  });
}

// --- Debt Commands ---
class CreateDebtCommand {
  final String workspaceId;
  final String personId;
  final DebtType debtType;
  final Money totalAmount;
  final DateTime? dueDate;

  CreateDebtCommand({
    required this.workspaceId,
    required this.personId,
    required this.debtType,
    required this.totalAmount,
    this.dueDate,
  });
}

class RecordPaymentCommand {
  final String workspaceId;
  final String debtId;
  final Money amount;
  final DateTime transactionDate;
  final String? notes;

  RecordPaymentCommand({
    required this.workspaceId,
    required this.debtId,
    required this.amount,
    required this.transactionDate,
    this.notes,
  });
}
