"""
Reminder Command Handlers — مشروع «مُعين» (Mouin)
"""

from typing import Optional
from backend.app.application.exceptions import NotFoundError
from backend.app.application.ports.unit_of_work import IUnitOfWork
from backend.app.application.ports.event_publisher import IDomainEventPublisher
from backend.app.application.ports.repositories import IReminderRepository
from backend.app.application.commands.reminder_commands import (
    CreateReminderRuleCommand, GenerateReminderInstanceCommand, SnoozeReminderCommand, DismissReminderCommand
)
from backend.app.domain.entities.reminder import ReminderRule
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId
from backend.app.domain.value_objects.types import ReminderTriggerType

class ReminderCommandHandler:
    def __init__(self, reminder_repo: IReminderRepository, uow: IUnitOfWork, event_publisher: Optional[IDomainEventPublisher] = None):
        self.reminder_repo = reminder_repo
        self.uow = uow
        self.event_publisher = event_publisher

    def handle_create_rule(self, cmd: CreateReminderRuleCommand) -> str:
        ws_id = WorkspaceId(cmd.workspace_id)
        rule_id = EntityId(cmd.rule_id) if cmd.rule_id else EntityId.new()
        item_id = EntityId(cmd.item_id)
        trigger_type = ReminderTriggerType(cmd.trigger_type)

        with self.uow:
            rule = ReminderRule.create(
                id=rule_id,
                workspace_id=ws_id,
                item_id=item_id,
                trigger_type=trigger_type,
                trigger_time=cmd.trigger_time,
                offset_minutes=cmd.offset_minutes,
                rrule=cmd.rrule
            )
            self.reminder_repo.save_rule(rule)
            if self.event_publisher:
                self.event_publisher.publish_all(rule.collect_events())
            self.uow.commit()

        return str(rule_id)

    def handle_generate_instance(self, cmd: GenerateReminderInstanceCommand) -> str:
        ws_id = WorkspaceId(cmd.workspace_id)
        rule_id = EntityId(cmd.rule_id)
        inst_id = EntityId(cmd.instance_id) if cmd.instance_id else EntityId.new()

        with self.uow:
            rule = self.reminder_repo.get_rule_by_id(ws_id, rule_id)
            if not rule or rule.is_deleted():
                raise NotFoundError(f"Reminder rule {rule_id} not found in workspace {ws_id}")
            
            instance = rule.generate_instance(inst_id, cmd.scheduled_time)
            self.reminder_repo.save_rule(rule)
            self.reminder_repo.save_instance(instance)
            if self.event_publisher:
                self.event_publisher.publish_all(rule.collect_events())
            self.uow.commit()

        return str(instance.id)

    def handle_snooze(self, cmd: SnoozeReminderCommand):
        ws_id = WorkspaceId(cmd.workspace_id)
        inst_id = EntityId(cmd.instance_id)

        with self.uow:
            inst = self.reminder_repo.get_instance_by_id(ws_id, inst_id)
            if not inst or inst.is_deleted():
                raise NotFoundError(f"Reminder instance {inst_id} not found")
            inst.snooze(cmd.snooze_until)
            self.reminder_repo.save_instance(inst)
            self.uow.commit()

    def handle_dismiss(self, cmd: DismissReminderCommand):
        ws_id = WorkspaceId(cmd.workspace_id)
        inst_id = EntityId(cmd.instance_id)

        with self.uow:
            inst = self.reminder_repo.get_instance_by_id(ws_id, inst_id)
            if not inst or inst.is_deleted():
                raise NotFoundError(f"Reminder instance {inst_id} not found")
            inst.dismiss()
            self.reminder_repo.save_instance(inst)
            self.uow.commit()
