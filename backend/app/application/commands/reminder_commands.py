"""
Reminder Application Commands — مشروع «مُعين» (Mouin)
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass(frozen=True)
class CreateReminderRuleCommand:
    workspace_id: str
    item_id: str
    trigger_type: str = "relative"
    trigger_time: Optional[datetime] = None
    offset_minutes: Optional[int] = None
    rrule: Optional[str] = None
    rule_id: Optional[str] = None

@dataclass(frozen=True)
class GenerateReminderInstanceCommand:
    workspace_id: str
    rule_id: str
    scheduled_time: datetime
    instance_id: Optional[str] = None

@dataclass(frozen=True)
class SnoozeReminderCommand:
    workspace_id: str
    instance_id: str
    snooze_until: datetime

@dataclass(frozen=True)
class DismissReminderCommand:
    workspace_id: str
    instance_id: str
