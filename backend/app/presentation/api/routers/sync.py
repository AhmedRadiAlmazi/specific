"""
Sync API Router (Push, Pull, Bootstrap) — مشروع «مُعين» (Mouin)
Strictly adheres to DATA_API_SYNC_CONTRACT v1.0 FINAL.
"""

from fastapi import APIRouter, Depends, Header, HTTPException, status
from typing import List, Dict, Any
from backend.app.presentation.api.dependencies.auth import AuthenticatedUser, get_current_user
from backend.app.presentation.api.dependencies.container import get_sync_service, SyncApplicationService
from backend.app.presentation.api.schemas.sync_dto import (
    SyncPushRequest, SyncPushResponse, SyncPushAckDTO, SyncPullResponse, SyncBootstrapResponse
)
from backend.app.presentation.api.routers.items import _to_item_dto

router = APIRouter(prefix="/api/v1/sync", tags=["Sync Engine"])

def _validate_workspace(x_workspace_id: str):
    if x_workspace_id.startswith("00000000-0000-0000-0000-000000000000"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: User does not have access to this workspace."
        )

@router.post("/push", response_model=SyncPushResponse)
def sync_push(
    payload: SyncPushRequest,
    x_workspace_id: str = Header(..., description="معرف مساحة العمل المستهدفة"),
    current_user: AuthenticatedUser = Depends(get_current_user),
    sync_service: SyncApplicationService = Depends(get_sync_service)
):
    _validate_workspace(x_workspace_id)
    ops_dicts = [op.model_dump() for op in payload.operations]
    raw_acks = sync_service.handle_push(x_workspace_id, ops_dicts)
    return SyncPushResponse(acks=[SyncPushAckDTO(**a) for a in raw_acks])

@router.get("/pull", response_model=SyncPullResponse)
def sync_pull(
    since_sequence: int = 0,
    limit: int = 50,
    x_workspace_id: str = Header(..., description="معرف مساحة العمل"),
    current_user: AuthenticatedUser = Depends(get_current_user),
    sync_service: SyncApplicationService = Depends(get_sync_service)
):
    _validate_workspace(x_workspace_id)
    res = sync_service.handle_pull(x_workspace_id, since_sequence, limit)
    return SyncPullResponse(
        changes=res['changes'],
        has_more=res['has_more'],
        next_cursor=res['next_cursor']
    )

@router.get("/bootstrap", response_model=SyncBootstrapResponse)
def sync_bootstrap(
    x_workspace_id: str = Header(..., description="معرف مساحة العمل"),
    current_user: AuthenticatedUser = Depends(get_current_user),
    sync_service: SyncApplicationService = Depends(get_sync_service)
):
    _validate_workspace(x_workspace_id)
    res = sync_service.handle_bootstrap(x_workspace_id)
    return SyncBootstrapResponse(
        snapshot_items=[_to_item_dto(i) for i in res['items']],
        initial_cursor=res['initial_cursor'],
        snapshot_at=res['snapshot_at']
    )
