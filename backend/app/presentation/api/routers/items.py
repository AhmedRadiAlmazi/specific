"""
Items & Tasks Router — مشروع «مُعين» (Mouin)
Strictly adheres to Single Domain Mutation Path.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from backend.app.presentation.api.dependencies.auth import AuthenticatedUser, get_current_user
from backend.app.presentation.api.dependencies.workspace import get_active_workspace
from backend.app.presentation.api.dependencies.container import (
    get_item_repo, get_task_handler, SqliteItemRepository, TaskCommandHandler
)
from backend.app.presentation.api.schemas.item_dto import (
    CreateTaskRequest, ItemResponseDTO, ItemListResponseDTO, TaskDetailDTO
)
from backend.app.application.commands.item_commands import (
    CreateTaskCommand, CompleteTaskCommand, SoftDeleteItemCommand
)
from backend.app.domain.value_objects.identity import WorkspaceId, EntityId

router = APIRouter(prefix="/api/v1/workspaces/{workspace_id}", tags=["Items & Tasks"])

def _to_item_dto(item) -> ItemResponseDTO:
    task_dto = None
    if item.task_detail:
        task_dto = TaskDetailDTO(
            due_date=item.task_detail.due_date,
            priority=item.task_detail.priority.value,
            status=item.task_detail.status.value,
            completed_at=item.task_detail.completed_at,
            estimated_duration_minutes=item.task_detail.estimated_duration_minutes
        )
    return ItemResponseDTO(
        id=str(item.id),
        workspace_id=str(item.workspace_id),
        item_type=item.item_type.value,
        title=item.title,
        summary=item.summary,
        privacy_classification=item.privacy_classification.value,
        entity_version=item.entity_version,
        task_detail=task_dto,
        created_at=item.created_at,
        updated_at=item.updated_at,
        deleted_at=item.deleted_at
    )

@router.get("/items", response_model=ItemListResponseDTO)
def list_items(
    workspace_id: str = Depends(get_active_workspace),
    limit: int = 50,
    offset: int = 0,
    repo: SqliteItemRepository = Depends(get_item_repo)
):
    ws_id = WorkspaceId(workspace_id)
    items = repo.list_by_workspace(ws_id, limit, offset)
    return ItemListResponseDTO(
        items=[_to_item_dto(i) for i in items],
        count=len(items)
    )

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

@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_item(
    item_id: str,
    workspace_id: str = Depends(get_active_workspace),
    handler: TaskCommandHandler = Depends(get_task_handler)
):
    cmd = SoftDeleteItemCommand(workspace_id=workspace_id, item_id=item_id)
    handler.handle_soft_delete(cmd)
