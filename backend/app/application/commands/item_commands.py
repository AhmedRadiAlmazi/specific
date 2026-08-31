"""
Item Application Commands — مشروع «مُعين» (Mouin)
Includes Unified Item, Task, Note, Appointment, and Document mutation commands.
"""

from dataclasses import dataclass
from datetime import datetime, date
from typing import Optional, Dict, Any

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
class CreateUnifiedItemCommand:
    workspace_id: str
    item_type: str
    title: str
    item_id: Optional[str] = None
    summary: Optional[str] = None
    category_id: Optional[str] = None
    privacy: str = "private"
    task_detail: Optional[Dict[str, Any]] = None
    note_detail: Optional[Dict[str, Any]] = None
    appointment_detail: Optional[Dict[str, Any]] = None
    document_detail: Optional[Dict[str, Any]] = None
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
    privacy: Optional[str] = None

@dataclass(frozen=True)
class SoftDeleteItemCommand:
    workspace_id: str
    item_id: str
