"""
Item Command Handlers — مشروع «مُعين» (Mouin)
"""

from typing import Optional
from backend.app.application.exceptions import NotFoundError, UnauthorizedWorkspaceAccessError
from backend.app.application.ports.unit_of_work import IUnitOfWork
from backend.app.application.ports.event_publisher import IDomainEventPublisher
from backend.app.application.ports.repositories import IItemRepository
from backend.app.application.commands.item_commands import (
    CreateTaskCommand, CompleteTaskCommand, UpdateItemCommand, SoftDeleteItemCommand
)
from backend.app.domain.entities.item import Item
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId, InstallationId
from backend.app.domain.value_objects.types import Priority, PrivacyClassification

class TaskCommandHandler:
    def __init__(self, item_repo: IItemRepository, uow: IUnitOfWork, event_publisher: Optional[IDomainEventPublisher] = None):
        self.item_repo = item_repo
        self.uow = uow
        self.event_publisher = event_publisher

    def handle_create(self, cmd: CreateTaskCommand) -> str:
        ws_id = WorkspaceId(cmd.workspace_id)
        item_id = EntityId(cmd.item_id) if cmd.item_id else EntityId.new()
        cat_id = EntityId(cmd.category_id) if cmd.category_id else None
        inst_id = InstallationId(cmd.installation_id) if cmd.installation_id else None
        priority = Priority(cmd.priority)
        privacy = PrivacyClassification(cmd.privacy)

        with self.uow:
            task_item = Item.create_task(
                id=item_id,
                workspace_id=ws_id,
                title=cmd.title,
                due_date=cmd.due_date,
                priority=priority,
                summary=cmd.summary,
                category_id=cat_id,
                privacy=privacy,
                temporal_expression=cmd.temporal_expression,
                installation_id=inst_id
            )
            self.item_repo.save(task_item)
            if self.event_publisher:
                self.event_publisher.publish_all(task_item.collect_events())
            self.uow.commit()

        return str(item_id)

    def handle_complete(self, cmd: CompleteTaskCommand):
        ws_id = WorkspaceId(cmd.workspace_id)
        item_id = EntityId(cmd.item_id)

        with self.uow:
            item = self.item_repo.get_by_id(ws_id, item_id)
            if not item or item.is_deleted():
                raise NotFoundError(f"Task {item_id} not found in workspace {ws_id}")
            if item.workspace_id != ws_id:
                raise UnauthorizedWorkspaceAccessError(f"Cross-workspace access denied for item {item_id}")
            
            item.complete_task()
            self.item_repo.save(item)
            if self.event_publisher:
                self.event_publisher.publish_all(item.collect_events())
            self.uow.commit()

    def handle_soft_delete(self, cmd: SoftDeleteItemCommand):
        ws_id = WorkspaceId(cmd.workspace_id)
        item_id = EntityId(cmd.item_id)

        with self.uow:
            item = self.item_repo.get_by_id(ws_id, item_id)
            if not item:
                raise NotFoundError(f"Item {item_id} not found")
            item.soft_delete()
            self.item_repo.save(item)
            if self.event_publisher:
                self.event_publisher.publish_all(item.collect_events())
            self.uow.commit()
