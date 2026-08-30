"""
Sync API DTO Schemas — مشروع «مُعين» (Mouin)
Strictly conforming to DATA_API_SYNC_CONTRACT v1.0 FINAL.
"""

from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from datetime import datetime
from backend.app.presentation.api.schemas.item_dto import ItemResponseDTO

class SyncOperationDTO(BaseModel):
    operation_id: str = Field(..., description="معرف العملية الفريد UUIDv7")
    entity_type: str
    entity_id: str
    operation_type: str = Field(..., description="insert, update, delete")
    payload: Dict[str, Any]
    base_version: int = 1

class SyncPushRequest(BaseModel):
    client_installation_id: str
    operations: List[SyncOperationDTO]

class SyncPushAckDTO(BaseModel):
    operation_id: str
    status: str = "success"  # success, duplicate_idempotent, conflict
    server_sequence: int
    new_entity_version: int

class SyncPushResponse(BaseModel):
    acks: List[SyncPushAckDTO]

class SyncChangeDTO(BaseModel):
    server_sequence: int
    entity_type: str
    entity_id: str
    change_type: str  # insert, update, delete
    payload: Dict[str, Any]
    entity_version: int
    committed_at: str

class SyncPullResponse(BaseModel):
    changes: List[SyncChangeDTO]
    has_more: bool = False
    next_cursor: int

class SyncBootstrapResponse(BaseModel):
    snapshot_items: List[ItemResponseDTO]
    initial_cursor: int
    snapshot_at: str
