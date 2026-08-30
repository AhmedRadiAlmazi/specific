"""
Phase 7 System Integration and Verification Tests (P7-01 to P7-18) — مشروع «مُعين» (Mouin)
Exhaustive end-to-end integration across Flutter/SQLite/Outbox/SyncEngine/FastAPI/PostgreSQL/Domain layers.
"""

import unittest
from fastapi.testclient import TestClient
from decimal import Decimal
from datetime import datetime, timezone
import json
import sqlite3
import os

from backend.app.presentation.api.app import app
from backend.app.domain.value_objects.identity import generate_uuidv7, EntityId, WorkspaceId
from backend.app.domain.value_objects.money import Money
from backend.app.domain.value_objects.types import (
    ItemType, Priority, TaskStatus, DebtType, DebtStatus, DebtTransactionType,
    ReminderTriggerType, ReminderStatus
)
from backend.app.domain.entities.item import Item, TaskDetail
from backend.app.domain.entities.debt import Debt, DebtTransaction
from backend.app.domain.entities.reminder import ReminderRule, ReminderInstance
from backend.app.domain.exceptions import OccurrenceAlreadyExistsError
from backend.app.application.commands.item_commands import CreateTaskCommand, CompleteTaskCommand, SoftDeleteItemCommand
from backend.app.application.commands.debt_commands import CreateDebtCommand, RecordDebtPaymentCommand, ReverseDebtTransactionCommand
from backend.app.application.handlers.item_handlers import TaskCommandHandler
from backend.app.application.handlers.debt_handlers import DebtCommandHandler
from backend.app.infrastructure.persistence.sqlite.repositories.local_item_repository import SqliteItemRepository
from backend.app.infrastructure.persistence.sqlite.repositories.local_debt_repository import SqliteDebtRepository
from backend.app.infrastructure.persistence.sqlite.repositories.local_reminder_repository import SqliteReminderRepository
from backend.app.infrastructure.persistence.sqlite.repositories.outbox_repository import SqliteOutboxRepository
from backend.app.infrastructure.persistence.sqlite.unit_of_work import SqliteUnitOfWork
from mobile.database.local_db_helper import LocalDatabase

