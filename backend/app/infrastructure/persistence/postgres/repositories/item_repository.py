"""
PostgreSQL Item Repository Implementation — مشروع «مُعين» (Mouin)
Implements IItemRepository with Workspace Scoping & Subtype Management.
"""

from typing import List, Optional, Any
from backend.app.application.ports.repositories import IItemRepository
from backend.app.domain.entities.item import Item
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId
from backend.app.domain.value_objects.types import ItemType
from backend.app.infrastructure.persistence.postgres.mappers.item_mapper import PostgresItemMapper

class PostgresItemRepository(IItemRepository):
    def __init__(self, connection: Any):
        self.connection = connection

    def save(self, item: Item) -> None:
        cursor = self.connection.cursor()
        
        # 1. Upsert items root table
        sql_item = """
            INSERT INTO items (
                id, workspace_id, item_type, title, summary, category_id,
                privacy_classification, temporal_original_expression, temporal_resolved_at,
                temporal_timezone, temporal_locale, temporal_calendar,
                created_by_installation_id, created_at, updated_at, deleted_at, entity_version
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
            )
            ON CONFLICT (id) DO UPDATE SET
                title = EXCLUDED.title,
                summary = EXCLUDED.summary,
                category_id = EXCLUDED.category_id,
                privacy_classification = EXCLUDED.privacy_classification,
                temporal_original_expression = EXCLUDED.temporal_original_expression,
                temporal_resolved_at = EXCLUDED.temporal_resolved_at,
                updated_at = EXCLUDED.updated_at,
                deleted_at = EXCLUDED.deleted_at,
                entity_version = EXCLUDED.entity_version;
        """
        cursor.execute(sql_item, (
            str(item.id), str(item.workspace_id), item.item_type.value, item.title, item.summary,
            str(item.category_id) if item.category_id else None,
            item.privacy_classification.value, item.temporal_original_expression,
            item.temporal_resolved_at, item.temporal_timezone, item.temporal_locale, item.temporal_calendar,
            str(item.created_by_installation_id) if item.created_by_installation_id else None,
            item.created_at, item.updated_at, item.deleted_at, item.entity_version
        ))

        # 2. Upsert specialized subtype table
        if item.item_type == ItemType.TASK and item.task_detail:
            sql_task = """
                INSERT INTO tasks (item_id, due_date, priority, status, completed_at, estimated_duration_minutes)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT (item_id) DO UPDATE SET
                    due_date = EXCLUDED.due_date,
                    priority = EXCLUDED.priority,
                    status = EXCLUDED.status,
                    completed_at = EXCLUDED.completed_at,
                    estimated_duration_minutes = EXCLUDED.estimated_duration_minutes;
            """
            cursor.execute(sql_task, (
                str(item.id), item.task_detail.due_date, item.task_detail.priority.value,
                item.task_detail.status.value, item.task_detail.completed_at, item.task_detail.estimated_duration_minutes
            ))
        elif item.item_type == ItemType.APPOINTMENT and item.appointment_detail:
            sql_appt = """
                INSERT INTO appointments (item_id, start_time, end_time, location, all_day, timezone)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT (item_id) DO UPDATE SET
                    start_time = EXCLUDED.start_time,
                    end_time = EXCLUDED.end_time,
                    location = EXCLUDED.location,
                    all_day = EXCLUDED.all_day,
                    timezone = EXCLUDED.timezone;
            """
            cursor.execute(sql_appt, (
                str(item.id), item.appointment_detail.start_time, item.appointment_detail.end_time,
                item.appointment_detail.location, item.appointment_detail.all_day, item.appointment_detail.timezone
            ))
        elif item.item_type == ItemType.NOTE and item.note_detail:
            sql_note = """
                INSERT INTO notes (item_id, content, content_format)
                VALUES (%s, %s, %s)
                ON CONFLICT (item_id) DO UPDATE SET
                    content = EXCLUDED.content,
                    content_format = EXCLUDED.content_format;
            """
            cursor.execute(sql_note, (
                str(item.id), item.note_detail.content, item.note_detail.content_format
            ))
        elif item.item_type == ItemType.DOCUMENT and item.document_detail:
            sql_doc = """
                INSERT INTO documents (item_id, document_type, issue_date, expiry_date, document_number, issuing_authority)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT (item_id) DO UPDATE SET
                    document_type = EXCLUDED.document_type,
                    issue_date = EXCLUDED.issue_date,
                    expiry_date = EXCLUDED.expiry_date,
                    document_number = EXCLUDED.document_number,
                    issuing_authority = EXCLUDED.issuing_authority;
            """
            cursor.execute(sql_doc, (
                str(item.id), item.document_detail.document_type, item.document_detail.issue_date,
                item.document_detail.expiry_date, item.document_detail.document_number, item.document_detail.issuing_authority
            ))

    def get_by_id(self, workspace_id: WorkspaceId, item_id: EntityId) -> Optional[Item]:
        cursor = self.connection.cursor()
        cursor.execute("SELECT * FROM items WHERE workspace_id = %s AND id = %s;", (str(workspace_id), str(item_id)))
        row = cursor.fetchone()
        if not row:
            return None

        # Convert row tuple to dict if needed
        cols = [desc[0] for desc in cursor.description]
        item_dict = dict(zip(cols, row))

        # Fetch subtype row
        item_type = item_dict['item_type']
        subtype_dict = None
        table_map = {
            "task": "tasks", "appointment": "appointments", "note": "notes",
            "document": "documents", "debt": "debts", "shopping": "shopping_lists"
        }
        if item_type in table_map:
            tname = table_map[item_type]
            cursor.execute(f"SELECT * FROM {tname} WHERE item_id = %s;", (str(item_id),))
            s_row = cursor.fetchone()
            if s_row:
                s_cols = [desc[0] for desc in cursor.description]
                subtype_dict = dict(zip(s_cols, s_row))

        return PostgresItemMapper.to_domain(item_dict, subtype_dict)

    def list_by_workspace(self, workspace_id: WorkspaceId, limit: int = 50, offset: int = 0) -> List[Item]:
        cursor = self.connection.cursor()
        cursor.execute(
            "SELECT * FROM items WHERE workspace_id = %s AND deleted_at IS NULL ORDER BY created_at DESC LIMIT %s OFFSET %s;",
            (str(workspace_id), limit, offset)
        )
        rows = cursor.fetchall()
        if not rows:
            return []
        cols = [desc[0] for desc in cursor.description]
        results = []
        for r in rows:
            d = dict(zip(cols, r))
            item = self.get_by_id(workspace_id, EntityId(str(d['id'])))
            if item:
                results.append(item)
        return results
