"""
Database Models & Contract Schemas v1.0 — مشروع «مُعين» (Mouin)
Strictly derived from DATA_API_SYNC_CONTRACT v1.0 FINAL & ERD_FINAL v1.0
"""

from datetime import datetime, date
from decimal import Decimal
from typing import Optional, List, Dict, Any, Literal
from uuid import UUID
from pydantic import BaseModel, Field, ConfigDict

# ------------------------------------------------------------------------------
# 1. Identity & Organization
# ------------------------------------------------------------------------------

class UserModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    email: str
    phone_number: Optional[str] = None
    password_hash: str
    full_name: str
    is_active: bool = True
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None

class DeviceModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    user_id: UUID
    device_fingerprint: str
    device_name: str
    device_type: Literal['android', 'ios', 'windows', 'macos', 'web']
    os_version: str
    created_at: datetime
    last_seen_at: datetime

class InstallationModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    device_id: UUID
    user_id: UUID
    app_version: str
    push_token: Optional[str] = None
    sync_protocol_version: int = 1
    is_active: bool = True
    installed_at: datetime
    last_active_at: datetime

class WorkspaceModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    owner_user_id: UUID
    name: str
    type: Literal['personal', 'family', 'team'] = 'personal'
    settings: Dict[str, Any] = Field(default_factory=dict)
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    entity_version: int = 1

class WorkspaceMemberModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    workspace_id: UUID
    user_id: UUID
    role: Literal['owner', 'admin', 'member', 'viewer'] = 'owner'
    joined_at: datetime
    deleted_at: Optional[datetime] = None

# ------------------------------------------------------------------------------
# 2. Master Data
# ------------------------------------------------------------------------------

class CategoryModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    workspace_id: UUID
    name: str
    color: str = '#6750A4'
    icon: str = 'folder'
    parent_id: Optional[UUID] = None
    entity_version: int = 1
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None

class PersonModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    workspace_id: UUID
    name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    relationship_type: Optional[str] = None
    notes: Optional[str] = None
    entity_version: int = 1
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None

# ------------------------------------------------------------------------------
# 3. Item Aggregate Root & Subtypes
# ------------------------------------------------------------------------------

ItemTypeLiteral = Literal['task', 'appointment', 'note', 'document', 'debt', 'shopping']
PrivacyLiteral = Literal['private', 'sensitive']

class ItemModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    workspace_id: UUID
    item_type: ItemTypeLiteral
    title: str
    summary: Optional[str] = None
    category_id: Optional[UUID] = None
    privacy_classification: PrivacyLiteral = 'private'
    temporal_original_expression: Optional[str] = None
    temporal_resolved_at: Optional[datetime] = None
    temporal_timezone: Optional[str] = None
    temporal_locale: Optional[str] = 'ar'
    temporal_calendar: Optional[str] = 'gregorian'
    created_by_installation_id: Optional[UUID] = None
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    entity_version: int = 1

class TaskModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    item_id: UUID
    due_date: Optional[datetime] = None
    priority: Literal['low', 'medium', 'high', 'urgent'] = 'medium'
    status: Literal['pending', 'in_progress', 'completed', 'cancelled'] = 'pending'
    completed_at: Optional[datetime] = None
    estimated_duration_minutes: Optional[int] = None

class AppointmentModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    item_id: UUID
    start_time: datetime
    end_time: Optional[datetime] = None
    location: Optional[str] = None
    all_day: bool = False
    timezone: str = 'Asia/Aden'

class NoteModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    item_id: UUID
    content: str
    content_format: Literal['plain_text', 'markdown'] = 'plain_text'

class DocumentModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    item_id: UUID
    document_type: str
    issue_date: Optional[date] = None
    expiry_date: Optional[date] = None
    document_number: Optional[str] = None
    issuing_authority: Optional[str] = None

class DebtModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    item_id: UUID
    debt_type: Literal['payable', 'receivable']
    person_id: UUID
    total_amount: Decimal
    currency: str = 'YER'
    due_date: Optional[date] = None
    status: Literal['active', 'settled', 'defaulted', 'cancelled'] = 'active'

class DebtTransactionModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    debt_id: UUID
    workspace_id: UUID
    transaction_type: Literal['payment', 'reversal', 'adjustment']
    amount: Decimal
    transaction_date: date
    notes: Optional[str] = None
    reference_transaction_id: Optional[UUID] = None
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    entity_version: int = 1

class ShoppingListModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    item_id: UUID
    is_archived: bool = False

class ShoppingEntryModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    shopping_list_id: UUID
    workspace_id: UUID
    item_name: str
    quantity: Decimal = Decimal('1.00')
    unit: Optional[str] = None
    is_checked: bool = False
    checked_at: Optional[datetime] = None
    sort_order: int = 0
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    entity_version: int = 1

