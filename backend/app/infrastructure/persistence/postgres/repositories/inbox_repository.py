"""
PostgreSQL Inbox & AI Staging Repository — مشروع «مُعين» (Mouin)
Implements IInboxRepository for raw user captures and AI suggestions staging.
"""

from typing import Optional, List, Any
from decimal import Decimal
import json
from datetime import datetime, timezone
import psycopg2

from backend.app.application.ports.repositories import IInboxRepository
from backend.app.domain.entities.inbox import InboxItem, AISuggestion
from backend.app.domain.value_objects.identity import WorkspaceId, EntityId, InstallationId
from backend.app.domain.value_objects.types import InboxSourceType, ProcessingStatus, AISuggestionValidationStatus

class PostgresInboxRepository(IInboxRepository):
    def __init__(self, connection: Any):
        self.connection = connection

    def save_inbox_item(self, item: InboxItem) -> None:
        """Upserts an inbox raw capture item."""
        cursor = self.connection.cursor()
        sql = """
            INSERT INTO inbox_items (id, workspace_id, content, capture_method, status, created_at)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                content = EXCLUDED.content,
                status = EXCLUDED.status;
        """
        cursor.execute(sql, (
            str(item.id),
            str(item.workspace_id),
            item.raw_text,
            item.source_type.value if hasattr(item.source_type, 'value') else str(item.source_type),
            item.processing_status.value if hasattr(item.processing_status, 'value') else str(item.processing_status),
            item.created_at
        ))

    def get_inbox_item_by_id(self, workspace_id: WorkspaceId, item_id: EntityId) -> Optional[InboxItem]:
        """Retrieves an inbox item by id within workspace boundary."""
        cursor = self.connection.cursor()
        sql = """
            SELECT id, workspace_id, content, capture_method, status, created_at
            FROM inbox_items
            WHERE workspace_id = %s AND id = %s;
        """
        cursor.execute(sql, (str(workspace_id), str(item_id)))
        row = cursor.fetchone()
        if not row:
            return None
        return InboxItem(
            id=EntityId(row[0]),
            workspace_id=WorkspaceId(row[1]),
            raw_text=row[2],
            source_type=InboxSourceType(row[3]),
            processing_status=ProcessingStatus(row[4]),
            created_at=row[5]
        )

    def save_suggestion(self, suggestion: AISuggestion) -> None:
        """Upserts an AI parsed suggestion."""
        cursor = self.connection.cursor()
        sql = """
            INSERT INTO ai_suggestions (id, workspace_id, inbox_item_id, suggested_type, payload, confidence_score, status, created_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                suggested_type = EXCLUDED.suggested_type,
                payload = EXCLUDED.payload,
                confidence_score = EXCLUDED.confidence_score,
                status = EXCLUDED.status;
        """
        payload_json = json.dumps(suggestion.suggested_payload) if isinstance(suggestion.suggested_payload, dict) else str(suggestion.suggested_payload)
        status_str = suggestion.validation_status.value if hasattr(suggestion.validation_status, 'value') else str(suggestion.validation_status)
        cursor.execute(sql, (
            str(suggestion.id),
            str(suggestion.workspace_id),
            str(suggestion.inbox_item_id),
            suggestion.intent,
            payload_json,
            float(suggestion.confidence_score),
            status_str,
            suggestion.created_at
        ))

    def get_suggestion_by_id(self, workspace_id: WorkspaceId, suggestion_id: EntityId) -> Optional[AISuggestion]:
        """Retrieves an AI suggestion within workspace boundary."""
        cursor = self.connection.cursor()
        sql = """
            SELECT id, workspace_id, inbox_item_id, suggested_type, payload, confidence_score, status, created_at
            FROM ai_suggestions
            WHERE workspace_id = %s AND id = %s;
        """
        cursor.execute(sql, (str(workspace_id), str(suggestion_id)))
        row = cursor.fetchone()
        if not row:
            return None
        payload = row[4]
        if isinstance(payload, str):
            try:
                payload = json.loads(payload)
            except Exception:
                pass
        return AISuggestion(
            id=EntityId(row[0]),
            workspace_id=WorkspaceId(row[1]),
            inbox_item_id=EntityId(row[2]),
            intent=row[3],
            suggested_payload=payload if isinstance(payload, dict) else {},
            confidence_score=Decimal(str(row[5])),
            validation_status=AISuggestionValidationStatus(row[6]),
            created_at=row[7]
        )
