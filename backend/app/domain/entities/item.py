"""
Item Aggregate Root & Specialized Subtypes — مشروع «مُعين» (Mouin)
Item is the Aggregate Root. Types: task, appointment, note, document, debt, shopping.
Reminder is strictly decoupled from Item.
"""

from dataclasses import dataclass, field
from datetime import datetime, date, timezone
from typing import Optional
from backend.app.domain.entities.base import AggregateRoot
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId, InstallationId
from backend.app.domain.value_objects.types import ItemType, PrivacyClassification, Priority, TaskStatus
from backend.app.domain.exceptions import InvariantViolationError, InvalidStateTransitionError
from backend.app.domain.events.domain_events import (
    ItemCreatedEvent, ItemUpdatedEvent, ItemSoftDeletedEvent, TaskCompletedEvent
)

@dataclass
class TaskDetail:
    due_date: Optional[datetime] = None
    priority: Priority = Priority.MEDIUM
    status: TaskStatus = TaskStatus.PENDING
    completed_at: Optional[datetime] = None
    estimated_duration_minutes: Optional[int] = None

    def __post_init__(self):
        if self.estimated_duration_minutes is not None and self.estimated_duration_minutes <= 0:
            raise InvariantViolationError("Estimated duration minutes must be positive.")

@dataclass
class AppointmentDetail:
    start_time: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    end_time: Optional[datetime] = None
    location: Optional[str] = None
    all_day: bool = False
    timezone: str = "Asia/Aden"

    def __post_init__(self):
        if self.end_time is not None and self.end_time < self.start_time:
            raise InvariantViolationError("Appointment end_time cannot be earlier than start_time.")

@dataclass
class NoteDetail:
    content: str = ""
    content_format: str = "plain_text"

    def __post_init__(self):
        if self.content_format not in ("plain_text", "markdown"):
            raise InvariantViolationError(f"Unsupported content format: {self.content_format}")

@dataclass
class DocumentDetail:
    document_type: str = ""
    issue_date: Optional[date] = None
    expiry_date: Optional[date] = None
    document_number: Optional[str] = None
    issuing_authority: Optional[str] = None

    def __post_init__(self):
        if not self.document_type or not self.document_type.strip():
            raise InvariantViolationError("Document document_type is required.")
        if self.expiry_date is not None and self.issue_date is not None:
            if self.expiry_date < self.issue_date:
                raise InvariantViolationError("Document expiry_date cannot be earlier than issue_date.")

@dataclass
class Item(AggregateRoot):
    item_type: ItemType = ItemType.TASK
    title: str = ""
    summary: Optional[str] = None
    category_id: Optional[EntityId] = None
    privacy_classification: PrivacyClassification = PrivacyClassification.PRIVATE
    temporal_original_expression: Optional[str] = None
    temporal_resolved_at: Optional[datetime] = None
    temporal_timezone: Optional[str] = None
    temporal_locale: Optional[str] = "ar"
    temporal_calendar: Optional[str] = "gregorian"
    created_by_installation_id: Optional[InstallationId] = None

    # Extension details (1:1 with Item)
    task_detail: Optional[TaskDetail] = None
    appointment_detail: Optional[AppointmentDetail] = None
    note_detail: Optional[NoteDetail] = None
    document_detail: Optional[DocumentDetail] = None

    def __post_init__(self):
        if not self.title or not self.title.strip():
            raise InvariantViolationError("Item title is mandatory and cannot be empty.")
        if str(self.item_type).lower() == "reminder":
            raise InvariantViolationError("Reminder is strictly an independent subsystem and CANNOT be an Item type.")
        if not isinstance(self.item_type, ItemType):
            try:
                self.item_type = ItemType(self.item_type)
            except ValueError:
                raise InvariantViolationError(f"Invalid item_type: {self.item_type}")

    @classmethod
    def create_task(
        cls,
        id: EntityId,
        workspace_id: WorkspaceId,
        title: str,
        due_date: Optional[datetime] = None,
        priority: Priority = Priority.MEDIUM,
        summary: Optional[str] = None,
        category_id: Optional[EntityId] = None,
        privacy: PrivacyClassification = PrivacyClassification.PRIVATE,
        temporal_expression: Optional[str] = None,
        installation_id: Optional[InstallationId] = None
    ) -> "Item":
        task_detail = TaskDetail(due_date=due_date, priority=priority, status=TaskStatus.PENDING)
        item = cls(
            id=id,
            workspace_id=workspace_id,
            item_type=ItemType.TASK,
            title=title,
            summary=summary,
            category_id=category_id,
            privacy_classification=privacy,
            temporal_original_expression=temporal_expression,
            temporal_resolved_at=due_date,
            created_by_installation_id=installation_id,
            task_detail=task_detail
        )
        item.record_event(ItemCreatedEvent(
            event_id=str(EntityId.new()),
            workspace_id=str(workspace_id),
            event_type="item.task_created",
            aggregate_type="item",
            aggregate_id=str(id),
            payload={"title": title, "priority": priority.value}
        ))
        return item

    def complete_task(self):
        if self.item_type != ItemType.TASK or not self.task_detail:
            raise InvalidStateTransitionError("Only Task items can be completed.")
        if self.task_detail.status == TaskStatus.COMPLETED:
            return  # Already completed
        self.task_detail.status = TaskStatus.COMPLETED
        self.task_detail.completed_at = datetime.now(timezone.utc)
        self.touch()
        self.record_event(TaskCompletedEvent(
            event_id=str(EntityId.new()),
            workspace_id=str(self.workspace_id),
            event_type="task.completed",
            aggregate_type="item",
            aggregate_id=str(self.id),
            payload={"completed_at": self.task_detail.completed_at.isoformat()}
        ))

    def update_title_and_summary(self, title: str, summary: Optional[str] = None):
        if not title or not title.strip():
            raise InvariantViolationError("Title cannot be empty.")
        self.title = title.strip()
        self.summary = summary
        self.touch()
        self.record_event(ItemUpdatedEvent(
            event_id=str(EntityId.new()),
            workspace_id=str(self.workspace_id),
            event_type="item.updated",
            aggregate_type="item",
            aggregate_id=str(self.id),
            payload={"title": self.title}
        ))

    def soft_delete(self):
        if not self.is_deleted():
            self.mark_deleted()
            self.record_event(ItemSoftDeletedEvent(
                event_id=str(EntityId.new()),
                workspace_id=str(self.workspace_id),
                event_type="item.deleted",
                aggregate_type="item",
                aggregate_id=str(self.id),
                payload={"deleted_at": self.deleted_at.isoformat()}
            ))
