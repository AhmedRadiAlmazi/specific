"""
Inbox & AI Suggestion Application Handlers — مشروع «مُعين» (Mouin)
Coordinates staging acceptance and converts confirmed AI suggestions into Domain Commands.
Strictly adheres to the Single Domain Mutation Path.
"""

from typing import Optional, Dict, Any
from decimal import Decimal
from backend.app.application.ports.repositories import IInboxRepository
from backend.app.application.ports.unit_of_work import IUnitOfWork
from backend.app.application.commands.inbox_commands import CreateInboxItemCommand, ConfirmAISuggestionCommand
from backend.app.application.commands.item_commands import CreateUnifiedItemCommand
from backend.app.application.handlers.item_handlers import TaskCommandHandler
from backend.app.domain.entities.inbox import InboxItem, AISuggestion
from backend.app.domain.value_objects.identity import WorkspaceId, EntityId, InstallationId, UserId
from backend.app.domain.value_objects.types import InboxSourceType, ItemType, Priority

class InboxCommandHandler:
    def __init__(
        self,
        inbox_repo: IInboxRepository,
        uow: IUnitOfWork,
        item_handler: Optional[TaskCommandHandler] = None
    ):
        self.inbox_repo = inbox_repo
        self.uow = uow
        self.item_handler = item_handler

    def handle_create(self, cmd: CreateInboxItemCommand) -> str:
        """Creates a raw capture in the inbox staging area."""
        ws_id = WorkspaceId(cmd.workspace_id)
        item_id = EntityId(cmd.inbox_id) if cmd.inbox_id else EntityId.new()
        inst_id = InstallationId(cmd.installation_id) if cmd.installation_id else None

        source = InboxSourceType(cmd.source_type) if hasattr(InboxSourceType, cmd.source_type) else InboxSourceType.MANUAL_QUICK_NOTE

        inbox_item = InboxItem(
            id=item_id,
            workspace_id=ws_id,
            raw_text=cmd.raw_text,
            source_type=source,
            created_by_installation_id=inst_id
        )

        with self.uow:
            self.inbox_repo.save_inbox_item(inbox_item)
            self.uow.commit()

        return str(item_id)

    def handle_confirm_suggestion(self, cmd: ConfirmAISuggestionCommand) -> Dict[str, Any]:
        """
        Confirms or rejects an AI Suggestion.
        When accepted, bridges directly to Domain Commands to ensure single mutation path.
        """
        ws_id = WorkspaceId(cmd.workspace_id)
        sug_id = EntityId(cmd.suggestion_id)
        user_id = UserId(cmd.user_id)

        with self.uow:
            suggestion = self.inbox_repo.get_suggestion_by_id(ws_id, sug_id)
            if not suggestion:
                raise ValueError(f"AI Suggestion {cmd.suggestion_id} not found in workspace {cmd.workspace_id}.")

            created_domain_id = None

            if cmd.accepted:
                suggestion.accept(user_id)
                self.inbox_repo.save_suggestion(suggestion)

                # Bridge to Domain Command if item_handler is wired
                if self.item_handler is not None and suggestion.suggested_payload:
                    payload = suggestion.suggested_payload
                    item_type_str = payload.get("item_type", "task").lower()
                    
                    try:
                        item_type = ItemType(item_type_str)
                    except ValueError:
                        item_type = ItemType.TASK

                    task_detail = None
                    if item_type == ItemType.TASK:
                        task_detail = {
                            "priority": payload.get("priority", Priority.MEDIUM.value),
                            "due_date": payload.get("due_date")
                        }

                    create_cmd = CreateUnifiedItemCommand(
                        workspace_id=cmd.workspace_id,
                        item_type=item_type.value,
                        title=payload.get("title", "عنصر مقترح من مُعين"),
                        summary=payload.get("summary") or payload.get("description"),
                        task_detail=task_detail,
                        item_id=payload.get("id")
                    )
                    created_domain_id = self.item_handler.handle_create_unified_item(create_cmd)
            else:
                suggestion.reject(user_id)
                self.inbox_repo.save_suggestion(suggestion)

            self.uow.commit()

            return {
                "suggestion_id": cmd.suggestion_id,
                "status": suggestion.validation_status.value if hasattr(suggestion.validation_status, 'value') else str(suggestion.validation_status),
                "created_domain_id": created_domain_id
            }
