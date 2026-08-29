"""
Shopping List & Entries Domain Model — مشروع «مُعين» (Mouin)
"""

from dataclasses import dataclass, field
from datetime import datetime, timezone
from decimal import Decimal
from typing import List, Optional
from backend.app.domain.entities.base import AggregateRoot, BaseEntity
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId
from backend.app.domain.exceptions import InvariantViolationError

@dataclass
class ShoppingEntry(BaseEntity):
    shopping_list_id: EntityId = field(default_factory=EntityId.new)
    item_name: str = ""
    quantity: Decimal = Decimal("1.00")
    unit: Optional[str] = None
    is_checked: bool = False
    checked_at: Optional[datetime] = None
    sort_order: int = 0

    def __post_init__(self):
        if not self.item_name or not self.item_name.strip():
            raise InvariantViolationError("ShoppingEntry item_name is required.")
        if self.quantity <= Decimal("0.00"):
            raise InvariantViolationError("ShoppingEntry quantity must be positive.")

    def toggle_check(self):
        self.is_checked = not self.is_checked
        self.checked_at = datetime.now(timezone.utc) if self.is_checked else None
        self.touch()

@dataclass
class ShoppingList(AggregateRoot):
    is_archived: bool = False
    _entries: List[ShoppingEntry] = field(default_factory=list)

    @property
    def entries(self) -> List[ShoppingEntry]:
        return [e for e in self._entries if not e.is_deleted()]

    def add_entry(self, entry_id: EntityId, item_name: str, quantity: Decimal = Decimal("1.00"), unit: Optional[str] = None) -> ShoppingEntry:
        entry = ShoppingEntry(
            id=entry_id,
            workspace_id=self.workspace_id,
            shopping_list_id=self.id,
            item_name=item_name,
            quantity=quantity,
            unit=unit,
            sort_order=len(self.entries)
        )
        self._entries.append(entry)
        self.touch()
        return entry
