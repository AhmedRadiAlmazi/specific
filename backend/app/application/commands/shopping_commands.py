"""
Shopping Application Commands — مشروع «مُعين» (Mouin)
"""

from dataclasses import dataclass
from typing import Optional

@dataclass(frozen=True)
class CreateShoppingListCommand:
    workspace_id: str
    title: str
    list_id: Optional[str] = None

@dataclass(frozen=True)
class AddShoppingEntryCommand:
    workspace_id: str
    shopping_list_id: str
    item_name: str
    quantity: str = "1.00"
    unit: Optional[str] = None
    entry_id: Optional[str] = None

@dataclass(frozen=True)
class CheckShoppingEntryCommand:
    workspace_id: str
    shopping_list_id: str
    entry_id: str