# ------------------------------------------------------------------------------
# 4. Reminders & Notifications Subsystem
# ------------------------------------------------------------------------------

class ReminderRuleModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    workspace_id: UUID
    item_id: UUID
    trigger_type: Literal['relative', 'absolute', 'recurring']
    trigger_time: Optional[datetime] = None
    offset_minutes: Optional[int] = None
    rrule: Optional[str] = None
    is_active: bool = True
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    entity_version: int = 1

class ReminderInstanceModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    rule_id: UUID
    item_id: UUID
    workspace_id: UUID
    occurrence_key: str
    scheduled_time: datetime
    status: Literal['pending', 'triggered', 'snoozed', 'dismissed', 'cancelled'] = 'pending'
    snoozed_until: Optional[datetime] = None
    fired_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    entity_version: int = 1

class NotificationModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    instance_id: UUID
    installation_id: UUID
    workspace_id: UUID
    delivery_channel: Literal['local_push', 'system_tray'] = 'local_push'
    title: str
    body: str
    scheduled_for: datetime
    sent_at: Optional[datetime] = None
    delivery_status: Literal['scheduled', 'delivered', 'failed', 'dismissed'] = 'scheduled'
    created_at: datetime

class NotificationActionModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    notification_id: UUID
    action_type: Literal['dismiss', 'snooze_5m', 'snooze_15m', 'snooze_1h', 'mark_done', 'view_item']
    acted_at: datetime
    payload: Optional[Dict[str, Any]] = None

# ------------------------------------------------------------------------------
# 5. Attachments
# ------------------------------------------------------------------------------

class AttachmentModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    workspace_id: UUID
    file_name: str
    file_size_bytes: int
    mime_type: str
    storage_path: str
    checksum_sha256: str
    privacy_classification: PrivacyLiteral = 'private'
    created_by_user_id: UUID
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    entity_version: int = 1

# ------------------------------------------------------------------------------
# 6. Inbox & AI Processing Pipeline
# ------------------------------------------------------------------------------

class InboxItemModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    workspace_id: UUID
    raw_text: str
    source_type: Literal['voice_transcription', 'manual_quick_note', 'share_intent', 'image_scan']
    processing_status: Literal['pending', 'processing', 'processed', 'rejected', 'error'] = 'pending'
    created_by_installation_id: Optional[UUID] = None
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    entity_version: int = 1

class AISuggestionModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    inbox_item_id: UUID
    workspace_id: UUID
    intent: str
    suggested_payload: Dict[str, Any]
    confidence_score: Decimal
    validation_status: Literal['pending_review', 'accepted', 'rejected', 'edited'] = 'pending_review'
    ai_schema_version: str = '1.0'
    model_name: str
    model_version: str
    prompt_version: str
    reviewed_by_user_id: Optional[UUID] = None
    reviewed_at: Optional[datetime] = None
    created_at: datetime

# ------------------------------------------------------------------------------
# 7. Events (Audit Log)
# ------------------------------------------------------------------------------

class EventModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    workspace_id: UUID
    user_id: Optional[UUID] = None
    installation_id: Optional[UUID] = None
    event_type: str
    aggregate_type: str
    aggregate_id: UUID
    payload: Dict[str, Any]
    occurred_at: datetime
    recorded_at: datetime

# ------------------------------------------------------------------------------
# 8. Sync Infrastructure
# ------------------------------------------------------------------------------

class SyncChangeModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    server_sequence: int
    workspace_id: UUID
    entity_type: str
    entity_id: UUID
    operation: Literal['insert', 'update', 'delete']
    entity_version: int
    source_installation_id: UUID
    operation_id: UUID
    change_payload: Dict[str, Any]
    created_at: datetime

class SyncIdempotencyModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    operation_id: UUID
    workspace_id: UUID
    installation_id: UUID
    entity_type: str
    entity_id: UUID
    payload_hash_sha256: str
    first_received_at: datetime
    status: Literal['processed', 'failed']
    response_summary: Optional[Dict[str, Any]] = None

class SyncConflictModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    workspace_id: UUID
    entity_type: str
    entity_id: UUID
    source_installation_id: UUID
    client_version: int
    server_version: int
    client_payload: Dict[str, Any]
    server_payload: Dict[str, Any]
    resolution_strategy: Literal['auto_merged', 'domain_resolved', 'pending_user_action', 'user_resolved']
    resolved_payload: Optional[Dict[str, Any]] = None
    resolved_at: Optional[datetime] = None
    created_at: datetime
