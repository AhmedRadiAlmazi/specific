"""
Unified Items & Tasks Router — مشروع «مُعين» (Mouin)
Strictly adheres to Single Domain Mutation Path with multi-tenancy workspace isolation.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from backend.app.presentation.api.dependencies.auth import AuthenticatedUser, get_current_user
from backend.app.presentation.api.dependencies.workspace import get_active_workspace
from backend.app.presentation.api.dependencies.container import (
    get_item_repo, get_task_handler, SqliteItemRepository, TaskCommandHandler
)
from backend.app.presentation.api.schemas.item_dto import (
    CreateTaskRequest, CreateUnifiedItemRequest, UpdateItemRequest,
    ItemResponseDTO, ItemListResponseDTO, TaskDetailDTO, NoteDetailDTO,
    AppointmentDetailDTO, DocumentDetailDTO
)
from backend.app.application.commands.item_commands import (
    CreateTaskCommand, CreateUnifiedItemCommand, CompleteTaskCommand, UpdateItemCommand, SoftDeleteItemCommand
)
from backend.app.domain.value_objects.identity import WorkspaceId, EntityId

router = APIRouter(prefix="/api/v1/workspaces/{workspace_id}", tags=["Unified Items & Tasks"])

def _to_item_dto(item) -> ItemResponseDTO:
    task_dto = None
    note_dto = None
    appt_dto = None
    doc_dto = None

    if item.task_detail:
        task_dto = TaskDetailDTO(
            due_date=item.task_detail.due_date,
            priority=item.task_detail.priority.value if hasattr(item.task_detail.priority, 'value') else str(item.task_detail.priority),
            status=item.task_detail.status.value if hasattr(item.task_detail.status, 'value') else str(item.task_detail.status),
            completed_at=item.task_detail.completed_at,
            estimated_duration_minutes=item.task_detail.estimated_duration_minutes
        )
    if item.note_detail:
        note_dto = NoteDetailDTO(
            content=item.note_detail.content,
            content_format=item.note_detail.content_format
        )
    if item.appointment_detail:
        appt_dto = AppointmentDetailDTO(
            start_time=item.appointment_detail.start_time,
            end_time=item.appointment_detail.end_time,
            location=item.appointment_detail.location,
            all_day=item.appointment_detail.all_day,
            timezone=item.appointment_detail.timezone
        )
    if item.document_detail:
        doc_dto = DocumentDetailDTO(
            document_type=item.document_detail.document_type,
            issue_date=item.document_detail.issue_date,
            expiry_date=item.document_detail.expiry_date,
            document_number=item.document_detail.document_number,
            issuing_authority=item.document_detail.issuing_authority
        )

    return ItemResponseDTO(
        id=str(item.id),
        workspace_id=str(item.workspace_id),
        item_type=item.item_type.value if hasattr(item.item_type, 'value') else str(item.item_type),
        title=item.title,
        summary=item.summary,
        privacy_classification=item.privacy_classification.value if hasattr(item.privacy_classification, 'value') else str(item.privacy_classification),
        entity_version=item.entity_version,
        task_detail=task_dto,
        note_detail=note_dto,
        appointment_detail=appt_dto,
        document_detail=doc_dto,
        created_at=item.created_at,
        updated_at=item.updated_at,
        deleted_at=item.deleted_at
    )

# 1. List Unified Items (with type filtering and pagination)
@router.get("/items", response_model=ItemListResponseDTO)
def list_items(
    workspace_id: str = Depends(get_active_workspace),
    item_type: Optional[str] = Query(None, description="فلترة بنوع العنصر (task, note, appointment, etc.)"),
    search: Optional[str] = Query(None, description="بحث نصي"),
    limit: int = 50,
    offset: int = 0,
    repo: SqliteItemRepository = Depends(get_item_repo)
):
    ws_id = WorkspaceId(workspace_id)
    items = repo.list_by_workspace(ws_id, limit=limit*2, offset=0)
    
    if item_type:
        t = item_type.lower()
        items = [i for i in items if (i.item_type.value if hasattr(i.item_type, 'value') else str(i.item_type)).lower() == t]
    if search:
        s = search.lower()
        items = [i for i in items if s in i.title.lower() or (i.summary and s in i.summary.lower())]

    paginated = items[offset:offset+limit]
    return ItemListResponseDTO(
        items=[_to_item_dto(i) for i in paginated],
        count=len(items)
    )

# 2. Create Unified Item (Task, Note, Appointment, Document, etc.)
@router.post("/items", response_model=ItemResponseDTO, status_code=status.HTTP_201_CREATED)
def create_unified_item(
    payload: CreateUnifiedItemRequest,
    workspace_id: str = Depends(get_active_workspace),
    handler: TaskCommandHandler = Depends(get_task_handler),
    repo: SqliteItemRepository = Depends(get_item_repo)
):
    cmd = CreateUnifiedItemCommand(
        workspace_id=workspace_id,
        item_type=payload.item_type,
        title=payload.title,
        summary=payload.summary,
        category_id=payload.category_id,
        privacy=payload.privacy.value,
        task_detail=payload.task_detail.model_dump() if payload.task_detail else None,
        note_detail=payload.note_detail.model_dump() if payload.note_detail else None,
        appointment_detail=payload.appointment_detail.model_dump() if payload.appointment_detail else None,
        document_detail=payload.document_detail.model_dump() if payload.document_detail else None,
    )
    item_id = handler.handle_create_unified_item(cmd)
    item = repo.get_by_id(WorkspaceId(workspace_id), EntityId(item_id))
    return _to_item_dto(item)

# 3. Create Task (Backward Compatibility Route)
@router.post("/tasks", response_model=ItemResponseDTO, status_code=status.HTTP_201_CREATED)
def create_task(
    payload: CreateTaskRequest,
    workspace_id: str = Depends(get_active_workspace),
    handler: TaskCommandHandler = Depends(get_task_handler),
    repo: SqliteItemRepository = Depends(get_item_repo)
):
    cmd = CreateTaskCommand(
        workspace_id=workspace_id,
        title=payload.title,
        due_date=payload.due_date,
        priority=payload.priority.value,
        summary=payload.summary,
        category_id=payload.category_id,
        privacy=payload.privacy.value,
        temporal_expression=payload.temporal_expression
    )
    task_id = handler.handle_create(cmd)
    item = repo.get_by_id(WorkspaceId(workspace_id), EntityId(task_id))
    return _to_item_dto(item)

# 4. Get Unified Item by ID
@router.get("/items/{item_id}", response_model=ItemResponseDTO)
def get_item(
    item_id: str,
    workspace_id: str = Depends(get_active_workspace),
    repo: SqliteItemRepository = Depends(get_item_repo)
):
    item = repo.get_by_id(WorkspaceId(workspace_id), EntityId(item_id))
    if not item or item.is_deleted():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Item {item_id} not found in workspace.")
    return _to_item_dto(item)

# 5. Patch / Update Item
@router.patch("/items/{item_id}", response_model=ItemResponseDTO)
def update_item(
    item_id: str,
    payload: UpdateItemRequest,
    workspace_id: str = Depends(get_active_workspace),
    handler: TaskCommandHandler = Depends(get_task_handler),
    repo: SqliteItemRepository = Depends(get_item_repo)
):
    item = repo.get_by_id(WorkspaceId(workspace_id), EntityId(item_id))
    if not item or item.is_deleted():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Item {item_id} not found.")

    new_title = payload.title or item.title
    new_summary = payload.summary if payload.summary is not None else item.summary
    new_privacy = payload.privacy.value if payload.privacy else None

    cmd = UpdateItemCommand(
        workspace_id=workspace_id,
        item_id=item_id,
        title=new_title,
        summary=new_summary,
        privacy=new_privacy
    )
    handler.handle_update(cmd)
    updated_item = repo.get_by_id(WorkspaceId(workspace_id), EntityId(item_id))
    return _to_item_dto(updated_item)

# 6. Complete Task (Task specific action)
@router.post("/tasks/{item_id}/complete", response_model=ItemResponseDTO)
def complete_task(
    item_id: str,
    workspace_id: str = Depends(get_active_workspace),
    handler: TaskCommandHandler = Depends(get_task_handler),
    repo: SqliteItemRepository = Depends(get_item_repo)
):
    cmd = CompleteTaskCommand(workspace_id=workspace_id, item_id=item_id)
    handler.handle_complete(cmd)
    item = repo.get_by_id(WorkspaceId(workspace_id), EntityId(item_id))
    return _to_item_dto(item)

# 7. Soft Delete Item
@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_item(
    item_id: str,
    workspace_id: str = Depends(get_active_workspace),
    handler: TaskCommandHandler = Depends(get_task_handler)
):
    cmd = SoftDeleteItemCommand(workspace_id=workspace_id, item_id=item_id)
    handler.handle_soft_delete(cmd)
