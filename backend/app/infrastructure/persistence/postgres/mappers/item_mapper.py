"""
PostgreSQL Item Data Mapper — مشروع «مُعين» (Mouin)
Bidirectional mapping between PostgreSQL relational rows and Item Aggregate Root.
"""

from typing import Dict, Any, Optional
from datetime import datetime
from backend.app.domain.entities.item import (
    Item, TaskDetail, AppointmentDetail, NoteDetail, DocumentDetail
)
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId, InstallationId
from backend.app.domain.value_objects.types import (
    ItemType, PrivacyClassification, Priority, TaskStatus
)

class PostgresItemMapper:
    @staticmethod
    def to_domain(item_row: Dict[str, Any], subtype_row: Optional[Dict[str, Any]] = None) -> Item:
        item_id = EntityId(str(item_row['id']))
        ws_id = WorkspaceId(str(item_row['workspace_id']))
        cat_id = EntityId(str(item_row['category_id'])) if item_row.get('category_id') else None
        inst_id = InstallationId(str(item_row['created_by_installation_id'])) if item_row.get('created_by_installation_id') else None
        item_type = ItemType(item_row['item_type'])
        privacy = PrivacyClassification(item_row['privacy_classification'])

        task_detail = None
        appt_detail = None
        note_detail = None
        doc_detail = None

        if subtype_row:
            if item_type == ItemType.TASK:
                task_detail = TaskDetail(
                    due_date=subtype_row.get('due_date'),
                    priority=Priority(subtype_row.get('priority', 'medium')),
                    status=TaskStatus(subtype_row.get('status', 'pending')),
                    completed_at=subtype_row.get('completed_at'),
                    estimated_duration_minutes=subtype_row.get('estimated_duration_minutes')
                )
            elif item_type == ItemType.APPOINTMENT:
                appt_detail = AppointmentDetail(
                    start_time=subtype_row['start_time'],
                    end_time=subtype_row.get('end_time'),
                    location=subtype_row.get('location'),
                    all_day=bool(subtype_row.get('all_day', False)),
                    timezone=subtype_row.get('timezone', 'Asia/Aden')
                )
            elif item_type == ItemType.NOTE:
                note_detail = NoteDetail(
                    content=subtype_row.get('content', ''),
                    content_format=subtype_row.get('content_format', 'plain_text')
                )
            elif item_type == ItemType.DOCUMENT:
                doc_detail = DocumentDetail(
                    document_type=subtype_row.get('document_type', 'general'),
                    issue_date=subtype_row.get('issue_date'),
                    expiry_date=subtype_row.get('expiry_date'),
                    document_number=subtype_row.get('document_number'),
                    issuing_authority=subtype_row.get('issuing_authority')
                )

        item = Item(
            id=item_id,
            workspace_id=ws_id,
            item_type=item_type,
            title=item_row['title'],
            summary=item_row.get('summary'),
            category_id=cat_id,
            privacy_classification=privacy,
            temporal_original_expression=item_row.get('temporal_original_expression'),
            temporal_resolved_at=item_row.get('temporal_resolved_at'),
            temporal_timezone=item_row.get('temporal_timezone'),
            temporal_locale=item_row.get('temporal_locale', 'ar'),
            temporal_calendar=item_row.get('temporal_calendar', 'gregorian'),
            created_by_installation_id=inst_id,
            task_detail=task_detail,
            appointment_detail=appt_detail,
            note_detail=note_detail,
            document_detail=doc_detail,
            created_at=item_row['created_at'],
            updated_at=item_row['updated_at'],
            deleted_at=item_row.get('deleted_at'),
            entity_version=item_row.get('entity_version', 1)
        )
        return item
