"""
Reminder Subsystem Domain Model — مشروع «مُعين» (Mouin)
Strict 4-tier lifecycle: ReminderRule -> ReminderInstance (with occurrence_key) -> Notification -> Action.
"""

from dataclasses import dataclass, field
from datetime import datetime, timezone
import hashlib
from typing import List, Optional
from backend.app.domain.entities.base import AggregateRoot, BaseEntity
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId, InstallationId
from backend.app.domain.value_objects.types import (
    ReminderTriggerType, ReminderStatus, DeliveryChannel, NotificationStatus, NotificationActionType
)
from backend.app.domain.exceptions import InvariantViolationError, OccurrenceAlreadyExistsError
from backend.app.domain.events.domain_events import (
    ReminderRuleCreatedEvent, ReminderInstanceCreatedEvent
)

@dataclass
class ReminderInstance(BaseEntity):
    rule_id: EntityId = field(default_factory=EntityId.new)
    item_id: EntityId = field(default_factory=EntityId.new)
    occurrence_key: str = ""
    scheduled_time: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    status: ReminderStatus = ReminderStatus.PENDING
    snoozed_until: Optional[datetime] = None
    fired_at: Optional[datetime] = None

    def __post_init__(self):
        if not self.occurrence_key:
            raise InvariantViolationError("ReminderInstance must have a non-empty occurrence_key.")

    def snooze(self, snooze_until: datetime):
        if snooze_until <= datetime.now(timezone.utc):
            raise InvariantViolationError("Snooze time must be in the future.")
        self.status = ReminderStatus.SNOOZED
        self.snoozed_until = snooze_until
        self.touch()

    def dismiss(self):
        self.status = ReminderStatus.DISMISSED
        self.touch()

@dataclass
class Notification(BaseEntity):
    instance_id: EntityId = field(default_factory=EntityId.new)
    installation_id: InstallationId = field(default_factory=InstallationId.new)
    delivery_channel: DeliveryChannel = DeliveryChannel.LOCAL_PUSH
    title: str = ""
    body: str = ""
    scheduled_for: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    sent_at: Optional[datetime] = None
    delivery_status: NotificationStatus = NotificationStatus.SCHEDULED

@dataclass
class ReminderRule(AggregateRoot):
    item_id: EntityId = field(default_factory=EntityId.new)
    trigger_type: ReminderTriggerType = ReminderTriggerType.RELATIVE
    trigger_time: Optional[datetime] = None
    offset_minutes: Optional[int] = None
    rrule: Optional[str] = None
    is_active: bool = True
    _instances: List[ReminderInstance] = field(default_factory=list)

    @classmethod
    def create(
        cls,
        id: EntityId,
        workspace_id: WorkspaceId,
        item_id: EntityId,
        trigger_type: ReminderTriggerType,
        trigger_time: Optional[datetime] = None,
        offset_minutes: Optional[int] = None,
        rrule: Optional[str] = None
    ) -> "ReminderRule":
        rule = cls(
            id=id,
            workspace_id=workspace_id,
            item_id=item_id,
            trigger_type=trigger_type,
            trigger_time=trigger_time,
            offset_minutes=offset_minutes,
            rrule=rrule,
            is_active=True
        )
        rule.record_event(ReminderRuleCreatedEvent(
            event_id=str(EntityId.new()),
            workspace_id=str(workspace_id),
            event_type="reminder.rule_created",
            aggregate_type="reminder_rule",
            aggregate_id=str(id),
            payload={"item_id": str(item_id), "trigger_type": trigger_type.value}
        ))
        return rule

    @property
    def instances(self) -> List[ReminderInstance]:
        return [inst for inst in self._instances if not inst.is_deleted()]

    def generate_instance(self, instance_id: EntityId, scheduled_time: datetime) -> ReminderInstance:
        # Deterministic occurrence key
        time_iso = scheduled_time.isoformat()
        occ_key = hashlib.sha256(f"{self.id}:{time_iso}".encode("utf-8")).hexdigest()

        # Check deduplication invariant
        if any(inst.occurrence_key == occ_key for inst in self.instances):
            raise OccurrenceAlreadyExistsError(f"Reminder occurrence for key {occ_key} already exists under rule {self.id}")

        instance = ReminderInstance(
            id=instance_id,
            workspace_id=self.workspace_id,
            rule_id=self.id,
            item_id=self.item_id,
            occurrence_key=occ_key,
            scheduled_time=scheduled_time,
            status=ReminderStatus.PENDING
        )
        self._instances.append(instance)
        self.touch()
        self.record_event(ReminderInstanceCreatedEvent(
            event_id=str(EntityId.new()),
            workspace_id=str(self.workspace_id),
            event_type="reminder.instance_created",
            aggregate_type="reminder_instance",
            aggregate_id=str(instance_id),
            payload={"rule_id": str(self.id), "occurrence_key": occ_key}
        ))
        return instance
