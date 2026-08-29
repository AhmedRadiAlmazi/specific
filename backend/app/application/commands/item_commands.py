"""
Item Application Commands — مشروع «مُعين» (Mouin)
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass(frozen=True)
class CreateTaskCommand:
    workspace_id: str
    title: str
    item_id: Optional[str] = None
    due_date: Optional[datetime] = None
    priority: str = "medium"
    summary: Optional[str] = None
    category_id: Optional[str] = None
    privacy: str = "private"
    temporal_expression: Optional[str] = None
    installation_id: Optional[str] = None

@dataclass(frozen=True)
class CompleteTaskCommand:
    workspace_id: str
    item_id: str

@dataclass(frozen=True)
class UpdateItemCommand:
    workspace_id: str
    item_id: str
    title: str
    summary: Optional[str] = None

@dataclass(frozen=True)
class SoftDeleteItemCommand:
    workspace_id: str
    item_id: str
