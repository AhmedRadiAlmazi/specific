"""
SQLite Local Reminder Repository — مشروع «مُعين» (Mouin)
"""

import sqlite3
from typing import List, Optional
from datetime import datetime
from backend.app.application.ports.repositories import IReminderRepository
from backend.app.domain.entities.reminder import ReminderRule, ReminderInstance
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId
from backend.app.domain.value_objects.types import ReminderTriggerType, ReminderStatus

def iso(dt) -> Optional[str]:
    return dt.isoformat() if dt else None

def parse_iso(dt_str) -> Optional[datetime]:
    if not dt_str:
        return None
    return datetime.fromisoformat(dt_str.replace("Z", "+00:00"))

class SqliteReminderRepository(IReminderRepository):
    def __init__(self, connection: sqlite3.Connection):
        self.connection = connection

    def save_rule(self, rule: ReminderRule) -> None:
        sql = """
            INSERT INTO local_reminder_rules (
                id, workspace_id, item_id, trigger_type, trigger_time, offset_minutes, rrule, is_active,
                created_at, updated_at, deleted_at, entity_version
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT (id) DO UPDATE SET
                trigger_type = excluded.trigger_type,
                trigger_time = excluded.trigger_time,
                offset_minutes = excluded.offset_minutes,
                rrule = excluded.rrule,
                is_active = excluded.is_active,
                updated_at = excluded.updated_at,
                deleted_at = excluded.deleted_at,
                entity_version = excluded.entity_version;
        """
        self.connection.execute(sql, (
            str(rule.id), str(rule.workspace_id), str(rule.item_id), rule.trigger_type.value,
            iso(rule.trigger_time), rule.offset_minutes, rule.rrule, 1 if rule.is_active else 0,
            iso(rule.created_at), iso(rule.updated_at), iso(rule.deleted_at), rule.entity_version
        ))

    def get_rule_by_id(self, workspace_id: WorkspaceId, rule_id: EntityId) -> Optional[ReminderRule]:
        cursor = self.connection.cursor()
        cursor.execute("SELECT * FROM local_reminder_rules WHERE workspace_id = ? AND id = ?;", (str(workspace_id), str(rule_id)))
        row = cursor.fetchone()
        if not row:
            return None

        # Fetch instances
        cursor.execute("SELECT * FROM local_reminder_instances WHERE rule_id = ? ORDER BY scheduled_time ASC;", (str(rule_id),))
        inst_rows = cursor.fetchall()
        instances = []
        for ir in inst_rows:
            inst = ReminderInstance(
                id=EntityId(str(ir['id'])),
                workspace_id=workspace_id,
                rule_id=rule_id,
                item_id=EntityId(str(ir['item_id'])),
                occurrence_key=ir['occurrence_key'],
                scheduled_time=parse_iso(ir['scheduled_time']),
                status=ReminderStatus(ir['status']),
                snoozed_until=parse_iso(ir['snoozed_until']),
                fired_at=parse_iso(ir['fired_at']),
                created_at=parse_iso(ir['created_at']),
                updated_at=parse_iso(ir['updated_at']),
                deleted_at=None,
                entity_version=ir['entity_version']
            )
            instances.append(inst)

        return ReminderRule(
            id=rule_id,
            workspace_id=workspace_id,
            item_id=EntityId(str(row['item_id'])),
            trigger_type=ReminderTriggerType(row['trigger_type']),
            trigger_time=parse_iso(row['trigger_time']),
            offset_minutes=row['offset_minutes'],
            rrule=row['rrule'],
            is_active=bool(row['is_active']),
            _instances=instances,
            created_at=parse_iso(row['created_at']),
            updated_at=parse_iso(row['updated_at']),
            deleted_at=parse_iso(row['deleted_at']),
            entity_version=row['entity_version']
        )

    def save_instance(self, instance: ReminderInstance) -> None:
        sql = """
            INSERT INTO local_reminder_instances (
                id, rule_id, item_id, workspace_id, occurrence_key, scheduled_time,
                status, snoozed_until, fired_at, created_at, updated_at, entity_version
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT (id) DO UPDATE SET
                status = excluded.status,
                snoozed_until = excluded.snoozed_until,
                fired_at = excluded.fired_at,
                updated_at = excluded.updated_at,
                entity_version = excluded.entity_version;
        """
        self.connection.execute(sql, (
            str(instance.id), str(instance.rule_id), str(instance.item_id), str(instance.workspace_id),
            instance.occurrence_key, iso(instance.scheduled_time), instance.status.value,
            iso(instance.snoozed_until), iso(instance.fired_at), iso(instance.created_at),
            iso(instance.updated_at), instance.entity_version
        ))

    def get_instance_by_id(self, workspace_id: WorkspaceId, instance_id: EntityId) -> Optional[ReminderInstance]:
        cursor = self.connection.cursor()
        cursor.execute("SELECT * FROM local_reminder_instances WHERE workspace_id = ? AND id = ?;", (str(workspace_id), str(instance_id)))
        ir = cursor.fetchone()
        if not ir:
            return None
        return ReminderInstance(
            id=instance_id,
            workspace_id=workspace_id,
            rule_id=EntityId(str(ir['rule_id'])),
            item_id=EntityId(str(ir['item_id'])),
            occurrence_key=ir['occurrence_key'],
            scheduled_time=parse_iso(ir['scheduled_time']),
            status=ReminderStatus(ir['status']),
            snoozed_until=parse_iso(ir['snoozed_until']),
            fired_at=parse_iso(ir['fired_at']),
            created_at=parse_iso(ir['created_at']),
            updated_at=parse_iso(ir['updated_at']),
            deleted_at=None,
            entity_version=ir['entity_version']
        )

    def list_pending_instances(self, workspace_id: WorkspaceId) -> List[ReminderInstance]:
        cursor = self.connection.cursor()
        cursor.execute(
            "SELECT id FROM local_reminder_instances WHERE workspace_id = ? AND status = 'pending' ORDER BY scheduled_time ASC;",
            (str(workspace_id),)
        )
        rows = cursor.fetchall()
        return [self.get_instance_by_id(workspace_id, EntityId(str(r['id']))) for r in rows if r]
