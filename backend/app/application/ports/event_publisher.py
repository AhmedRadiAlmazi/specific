"""
Domain Event Publisher Port — مشروع «مُعين» (Mouin)
"""

from abc import ABC, abstractmethod
from typing import List
from backend.app.domain.events.domain_events import DomainEvent

class IDomainEventPublisher(ABC):
    @abstractmethod
    def publish(self, event: DomainEvent):
        pass

    @abstractmethod
    def publish_all(self, events: List[DomainEvent]):
        pass
