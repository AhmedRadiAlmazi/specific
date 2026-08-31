"""
PostgreSQL Attachment Repository Implementation — مشروع «مُعين» (Mouin)
Implements IAttachmentRepository for secure metadata storage and SHA-256 integrity.
"""

from typing import Optional, List, Any
import psycopg2

from backend.app.application.ports.repositories import IAttachmentRepository
from backend.app.domain.entities.attachment import Attachment
from backend.app.domain.value_objects.identity import WorkspaceId, EntityId, UserId
from backend.app.domain.value_objects.types import PrivacyClassification

class PostgresAttachmentRepository(IAttachmentRepository):
    def __init__(self, connection: Any):
        self.connection = connection

    def save(self, attachment: Attachment) -> None:
        """Upserts an attachment record."""
        cursor = self.connection.cursor()
        sql = """
            INSERT INTO attachments (id, workspace_id, file_name, file_size_bytes, mime_type, storage_path, checksum_sha256, privacy_classification, created_by_user_id, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                file_name = EXCLUDED.file_name,
                file_size_bytes = EXCLUDED.file_size_bytes,
                mime_type = EXCLUDED.mime_type,
                storage_path = EXCLUDED.storage_path,
                checksum_sha256 = EXCLUDED.checksum_sha256,
                privacy_classification = EXCLUDED.privacy_classification,
                updated_at = EXCLUDED.updated_at;
        """
        cursor.execute(sql, (
            str(attachment.id),
            str(attachment.workspace_id),
            attachment.file_name,
            attachment.file_size_bytes,
            attachment.mime_type,
            attachment.storage_path,
            attachment.checksum_sha256,
            attachment.privacy_classification.value if hasattr(attachment.privacy_classification, 'value') else str(attachment.privacy_classification),
            str(attachment.created_by_user_id) if attachment.created_by_user_id else None,
            attachment.created_at,
            attachment.updated_at
        ))

    def get_by_id(self, workspace_id: WorkspaceId, attachment_id: EntityId) -> Optional[Attachment]:
        """Retrieves attachment metadata within workspace boundary."""
        cursor = self.connection.cursor()
        sql = """
            SELECT id, workspace_id, file_name, file_size_bytes, mime_type, storage_path, checksum_sha256, privacy_classification, created_by_user_id, created_at, updated_at
            FROM attachments
            WHERE workspace_id = %s AND id = %s;
        """
        cursor.execute(sql, (str(workspace_id), str(attachment_id)))
        row = cursor.fetchone()
        if not row:
            return None
        return Attachment(
            id=EntityId(row[0]),
            workspace_id=WorkspaceId(row[1]),
            file_name=row[2],
            file_size_bytes=row[3],
            mime_type=row[4],
            storage_path=row[5],
            checksum_sha256=row[6],
            privacy_classification=PrivacyClassification(row[7]),
            created_by_user_id=UserId(row[8]) if row[8] else None,
            created_at=row[9],
            updated_at=row[10]
        )
