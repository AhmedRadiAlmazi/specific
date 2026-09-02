"""
Attachments API Router — مشروع «مُعين» (Mouin)
Provides secure endpoints for uploading and downloading audio recordings, images, and documents.
Enforces multi-tenant workspace isolation and SHA-256 integrity verification.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Response, Request
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timezone
import uuid
import base64

from backend.app.presentation.api.dependencies.auth import AuthenticatedUser, get_current_user
from backend.app.presentation.api.dependencies.workspace import get_active_workspace
from backend.app.infrastructure.storage.attachment_storage import AttachmentStorageService
from backend.app.domain.entities.attachment import Attachment
from backend.app.domain.value_objects.identity import WorkspaceId, EntityId, UserId
from backend.app.domain.value_objects.types import PrivacyClassification
from backend.app.infrastructure.persistence.postgres.repositories.attachment_repository import PostgresAttachmentRepository
from backend.app.presentation.api.dependencies.container import get_postgres_manager, _use_postgres

router = APIRouter(prefix="/api/v1/workspaces/{workspace_id}/attachments", tags=["Attachments Storage"])

_storage_service: Optional[AttachmentStorageService] = None

def get_storage_service() -> AttachmentStorageService:
    global _storage_service
    if _storage_service is None:
        _storage_service = AttachmentStorageService()
    return _storage_service

class UploadAttachmentRequest(BaseModel):
    file_name: str
    content_base64: str
    mime_type: Optional[str] = "application/octet-stream"
    privacy_classification: Optional[str] = "private"

@router.post("/upload")
async def upload_attachment(
    payload: UploadAttachmentRequest,
    workspace_id: str = Depends(get_active_workspace),
    current_user: AuthenticatedUser = Depends(get_current_user),
    storage: AttachmentStorageService = Depends(get_storage_service),
    pg_mgr = Depends(get_postgres_manager)
):
    """Uploads an attachment file or voice memo with SHA-256 checksum and workspace scoping."""
    try:
        file_bytes = base64.b64decode(payload.content_base64)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid base64 payload."
        )

    if not file_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot upload an empty file."
        )

    try:
        rel_path, checksum, file_size = storage.save_file(
            workspace_id=workspace_id,
            file_bytes=file_bytes,
            file_name=payload.file_name or "attachment.bin",
            mime_type=payload.mime_type or "application/octet-stream"
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

    attachment_id = str(uuid.uuid4())
    privacy_classification = payload.privacy_classification or "private"
    privacy_enum = PrivacyClassification(privacy_classification) if privacy_classification in [p.value for p in PrivacyClassification] else PrivacyClassification.PRIVATE

    attachment = Attachment(
        id=EntityId(attachment_id),
        workspace_id=WorkspaceId(workspace_id),
        file_name=payload.file_name or "attachment.bin",
        file_size_bytes=file_size,
        mime_type=payload.mime_type or "application/octet-stream",
        storage_path=rel_path,
        checksum_sha256=checksum,
        privacy_classification=privacy_enum,
        created_by_user_id=UserId(current_user.user_id)
    )

    if _use_postgres():
        conn = pg_mgr.get_connection()
        repo = PostgresAttachmentRepository(conn)
        repo.save(attachment)

    return {
        "id": str(attachment.id),
        "workspace_id": workspace_id,
        "file_name": attachment.file_name,
        "file_size_bytes": attachment.file_size_bytes,
        "mime_type": attachment.mime_type,
        "checksum_sha256": attachment.checksum_sha256,
        "privacy_classification": attachment.privacy_classification.value,
        "storage_path": attachment.storage_path,
        "created_at": attachment.created_at.isoformat()
    }

@router.get("/{attachment_id}/download")
def download_attachment(
    attachment_id: str,
    workspace_id: str = Depends(get_active_workspace),
    current_user: AuthenticatedUser = Depends(get_current_user),
    storage: AttachmentStorageService = Depends(get_storage_service),
    pg_mgr = Depends(get_postgres_manager)
):
    """Downloads an attachment file by verifying workspace authorization."""
    if _use_postgres():
        conn = pg_mgr.get_connection()
        repo = PostgresAttachmentRepository(conn)
        att = repo.get_by_id(WorkspaceId(workspace_id), EntityId(attachment_id))
        if not att:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Attachment {attachment_id} not found in workspace."
            )
        storage_path = att.storage_path
        mime_type = att.mime_type
        file_name = att.file_name
    else:
        storage_path = f"{workspace_id}/{attachment_id}"
        mime_type = "application/octet-stream"
        file_name = "downloaded_file.bin"

    try:
        file_bytes = storage.read_file(workspace_id, storage_path)
    except FileNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"File binary not found on storage."
        )

    return Response(
        content=file_bytes,
        media_type=mime_type,
        headers={"Content-Disposition": f'attachment; filename="{file_name}"'}
    )
