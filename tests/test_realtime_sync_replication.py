"""
Phase 5 Real-Time Sync & Multi-Device Replication Test Suite — مشروع «مُعين» (Mouin)
Validates Bidirectional Push/Pull Replication, SHA-256 Idempotency, and Cross-Device Convergence.
"""

import unittest
from unittest.mock import MagicMock
import json
import hashlib
from datetime import datetime, timezone

from backend.app.presentation.api.dependencies.sync_service import SyncApplicationService
from backend.app.domain.value_objects.identity import WorkspaceId, EntityId

class TestRealtimeSyncReplication(unittest.TestCase):
    def setUp(self):
        self.mock_item_repo = MagicMock()
        self.mock_debt_repo = MagicMock()
        self.mock_uow = MagicMock()
        self.sync_service = SyncApplicationService(
            item_repo=self.mock_item_repo,
            debt_repo=self.mock_debt_repo,
            uow=self.mock_uow,
            sync_repo=None  # in-memory stream mode
        )
        self.ws_id_a = "018e3a2b-0002-7000-8000-000000000002"
        self.ws_id_b = "018e3a2b-0003-7000-8000-000000000003"

    def test_multi_device_push_and_pull_replication(self):
        # 1. Device A pushes an offline-created Task
        op_1 = {
            "operation_id": "op-task-001",
            "entity_type": "item",
            "entity_id": "task-uuid-001",
            "operation_type": "insert",
            "payload": {
                "id": "task-uuid-001",
                "title": "شراء حليب وخبز",
                "priority": "high",
                "status": "pending"
            },
            "base_version": 1
        }
        
        # 2. Device A pushes an offline-created Debt
        op_2 = {
            "operation_id": "op-debt-001",
            "entity_type": "debt",
            "entity_id": "debt-uuid-001",
            "operation_type": "insert",
            "payload": {
                "id": "debt-uuid-001",
                "person_id": "سالم",
                "debt_type": "receivable",
                "total_amount": "5000.00"
            },
            "base_version": 1
        }

        acks = self.sync_service.handle_push(self.ws_id_a, [op_1, op_2])
        self.assertEqual(len(acks), 2)
        self.assertEqual(acks[0]["status"], "success")
        self.assertEqual(acks[1]["status"], "success")
        self.assertEqual(acks[0]["server_sequence"], 1)
        self.assertEqual(acks[1]["server_sequence"], 2)

        # 3. Device B pulls changes since sequence 0
        pull_result = self.sync_service.handle_pull(self.ws_id_a, since_sequence=0, limit=50)
        changes = pull_result["changes"]
        self.assertEqual(len(changes), 2)
        self.assertEqual(changes[0]["payload"]["title"], "شراء حليب وخبز")
        self.assertEqual(changes[1]["payload"]["person_id"], "سالم")
        self.assertEqual(pull_result["next_cursor"], 2)
        self.assertFalse(pull_result["has_more"])

    def test_sync_push_idempotency_prevents_duplicate_records(self):
        op = {
            "operation_id": "op-idempotent-001",
            "entity_type": "item",
            "entity_id": "task-uuid-002",
            "operation_type": "insert",
            "payload": {"title": "دفع فاتورة الكهرباء"},
            "base_version": 1
        }

        # First Push
        acks_1 = self.sync_service.handle_push(self.ws_id_a, [op])
        self.assertEqual(acks_1[0]["status"], "success")
        self.assertEqual(acks_1[0]["server_sequence"], 1)

        # Replayed Duplicate Push
        acks_2 = self.sync_service.handle_push(self.ws_id_a, [op])
        self.assertEqual(acks_2[0]["status"], "duplicate_idempotent")

        # Stream should still contain only 1 change
        pull = self.sync_service.handle_pull(self.ws_id_a, since_sequence=0)
        self.assertEqual(len(pull["changes"]), 1)

    def test_cross_tenant_workspace_isolation_in_pull(self):
        op_a = {
            "operation_id": "op-ws-a",
            "entity_type": "item",
            "entity_id": "task-a",
            "operation_type": "insert",
            "payload": {"title": "خاص بـ Workspace A"}
        }
        op_b = {
            "operation_id": "op-ws-b",
            "entity_type": "item",
            "entity_id": "task-b",
            "operation_type": "insert",
            "payload": {"title": "خاص بـ Workspace B"}
        }

        self.sync_service.handle_push(self.ws_id_a, [op_a])
        self.sync_service.handle_push(self.ws_id_b, [op_b])

        pull_a = self.sync_service.handle_pull(self.ws_id_a, since_sequence=0)
        self.assertEqual(len(pull_a["changes"]), 1)
        self.assertEqual(pull_a["changes"][0]["payload"]["title"], "خاص بـ Workspace A")

        pull_b = self.sync_service.handle_pull(self.ws_id_b, since_sequence=0)
        self.assertEqual(len(pull_b["changes"]), 1)
        self.assertEqual(pull_b["changes"][0]["payload"]["title"], "خاص بـ Workspace B")

if __name__ == "__main__":
    unittest.main()
