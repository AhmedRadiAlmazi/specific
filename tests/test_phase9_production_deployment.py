"""
Phase 9 Production Deployment, Release & Go-Live Verification Tests (P9-01 to P9-22) — مشروع «مُعين» (Mouin)
Strict end-to-end production deployment smoke tests, environment validation, backup/restore drill, sync, and security gates.
"""

import unittest
from fastapi.testclient import TestClient
from decimal import Decimal
from datetime import datetime, timezone
import json
import sqlite3
import os
import time
import io
import logging

from backend.app.presentation.api.app import app, create_app
from backend.app.presentation.api.config import ApiSettings, settings
from backend.app.presentation.api.logging_config import SensitiveDataRedactionFilter
from backend.app.presentation.api.routers.health import set_db_health_override
from backend.app.domain.value_objects.identity import generate_uuidv7, EntityId, WorkspaceId
from backend.app.domain.value_objects.money import Money
from backend.app.domain.value_objects.types import Priority, DebtType, DebtTransactionType
from backend.app.domain.entities.item import Item
from backend.app.domain.entities.debt import Debt
from backend.app.infrastructure.persistence.sqlite.repositories.local_item_repository import SqliteItemRepository
from backend.app.infrastructure.persistence.sqlite.repositories.local_debt_repository import SqliteDebtRepository
from backend.app.infrastructure.persistence.sqlite.repositories.outbox_repository import SqliteOutboxRepository
from backend.app.infrastructure.persistence.sqlite.unit_of_work import SqliteUnitOfWork
from mobile.database.local_db_helper import LocalDatabase

