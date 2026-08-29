"""
SQLite Outbox Repository — مشروع «مُعين» (Mouin)
Matches exact schema of table outbox in sqlite_schema.sql.
"""

import sqlite3
import json
from typing import List, Dict, Any, Optional
from datetime import datetime, timezone

class SqliteOutboxRepository:
    def __init__(self, connection: sqlite3.Connection):
        self.connection = connection

    def enqueue_operation(
        self,
        operation_id: str,
        entity_type: str,
        entity_id: str,
        operation: str,
        payload: Dict[str, Any],
        base_version: int = 1
    ) -> None:
        sql = """
            INSERT INTO outbox (
                operation_id, entity_type, entity_id, operation,
                payload, base_version, attempt_count, status, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, 0, 'pending', ?);
        """
        now_iso = datetime.now(timezone.utc).isoformat()
        self.connection.execute(sql, (
            operation_id, entity_type, entity_id, operation,
            json.dumps(payload), base_version, now_iso
        ))

    def get_pending_operations(self, limit: int = 50) -> List[Dict[str, Any]]:
        cursor = self.connection.cursor()
        cursor.execute("SELECT * FROM outbox WHERE status = 'pending' ORDER BY created_at ASC LIMIT ?;", (limit,))
        rows = cursor.fetchall()
        return [dict(r) for r in rows]

    def mark_completed(self, operation_id: str) -> None:
        self.connection.execute("DELETE FROM outbox WHERE operation_id = ?;", (operation_id,))
