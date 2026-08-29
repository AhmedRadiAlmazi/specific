"""
Domain Enums & Type Definitions — مشروع «مُعين» (Mouin)
"""

from enum import Enum

class ItemType(str, Enum):
    TASK = "task"
    APPOINTMENT = "appointment"
    NOTE = "note"
    DOCUMENT = "document"
    DEBT = "debt"
    SHOPPING = "shopping"

class PrivacyClassification(str, Enum):
    PRIVATE = "private"
    SENSITIVE = "sensitive"

class Priority(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"

class TaskStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class DebtType(str, Enum):
    PAYABLE = "payable"      # دين عليّ للغير
    RECEIVABLE = "receivable"  # دين لي على الغير

class DebtStatus(str, Enum):
    ACTIVE = "active"
    SETTLED = "settled"
    DEFAULTED = "defaulted"
    CANCELLED = "cancelled"

class DebtTransactionType(str, Enum):
    PAYMENT = "payment"
    REVERSAL = "reversal"
    ADJUSTMENT = "adjustment"

class ReminderTriggerType(str, Enum):
    RELATIVE = "relative"
    ABSOLUTE = "absolute"
    RECURRING = "recurring"

class ReminderStatus(str, Enum):
    PENDING = "pending"
    TRIGGERED = "triggered"
    SNOOZED = "snoozed"
    DISMISSED = "dismissed"
    CANCELLED = "cancelled"

class DeliveryChannel(str, Enum):
    LOCAL_PUSH = "local_push"
    SYSTEM_TRAY = "system_tray"

class NotificationStatus(str, Enum):
    SCHEDULED = "scheduled"
    DELIVERED = "delivered"
    FAILED = "failed"
    DISMISSED = "dismissed"

class NotificationActionType(str, Enum):
    DISMISS = "dismiss"
    SNOOZE_5M = "snooze_5m"
    SNOOZE_15M = "snooze_15m"
    SNOOZE_1H = "snooze_1h"
    MARK_DONE = "mark_done"
    VIEW_ITEM = "view_item"

class InboxSourceType(str, Enum):
    VOICE_TRANSCRIPTION = "voice_transcription"
    MANUAL_QUICK_NOTE = "manual_quick_note"
    SHARE_INTENT = "share_intent"
    IMAGE_SCAN = "image_scan"

class ProcessingStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    PROCESSED = "processed"
    REJECTED = "rejected"
    ERROR = "error"

class AISuggestionValidationStatus(str, Enum):
    PENDING_REVIEW = "pending_review"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    EDITED = "edited"