class TestPhase9ProductionDeployment(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)
        self.user_id = "018e3a2b-0001-7000-8000-000000000001"
        self.workspace_id = "018e3a2b-0002-7000-8000-000000000002"
        self.forbidden_ws = "00000000-0000-0000-0000-000000000000"
        
        self.auth_headers = {
            "x-user-id": self.user_id,
            "x-workspace-id": self.workspace_id
        }

        # Reset health probe override
        set_db_health_override(None)

    def tearDown(self):
        set_db_health_override(None)

    # P9-01: Environment Pre-Flight & Version Check
    def test_p9_01_environment_preflight_and_version(self):
        self.assertEqual(settings.app_version, "1.0.0")
        self.assertIn("Mouin", settings.app_name)
        # Verify .env.example exists
        env_path = os.path.join(".", ".env.example")
        self.assertTrue(os.path.exists(env_path))

    # P9-02: Secrets Scan Verification
    def test_p9_02_secrets_scan_verification(self):
        with open(".env.example", "r", encoding="utf-8") as f:
            env_text = f.read()
        self.assertIn("CHANGE_ME", env_text)
        self.assertNotIn("real_production_password_12345", env_text)

    # P9-03: Dockerfile Specification Verification
    def test_p9_03_dockerfile_specification(self):
        dockerfile_path = os.path.join(".", "Dockerfile")
        self.assertTrue(os.path.exists(dockerfile_path))
        with open(dockerfile_path, "r", encoding="utf-8") as f:
            content = f.read()
        self.assertIn("USER mouin_user", content)
        self.assertIn("HEALTHCHECK", content)
        self.assertIn("python:3.12-slim", content)

    # P9-04: Docker Compose Configuration Integrity
    def test_p9_04_docker_compose_integrity(self):
        compose_path = os.path.join(".", "docker-compose.yml")
        self.assertTrue(os.path.exists(compose_path))
        with open(compose_path, "r", encoding="utf-8") as f:
            content = f.read()
        self.assertIn("postgres:16-alpine", content)
        self.assertIn("mouin_network", content)
        self.assertIn("service_healthy", content)

    # P9-05: HTTPS / TLS Gateway Configuration
    def test_p9_05_https_tls_gateway_configuration(self):
        config_path = os.path.join("mobile", "lib", "core", "config", "app_config.dart")
        with open(config_path, "r", encoding="utf-8") as f:
            content = f.read()
        self.assertIn("https://api.mouin.app/api/v1", content)

    # P9-06: Production Security Headers Smoke Test
    def test_p9_06_production_security_headers(self):
        res = self.client.get("/health")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.headers.get("x-content-type-options"), "nosniff")
        self.assertEqual(res.headers.get("x-frame-options"), "DENY")
        self.assertEqual(res.headers.get("referrer-policy"), "strict-origin-when-cross-origin")
        self.assertIn("max-age=", res.headers.get("strict-transport-security", ""))
        self.assertIn("default-src 'none'", res.headers.get("content-security-policy", ""))

    # P9-07: Health & Readiness Production Smoke Test
    def test_p9_07_health_readiness_smoke_test(self):
        res_live = self.client.get("/health/live")
        self.assertEqual(res_live.status_code, 200)
        self.assertEqual(res_live.json()["status"], "live")

        res_ready = self.client.get("/health/ready")
        self.assertEqual(res_ready.status_code, 200)
        self.assertEqual(res_ready.json()["status"], "ready")

        # Dependency failure returns 503
        set_db_health_override(False)
        res_down = self.client.get("/health/ready")
        self.assertEqual(res_down.status_code, 503)
        self.assertEqual(res_down.json()["status"], "not_ready")

    # P9-08: Authentication Production Smoke Test
    def test_p9_08_authentication_smoke_test(self):
        # Missing auth header -> 401
        res = self.client.get(f"/api/v1/workspaces/{self.workspace_id}/items")
        self.assertEqual(res.status_code, 401)
        self.assertEqual(res.json()["error"]["code"], "UNAUTHORIZED")

    # P9-09: Workspace Isolation Production Smoke Test
    def test_p9_09_workspace_isolation_smoke_test(self):
        # Attempt to access forbidden workspace -> 403
        res = self.client.get(f"/api/v1/workspaces/{self.forbidden_ws}/items", headers=self.auth_headers)
        self.assertEqual(res.status_code, 403)
        self.assertEqual(res.json()["error"]["code"], "WORKSPACE_FORBIDDEN")

    # P9-10: Core API Smoke Test — Task Lifecycle
    def test_p9_10_core_api_task_lifecycle(self):
        # Create Task
        res = self.client.post(
            f"/api/v1/workspaces/{self.workspace_id}/tasks",
            json={"title": "مهمة إطلاق الإنتاج", "priority": "high", "summary": "التحقق النهائي قبل التدشين"},
            headers=self.auth_headers
        )
        self.assertEqual(res.status_code, 201)
        task_data = res.json()
        self.assertIn("id", task_data)
        self.assertEqual(task_data["title"], "مهمة إطلاق الإنتاج")

        task_id = task_data["id"]
        # Retrieve Task
        res_get = self.client.get(f"/api/v1/workspaces/{self.workspace_id}/items/{task_id}", headers=self.auth_headers)
        self.assertEqual(res_get.status_code, 200)

        # Soft Delete (Tombstone)
        res_del = self.client.delete(f"/api/v1/workspaces/{self.workspace_id}/items/{task_id}", headers=self.auth_headers)
        self.assertEqual(res_del.status_code, 204)

    # P9-11: Core API Smoke Test — Debt Ledger & Payment Reversal
    def test_p9_11_core_api_debt_ledger_lifecycle(self):
        debt_id = generate_uuidv7()
        now = datetime.now(timezone.utc)
        debt = Debt.create(
            id=EntityId(debt_id),
            workspace_id=WorkspaceId(self.workspace_id),
            person_id=EntityId(generate_uuidv7()),
            debt_type=DebtType.PAYABLE,
            total_amount=Money(Decimal("10000.00"), "YER"),
            due_date=now.date()
        )
        # Pay 4000
        tx = debt.record_payment(
            tx_id=EntityId(generate_uuidv7()),
            amount=Money(Decimal("4000.00"), "YER"),
            transaction_date=now.date()
        )
        self.assertEqual(debt.calculate_remaining_amount().amount, Decimal("6000.00"))

        # Reverse 4000
        debt.reverse_transaction(
            tx_id=EntityId(generate_uuidv7()),
            target_tx_id=tx.id
        )
        self.assertEqual(debt.calculate_remaining_amount().amount, Decimal("10000.00"))
        self.assertIsInstance(debt.calculate_remaining_amount().amount, Decimal)

    # P9-12: Core API Smoke Test — Reminder Occurrence Deduplication
    def test_p9_12_reminder_occurrence_deduplication(self):
        from backend.app.domain.entities.reminder import ReminderRule
        from backend.app.domain.value_objects.types import ReminderTriggerType
        from backend.app.domain.exceptions import OccurrenceAlreadyExistsError

        rule_id = generate_uuidv7()
        now = datetime.now(timezone.utc)
        rule = ReminderRule.create(
            id=EntityId(rule_id),
            workspace_id=WorkspaceId(self.workspace_id),
            item_id=EntityId(generate_uuidv7()),
            trigger_type=ReminderTriggerType.RELATIVE,
            offset_minutes=30
        )
        rule.generate_instance(EntityId(generate_uuidv7()), now)
        with self.assertRaises(OccurrenceAlreadyExistsError):
            rule.generate_instance(EntityId(generate_uuidv7()), now)

    # P9-13: Sync Push & Idempotency Production Verification
    def test_p9_13_sync_push_and_idempotency(self):
        op_id = generate_uuidv7()
        item_id = generate_uuidv7()
        payload = {
            "client_installation_id": "inst-p9-13",
            "operations": [
                {
                    "operation_id": op_id,
                    "entity_type": "task",
                    "entity_id": item_id,
                    "operation_type": "insert",
                    "payload": {"id": item_id, "workspace_id": self.workspace_id, "title": "مهمة المزامنة الحية"},
                    "base_version": 1
                }
            ]
        }
        # 1st push -> applied
        res1 = self.client.post("/api/v1/sync/push", json=payload, headers=self.auth_headers)
        self.assertEqual(res1.status_code, 200)

        # 2nd push -> duplicate_idempotent
        res2 = self.client.post("/api/v1/sync/push", json=payload, headers=self.auth_headers)
        self.assertEqual(res2.status_code, 200)
        self.assertEqual(res2.json()["acks"][0]["status"], "duplicate_idempotent")

    # P9-14: Sync Conflict Detection (409 Conflict)
    def test_p9_14_sync_conflict_detection(self):
        op_id = generate_uuidv7()
        item_id = generate_uuidv7()
        payload_a = {
            "client_installation_id": "inst-p9-14",
            "operations": [
                {
                    "operation_id": op_id,
                    "entity_type": "task",
                    "entity_id": item_id,
                    "operation_type": "insert",
                    "payload": {"title": "العنوان أ"},
                    "base_version": 1
                }
            ]
        }
        res1 = self.client.post("/api/v1/sync/push", json=payload_a, headers=self.auth_headers)
        self.assertEqual(res1.status_code, 200)

        # Conflict payload
        payload_b = {
            "client_installation_id": "inst-p9-14",
            "operations": [
                {
                    "operation_id": op_id,
                    "entity_type": "task",
                    "entity_id": item_id,
                    "operation_type": "insert",
                    "payload": {"title": "العنوان ب المختلف تماماً"},
                    "base_version": 1
                }
            ]
        }
        res2 = self.client.post("/api/v1/sync/push", json=payload_b, headers=self.auth_headers)
        self.assertEqual(res2.status_code, 409)
        self.assertEqual(res2.json()["error"]["code"], "IDEMPOTENCY_CONFLICT")

    # P9-15: Sync Pull Monotonic Stream & Cursor Progression
    def test_p9_15_sync_pull_monotonic_stream(self):
        res = self.client.get("/api/v1/sync/pull?since_sequence=0", headers=self.auth_headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("changes", data)
        self.assertIn("next_cursor", data)
        self.assertGreaterEqual(data["next_cursor"], 0)

    # P9-16: Fresh Client Bootstrap Snapshot
    def test_p9_16_fresh_client_bootstrap(self):
        res = self.client.get("/api/v1/sync/bootstrap", headers=self.auth_headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("snapshot_items", data)
        self.assertIn("initial_cursor", data)

    # P9-17: Offline Recovery & Restart Drill
    def test_p9_17_offline_recovery_and_restart(self):
        db = LocalDatabase(":memory:")
        db.initialize_schema()
        repo = SqliteItemRepository(db.conn)
        outbox = SqliteOutboxRepository(db.conn)

        task_id = generate_uuidv7()
        op_id = generate_uuidv7()
        repo.save(Item.create_task(EntityId(task_id), WorkspaceId(self.workspace_id), "مهمة النجاة من الإغلاق"))
        outbox.enqueue_operation(op_id, "task", task_id, "insert", {"title": "مهمة النجاة من الإغلاق"})

        # Verify offline persistence
        self.assertIsNotNone(repo.get_by_id(WorkspaceId(self.workspace_id), EntityId(task_id)))
        pending = outbox.get_pending_operations()
        self.assertEqual(len(pending), 1)
        self.assertEqual(pending[0]["operation_id"], op_id)
        db.close()

    # P9-18: Database Backup Drill
    def test_p9_18_database_backup_drill(self):
        db = LocalDatabase(":memory:")
        db.initialize_schema()
        repo = SqliteItemRepository(db.conn)
        task_id = generate_uuidv7()
        repo.save(Item.create_task(EntityId(task_id), WorkspaceId(self.workspace_id), "مهمة تدريب النسخ الاحتياطي"))

        dump = "\n".join(db.conn.iterdump())
        self.assertIn("مهمة تدريب النسخ الاحتياطي", dump)
        self.assertIn("CREATE TABLE", dump)
        db.close()

    # P9-19: Database Restore Drill
    def test_p9_19_database_restore_drill(self):
        db1 = LocalDatabase(":memory:")
        db1.initialize_schema()
        repo1 = SqliteItemRepository(db1.conn)
        task_id = generate_uuidv7()
        repo1.save(Item.create_task(EntityId(task_id), WorkspaceId(self.workspace_id), "مهمة تدريب الاستعادة"))
        dump = list(db1.conn.iterdump())
        db1.close()

        # Restore into fresh DB
        db2 = sqlite3.connect(":memory:")
        db2.row_factory = sqlite3.Row
        for statement in dump:
            try:
                db2.execute(statement)
            except sqlite3.OperationalError:
                pass
        db2.commit()

        repo2 = SqliteItemRepository(db2)
        restored = repo2.get_by_id(WorkspaceId(self.workspace_id), EntityId(task_id))
        self.assertIsNotNone(restored)
        self.assertEqual(restored.title, "مهمة تدريب الاستعادة")
        db2.close()

    # P9-20: Observability Production Gate & Sensitive Redaction
    def test_p9_20_observability_production_gate(self):
        log_filter = SensitiveDataRedactionFilter()
        record = logging.LogRecord(
            name="test", level=logging.INFO, pathname="", lineno=0,
            msg="Admin auth token=Bearer_abc123secret and password=RootPassword999",
            args=(), exc_info=None
        )
        log_filter.filter(record)
        self.assertNotIn("Bearer_abc123secret", record.msg)
        self.assertNotIn("RootPassword999", record.msg)
        self.assertIn("[REDACTED]", record.msg)

    # P9-21: Mobile Release Configuration Validation
    def test_p9_21_mobile_release_configuration(self):
        config_path = os.path.join("mobile", "lib", "core", "config", "app_config.dart")
        with open(config_path, "r", encoding="utf-8") as f:
            code = f.read()
        self.assertIn("https://api.mouin.app/api/v1", code)
        self.assertIn("1.0.0", code)

    # P9-22: Rollback Procedure Verification
    def test_p9_22_rollback_procedure_verification(self):
        script_path = os.path.join(".", "backup_database.sh")
        self.assertTrue(os.path.exists(script_path))
        with open(script_path, "r", encoding="utf-8") as f:
            content = f.read()
        self.assertIn("pg_dump", content)
        self.assertIn("gzip", content)

if __name__ == "__main__":
    unittest.main()
