"""
Item Command Handlers — مشروع «مُعين» (Mouin)
Implements CQRS Command Handlers for Tasks and Unified Items.
"""

from typing import Optional
from datetime import datetime, date
from backend.app.application.exceptions import NotFoundError, UnauthorizedWorkspaceAccessError
from backend.app.application.ports.unit_of_work import IUnitOfWork
from backend.app.application.ports.event_publisher import IDomainEventPublisher
from backend.app.application.ports.repositories import IItemRepository
from backend.app.application.commands.item_commands import (
    CreateTaskCommand, CreateUnifiedItemCommand, CompleteTaskCommand, UpdateItemCommand, SoftDeleteItemCommand
)
from backend.app.domain.entities.item import Item, TaskDetail, NoteDetail, AppointmentDetail, DocumentDetail
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId, InstallationId
from backend.app.domain.value_objects.types import ItemType, Priority, PrivacyClassification, TaskStatus

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

    def handle_create_unified_item(self, cmd: CreateUnifiedItemCommand) -> str:
        ws_id = WorkspaceId(cmd.workspace_id)
        item_id = EntityId(cmd.item_id) if cmd.item_id else EntityId.new()
        cat_id = EntityId(cmd.category_id) if cmd.category_id else None
        inst_id = InstallationId(cmd.installation_id) if cmd.installation_id else None
        privacy = PrivacyClassification(cmd.privacy)
        item_type = ItemType(cmd.item_type.lower())

        with self.uow:
            if item_type == ItemType.TASK:
                t_detail = cmd.task_detail or {}
                due = t_detail.get("due_date")
                if isinstance(due, str):
                    due = datetime.fromisoformat(due.replace("Z", "+00:00"))
                prio = Priority(t_detail.get("priority", "medium"))
                item = Item.create_task(
                    id=item_id, workspace_id=ws_id, title=cmd.title,
                    due_date=due, priority=prio, summary=cmd.summary,
                    category_id=cat_id, privacy=privacy, installation_id=inst_id
                )
            elif item_type == ItemType.NOTE:
                n_detail = cmd.note_detail or {}
                item = Item.create_note(
                    id=item_id, workspace_id=ws_id, title=cmd.title,
                    content=n_detail.get("content", ""),
                    content_format=n_detail.get("content_format", "plain_text"),
                    summary=cmd.summary, category_id=cat_id, privacy=privacy, installation_id=inst_id
                )
            elif item_type == ItemType.APPOINTMENT:
                a_detail = cmd.appointment_detail or {}
                start = a_detail.get("start_time") or datetime.now(timezone.utc)
                if isinstance(start, str):
                    start = datetime.fromisoformat(start.replace("Z", "+00:00"))
                end = a_detail.get("end_time")
                if isinstance(end, str):
                    end = datetime.fromisoformat(end.replace("Z", "+00:00"))
                item = Item.create_appointment(
                    id=item_id, workspace_id=ws_id, title=cmd.title,
                    start_time=start, end_time=end,
                    location=a_detail.get("location"),
                    all_day=bool(a_detail.get("all_day", False)),
                    timezone_str=a_detail.get("timezone", "Asia/Aden"),
                    summary=cmd.summary, category_id=cat_id, privacy=privacy, installation_id=inst_id
                )
            elif item_type == ItemType.DOCUMENT:
                d_detail = cmd.document_detail or {}
                item = Item.create_document(
                    id=item_id, workspace_id=ws_id, title=cmd.title,
                    document_type=d_detail.get("document_type", "general"),
                    document_number=d_detail.get("document_number"),
                    issuing_authority=d_detail.get("issuing_authority"),
                    summary=cmd.summary, category_id=cat_id, privacy=privacy, installation_id=inst_id
                )
            else:
                # Generic fallback item (shopping, etc.)
                item = Item(
                    id=item_id, workspace_id=ws_id, item_type=item_type,
                    title=cmd.title, summary=cmd.summary, category_id=cat_id,
                    privacy_classification=privacy, created_by_installation_id=inst_id
                )

            self.item_repo.save(item)
            if self.event_publisher:
                self.event_publisher.publish_all(item.collect_events())
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

    def handle_update(self, cmd: UpdateItemCommand):
        ws_id = WorkspaceId(cmd.workspace_id)
        item_id = EntityId(cmd.item_id)

        with self.uow:
            item = self.item_repo.get_by_id(ws_id, item_id)
            if not item or item.is_deleted():
                raise NotFoundError(f"Item {item_id} not found in workspace {ws_id}")
            if item.workspace_id != ws_id:
                raise UnauthorizedWorkspaceAccessError(f"Cross-workspace access denied for item {item_id}")
            
            item.update_title_and_summary(cmd.title, cmd.summary)
            if cmd.privacy:
                item.privacy_classification = PrivacyClassification(cmd.privacy)
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

# Alias for generic use
ItemCommandHandler = TaskCommandHandler
