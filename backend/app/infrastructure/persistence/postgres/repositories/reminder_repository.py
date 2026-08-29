"""
PostgreSQL Reminder Repository Implementation — مشروع «مُعين» (Mouin)
"""

from typing import List, Optional, Any
from backend.app.application.ports.repositories import IReminderRepository
from backend.app.domain.entities.reminder import ReminderRule, ReminderInstance
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId
from backend.app.domain.value_objects.types import ReminderTriggerType, ReminderStatus

class PostgresReminderRepository(IReminderRepository):
    def __init__(self, connection: Any):
        self.connection = connection

    def save_rule(self, rule: ReminderRule) -> None:
        cursor = self.connection.cursor()
        sql = """
            INSERT INTO reminder_rules (
                id, workspace_id, item_id, trigger_type, trigger_time, offset_minutes, rrule, is_active,
                created_at, updated_at, deleted_at, entity_version
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                trigger_type = EXCLUDED.trigger_type,
                trigger_time = EXCLUDED.trigger_time,
                offset_minutes = EXCLUDED.offset_minutes,
                rrule = EXCLUDED.rrule,
                is_active = EXCLUDED.is_active,
                updated_at = EXCLUDED.updated_at,
                deleted_at = EXCLUDED.deleted_at,
                entity_version = EXCLUDED.entity_version;
        """
        cursor.execute(sql, (
            str(rule.id), str(rule.workspace_id), str(rule.item_id), rule.trigger_type.value,
            rule.trigger_time, rule.offset_minutes, rule.rrule, rule.is_active,
            rule.created_at, rule.updated_at, rule.deleted_at, rule.entity_version
        ))

    def get_rule_by_id(self, workspace_id: WorkspaceId, rule_id: EntityId) -> Optional[ReminderRule]:
        cursor = self.connection.cursor()
        cursor.execute("SELECT * FROM reminder_rules WHERE workspace_id = %s AND id = %s;", (str(workspace_id), str(rule_id)))
        row = cursor.fetchone()
        if not row:
            return None
        cols = [desc[0] for desc in cursor.description]
        r_dict = dict(zip(cols, row))

        # Instances
        cursor.execute("SELECT * FROM reminder_instances WHERE rule_id = %s ORDER BY scheduled_time ASC;", (str(rule_id),))
        inst_rows = cursor.fetchall()
        inst_cols = [desc[0] for desc in cursor.description]
        instances = []
        for ir in inst_rows:
            ird = dict(zip(inst_cols, ir))
            inst = ReminderInstance(
                id=EntityId(str(ird['id'])),
                workspace_id=workspace_id,
                rule_id=rule_id,
                item_id=EntityId(str(ird['item_id'])),
                occurrence_key=ird['occurrence_key'],
                scheduled_time=ird['scheduled_time'],
                status=ReminderStatus(ird['status']),
                snoozed_until=ird.get('snoozed_until'),
                fired_at=ird.get('fired_at'),
                created_at=ird['created_at'],
                updated_at=ird['updated_at'],
                deleted_at=ird.get('deleted_at'),
                entity_version=ird.get('entity_version', 1)
            )
            instances.append(inst)

        return ReminderRule(
            id=rule_id,
            workspace_id=workspace_id,
            item_id=EntityId(str(r_dict['item_id'])),
            trigger_type=ReminderTriggerType(r_dict['trigger_type']),
            trigger_time=r_dict.get('trigger_time'),
            offset_minutes=r_dict.get('offset_minutes'),
            rrule=r_dict.get('rrule'),
            is_active=r_dict.get('is_active', True),
            _instances=instances,
            created_at=r_dict['created_at'],
            updated_at=r_dict['updated_at'],
            deleted_at=r_dict.get('deleted_at'),
            entity_version=r_dict.get('entity_version', 1)
        )

    def save_instance(self, instance: ReminderInstance) -> None:
        cursor = self.connection.cursor()
        sql = """
            INSERT INTO reminder_instances (
                id, rule_id, item_id, workspace_id, occurrence_key, scheduled_time,
                status, snoozed_until, fired_at, created_at, updated_at, deleted_at, entity_version
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                status = EXCLUDED.status,
                snoozed_until = EXCLUDED.snoozed_until,
                fired_at = EXCLUDED.fired_at,
                updated_at = EXCLUDED.updated_at,
                deleted_at = EXCLUDED.deleted_at,
                entity_version = EXCLUDED.entity_version;
        """
        cursor.execute(sql, (
            str(instance.id), str(instance.rule_id), str(instance.item_id), str(instance.workspace_id),
            instance.occurrence_key, instance.scheduled_time, instance.status.value,
            instance.snoozed_until, instance.fired_at, instance.created_at,
            instance.updated_at, instance.deleted_at, instance.entity_version
        ))

    def get_instance_by_id(self, workspace_id: WorkspaceId, instance_id: EntityId) -> Optional[ReminderInstance]:
        cursor = self.connection.cursor()
        cursor.execute("SELECT * FROM reminder_instances WHERE workspace_id = %s AND id = %s;", (str(workspace_id), str(instance_id)))
        row = cursor.fetchone()
        if not row:
            return None
        cols = [desc[0] for desc in cursor.description]
        ird = dict(zip(cols, row))
        return ReminderInstance(
            id=instance_id,
            workspace_id=workspace_id,
            rule_id=EntityId(str(ird['rule_id'])),
            item_id=EntityId(str(ird['item_id'])),
            occurrence_key=ird['occurrence_key'],
            scheduled_time=ird['scheduled_time'],
            status=ReminderStatus(ird['status']),
            snoozed_until=ird.get('snoozed_until'),
            fired_at=ird.get('fired_at'),
            created_at=ird['created_at'],
            updated_at=ird['updated_at'],
            deleted_at=ird.get('deleted_at'),
            entity_version=ird.get('entity_version', 1)
        )

    def list_pending_instances(self, workspace_id: WorkspaceId) -> List[ReminderInstance]:
        cursor = self.connection.cursor()
        cursor.execute(
            "SELECT id FROM reminder_instances WHERE workspace_id = %s AND status = 'pending' AND deleted_at IS NULL ORDER BY scheduled_time ASC;",
            (str(workspace_id),)
        )
        rows = cursor.fetchall()
        return [self.get_instance_by_id(workspace_id, EntityId(str(r[0]))) for r in rows if r]
