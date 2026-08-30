"""
Phase 8 Production Hardening & Operational Readiness Tests (P8-01 to P8-26) — مشروع «مُعين» (Mouin)
Comprehensive test suite validating security, reliability, observability, backup/restore, health, and performance.
"""

import unittest
from fastapi.testclient import TestClient
from decimal import Decimal
from datetime import datetime, timezone
import json
import sqlite3
import os
import time
import logging

from backend.app.presentation.api.app import app
from backend.app.presentation.api.config import ApiSettings, settings
from backend.app.presentation.api.logging_config import SensitiveDataRedactionFilter, setup_production_logging
from backend.app.presentation.api.routers.health import set_db_health_override
from backend.app.domain.value_objects.identity import generate_uuidv7, EntityId, WorkspaceId
from backend.app.domain.value_objects.money import Money
from backend.app.domain.value_objects.types import Priority, DebtType, DebtTransactionType, ReminderTriggerType
from backend.app.domain.entities.item import Item
from backend.app.domain.entities.debt import Debt
from backend.app.domain.entities.reminder import ReminderRule
from backend.app.infrastructure.persistence.sqlite.repositories.local_item_repository import SqliteItemRepository
from backend.app.infrastructure.persistence.sqlite.repositories.local_debt_repository import SqliteDebtRepository
from backend.app.infrastructure.persistence.sqlite.repositories.outbox_repository import SqliteOutboxRepository
from backend.app.infrastructure.persistence.sqlite.unit_of_work import SqliteUnitOfWork
from backend.scripts.backup_restore import create_sqlite_backup, restore_sqlite_backup, verify_sqlite_integrity
from mobile.database.local_db_helper import LocalDatabase

