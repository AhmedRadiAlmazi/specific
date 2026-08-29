"""
Domain Events — مشروع «مُعين» (Mouin)
Pure domain events representing 'What happened?' for audit and observability.
"""

from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Dict, Any, Optional

@dataclass(frozen=True)
class DomainEvent:
    event_id: str
    workspace_id: str
    event_type: str
    aggregate_type: str
    aggregate_id: str
    payload: Dict[str, Any]
    occurred_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

@dataclass(frozen=True)
class ItemCreatedEvent(DomainEvent):
    pass

@dataclass(frozen=True)
class ItemUpdatedEvent(DomainEvent):
    pass

@dataclass(frozen=True)
class ItemSoftDeletedEvent(DomainEvent):
    pass

@dataclass(frozen=True)
class TaskCompletedEvent(DomainEvent):
    pass

@dataclass(frozen=True)
class DebtCreatedEvent(DomainEvent):
    pass

@dataclass(frozen=True)
class DebtPaymentRecordedEvent(DomainEvent):
    pass

@dataclass(frozen=True)
class DebtTransactionReversedEvent(DomainEvent):
    pass

@dataclass(frozen=True)
class ReminderRuleCreatedEvent(DomainEvent):
    pass

@dataclass(frozen=True)
class ReminderInstanceCreatedEvent(DomainEvent):
    pass
