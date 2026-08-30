"""
Item & Task DTO Schemas — مشروع «مُعين» (Mouin)
"""

from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime
from decimal import Decimal
from backend.app.domain.value_objects.types import Priority, PrivacyClassification, TaskStatus

class CreateTaskRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=255, description="عنوان المهمة")
    due_date: Optional[datetime] = None
    priority: Priority = Priority.MEDIUM
    summary: Optional[str] = None
    category_id: Optional[str] = None
    privacy: PrivacyClassification = PrivacyClassification.PRIVATE
    temporal_expression: Optional[str] = None

class TaskDetailDTO(BaseModel):
    due_date: Optional[datetime] = None
    priority: str
    status: str
    completed_at: Optional[datetime] = None
    estimated_duration_minutes: Optional[int] = None

class ItemResponseDTO(BaseModel):
    id: str
    workspace_id: str
    item_type: str
    title: str
    summary: Optional[str] = None
    privacy_classification: str
    entity_version: int
    task_detail: Optional[TaskDetailDTO] = None
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None

class ItemListResponseDTO(BaseModel):
    items: List[ItemResponseDTO]
    count: int