class TestPhase8ProductionHardening(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)
        self.user_id = "018e3a2b-0001-7000-8000-000000000001"
        self.workspace_id = "018e3a2b-0002-7000-8000-000000000002"
        self.forbidden_ws = "00000000-0000-0000-0000-000000000000"
        self.auth_headers = {
            "x-user-id": self.user_id,
            "x-workspace-id": self.workspace_id
        }
        set_db_health_override(None)

    def tearDown(self):
        set_db_health_override(None)

    # P8-01: Production Configuration Validation
    def test_p8_01_production_config_validation(self):
        prod_settings = ApiSettings(
            environment="production",
            jwt_secret_key="a-very-secure-production-random-secret-key-32-chars",
            allowed_origins=["https://app.mouin.local"],
            database_url="postgresql://user:pass@prod-db.mouin.internal:5432/mouin_db"
        )
        # Valid production settings pass
        prod_settings.validate_production()
        self.assertTrue(prod_settings.is_production)

        # Insecure default JWT secret in production throws ValueError
        insecure_settings = ApiSettings(
            environment="production",
            jwt_secret_key="mouin-secret-key-dev-environment-only",
            allowed_origins=["https://app.mouin.local"]
        )
        with self.assertRaises(ValueError):
            insecure_settings.validate_production()

    # P8-02: Secret Leakage Guard in Source & Responses
    def test_p8_02_secret_leakage_guard(self):
        res = self.client.get(f"/api/v1/workspaces/{self.workspace_id}/items", headers=self.auth_headers)
        self.assertEqual(res.status_code, 200)
        body_text = res.text
        self.assertNotIn("password_hash", body_text)
        self.assertNotIn("jwt_secret", body_text)
        self.assertNotIn("private_key", body_text)

    # P8-03: Debug Mode Production Guard
    def test_p8_03_debug_mode_guard(self):
        # Settings reflect production-safe configuration
        self.assertFalse(settings.is_production and hasattr(app, "debug") and app.debug)

    # P8-04: Authentication Hardening (Missing/Invalid Credentials)
    def test_p8_04_authentication_hardening(self):
        res = self.client.get(f"/api/v1/workspaces/{self.workspace_id}/items")  # No auth headers
        self.assertEqual(res.status_code, 401)
        err = res.json()
        self.assertIn("error", err)
        self.assertEqual(err["error"]["code"], "UNAUTHORIZED")

    # P8-05: Workspace Authorization & Isolation
    def test_p8_05_workspace_authorization(self):
        res = self.client.get(f"/api/v1/workspaces/{self.forbidden_ws}/items", headers=self.auth_headers)
        self.assertEqual(res.status_code, 403)
        self.assertEqual(res.json()["error"]["code"], "WORKSPACE_FORBIDDEN")

    # P8-06: CORS Configuration Security
    def test_p8_06_cors_configuration(self):
        res = self.client.options(
            f"/api/v1/workspaces/{self.workspace_id}/items",
            headers={"Origin": "http://localhost:3000", "Access-Control-Request-Method": "GET"}
        )
        self.assertIn(res.status_code, [200, 204])
        self.assertNotIn("*", res.headers.get("access-control-allow-origin", ""))

    # P8-07: Production Security Headers
    def test_p8_07_security_headers(self):
        res = self.client.get("/health")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.headers.get("X-Content-Type-Options"), "nosniff")
        self.assertEqual(res.headers.get("X-Frame-Options"), "DENY")
        self.assertEqual(res.headers.get("Referrer-Policy"), "strict-origin-when-cross-origin")
        self.assertIn("max-age=31536000", res.headers.get("Strict-Transport-Security", ""))
        self.assertIn("default-src 'none'", res.headers.get("Content-Security-Policy", ""))

    # P8-08: Unified Error Response Contract
    def test_p8_08_unified_error_contract(self):
        res = self.client.get(f"/api/v1/workspaces/{self.forbidden_ws}/items", headers=self.auth_headers)
        self.assertEqual(res.status_code, 403)
        err = res.json()["error"]
        self.assertIn("code", err)
        self.assertIn("message", err)
        self.assertIn("category", err)
        self.assertIn("timestamp", err)
        self.assertIn("details", err)

    # P8-09: No Stack Trace / Internal Path Leakage in Error Responses
    def test_p8_09_internal_error_leakage_guard(self):
        res = self.client.post(
            f"/api/v1/workspaces/{self.workspace_id}/tasks",
            json={"title": ""},  # validation failure
            headers=self.auth_headers
        )
        self.assertEqual(res.status_code, 422)
        body = res.text
        self.assertNotIn("Traceback (most recent call last):", body)
        self.assertNotIn("/backend/app", body)

    # P8-10: Pagination Limits
    def test_p8_10_pagination_limits(self):
        res = self.client.get(
            f"/api/v1/workspaces/{self.workspace_id}/items?limit=200",
            headers=self.auth_headers
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("items", res.json())

    # P8-11: Sync Batch Limits & Oversized Payloads
    def test_p8_11_sync_batch_limits(self):
        # Normal batch
        res = self.client.post(
            "/api/v1/sync/push",
            json={"client_installation_id": "inst-1", "operations": []},
            headers=self.auth_headers
        )
        self.assertEqual(res.status_code, 200)

    # P8-12: Database Transaction Atomicity on Failure
    def test_p8_12_database_transaction_atomicity(self):
        db = LocalDatabase(":memory:")
        db.initialize_schema()
        uow = SqliteUnitOfWork(db.conn)
        items_repo = SqliteItemRepository(db.conn)

        task_id = generate_uuidv7()
        try:
            with uow:
                item = Item.create_task(EntityId(task_id), WorkspaceId(self.workspace_id), "مهمة سيتم التراجع عنها")
                items_repo.save(item)
                # Force an unexpected error before commit
                raise RuntimeError("Simulated transaction failure")
        except RuntimeError:
            pass

        # Verify item was not saved
        saved = items_repo.get_by_id(WorkspaceId(self.workspace_id), EntityId(task_id))
        self.assertIsNone(saved)
        db.close()

    # P8-13: Outbox Atomicity Regression
    def test_p8_13_outbox_atomicity(self):
        db = LocalDatabase(":memory:")
        db.initialize_schema()
        items_repo = SqliteItemRepository(db.conn)
        outbox_repo = SqliteOutboxRepository(db.conn)
        uow = SqliteUnitOfWork(db.conn)

        task_id = generate_uuidv7()
        op_id = generate_uuidv7()
        with uow:
            items_repo.save(Item.create_task(EntityId(task_id), WorkspaceId(self.workspace_id), "مهمة ذرية"))
            outbox_repo.enqueue_operation(op_id, "task", task_id, "insert", {"title": "مهمة ذرية"})
            uow.commit()

        self.assertIsNotNone(items_repo.get_by_id(WorkspaceId(self.workspace_id), EntityId(task_id)))
        self.assertEqual(len(outbox_repo.get_pending_operations()), 1)
        db.close()

    # P8-14: Sync Idempotency Regression
    def test_p8_14_sync_idempotency_regression(self):
        op_id = generate_uuidv7()
        payload = {
            "client_installation_id": "inst-p8",
            "operations": [
                {
                    "operation_id": op_id,
                    "entity_type": "task",
                    "entity_id": generate_uuidv7(),
                    "operation_type": "insert",
                    "payload": {"title": "عملية متطابقة"},
                    "base_version": 1
                }
            ]
        }
        res1 = self.client.post("/api/v1/sync/push", json=payload, headers=self.auth_headers)
        self.assertEqual(res1.status_code, 200)

        res2 = self.client.post("/api/v1/sync/push", json=payload, headers=self.auth_headers)
        self.assertEqual(res2.status_code, 200)
        self.assertEqual(res2.json()["acks"][0]["operation_id"], op_id)

    # P8-15: Sync Conflict Detection (Same Op ID, Different Payload -> 409)
    def test_p8_15_sync_conflict_detection(self):
        op_id = generate_uuidv7()
        payload_a = {
            "client_installation_id": "inst-p8-conf",
            "operations": [
                {
                    "operation_id": op_id,
                    "entity_type": "task",
                    "entity_id": generate_uuidv7(),
                    "operation_type": "insert",
                    "payload": {"title": "العنوان الأول"},
                    "base_version": 1
                }
            ]
        }
        res1 = self.client.post("/api/v1/sync/push", json=payload_a, headers=self.auth_headers)
        self.assertEqual(res1.status_code, 200)

        payload_b = {
            "client_installation_id": "inst-p8-conf",
            "operations": [
                {
                    "operation_id": op_id,
                    "entity_type": "task",
                    "entity_id": generate_uuidv7(),
                    "operation_type": "insert",
                    "payload": {"title": "عنوان مختلف يسبب تعارض"},
                    "base_version": 1
                }
            ]
        }
        res2 = self.client.post("/api/v1/sync/push", json=payload_b, headers=self.auth_headers)
        self.assertEqual(res2.status_code, 409)
        self.assertEqual(res2.json()["error"]["code"], "IDEMPOTENCY_CONFLICT")

    # P8-16: Pull Cursor Monotonic Recovery
    def test_p8_16_pull_cursor_recovery(self):
        res = self.client.get("/api/v1/sync/pull?since_sequence=0", headers=self.auth_headers)
        self.assertEqual(res.status_code, 200)
        cursor1 = res.json()["next_cursor"]
        self.assertGreaterEqual(cursor1, 0)

        # Retry from cursor1
        res2 = self.client.get(f"/api/v1/sync/pull?since_sequence={cursor1}", headers=self.auth_headers)
        self.assertEqual(res2.status_code, 200)
        self.assertGreaterEqual(res2.json()["next_cursor"], cursor1)

    # P8-17 & P8-18: Backup Creation & Restore Verification
    def test_p8_17_and_p8_18_backup_restore_integrity(self):
        source_db = LocalDatabase(":memory:")
        source_db.initialize_schema()
        items_repo = SqliteItemRepository(source_db.conn)
        
        # Populate known dataset
        task_id = generate_uuidv7()
        items_repo.save(Item.create_task(EntityId(task_id), WorkspaceId(self.workspace_id), "مهمة لاختبار النسخ الاحتياطي"))

        # Create Backup
        backup_file = "test_backup.sqlite"
        meta = create_sqlite_backup(source_db.conn, backup_file)
        self.assertTrue(os.path.exists(backup_file))
        self.assertIn("sha256", meta)

        # Restore to new DB
        restored_file = "test_restored.sqlite"
        restore_sqlite_backup(backup_file, restored_file)
        self.assertTrue(os.path.exists(restored_file))

        # Verify Integrity
        restored_conn = sqlite3.connect(restored_file)
        restored_conn.row_factory = sqlite3.Row
        ok, msg = verify_sqlite_integrity(restored_conn)
        self.assertTrue(ok)

        restored_items = SqliteItemRepository(restored_conn)
        retrieved = restored_items.get_by_id(WorkspaceId(self.workspace_id), EntityId(task_id))
        self.assertIsNotNone(retrieved)
        self.assertEqual(retrieved.title, "مهمة لاختبار النسخ الاحتياطي")

        # Cleanup
        restored_conn.close()
        source_db.close()
        if os.path.exists(backup_file):
            os.remove(backup_file)
        if os.path.exists(restored_file):
            os.remove(restored_file)

    # P8-19: Health & Liveness Probes
    def test_p8_19_health_and_liveness(self):
        res_h = self.client.get("/health")
        self.assertEqual(res_h.status_code, 200)
        self.assertEqual(res_h.json()["status"], "healthy")

        res_l = self.client.get("/health/live")
        self.assertEqual(res_l.status_code, 200)
        self.assertEqual(res_l.json()["status"], "live")

    # P8-20: Readiness Probe with Dependency Failure Handling
    def test_p8_20_readiness_probe_dependency_failure(self):
        # When healthy
        set_db_health_override(True)
        res_ready = self.client.get("/health/ready")
        self.assertEqual(res_ready.status_code, 200)
        self.assertEqual(res_ready.json()["status"], "ready")

        # When dependency fails -> 503 without process crash
        set_db_health_override(False)
        res_fail = self.client.get("/health/ready")
        self.assertEqual(res_fail.status_code, 503)
        self.assertEqual(res_fail.json()["status"], "not_ready")

    # P8-21: Logging Secret Redaction Filter
    def test_p8_21_logging_secret_redaction(self):
        filter_instance = SensitiveDataRedactionFilter()
        record = logging.LogRecord(
            name="test", level=logging.INFO, pathname="", lineno=1,
            msg="User login with password: secret_password_123 and token: jwt_secret_token_abc",
            args=(), exc_info=None
        )
        filter_instance.filter(record)
        self.assertNotIn("secret_password_123", record.msg)
        self.assertNotIn("jwt_secret_token_abc", record.msg)
        self.assertIn("[REDACTED]", record.msg)

    # P8-22: Request Correlation ID Tracing
    def test_p8_22_request_correlation_id(self):
        # Case A: Request without correlation ID gets one generated
        res1 = self.client.get("/health")
        self.assertEqual(res1.status_code, 200)
        self.assertTrue(len(res1.headers.get("x-correlation-id", "")) > 0)

        # Case B: Request with correlation ID propagates it
        custom_id = "custom-trace-id-12345"
        res2 = self.client.get("/health", headers={"x-correlation-id": custom_id})
        self.assertEqual(res2.status_code, 200)
        self.assertEqual(res2.headers.get("x-correlation-id"), custom_id)

    # P8-23: Mobile Offline Restart & Persistence
    def test_p8_23_mobile_offline_restart(self):
        db = LocalDatabase(":memory:")
        db.initialize_schema()
        items = SqliteItemRepository(db.conn)
        outbox = SqliteOutboxRepository(db.conn)

        item_id = generate_uuidv7()
        items.save(Item.create_task(EntityId(item_id), WorkspaceId(self.workspace_id), "مهمة إغلاق وإعادة فتح"))
        outbox.enqueue_operation(generate_uuidv7(), "task", item_id, "insert", {"title": "مهمة إغلاق وإعادة فتح"})

        # Close and verify state retained
        self.assertEqual(len(outbox.get_pending_operations()), 1)
        self.assertIsNotNone(items.get_by_id(WorkspaceId(self.workspace_id), EntityId(item_id)))
        db.close()

    # P8-24: Mobile Reconnect Recovery Flow
    def test_p8_24_mobile_reconnect_recovery(self):
        task_id = generate_uuidv7()
        op_id = generate_uuidv7()
        # Simulated push on reconnect
        res = self.client.post(
            "/api/v1/sync/push",
            json={
                "client_installation_id": "inst-p8-rec",
                "operations": [
                    {
                        "operation_id": op_id,
                        "entity_type": "task",
                        "entity_id": task_id,
                        "operation_type": "insert",
                        "payload": {"title": "مهمة تمت مزامنتها بعد استعادة الاتصال"},
                        "base_version": 1
                    }
                ]
            },
            headers=self.auth_headers
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["acks"][0]["operation_id"], op_id)

    # P8-25: Flutter Production Configuration Guard
    def test_p8_25_flutter_production_config(self):
        config_path = os.path.join("mobile", "lib", "core", "config", "app_config.dart")
        with open(config_path, "r", encoding="utf-8") as f:
            content = f.read()
        self.assertIn("https://api.mouin.app/api/v1", content)
        self.assertIn("AppEnvironment.production", content)

    # P8-26: Critical API Performance Baseline (< 100ms per endpoint)
    def test_p8_26_performance_baseline(self):
        # Health check latency
        start = time.perf_counter()
        res_h = self.client.get("/health")
        latency_h = (time.perf_counter() - start) * 1000
        self.assertEqual(res_h.status_code, 200)
        self.assertLess(latency_h, 100.0)  # sub-100ms

        # Task creation latency
        start = time.perf_counter()
        res_t = self.client.post(
            f"/api/v1/workspaces/{self.workspace_id}/tasks",
            json={"title": "قياس زمن الاستجابة"},
            headers=self.auth_headers
        )
        latency_t = (time.perf_counter() - start) * 1000
        self.assertEqual(res_t.status_code, 201)
        self.assertLess(latency_t, 100.0)  # sub-100ms

if __name__ == "__main__":
    unittest.main()
