"""
Base Entity & Aggregate Root Abstractions — مشروع «مُعين» (Mouin)
"""

from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import List, Optional
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId
from backend.app.domain.events.domain_events import DomainEvent

@dataclass
class BaseEntity:
    id: EntityId
    workspace_id: WorkspaceId
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    deleted_at: Optional[datetime] = None
    entity_version: int = 1

    def is_deleted(self) -> bool:
        return self.deleted_at is not None

    def mark_deleted(self, deleted_time: Optional[datetime] = None):
        self.deleted_at = deleted_time or datetime.now(timezone.utc)
        self.touch()

    def touch(self):
        self.updated_at = datetime.now(timezone.utc)
        self.entity_version += 1

@dataclass
class AggregateRoot(BaseEntity):
    _domain_events: List[DomainEvent] = field(default_factory=list, init=False, repr=False)

    def record_event(self, event: DomainEvent):
        self._domain_events.append(event)

    def collect_events(self) -> List[DomainEvent]:
        events = list(self._domain_events)
        self._domain_events.clear()
        return events
