"""
SQLite Local Item Repository — مشروع «مُعين» (Mouin)
Implements IItemRepository with Workspace Scoping & Cascade Deletes.
"""

import sqlite3
from typing import List, Optional
from backend.app.application.ports.repositories import IItemRepository
from backend.app.domain.entities.item import Item
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId
from backend.app.domain.value_objects.types import ItemType
from backend.app.infrastructure.persistence.sqlite.mappers.local_item_mapper import SqliteItemMapper

def iso(dt) -> Optional[str]:
    return dt.isoformat() if dt else None

class SqliteItemRepository(IItemRepository):
    def __init__(self, connection: sqlite3.Connection):
        self.connection = connection

    def save(self, item: Item) -> None:
        # 1. Upsert local_items root
        sql_item = """
            INSERT INTO local_items (
                id, workspace_id, item_type, title, summary, category_id,
                privacy_classification, temporal_original_expression, temporal_resolved_at,
                temporal_timezone, temporal_locale, temporal_calendar,
                created_by_installation_id, created_at, updated_at, deleted_at, entity_version
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT (id) DO UPDATE SET
                title = excluded.title,
                summary = excluded.summary,
                category_id = excluded.category_id,
                privacy_classification = excluded.privacy_classification,
                temporal_original_expression = excluded.temporal_original_expression,
                temporal_resolved_at = excluded.temporal_resolved_at,
                updated_at = excluded.updated_at,
                deleted_at = excluded.deleted_at,
                entity_version = excluded.entity_version;
        """
        self.connection.execute(sql_item, (
            str(item.id), str(item.workspace_id), item.item_type.value, item.title, item.summary,
            str(item.category_id) if item.category_id else None,
            item.privacy_classification.value, item.temporal_original_expression,
            iso(item.temporal_resolved_at), item.temporal_timezone, item.temporal_locale, item.temporal_calendar,
            str(item.created_by_installation_id) if item.created_by_installation_id else None,
            iso(item.created_at), iso(item.updated_at), iso(item.deleted_at), item.entity_version
        ))

        # 2. Upsert specialized subtype table
        if item.item_type == ItemType.TASK and item.task_detail:
            sql_task = """
                INSERT INTO local_tasks (item_id, due_date, priority, status, completed_at, estimated_duration_minutes)
                VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT (item_id) DO UPDATE SET
                    due_date = excluded.due_date,
                    priority = excluded.priority,
                    status = excluded.status,
                    completed_at = excluded.completed_at,
                    estimated_duration_minutes = excluded.estimated_duration_minutes;
            """
            self.connection.execute(sql_task, (
                str(item.id), iso(item.task_detail.due_date), item.task_detail.priority.value,
                item.task_detail.status.value, iso(item.task_detail.completed_at), item.task_detail.estimated_duration_minutes
            ))
        elif item.item_type == ItemType.APPOINTMENT and item.appointment_detail:
            sql_appt = """
                INSERT INTO local_appointments (item_id, start_time, end_time, location, all_day, timezone)
                VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT (item_id) DO UPDATE SET
                    start_time = excluded.start_time,
                    end_time = excluded.end_time,
                    location = excluded.location,
                    all_day = excluded.all_day,
                    timezone = excluded.timezone;
            """
            self.connection.execute(sql_appt, (
                str(item.id), iso(item.appointment_detail.start_time), iso(item.appointment_detail.end_time),
                item.appointment_detail.location, 1 if item.appointment_detail.all_day else 0, item.appointment_detail.timezone
            ))
        elif item.item_type == ItemType.NOTE and item.note_detail:
            sql_note = """
                INSERT INTO local_notes (item_id, content, content_format)
                VALUES (?, ?, ?)
                ON CONFLICT (item_id) DO UPDATE SET
                    content = excluded.content,
                    content_format = excluded.content_format;
            """
            self.connection.execute(sql_note, (
                str(item.id), item.note_detail.content, item.note_detail.content_format
            ))
        elif item.item_type == ItemType.DOCUMENT and item.document_detail:
            sql_doc = """
                INSERT INTO local_documents (item_id, document_type, issue_date, expiry_date, document_number, issuing_authority)
                VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT (item_id) DO UPDATE SET
                    document_type = excluded.document_type,
                    issue_date = excluded.issue_date,
                    expiry_date = excluded.expiry_date,
                    document_number = excluded.document_number,
                    issuing_authority = excluded.issuing_authority;
            """
            self.connection.execute(sql_doc, (
                str(item.id), item.document_detail.document_type,
                iso(item.document_detail.issue_date), iso(item.document_detail.expiry_date),
                item.document_detail.document_number, item.document_detail.issuing_authority
            ))

    def get_by_id(self, workspace_id: WorkspaceId, item_id: EntityId) -> Optional[Item]:
        cursor = self.connection.cursor()
        cursor.execute("SELECT * FROM local_items WHERE workspace_id = ? AND id = ?;", (str(workspace_id), str(item_id)))
        item_row = cursor.fetchone()
        if not item_row:
            return None

        item_type = item_row['item_type']
        table_map = {
            "task": "local_tasks", "appointment": "local_appointments", "note": "local_notes",
            "document": "local_documents", "debt": "local_debts", "shopping": "local_shopping_lists"
        }
        subtype_row = None
        if item_type in table_map:
            tname = table_map[item_type]
            cursor.execute(f"SELECT * FROM {tname} WHERE item_id = ?;", (str(item_id),))
            subtype_row = cursor.fetchone()

        return SqliteItemMapper.to_domain(item_row, subtype_row)

    def list_by_workspace(self, workspace_id: WorkspaceId, limit: int = 50, offset: int = 0) -> List[Item]:
        cursor = self.connection.cursor()
        cursor.execute(
            "SELECT id FROM local_items WHERE workspace_id = ? AND deleted_at IS NULL ORDER BY created_at DESC LIMIT ? OFFSET ?;",
            (str(workspace_id), limit, offset)
        )
        rows = cursor.fetchall()
        return [self.get_by_id(workspace_id, EntityId(str(r['id']))) for r in rows if r]
