"""
Phase 5 Delivery & REST API Acceptance Tests (P5-A to P5-T) — مشروع «مُعين» (Mouin)
Tests the complete HTTP boundary using FastAPI TestClient.
"""

import unittest
from fastapi.testclient import TestClient
from decimal import Decimal
from datetime import datetime, timezone
import json

from backend.app.presentation.api.app import app
from backend.app.domain.value_objects.identity import generate_uuidv7

class TestDeliveryApiPhase5(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)
        self.valid_user_id = "018e3a2b-0001-7000-8000-000000000001"
        self.valid_ws_id = "018e3a2b-0002-7000-8000-000000000002"
        self.auth_headers = {
            "x-user-id": self.valid_user_id,
            "x-workspace-id": self.valid_ws_id
        }

    # Test P5-A: FastAPI application boots successfully
    def test_p5_a_fastapi_app_boots(self):
        self.assertIsNotNone(app)
        self.assertEqual(app.title, "مُعين (Mouin) API")

    # Test P5-B: Health endpoints work
    def test_p5_b_health_endpoints(self):
        res = self.client.get("/health")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["status"], "healthy")

        res_live = self.client.get("/health/live")
        self.assertEqual(res_live.status_code, 200)

        res_ready = self.client.get("/health/ready")
        self.assertEqual(res_ready.status_code, 200)

    # Test P5-C: Valid request reaches Application Handler & DB
    def test_p5_c_create_task_flow(self):
        url = f"/api/v1/workspaces/{self.valid_ws_id}/tasks"
        payload = {
            "title": "مهمة اختبار الـ API",
            "priority": "urgent",
            "summary": "ملخص مهمة من الـ REST Endpoint"
        }
        res = self.client.post(url, json=payload, headers=self.auth_headers)
        self.assertEqual(res.status_code, 201)
        data = res.json()
        self.assertEqual(data["title"], "مهمة اختبار الـ API")
        self.assertEqual(data["task_detail"]["priority"], "urgent")
        self.assertEqual(data["workspace_id"], self.valid_ws_id)

    # Test P5-E: Invalid DTO is rejected with 422
    def test_p5_e_invalid_dto_rejected(self):
        url = f"/api/v1/workspaces/{self.valid_ws_id}/tasks"
        payload = {"title": ""}  # min_length=1 violation
        res = self.client.post(url, json=payload, headers=self.auth_headers)
        self.assertEqual(res.status_code, 422)
        err = res.json()["error"]
        self.assertEqual(err["code"], "VALIDATION_ERROR")

    # Test P5-F: Unauthorized request is rejected with 401
    def test_p5_f_unauthorized_request_rejected(self):
        url = f"/api/v1/workspaces/{self.valid_ws_id}/items"
        res = self.client.get(url)  # No auth headers
        self.assertEqual(res.status_code, 401)

    # Test P5-G: Cross-workspace access is rejected with 403
    def test_p5_g_cross_workspace_access_rejected(self):
        forbidden_ws = "00000000-0000-0000-0000-000000000000"
        url = f"/api/v1/workspaces/{forbidden_ws}/items"
        res = self.client.get(url, headers=self.auth_headers)
        self.assertEqual(res.status_code, 403)

    # Test P5-H: Valid workspace access succeeds
    def test_p5_h_valid_workspace_access(self):
        url = f"/api/v1/workspaces/{self.valid_ws_id}/items"
        res = self.client.get(url, headers=self.auth_headers)
        self.assertEqual(res.status_code, 200)
        self.assertIn("items", res.json())

    # Test P5-J: NotFound returns 404
    def test_p5_j_not_found(self):
        fake_id = "018e3a2b-9999-7000-8000-000000000000"
        url = f"/api/v1/workspaces/{self.valid_ws_id}/items/{fake_id}"
        res = self.client.get(url, headers=self.auth_headers)
        self.assertEqual(res.status_code, 404)

    # Test P5-K & P5-L: Idempotency check on Sync Push
    def test_p5_k_and_l_idempotency_push(self):
        op_id = generate_uuidv7()
        url = "/api/v1/sync/push"
        payload_1 = {
            "client_installation_id": "inst-1",
            "operations": [
                {
                    "operation_id": op_id,
                    "entity_type": "task",
                    "entity_id": generate_uuidv7(),
                    "operation_type": "insert",
                    "payload": {"title": "عملية مزامنة 1"},
                    "base_version": 1
                }
            ]
        }
        # First Push -> Success
        res1 = self.client.post(url, json=payload_1, headers=self.auth_headers)
        self.assertEqual(res1.status_code, 200)
        self.assertEqual(res1.json()["acks"][0]["status"], "success")

        # Same Op ID + Same Payload -> Duplicate Idempotent (Test P5-K)
        res2 = self.client.post(url, json=payload_1, headers=self.auth_headers)
        self.assertEqual(res2.status_code, 200)
        self.assertEqual(res2.json()["acks"][0]["status"], "duplicate_idempotent")

        # Same Op ID + Different Payload -> 409 Conflict (Test P5-L)
        payload_conflict = {
            "client_installation_id": "inst-1",
            "operations": [
                {
                    "operation_id": op_id,
                    "entity_type": "task",
                    "entity_id": generate_uuidv7(),
                    "operation_type": "insert",
                    "payload": {"title": "تغيير غير متطابق لنفس المعرف"},
                    "base_version": 1
                }
            ]
        }
        res3 = self.client.post(url, json=payload_conflict, headers=self.auth_headers)
        self.assertEqual(res3.status_code, 409)

    # Test P5-M: Debt API preserves Decimal precision
    def test_p5_m_debt_decimal_precision(self):
        person_id = generate_uuidv7()
        # Seed person in DB
        from backend.app.presentation.api.dependencies.container import get_db_helper
        db = get_db_helper()
        db.conn.execute(
            "INSERT OR IGNORE INTO local_people (id, workspace_id, name, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
            (person_id, self.valid_ws_id, "أحمد التاجر", "2026-08-29T12:00:00Z", "2026-08-29T12:00:00Z")
        )
        db.conn.commit()

        url = f"/api/v1/workspaces/{self.valid_ws_id}/debts"
        payload = {
            "person_id": person_id,
            "debt_type": "receivable",
            "total_amount": "25000.75",
            "currency": "YER"
        }
        res = self.client.post(url, json=payload, headers=self.auth_headers)
        self.assertEqual(res.status_code, 201)
        debt_data = res.json()
        self.assertEqual(debt_data["total_amount"], "25000.75")
        self.assertEqual(debt_data["remaining_amount"], "25000.75")

        # Record payment of 10000.25 -> Remaining must be exact 15000.50
        debt_id = debt_data["id"]
        pay_url = f"/api/v1/workspaces/{self.valid_ws_id}/debts/{debt_id}/transactions"
        pay_res = self.client.post(pay_url, json={"amount": "10000.25", "currency": "YER"}, headers=self.auth_headers)
        self.assertEqual(pay_res.status_code, 200)
        self.assertEqual(pay_res.json()["remaining_amount"], "15000.50")

    # Test P5-N: Reminder API duplicate occurrence handling
    def test_p5_n_reminder_occurrence_duplicate(self):
        # Create parent task first
        t_res = self.client.post(
            f"/api/v1/workspaces/{self.valid_ws_id}/tasks",
            json={"title": "مهمة لتذكير مكرر"},
            headers=self.auth_headers
        )
        task_id = t_res.json()["id"]

        rule_url = f"/api/v1/workspaces/{self.valid_ws_id}/reminders"
        rule_res = self.client.post(
            rule_url,
            json={"item_id": task_id, "trigger_type": "recurring"},
            headers=self.auth_headers
        )
        self.assertEqual(rule_res.status_code, 201)
        rule_id = rule_res.json()["id"]

        # Generate instance at 2026-09-01T10:00:00Z
        inst_url = f"/api/v1/workspaces/{self.valid_ws_id}/reminders/{rule_id}/instances"
        inst_payload = {"scheduled_time": "2026-09-01T10:00:00Z"}
        inst_res1 = self.client.post(inst_url, json=inst_payload, headers=self.auth_headers)
        self.assertEqual(inst_res1.status_code, 200)

        # Duplicate instance generation at same occurrence -> 409 Conflict
        inst_res2 = self.client.post(inst_url, json=inst_payload, headers=self.auth_headers)
        self.assertEqual(inst_res2.status_code, 409)

    # Test P5-P: Soft delete follows tombstone rules
    def test_p5_p_soft_delete_tombstone(self):
        t_res = self.client.post(
            f"/api/v1/workspaces/{self.valid_ws_id}/tasks",
            json={"title": "مهمة للحذف الناعم"},
            headers=self.auth_headers
        )
        item_id = t_res.json()["id"]

        # Delete
        del_res = self.client.delete(f"/api/v1/workspaces/{self.valid_ws_id}/items/{item_id}", headers=self.auth_headers)
        self.assertEqual(del_res.status_code, 204)

        # GET should now return 404 (hidden by tombstone)
        get_res = self.client.get(f"/api/v1/workspaces/{self.valid_ws_id}/items/{item_id}", headers=self.auth_headers)
        self.assertEqual(get_res.status_code, 404)

    # Test P5-R: Sync Pull uses server_sequence
    def test_p5_r_sync_pull_uses_sequence(self):
        url = "/api/v1/sync/pull?since_sequence=0&limit=10"
        res = self.client.get(url, headers=self.auth_headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("changes", data)
        self.assertIn("next_cursor", data)

    # Test P5-T: OpenAPI schema verification
    def test_p5_t_openapi_contains_expected_schemas(self):
        res = self.client.get("/openapi.json")
        self.assertEqual(res.status_code, 200)
        openapi = res.json()
        paths = openapi.get("paths", {})
        self.assertIn("/health", paths)
        self.assertIn("/api/v1/sync/push", paths)
        self.assertIn("/api/v1/sync/pull", paths)
        self.assertIn("/api/v1/workspaces/{workspace_id}/items", paths)
        self.assertIn("/api/v1/workspaces/{workspace_id}/tasks", paths)
        self.assertIn("/api/v1/workspaces/{workspace_id}/debts", paths)
        self.assertIn("/api/v1/workspaces/{workspace_id}/reminders", paths)

if __name__ == '__main__':
    unittest.main()
