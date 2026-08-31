"""
Phase 4 Integration Tests: Inbox Staging, AI Confirmation, and PostgreSQL Repositories
مشروع «مُعين» (Mouin)
"""

import unittest
from unittest.mock import MagicMock
from decimal import Decimal
import json

from backend.app.domain.entities.inbox import InboxItem, AISuggestion
from backend.app.domain.value_objects.identity import WorkspaceId, EntityId, UserId
from backend.app.domain.value_objects.types import InboxSourceType, AISuggestionValidationStatus, ItemType
from backend.app.application.commands.inbox_commands import CreateInboxItemCommand, ConfirmAISuggestionCommand
from backend.app.application.handlers.inbox_handlers import InboxCommandHandler
from backend.app.infrastructure.persistence.postgres.repositories.inbox_repository import PostgresInboxRepository
from backend.app.infrastructure.persistence.postgres.repositories.attachment_repository import PostgresAttachmentRepository
from backend.app.infrastructure.persistence.postgres.repositories.shopping_repository import PostgresShoppingRepository
from backend.app.infrastructure.persistence.postgres.repositories.user_repository import PostgresUserRepository

class TestInboxAIStaging(unittest.TestCase):
    def setUp(self):
        self.mock_conn = MagicMock()
        self.mock_cursor = MagicMock()
        self.mock_conn.cursor.return_value = self.mock_cursor
        
        self.inbox_repo = PostgresInboxRepository(self.mock_conn)
        self.attachment_repo = PostgresAttachmentRepository(self.mock_conn)
        self.shopping_repo = PostgresShoppingRepository(self.mock_conn)
        self.user_repo = PostgresUserRepository(self.mock_conn)
        
        self.uow = MagicMock()
        self.item_handler = MagicMock()
        self.inbox_handler = InboxCommandHandler(self.inbox_repo, self.uow, self.item_handler)
        
        self.ws_id = "018e3a2b-0002-7000-8000-000000000002"
        self.user_id = "018e3a2b-0001-7000-8000-000000000001"

    def test_inbox_create_command(self):
        cmd = CreateInboxItemCommand(
            workspace_id=self.ws_id,
            raw_text="ذكرني اتصل بالدكتور غداً الساعة 5",
            source_type="voice_transcript"
        )
        item_id = self.inbox_handler.handle_create(cmd)
        self.assertTrue(len(item_id) > 10)
        self.mock_cursor.execute.assert_called()

    def test_confirm_ai_suggestion_accepted_bridges_to_domain(self):
        sug_id = "018e3a2b-0010-7000-8000-000000000010"
        mock_suggestion = AISuggestion(
            id=EntityId(sug_id),
            workspace_id=WorkspaceId(self.ws_id),
            inbox_item_id=EntityId.new(),
            intent="create_task",
            suggested_payload={"item_type": "task", "title": "الاتصال بالدكتور", "priority": "high"},
            confidence_score=Decimal("0.950"),
            validation_status=AISuggestionValidationStatus.PENDING_REVIEW
        )
        
        # Configure mock get_suggestion_by_id
        self.mock_cursor.fetchone.return_value = (
            sug_id, self.ws_id, str(mock_suggestion.inbox_item_id), "create_task",
            json.dumps(mock_suggestion.suggested_payload), 0.950, "pending_review", "2026-08-31T20:00:00Z"
        )
        
        self.item_handler.handle_create_unified_item.return_value = "new-task-uuid"

        cmd = ConfirmAISuggestionCommand(
            workspace_id=self.ws_id,
            suggestion_id=sug_id,
            user_id=self.user_id,
            accepted=True
        )

        res = self.inbox_handler.handle_confirm_suggestion(cmd)
        self.assertEqual(res["status"], "accepted")
        self.assertEqual(res["created_domain_id"], "new-task-uuid")
        self.item_handler.handle_create_unified_item.assert_called_once()

    def test_confirm_ai_suggestion_rejected(self):
        sug_id = "018e3a2b-0010-7000-8000-000000000010"
        self.mock_cursor.fetchone.return_value = (
            sug_id, self.ws_id, "018e3a2b-0009-7000-8000-000000000009", "create_task",
            "{}", 0.950, "pending_review", "2026-08-31T20:00:00Z"
        )

        cmd = ConfirmAISuggestionCommand(
            workspace_id=self.ws_id,
            suggestion_id=sug_id,
            user_id=self.user_id,
            accepted=False
        )

        res = self.inbox_handler.handle_confirm_suggestion(cmd)
        self.assertEqual(res["status"], "rejected")
        self.assertIsNone(res["created_domain_id"])
        self.item_handler.handle_create_unified_item.assert_not_called()

    def test_user_repository_workspace_membership_check(self):
        self.mock_cursor.fetchone.return_value = (1,)
        is_member = self.user_repo.is_member_of_workspace(self.user_id, self.ws_id)
        self.assertTrue(is_member)

        self.mock_cursor.fetchone.return_value = None
        is_not_member = self.user_repo.is_member_of_workspace("intruder-user", self.ws_id)
        self.assertFalse(is_not_member)

if __name__ == "__main__":
    unittest.main()
