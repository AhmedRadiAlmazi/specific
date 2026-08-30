"""
Reminders Subsystem Router — مشروع «مُعين» (Mouin)
"""

from fastapi import APIRouter, Depends, HTTPException, status
from backend.app.presentation.api.dependencies.workspace import get_active_workspace
from backend.app.presentation.api.dependencies.container import (
    get_reminder_repo, get_reminder_handler, SqliteReminderRepository, ReminderCommandHandler
)
from backend.app.presentation.api.schemas.reminder_dto import (
    CreateReminderRuleRequest, GenerateReminderInstanceRequest, SnoozeReminderRequest,
    ReminderRuleResponseDTO, ReminderInstanceDTO
)
from backend.app.application.commands.reminder_commands import (
    CreateReminderRuleCommand, GenerateReminderInstanceCommand, SnoozeReminderCommand, DismissReminderCommand
)
from backend.app.domain.value_objects.identity import WorkspaceId, EntityId

router = APIRouter(prefix="/api/v1/workspaces/{workspace_id}/reminders", tags=["Reminders Subsystem"])

def _to_rule_dto(rule) -> ReminderRuleResponseDTO:
    inst_dtos = [
        ReminderInstanceDTO(
            id=str(inst.id),
            rule_id=str(inst.rule_id),
            item_id=str(inst.item_id),
            occurrence_key=inst.occurrence_key,
            scheduled_time=inst.scheduled_time,
            status=inst.status.value,
            snoozed_until=inst.snoozed_until
        )
        for inst in rule.instances
    ]
    return ReminderRuleResponseDTO(
        id=str(rule.id),
        workspace_id=str(rule.workspace_id),
        item_id=str(rule.item_id),
        trigger_type=rule.trigger_type.value,
        trigger_time=rule.trigger_time,
        is_active=rule.is_active,
        instances=inst_dtos
    )

@router.post("", response_model=ReminderRuleResponseDTO, status_code=status.HTTP_201_CREATED)
def create_reminder_rule(
    payload: CreateReminderRuleRequest,
    workspace_id: str = Depends(get_active_workspace),
    handler: ReminderCommandHandler = Depends(get_reminder_handler),
    repo: SqliteReminderRepository = Depends(get_reminder_repo)
):
    cmd = CreateReminderRuleCommand(
        workspace_id=workspace_id,
        item_id=payload.item_id,
        trigger_type=payload.trigger_type.value,
        trigger_time=payload.trigger_time,
        offset_minutes=payload.offset_minutes,
        rrule=payload.rrule
    )
    rule_id = handler.handle_create_rule(cmd)
    rule = repo.get_rule_by_id(WorkspaceId(workspace_id), EntityId(rule_id))
    return _to_rule_dto(rule)

@router.post("/{rule_id}/instances", response_model=ReminderRuleResponseDTO)
def generate_instance(
    rule_id: str,
    payload: GenerateReminderInstanceRequest,
    workspace_id: str = Depends(get_active_workspace),
    handler: ReminderCommandHandler = Depends(get_reminder_handler),
    repo: SqliteReminderRepository = Depends(get_reminder_repo)
):
    cmd = GenerateReminderInstanceCommand(
        workspace_id=workspace_id,
        rule_id=rule_id,
        scheduled_time=payload.scheduled_time
    )
    handler.handle_generate_instance(cmd)
    rule = repo.get_rule_by_id(WorkspaceId(workspace_id), EntityId(rule_id))
    return _to_rule_dto(rule)

@router.post("/instances/{instance_id}/snooze", status_code=status.HTTP_200_OK)
def snooze_instance(
    instance_id: str,
    payload: SnoozeReminderRequest,
    workspace_id: str = Depends(get_active_workspace),
    handler: ReminderCommandHandler = Depends(get_reminder_handler)
):
    cmd = SnoozeReminderCommand(
        workspace_id=workspace_id,
        instance_id=instance_id,
        snooze_until=payload.snooze_until
    )
    handler.handle_snooze(cmd)
    return {"status": "snoozed", "instance_id": instance_id}

@router.post("/instances/{instance_id}/dismiss", status_code=status.HTTP_200_OK)
def dismiss_instance(
    instance_id: str,
    workspace_id: str = Depends(get_active_workspace),
    handler: ReminderCommandHandler = Depends(get_reminder_handler)
):
    cmd = DismissReminderCommand(
        workspace_id=workspace_id,
        instance_id=instance_id
    )
    handler.handle_dismiss(cmd)
    return {"status": "dismissed", "instance_id": instance_id}
