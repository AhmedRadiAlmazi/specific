"""
SQLite Local Item Mapper — مشروع «مُعين» (Mouin)
"""

from typing import Dict, Any, Optional
from datetime import datetime, date
from backend.app.domain.entities.item import (
    Item, TaskDetail, AppointmentDetail, NoteDetail, DocumentDetail
)
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId, InstallationId
from backend.app.domain.value_objects.types import (
    ItemType, PrivacyClassification, Priority, TaskStatus
)

def parse_iso(dt_str: Optional[str]) -> Optional[datetime]:
    if not dt_str:
        return None
    return datetime.fromisoformat(dt_str.replace("Z", "+00:00"))

def parse_date(d_str: Optional[str]) -> Optional[date]:
    if not d_str:
        return None
    return date.fromisoformat(d_str)

class SqliteItemMapper:
    @staticmethod
    def to_domain(item_row: Any, subtype_row: Optional[Any] = None) -> Item:
        item_id = EntityId(str(item_row['id']))
        ws_id = WorkspaceId(str(item_row['workspace_id']))
        cat_id = EntityId(str(item_row['category_id'])) if item_row['category_id'] else None
        inst_id = InstallationId(str(item_row['created_by_installation_id'])) if item_row['created_by_installation_id'] else None
        item_type = ItemType(item_row['item_type'])
        privacy = PrivacyClassification(item_row['privacy_classification'])

        task_detail = None
        appt_detail = None
        note_detail = None
        doc_detail = None

        if subtype_row:
            if item_type == ItemType.TASK:
                task_detail = TaskDetail(
                    due_date=parse_iso(subtype_row['due_date']),
                    priority=Priority(subtype_row['priority']),
                    status=TaskStatus(subtype_row['status']),
                    completed_at=parse_iso(subtype_row['completed_at']),
                    estimated_duration_minutes=subtype_row['estimated_duration_minutes']
                )
            elif item_type == ItemType.APPOINTMENT:
                appt_detail = AppointmentDetail(
                    start_time=parse_iso(subtype_row['start_time']),
                    end_time=parse_iso(subtype_row['end_time']),
                    location=subtype_row['location'],
                    all_day=bool(subtype_row['all_day']),
                    timezone=subtype_row['timezone'] or 'Asia/Aden'
                )
            elif item_type == ItemType.NOTE:
                note_detail = NoteDetail(
                    content=subtype_row['content'] or '',
                    content_format=subtype_row['content_format'] or 'plain_text'
                )
            elif item_type == ItemType.DOCUMENT:
                doc_detail = DocumentDetail(
                    document_type=subtype_row['document_type'] or 'general',
                    issue_date=parse_date(subtype_row['issue_date']),
                    expiry_date=parse_date(subtype_row['expiry_date']),
                    document_number=subtype_row['document_number'],
                    issuing_authority=subtype_row['issuing_authority']
                )

        item = Item(
            id=item_id,
            workspace_id=ws_id,
            item_type=item_type,
            title=item_row['title'],
            summary=item_row['summary'],
            category_id=cat_id,
            privacy_classification=privacy,
            temporal_original_expression=item_row['temporal_original_expression'],
            temporal_resolved_at=parse_iso(item_row['temporal_resolved_at']),
            temporal_timezone=item_row['temporal_timezone'],
            temporal_locale=item_row['temporal_locale'] or 'ar',
            temporal_calendar=item_row['temporal_calendar'] or 'gregorian',
            created_by_installation_id=inst_id,
            task_detail=task_detail,
            appointment_detail=appt_detail,
            note_detail=note_detail,
            document_detail=doc_detail,
            created_at=parse_iso(item_row['created_at']),
            updated_at=parse_iso(item_row['updated_at']),
            deleted_at=parse_iso(item_row['deleted_at']),
            entity_version=item_row['entity_version']
        )
        return item
