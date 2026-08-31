"""
Item & Task DTO Schemas — مشروع «مُعين» (Mouin)
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, date
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
    priority: str = "medium"
    status: str = "pending"
    completed_at: Optional[datetime] = None
    estimated_duration_minutes: Optional[int] = None

class NoteDetailDTO(BaseModel):
    content: str = ""
    content_format: str = "plain_text"

class AppointmentDetailDTO(BaseModel):
    start_time: datetime
    end_time: Optional[datetime] = None
    location: Optional[str] = None
    all_day: bool = False
    timezone: str = "Asia/Aden"

class DocumentDetailDTO(BaseModel):
    document_type: str = "general"
    issue_date: Optional[date] = None
    expiry_date: Optional[date] = None
    document_number: Optional[str] = None
    issuing_authority: Optional[str] = None

class CreateUnifiedItemRequest(BaseModel):
    item_type: str = Field(..., description="نوع العنصر: task, note, appointment, document, shopping, debt")
    title: str = Field(..., min_length=1, max_length=255, description="عنوان العنصر")
    summary: Optional[str] = None
    category_id: Optional[str] = None
    privacy: PrivacyClassification = PrivacyClassification.PRIVATE
    task_detail: Optional[TaskDetailDTO] = None
    note_detail: Optional[NoteDetailDTO] = None
    appointment_detail: Optional[AppointmentDetailDTO] = None
    document_detail: Optional[DocumentDetailDTO] = None

class UpdateItemRequest(BaseModel):
    title: Optional[str] = None
    summary: Optional[str] = None
    privacy: Optional[PrivacyClassification] = None

class ItemResponseDTO(BaseModel):
    id: str
    workspace_id: str
    item_type: str
    title: str
    summary: Optional[str] = None
    privacy_classification: str
    entity_version: int
    task_detail: Optional[TaskDetailDTO] = None
    note_detail: Optional[NoteDetailDTO] = None
    appointment_detail: Optional[AppointmentDetailDTO] = None
    document_detail: Optional[DocumentDetailDTO] = None
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None

class ItemListResponseDTO(BaseModel):
    items: List[ItemResponseDTO]
    count: int
