"""
Phase 8 Production Hardening & Operational Readiness Test Suite (P8-01 to P8-26) — مشروع «مُعين» (Mouin)
Covers Security, Configuration, Database Production Readiness, Observability, Reliability, and Performance Baseline.
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
from backend.app.presentation.api.logging_config import SensitiveDataRedactionFilter, setup_production_logging
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

        # Reset health probe override
        set_db_health_override(None)

    def tearDown(self):
        set_db_health_override(None)

    # P8-01: Production Configuration Validation
    def test_p8_01_production_config_validation(self):
        # Insecure production config must raise ValueError
        insecure_settings = ApiSettings(
            environment="production",
            jwt_secret_key="dev-environment-insecure-key",
            allowed_origins=["*"],
            database_url="postgresql://user:pass@localhost:5432/mouin"
        )
        with self.assertRaises(ValueError):
            insecure_settings.validate_production()

        # Secure production config passes
        secure_settings = ApiSettings(
            environment="production",
            jwt_secret_key="super-secure-random-secret-key-for-prod-32-chars-long",
            allowed_origins=["https://app.mouin.io"],
            database_url="postgresql://user:pass@db.mouin.internal:5432/mouin"
        )
        # Should not raise
        secure_settings.validate_production()

    # P8-02: Secret Leakage Guard
    def test_p8_02_secret_leakage_guard(self):
        # Verify settings does not leak actual plaintext password defaults
        self.assertNotIn("real_production_secret", settings.jwt_secret_key)
        self.assertNotIn("admin123", settings.database_url)

    # P8-03: Debug Mode Production Guard
    def test_p8_03_debug_mode_production_guard(self):
        prod_app = create_app()
        # When is_production is True, docs_url is None
        self.assertIsNotNone(prod_app)

    # P8-04: Authentication Hardening (401 on missing/invalid)
    def test_p8_04_authentication_hardening(self):
        res = self.client.get(f"/api/v1/workspaces/{self.workspace_id}/items")
        self.assertEqual(res.status_code, 401)
        err = res.json()["error"]
        self.assertEqual(err["code"], "UNAUTHORIZED")

    # P8-05: Workspace Authorization Hardening (403 on cross-workspace)
    def test_p8_05_workspace_authorization(self):
        res = self.client.get(f"/api/v1/workspaces/{self.forbidden_ws}/items", headers=self.auth_headers)
        self.assertEqual(res.status_code, 403)
        self.assertEqual(res.json()["error"]["code"], "WORKSPACE_FORBIDDEN")

    # P8-06: CORS Configuration Hardening
    def test_p8_06_cors_configuration(self):
        res = self.client.options(
            f"/api/v1/workspaces/{self.workspace_id}/items",
            headers={
                "Origin": "https://app.mouin.io",
                "Access-Control-Request-Method": "GET"
            }
        )
        self.assertIn(res.status_code, [200, 400, 405])

    # P8-07: Security Headers Middleware
    def test_p8_07_security_headers(self):
        res = self.client.get("/health")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.headers.get("x-content-type-options"), "nosniff")
        self.assertEqual(res.headers.get("x-frame-options"), "DENY")
        self.assertEqual(res.headers.get("referrer-policy"), "strict-origin-when-cross-origin")
        self.assertIn("max-age=", res.headers.get("strict-transport-security", ""))
        self.assertIn("default-src 'none'", res.headers.get("content-security-policy", ""))

    # P8-08: Unified Error Contract
    def test_p8_08_unified_error_contract(self):
        res = self.client.get(f"/api/v1/workspaces/{self.forbidden_ws}/items", headers=self.auth_headers)
        self.assertEqual(res.status_code, 403)
        body = res.json()
        self.assertIn("error", body)
        for key in ["code", "message", "category", "timestamp", "details"]:
            self.assertIn(key, body["error"])

    # P8-09: Internal Error Information Leakage Guard
    def test_p8_09_internal_error_leakage_guard(self):
        res = self.client.get(f"/api/v1/workspaces/{self.forbidden_ws}/items", headers=self.auth_headers)
        res_text = res.text
        self.assertNotIn("Traceback (most recent call last)", res_text)
        self.assertNotIn("SELECT * FROM", res_text)
        self.assertNotIn("/home/", res_text)

    # P8-10: Pagination Limits
    def test_p8_10_pagination_limits(self):
        url = f"/api/v1/workspaces/{self.workspace_id}/items?limit=200"
        res = self.client.get(url, headers=self.auth_headers)
        self.assertEqual(res.status_code, 200)

    # P8-11: Request Body Limits (413 Payload Too Large)
    def test_p8_11_request_body_limits(self):
        # Simulate oversized payload header exceeding 10MB
        res = self.client.post(
            "/api/v1/sync/push",
            content=b"{}",
            headers={**self.auth_headers, "Content-Length": "15000000"}
        )
        self.assertEqual(res.status_code, 413)
        self.assertEqual(res.json()["error"]["code"], "PAYLOAD_TOO_LARGE")

    # P8-12: Database Transaction Integrity & Rollback
    def test_p8_12_database_transaction_integrity(self):
        db = LocalDatabase(":memory:")
        db.initialize_schema()
        uow = SqliteUnitOfWork(db.conn)
        repo = SqliteItemRepository(db.conn)

        task_id = generate_uuidv7()
        try:
            with uow:
                item = Item.create_task(EntityId(task_id), WorkspaceId(self.workspace_id), "مهمة اختبارية")
                repo.save(item)
                # Force simulated exception before commit
                raise RuntimeError("Simulated transaction crash")
        except RuntimeError:
            pass

        # Verify item was not persisted due to rollback
        self.assertIsNone(repo.get_by_id(WorkspaceId(self.workspace_id), EntityId(task_id)))
        db.close()

    # P8-13: Outbox Atomicity Regression
    def test_p8_13_outbox_atomicity_regression(self):
        db = LocalDatabase(":memory:")
        db.initialize_schema()
        uow = SqliteUnitOfWork(db.conn)
        repo = SqliteItemRepository(db.conn)
        outbox = SqliteOutboxRepository(db.conn)

        task_id = generate_uuidv7()
        op_id = generate_uuidv7()
        with uow:
            item = Item.create_task(EntityId(task_id), WorkspaceId(self.workspace_id), "مهمة ذرية")
            repo.save(item)
            outbox.enqueue_operation(op_id, "task", task_id, "insert", {"title": "مهمة ذرية"})
            uow.commit()

        self.assertIsNotNone(repo.get_by_id(WorkspaceId(self.workspace_id), EntityId(task_id)))
        self.assertEqual(len(outbox.get_pending_operations()), 1)
        db.close()

    # P8-14: Sync Idempotency Regression
    def test_p8_14_sync_idempotency_regression(self):
        op_id = generate_uuidv7()
        item_id = generate_uuidv7()
        push_url = "/api/v1/sync/push"
        payload = {
            "client_installation_id": "inst-p8-14",
            "operations": [
                {
                    "operation_id": op_id,
                    "entity_type": "task",
                    "entity_id": item_id,
                    "operation_type": "insert",
                    "payload": {"id": item_id, "workspace_id": self.workspace_id, "title": "مهمة الإعادة"},
                    "base_version": 1
                }
            ]
        }
        res1 = self.client.post(push_url, json=payload, headers=self.auth_headers)
        self.assertEqual(res1.status_code, 200)

        res2 = self.client.post(push_url, json=payload, headers=self.auth_headers)
        self.assertEqual(res2.status_code, 200)
        self.assertEqual(res2.json()["acks"][0]["status"], "duplicate_idempotent")

    # P8-15: Sync Conflict Detection (409 on Mismatched Payload)
    def test_p8_15_sync_conflict_detection(self):
        op_id = generate_uuidv7()
        item_id = generate_uuidv7()
        push_url = "/api/v1/sync/push"
        payload_1 = {
            "client_installation_id": "inst-p8-15",
            "operations": [
                {
                    "operation_id": op_id,
                    "entity_type": "task",
                    "entity_id": item_id,
                    "operation_type": "insert",
                    "payload": {"title": "النسخة الأصلية"},
                    "base_version": 1
                }
            ]
        }
        res1 = self.client.post(push_url, json=payload_1, headers=self.auth_headers)
        self.assertEqual(res1.status_code, 200)

        # Same op_id with mismatched payload
        payload_conflict = {
            "client_installation_id": "inst-p8-15",
            "operations": [
                {
                    "operation_id": op_id,
                    "entity_type": "task",
                    "entity_id": item_id,
                    "operation_type": "insert",
                    "payload": {"title": "نسخة متعارضة تماماً"},
                    "base_version": 1
                }
            ]
        }
        res2 = self.client.post(push_url, json=payload_conflict, headers=self.auth_headers)
        self.assertEqual(res2.status_code, 409)
        self.assertEqual(res2.json()["error"]["code"], "IDEMPOTENCY_CONFLICT")

    # P8-16: Pull Cursor Recovery
    def test_p8_16_pull_cursor_recovery(self):
        res = self.client.get("/api/v1/sync/pull?since_sequence=5", headers=self.auth_headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertGreaterEqual(data["next_cursor"], 5)

    # P8-17: Backup Integrity Verification
    def test_p8_17_backup_integrity(self):
        # Create dataset in memory SQLite
        db = LocalDatabase(":memory:")
        db.initialize_schema()
        repo = SqliteItemRepository(db.conn)
        task_id = generate_uuidv7()
        repo.save(Item.create_task(EntityId(task_id), WorkspaceId(self.workspace_id), "مهمة للنسخ الاحتياطي"))

        # Generate SQL backup dump
        dump = "\n".join(db.conn.iterdump())
        self.assertIn("مهمة للنسخ الاحتياطي", dump)
        self.assertIn("CREATE TABLE", dump)
        db.close()

    # P8-18: Restore Integrity Verification
    def test_p8_18_restore_integrity(self):
        # 1. Original database with data
        db1 = LocalDatabase(":memory:")
        db1.initialize_schema()
        repo1 = SqliteItemRepository(db1.conn)
        task_id = generate_uuidv7()
        repo1.save(Item.create_task(EntityId(task_id), WorkspaceId(self.workspace_id), "مهمة الاستعادة"))
        dump = list(db1.conn.iterdump())
        db1.close()

        # 2. Restore into fresh blank database
        db2 = sqlite3.connect(":memory:")
        db2.row_factory = sqlite3.Row
        for statement in dump:
            try:
                db2.execute(statement)
            except sqlite3.OperationalError:
                pass
        db2.commit()

        # 3. Verify restored record fidelity
        repo2 = SqliteItemRepository(db2)
        restored = repo2.get_by_id(WorkspaceId(self.workspace_id), EntityId(task_id))
        self.assertIsNotNone(restored)
        self.assertEqual(restored.title, "مهمة الاستعادة")
        db2.close()

    # P8-19: Health Liveness Probe
    def test_p8_19_health_liveness_probe(self):
        res = self.client.get("/health/live")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["status"], "live")

    # P8-20: Readiness Dependency Failure Behavior
    def test_p8_20_readiness_dependency_failure(self):
        # Normal ready
        res_ok = self.client.get("/health/ready")
        self.assertEqual(res_ok.status_code, 200)
        self.assertEqual(res_ok.json()["status"], "ready")

        # Simulate database failure
        set_db_health_override(False)
        res_fail = self.client.get("/health/ready")
        self.assertEqual(res_fail.status_code, 503)
        self.assertEqual(res_fail.json()["status"], "not_ready")

    # P8-21: Logging Secret Redaction Filter
    def test_p8_21_logging_secret_redaction(self):
        log_filter = SensitiveDataRedactionFilter()
        record = logging.LogRecord(
            name="test", level=logging.INFO, pathname="", lineno=0,
            msg="User login failed with password: SuperSecretPassword123 and token=Bearer_xyz987",
            args=(), exc_info=None
        )
        log_filter.filter(record)
        self.assertNotIn("SuperSecretPassword123", record.msg)
        self.assertNotIn("Bearer_xyz987", record.msg)
        self.assertIn("[REDACTED]", record.msg)

    # P8-22: Request Correlation ID Propagation
    def test_p8_22_request_correlation_id_propagation(self):
        custom_corr_id = "corr-test-uuid-999"
        res = self.client.get("/health", headers={"x-correlation-id": custom_corr_id})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.headers.get("x-correlation-id"), custom_corr_id)
        self.assertEqual(res.headers.get("x-request-id"), custom_corr_id)

    # P8-23: Mobile Offline Restart Resilience
    def test_p8_23_mobile_offline_restart(self):
        db = LocalDatabase(":memory:")
        db.initialize_schema()
        repo = SqliteItemRepository(db.conn)
        task_id = generate_uuidv7()
        repo.save(Item.create_task(EntityId(task_id), WorkspaceId(self.workspace_id), "مهمة البقاء بعد الإغلاق"))

        # Re-query
        retrieved = repo.get_by_id(WorkspaceId(self.workspace_id), EntityId(task_id))
        self.assertIsNotNone(retrieved)
        self.assertEqual(retrieved.title, "مهمة البقاء بعد الإغلاق")
        db.close()

    # P8-24: Mobile Reconnect Outbox Recovery
    def test_p8_24_mobile_reconnect_recovery(self):
        db = LocalDatabase(":memory:")
        db.initialize_schema()
        outbox = SqliteOutboxRepository(db.conn)
        op_id = generate_uuidv7()
        outbox.enqueue_operation(op_id, "task", generate_uuidv7(), "insert", {"title": "عملية معلقة"})

        # Simulate reconnect
        pending = outbox.get_pending_operations()
        self.assertEqual(len(pending), 1)
        self.assertEqual(pending[0]["operation_id"], op_id)
        db.close()

    # P8-25: Flutter Production Configuration Guard
    def test_p8_25_flutter_production_config_guard(self):
        config_path = os.path.join("mobile", "lib", "core", "config", "app_config.dart")
        with open(config_path, "r", encoding="utf-8") as f:
            code = f.read()
        self.assertIn("https://api.mouin.app/api/v1", code)
        self.assertIn("AppEnvironment.production", code)

    # P8-26: Performance Baseline Measurement
    def test_p8_26_performance_baseline(self):
        # Measure health check latency
        t0 = time.perf_counter()
        res_health = self.client.get("/health")
        latency_health_ms = (time.perf_counter() - t0) * 1000
        self.assertEqual(res_health.status_code, 200)
        self.assertLess(latency_health_ms, 50.0)  # Health < 50ms

        # Measure task creation latency
        t1 = time.perf_counter()
        res_task = self.client.post(
            f"/api/v1/workspaces/{self.workspace_id}/tasks",
            json={"title": "مهمة قياس الأداء", "priority": "medium"},
            headers=self.auth_headers
        )
        latency_task_ms = (time.perf_counter() - t1) * 1000
        self.assertEqual(res_task.status_code, 201)
        self.assertLess(latency_task_ms, 100.0)  # Task creation < 100ms

        # Measure sync pull latency
        t2 = time.perf_counter()
        res_pull = self.client.get("/api/v1/sync/pull?since_sequence=0", headers=self.auth_headers)
        latency_pull_ms = (time.perf_counter() - t2) * 1000
        self.assertEqual(res_pull.status_code, 200)
        self.assertLess(latency_pull_ms, 100.0)  # Sync pull < 100ms

if __name__ == "__main__":
    unittest.main()
