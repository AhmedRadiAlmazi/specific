"""
Reminder Subsystem DTO Schemas — مشروع «مُعين» (Mouin)
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from backend.app.domain.value_objects.types import ReminderTriggerType, ReminderStatus

class CreateReminderRuleRequest(BaseModel):
    item_id: str = Field(..., description="معرف العنصر المرتبط به التذكير")
    trigger_type: ReminderTriggerType = ReminderTriggerType.RELATIVE
    trigger_time: Optional[datetime] = None
    offset_minutes: Optional[int] = None
    rrule: Optional[str] = None

class GenerateReminderInstanceRequest(BaseModel):
    scheduled_time: datetime = Field(..., description="موعد التذكير المحدد")

class SnoozeReminderRequest(BaseModel):
    snooze_until: datetime = Field(..., description="موعد انتهاء التأجيل في المستقبل")

class ReminderInstanceDTO(BaseModel):
    id: str
    rule_id: str
    item_id: str
    occurrence_key: str
    scheduled_time: datetime
    status: str
    snoozed_until: Optional[datetime] = None

class ReminderRuleResponseDTO(BaseModel):
    id: str
    workspace_id: str
    item_id: str
    trigger_type: str
    trigger_time: Optional[datetime] = None
    is_active: bool
    instances: List[ReminderInstanceDTO] = Field(default_factory=list)