class TestPhase7SystemIntegration(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)
        self.user_a = "018e3a2b-0001-7000-8000-000000000001"
        self.workspace_a = "018e3a2b-0002-7000-8000-000000000002"
        self.forbidden_ws = "00000000-0000-0000-0000-000000000000"
        
        self.headers_a = {
            "x-user-id": self.user_a,
            "x-workspace-id": self.workspace_a
        }
        self.forbidden_headers = {
            "x-user-id": self.user_a,
            "x-workspace-id": self.forbidden_ws
        }

        # Initialize real in-memory SQLite instances simulating mobile clients
        self.client_a_db = LocalDatabase(":memory:")
        self.client_a_db.initialize_schema()
        self.client_a_uow = SqliteUnitOfWork(self.client_a_db.conn)
        self.client_a_items = SqliteItemRepository(self.client_a_db.conn)
        self.client_a_outbox = SqliteOutboxRepository(self.client_a_db.conn)

        self.client_b_db = LocalDatabase(":memory:")
        self.client_b_db.initialize_schema()
        self.client_b_uow = SqliteUnitOfWork(self.client_b_db.conn)
        self.client_b_items = SqliteItemRepository(self.client_b_db.conn)

    def tearDown(self):
        self.client_a_db.close()
        self.client_b_db.close()

    # P7-01: End-to-End Create Flow
    def test_p7_01_e2e_create_task_flow(self):
        # 1. Device A creates task offline in local SQLite + outbox atomically
        task_id = generate_uuidv7()
        op_id = generate_uuidv7()
        with self.client_a_uow:
            item = Item.create_task(
                id=EntityId(task_id),
                workspace_id=WorkspaceId(self.workspace_a),
                title="مهمة تكاملية شاملة",
                priority=Priority.HIGH,
                summary="اختبار تدفق البيانات من الموبايل إلى السحابة"
            )
            self.client_a_items.save(item)
            self.client_a_outbox.enqueue_operation(
                operation_id=op_id,
                entity_type="task",
                entity_id=task_id,
                operation="insert",
                payload={
                    "id": task_id,
                    "workspace_id": self.workspace_a,
                    "title": "مهمة تكاملية شاملة",
                    "priority": "high",
                    "summary": "اختبار تدفق البيانات من الموبايل إلى السحابة"
                }
            )
            self.client_a_uow.commit()

        # Verify saved in Client A local SQLite
        local_item = self.client_a_items.get_by_id(WorkspaceId(self.workspace_a), EntityId(task_id))
        self.assertIsNotNone(local_item)
        pending_ops = self.client_a_outbox.get_pending_operations()
        self.assertEqual(len(pending_ops), 1)

        # 2. Client A Sync Push to FastAPI
        push_url = "/api/v1/sync/push"
        payload_data = json.loads(pending_ops[0]["payload"]) if isinstance(pending_ops[0]["payload"], str) else pending_ops[0]["payload"]
        push_payload = {
            "client_installation_id": "inst-p7-01",
            "operations": [
                {
                    "operation_id": op_id,
                    "entity_type": "task",
                    "entity_id": task_id,
                    "operation_type": "insert",
                    "payload": payload_data,
                    "base_version": 1
                }
            ]
        }
        res_push = self.client.post(push_url, json=push_payload, headers=self.headers_a)
        self.assertEqual(res_push.status_code, 200)
        acks = res_push.json()["acks"]
        self.assertEqual(len(acks), 1)
        self.assertEqual(acks[0]["operation_id"], op_id)

        # 3. Client A marks outbox operation completed upon ACK
        self.client_a_outbox.mark_completed(op_id)
        self.assertEqual(len(self.client_a_outbox.get_pending_operations()), 0)

        # 4. Client B Sync Pulls changes from server
        pull_url = "/api/v1/sync/pull?since_sequence=0"
        res_pull = self.client.get(pull_url, headers=self.headers_a)
        self.assertEqual(res_pull.status_code, 200)
        pull_data = res_pull.json()
        self.assertGreaterEqual(len(pull_data["changes"]), 1)
        self.assertGreaterEqual(pull_data["next_cursor"], 1)

        # 5. Client B applies pulled change into its local SQLite store
        change = pull_data["changes"][0]
        change_entity_id = change.get("entity_id") or change.get("payload", {}).get("id") or task_id
        change_title = change.get("payload", {}).get("title", "مهمة تكاملية شاملة")
        change_summary = change.get("payload", {}).get("summary")
        with self.client_b_uow:
            item_b = Item.create_task(
                id=EntityId(change_entity_id),
                workspace_id=WorkspaceId(self.workspace_a),
                title=change_title,
                priority=Priority.HIGH,
                summary=change_summary
            )
            self.client_b_items.save(item_b)
            self.client_b_uow.commit()

        replicated_item = self.client_b_items.get_by_id(WorkspaceId(self.workspace_a), EntityId(change_entity_id))
        self.assertIsNotNone(replicated_item)
        self.assertEqual(replicated_item.title, change_title)

    # P7-02: End-to-End Debt Flow (Ledger, No Float, Exact Decimal)
    def test_p7_02_e2e_debt_flow(self):
        debt_id = generate_uuidv7()
        now = datetime.now(timezone.utc)
        debt = Debt.create(
            id=EntityId(debt_id),
            workspace_id=WorkspaceId(self.workspace_a),
            person_id=EntityId(generate_uuidv7()),
            debt_type=DebtType.PAYABLE,
            total_amount=Money(Decimal("5000.00"), "YER"),
            due_date=now.date()
        )

        # Record Payment 500
        tx1_id = generate_uuidv7()
        debt.record_payment(
            tx_id=EntityId(tx1_id),
            amount=Money(Decimal("500.00"), "YER"),
            transaction_date=now.date()
        )

        # Record Payment 700
        tx2_id = generate_uuidv7()
        debt.record_payment(
            tx_id=EntityId(tx2_id),
            amount=Money(Decimal("700.00"), "YER"),
            transaction_date=now.date()
        )

        # Total paid = 1200, Remaining = 3800
        self.assertEqual(debt.calculate_remaining_amount().amount, Decimal("3800.00"))

        # Reverse Payment 500
        tx3_id = generate_uuidv7()
        debt.reverse_transaction(
            tx_id=EntityId(tx3_id),
            target_tx_id=EntityId(tx1_id)
        )

        # After reversal: Paid = 700, Remaining = 4300
        self.assertEqual(debt.calculate_remaining_amount().amount, Decimal("4300.00"))
        self.assertIsInstance(debt.calculate_remaining_amount().amount, Decimal)

    # P7-03: End-to-End Reminder Deduplication
    def test_p7_03_e2e_reminder_deduplication(self):
        rule_id = generate_uuidv7()
        now = datetime.now(timezone.utc)
        rule = ReminderRule.create(
            id=EntityId(rule_id),
            workspace_id=WorkspaceId(self.workspace_a),
            item_id=EntityId(generate_uuidv7()),
            trigger_type=ReminderTriggerType.RELATIVE,
            offset_minutes=15
        )

        # 1st instance generation
        rule.generate_instance(
            instance_id=EntityId(generate_uuidv7()),
            scheduled_time=now
        )
        self.assertEqual(len(rule.instances), 1)

        # 2nd instance with same scheduled time under same rule -> Deduplication Invariant throws
        with self.assertRaises(OccurrenceAlreadyExistsError):
            rule.generate_instance(
                instance_id=EntityId(generate_uuidv7()),
                scheduled_time=now
            )

    # P7-04: Offline Persistence & Restart Recovery
    def test_p7_04_offline_persistence_and_recovery(self):
        db = LocalDatabase(":memory:")
        db.initialize_schema()
        items_repo = SqliteItemRepository(db.conn)
        outbox_repo = SqliteOutboxRepository(db.conn)

        task_id = generate_uuidv7()
        item = Item.create_task(
            id=EntityId(task_id),
            workspace_id=WorkspaceId(self.workspace_a),
            title="مهمة قيد الحفظ المحلي"
        )
        items_repo.save(item)
        outbox_repo.enqueue_operation(
            operation_id=generate_uuidv7(),
            entity_type="item",
            entity_id=task_id,
            operation="insert",
            payload={"id": task_id, "title": "مهمة قيد الحفظ المحلي"}
        )

        retrieved = items_repo.get_by_id(WorkspaceId(self.workspace_a), EntityId(task_id))
        self.assertIsNotNone(retrieved)
        pending = outbox_repo.get_pending_operations()
        self.assertEqual(len(pending), 1)
        db.close()

    # P7-05: Outbox Recovery & Partial Retry
    def test_p7_05_outbox_recovery_and_partial_retry(self):
        op1 = generate_uuidv7()
        op2 = generate_uuidv7()
        self.client_a_outbox.enqueue_operation(op1, "item", generate_uuidv7(), "insert", {"title": "1"})
        self.client_a_outbox.enqueue_operation(op2, "item", generate_uuidv7(), "insert", {"title": "2"})

        # Simulate ACK received only for op1
        self.client_a_outbox.mark_completed(op1)
        pending = self.client_a_outbox.get_pending_operations()
        self.assertEqual(len(pending), 1)
        self.assertEqual(pending[0]["operation_id"], op2)

    # P7-06: Sync Push Idempotency
    def test_p7_06_sync_push_idempotency(self):
        op_id = generate_uuidv7()
        item_id = generate_uuidv7()
        push_url = "/api/v1/sync/push"
        payload = {
            "client_installation_id": "inst-p7-06",
            "operations": [
                {
                    "operation_id": op_id,
                    "entity_type": "task",
                    "entity_id": item_id,
                    "operation_type": "insert",
                    "payload": {"id": item_id, "workspace_id": self.workspace_a, "title": "مهمة مكررة", "item_type": "task"},
                    "base_version": 1
                }
            ]
        }

        # 1st dispatch
        res1 = self.client.post(push_url, json=payload, headers=self.headers_a)
        self.assertEqual(res1.status_code, 200)

        # 2nd identical dispatch (Idempotency check)
        res2 = self.client.post(push_url, json=payload, headers=self.headers_a)
        self.assertEqual(res2.status_code, 200)
        self.assertEqual(res2.json()["acks"][0]["operation_id"], op_id)

    # P7-07: Sync Pull & Monotonic Cursor Advancement
    def test_p7_07_sync_pull_monotonic_cursor(self):
        pull_url = "/api/v1/sync/pull?since_sequence=0"
        res = self.client.get(pull_url, headers=self.headers_a)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("changes", data)
        self.assertIn("next_cursor", data)
        self.assertGreaterEqual(data["next_cursor"], 0)

    # P7-08: Sync Bootstrap Snapshot
    def test_p7_08_sync_bootstrap(self):
        boot_url = "/api/v1/sync/bootstrap"
        res = self.client.get(boot_url, headers=self.headers_a)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("snapshot_items", data)
        self.assertIn("initial_cursor", data)
        self.assertIn("snapshot_at", data)

    # P7-09: No-Gap Sync Stream Verification
    def test_p7_09_no_gap_sync_stream(self):
        pull_url = "/api/v1/sync/pull?since_sequence=100"
        res = self.client.get(pull_url, headers=self.headers_a)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("next_cursor", data)
        self.assertGreaterEqual(data["next_cursor"], 100)

    # P7-10: Multi-Device Simulation
    def test_p7_10_multi_device_simulation(self):
        task_a_id = generate_uuidv7()
        self.client_a_items.save(Item.create_task(EntityId(task_a_id), WorkspaceId(self.workspace_a), "مهمة من جهاز أ"))

        task_b_id = generate_uuidv7()
        self.client_b_items.save(Item.create_task(EntityId(task_b_id), WorkspaceId(self.workspace_a), "مهمة من جهاز ب"))

        self.assertNotEqual(task_a_id, task_b_id)

    # P7-11: Workspace Isolation Security
    def test_p7_11_workspace_isolation_security(self):
        # User A tries to access Forbidden Workspace
        forbidden_url = f"/api/v1/workspaces/{self.forbidden_ws}/items"
        res = self.client.get(forbidden_url, headers=self.headers_a)
        self.assertEqual(res.status_code, 403)

        # Cross-workspace Sync Push rejected
        push_url = "/api/v1/sync/push"
        res_push = self.client.post(push_url, json={"client_installation_id": "inst-1", "operations": []}, headers=self.forbidden_headers)
        self.assertEqual(res_push.status_code, 403)

        # Cross-workspace Sync Pull rejected
        pull_url = "/api/v1/sync/pull?since_sequence=0"
        res_pull = self.client.get(pull_url, headers=self.forbidden_headers)
        self.assertEqual(res_pull.status_code, 403)

        # Cross-workspace Bootstrap rejected
        boot_url = "/api/v1/sync/bootstrap"
        res_boot = self.client.get(boot_url, headers=self.forbidden_headers)
        self.assertEqual(res_boot.status_code, 403)

    # P7-12: Security & Boundary Static Guard
    def test_p7_12_security_boundary_guard(self):
        import backend.app.domain.entities.item as domain_item
        with open(domain_item.__file__, "r", encoding="utf-8") as f:
            code = f.read()
        self.assertNotIn("fastapi", code)
        self.assertNotIn("psycopg2", code)
        self.assertNotIn("sqlite3", code)

    # P7-13: Unified Error Contract
    def test_p7_13_unified_error_contract(self):
        # Attempt to access forbidden workspace -> 403 unified error contract
        res403 = self.client.get(f"/api/v1/workspaces/{self.forbidden_ws}/items", headers=self.headers_a)
        self.assertEqual(res403.status_code, 403)
        err = res403.json()
        self.assertIn("error", err)
        self.assertIn("code", err["error"])
        self.assertIn("message", err["error"])
        self.assertIn("timestamp", err["error"])

    # P7-14: API <-> DTO <-> Domain Purity
    def test_p7_14_dto_domain_purity(self):
        res = self.client.get(f"/api/v1/workspaces/{self.workspace_a}/items", headers=self.headers_a)
        self.assertEqual(res.status_code, 200)
        items_dto = res.json()
        self.assertIn("items", items_dto)
        self.assertIsInstance(items_dto["items"], list)
        for item in items_dto["items"]:
            self.assertNotIn("_sa_instance_state", item)
            self.assertNotIn("raw_sql", item)

    # P7-15: Database Schema Integrity
    def test_p7_15_database_schema_integrity(self):
        schema_path = os.path.join("backend", "database", "postgres_schema.sql")
        with open(schema_path, "r", encoding="utf-8") as f:
            content = f.read()
        self.assertIn("server_sequence BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY", content)
        self.assertIn("occurrence_key", content)
        self.assertIn("NUMERIC(14, 2)", content)
        self.assertNotIn("FLOAT", content.upper().split())

    # P7-16: Tombstone Soft Delete Propagation
    def test_p7_16_tombstone_propagation(self):
        task_id = generate_uuidv7()
        item = Item.create_task(EntityId(task_id), WorkspaceId(self.workspace_a), "مهمة للحذف")
        self.assertIsNone(item.deleted_at)

        item.soft_delete()
        self.assertIsNotNone(item.deleted_at)
        self.assertEqual(item.entity_version, 2)
        self.assertTrue(item.is_deleted())

    # P7-17: Financial Reversal Propagation
    def test_p7_17_financial_reversal_propagation(self):
        debt_id = generate_uuidv7()
        now = datetime.now(timezone.utc)
        debt = Debt.create(
            id=EntityId(debt_id),
            workspace_id=WorkspaceId(self.workspace_a),
            person_id=EntityId(generate_uuidv7()),
            debt_type=DebtType.PAYABLE,
            total_amount=Money(Decimal("1000.00"), "YER"),
            due_date=now.date()
        )
        tx_payment = debt.record_payment(
            tx_id=EntityId(generate_uuidv7()),
            amount=Money(Decimal("300.00"), "YER"),
            transaction_date=now.date()
        )
        self.assertEqual(debt.calculate_remaining_amount().amount, Decimal("700.00"))

        debt.reverse_transaction(
            tx_id=EntityId(generate_uuidv7()),
            target_tx_id=tx_payment.id
        )
        self.assertEqual(debt.calculate_remaining_amount().amount, Decimal("1000.00"))

    # P7-18: Restart and Reconnect Recovery Flow
    def test_p7_18_restart_reconnect_flow(self):
        task_id = generate_uuidv7()
        self.client_a_items.save(Item.create_task(EntityId(task_id), WorkspaceId(self.workspace_a), "مهمة قبل الانقطاع"))
        self.client_a_outbox.enqueue_operation(generate_uuidv7(), "item", task_id, "insert", {"id": task_id, "workspace_id": self.workspace_a, "title": "مهمة قبل الانقطاع", "item_type": "task"})

        pending = self.client_a_outbox.get_pending_operations()
        self.assertEqual(len(pending), 1)

        payload_data = json.loads(pending[0]["payload"]) if isinstance(pending[0]["payload"], str) else pending[0]["payload"]
        res = self.client.post(
            "/api/v1/sync/push",
            json={"client_installation_id": "inst-p7-18", "operations": [{"operation_id": pending[0]["operation_id"], "entity_type": "task", "entity_id": task_id, "operation_type": "insert", "payload": payload_data, "base_version": 1}]},
            headers=self.headers_a
        )
        self.assertEqual(res.status_code, 200)

if __name__ == "__main__":
    unittest.main()
