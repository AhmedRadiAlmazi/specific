"""
PostgreSQL Sync Repository Implementation — مشروع «مُعين» (Mouin)
Provides persistent replication stream, idempotency gate, and conflict recording.
"""

from typing import List, Dict, Any, Optional
import json
from datetime import datetime, timezone
import psycopg2

from backend.app.domain.value_objects.identity import WorkspaceId, EntityId

class PostgresSyncRepository:
    def __init__(self, connection: Any):
        self.connection = connection

    def check_idempotency(self, operation_id: str) -> Optional[Dict[str, Any]]:
        """Checks if an operation has already been processed and cached."""
        cursor = self.connection.cursor()
        cursor.execute(
            "SELECT operation_id, payload_hash_sha256, server_sequence, status FROM sync_idempotency WHERE operation_id = %s;",
            (operation_id,)
        )
        row = cursor.fetchone()
        if not row:
            return None
        cols = [desc[0] for desc in cursor.description]
        return dict(zip(cols, row))

    def record_idempotency(self, operation_id: str, payload_hash: str, server_sequence: int, status: str = "processed") -> None:
        """Stores or updates the idempotency record."""
        cursor = self.connection.cursor()
        sql = """
            INSERT INTO sync_idempotency (operation_id, payload_hash_sha256, server_sequence, status)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (operation_id) DO NOTHING;
        """
        cursor.execute(sql, (operation_id, payload_hash, server_sequence, status))

    def record_sync_change(
        self,
        workspace_id: WorkspaceId,
        entity_type: str,
        entity_id: EntityId,
        change_type: str,
        payload: Dict[str, Any],
        entity_version: int
    ) -> int:
        """Appends a change record into sync_changes and returns allocated BIGINT server_sequence."""
        cursor = self.connection.cursor()
        sql = """
            INSERT INTO sync_changes (workspace_id, entity_type, entity_id, change_type, payload, entity_version, committed_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING server_sequence;
        """
        now = datetime.now(timezone.utc)
        payload_json = json.dumps(payload)
        cursor.execute(sql, (
            str(workspace_id), entity_type, str(entity_id), change_type,
            payload_json, entity_version, now
        ))
        row = cursor.fetchone()
        return row[0] if row else 1

    def fetch_stream_since(
        self,
        workspace_id: WorkspaceId,
        since_sequence: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """Fetches ordered monotonic change stream strictly after since_sequence."""
        cursor = self.connection.cursor()
        sql = """
            SELECT server_sequence, workspace_id, entity_type, entity_id, change_type, payload, entity_version, committed_at
            FROM sync_changes
            WHERE workspace_id = %s AND server_sequence > %s
            ORDER BY server_sequence ASC
            LIMIT %s;
        """
        cursor.execute(sql, (str(workspace_id), since_sequence, limit))
        rows = cursor.fetchall()
        if not rows:
            return []
        cols = [desc[0] for desc in cursor.description]
        results = []
        for r in rows:
            d = dict(zip(cols, r))
            if isinstance(d.get("payload"), str):
                try:
                    d["payload"] = json.loads(d["payload"])
                except Exception:
                    pass
            results.append(d)
        return results

    def get_current_max_sequence(self, workspace_id: WorkspaceId) -> int:
        """Returns the highest committed server_sequence for a workspace."""
        cursor = self.connection.cursor()
        cursor.execute(
            "SELECT COALESCE(MAX(server_sequence), 0) FROM sync_changes WHERE workspace_id = %s;",
            (str(workspace_id),)
        )
        row = cursor.fetchone()
        return row[0] if row else 0
