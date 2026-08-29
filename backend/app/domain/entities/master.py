"""
Master Data Entities (Category & Person) — مشروع «مُعين» (Mouin)
"""

from dataclasses import dataclass
from typing import Optional
from backend.app.domain.entities.base import AggregateRoot
from backend.app.domain.value_objects.identity import EntityId
from backend.app.domain.exceptions import InvariantViolationError

@dataclass
class Category(AggregateRoot):
    name: str = ""
    color: str = "#6750A4"
    icon: str = "folder"
    parent_id: Optional[EntityId] = None

    def __post_init__(self):
        if not self.name or not self.name.strip():
            raise InvariantViolationError("Category name is required.")

@dataclass
class Person(AggregateRoot):
    name: str = ""
    phone: Optional[str] = None
    email: Optional[str] = None
    relationship_type: Optional[str] = None
    notes: Optional[str] = None

    def __post_init__(self):
        if not self.name or not self.name.strip():
            raise InvariantViolationError("Person name is required.")
