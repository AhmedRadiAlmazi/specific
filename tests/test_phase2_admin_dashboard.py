"""
Phase 2 Comprehensive Automated Tests: Real Admin Dashboard & Management Center
مشروع «مُعين» (Mouin)
"""

import unittest
from fastapi.testclient import TestClient
import json
import uuid
from decimal import Decimal

from backend.app.presentation.api.app import app
from backend.app.presentation.api.routers.auth import USERS_DB

class TestPhase2AdminDashboard(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)
        self.admin_email = "admin@mouin.app"
        self.member_email = "user@mouin.app"
        self.password = "Password123!"
        
        # 1. Login as Admin
        admin_login = self.client.post("/api/v1/auth/login", json={
            "username": self.admin_email,
            "password": self.password
        })
        self.assertEqual(admin_login.status_code, 200)
        self.admin_token = admin_login.json()["access_token"]
        self.admin_user_id = admin_login.json()["user"]["id"]
        self.admin_headers = {
            "Authorization": f"Bearer {self.admin_token}",
            "x-user-id": self.admin_user_id
        }

        # 2. Login as Regular Member
        member_login = self.client.post("/api/v1/auth/login", json={
            "username": self.member_email,
            "password": self.password
        })
        self.assertEqual(member_login.status_code, 200)
        self.member_token = member_login.json()["access_token"]
        self.member_user_id = member_login.json()["user"]["id"]
        self.member_headers = {
            "Authorization": f"Bearer {self.member_token}",
            "x-user-id": self.member_user_id
        }

    # ==================== 1. Security & RBAC Guards ====================
    def test_anonymous_access_denied(self):
        """Anonymous callers must receive 401 Unauthorized on admin APIs."""
        endpoints = [
            "/api/v1/admin/dashboard",
            "/api/v1/admin/users",
            "/api/v1/admin/workspaces",
            "/api/v1/admin/tasks",
            "/api/v1/admin/debts",
            "/api/v1/admin/reminders",
            "/api/v1/admin/sync"
        ]
        for ep in endpoints:
            res = self.client.get(ep)
            self.assertEqual(res.status_code, 401, f"Failed on endpoint {ep}")
            self.assertIn("error", res.json())
            self.assertEqual(res.json()["error"]["code"], "UNAUTHORIZED")

    def test_member_role_forbidden(self):
        """Regular member users must receive 403 Forbidden on admin APIs."""
        endpoints = [
            "/api/v1/admin/dashboard",
            "/api/v1/admin/users",
            "/api/v1/admin/workspaces",
            "/api/v1/admin/tasks",
            "/api/v1/admin/debts",
            "/api/v1/admin/reminders",
            "/api/v1/admin/sync"
        ]
        for ep in endpoints:
            res = self.client.get(ep, headers=self.member_headers)
            self.assertEqual(res.status_code, 403, f"Failed on endpoint {ep}")
            self.assertIn("error", res.json())
            self.assertIn(res.json()["error"]["code"], ["FORBIDDEN", "WORKSPACE_FORBIDDEN"])

    def test_admin_role_authorized(self):
        """Authorized admin users receive 200 OK on admin APIs."""
        res = self.client.get("/api/v1/admin/dashboard", headers=self.admin_headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["system_status"], "healthy")
        self.assertTrue(data["total_users"] >= 2)
        self.assertTrue(data["total_workspaces"] >= 2)
        self.assertIn("recent_sync_stream", data)

    # ==================== 2. User Management ====================
    def test_user_management_crud(self):
        # 1. List Users
        list_res = self.client.get("/api/v1/admin/users", headers=self.admin_headers)
        self.assertEqual(list_res.status_code, 200)
        self.assertTrue(list_res.json()["total"] >= 2)
        
        # 2. Create User
        new_email = f"manager_{uuid.uuid4().hex[:6]}@mouin.app"
        create_res = self.client.post("/api/v1/admin/users", json={
            "name": "مدير المشاريع",
            "email": new_email,
            "role": "admin",
            "permissions": ["manage_all", "items:write"],
            "workspace_ids": ["018e3a2b-0002-7000-8000-000000000002"]
        }, headers=self.admin_headers)
        self.assertEqual(create_res.status_code, 201)
        created_user = create_res.json()
        new_user_id = created_user["id"]
        self.assertEqual(created_user["email"], new_email)
        self.assertNotIn("password", created_user)

        # 3. Get User Detail
        detail_res = self.client.get(f"/api/v1/admin/users/{new_user_id}", headers=self.admin_headers)
        self.assertEqual(detail_res.status_code, 200)
        self.assertEqual(detail_res.json()["id"], new_user_id)

        # 4. Patch User Status / Role
        patch_res = self.client.patch(f"/api/v1/admin/users/{new_user_id}", json={
            "name": "مدير المشاريع المعتمد",
            "status": "deactivated"
        }, headers=self.admin_headers)
        self.assertEqual(patch_res.status_code, 200)
        self.assertEqual(patch_res.json()["name"], "مدير المشاريع المعتمد")
        self.assertEqual(patch_res.json()["status"], "deactivated")

    # ==================== 3. Workspace Management ====================
    def test_workspace_management_crud(self):
        # 1. List Workspaces
        list_res = self.client.get("/api/v1/admin/workspaces", headers=self.admin_headers)
        self.assertEqual(list_res.status_code, 200)
        self.assertTrue(list_res.json()["total"] >= 2)

        # 2. Create Workspace
        create_res = self.client.post("/api/v1/admin/workspaces", json={
            "name": "مساحة الاستشارات الاستراتيجية",
            "owner_id": self.admin_user_id
        }, headers=self.admin_headers)
        self.assertEqual(create_res.status_code, 201)
        ws_id = create_res.json()["id"]

        # 3. Get Workspace Detail
        detail_res = self.client.get(f"/api/v1/admin/workspaces/{ws_id}", headers=self.admin_headers)
        self.assertEqual(detail_res.status_code, 200)
        self.assertEqual(detail_res.json()["name"], "مساحة الاستشارات الاستراتيجية")

        # 4. Patch Workspace
        patch_res = self.client.patch(f"/api/v1/admin/workspaces/{ws_id}", json={
            "name": "مساحة الاستشارات والمالية",
            "ws_status": "archived"
        }, headers=self.admin_headers)
        self.assertEqual(patch_res.status_code, 200)
        self.assertEqual(patch_res.json()["name"], "مساحة الاستشارات والمالية")

    # ==================== 4. Tasks Management ====================
    def test_task_management_crud(self):
        ws_id = "018e3a2b-0002-7000-8000-000000000002"
        # 1. Create Task
        create_res = self.client.post("/api/v1/admin/tasks", json={
            "workspace_id": ws_id,
            "title": "مهمة إدارية للاختبار المؤتمت",
            "priority": "urgent"
        }, headers=self.admin_headers)
        self.assertEqual(create_res.status_code, 201)
        task_id = create_res.json()["id"]
        self.assertEqual(create_res.json()["title"], "مهمة إدارية للاختبار المؤتمت")

        # 2. Get Task Detail
        detail_res = self.client.get(f"/api/v1/admin/tasks/{task_id}", headers=self.admin_headers)
        self.assertEqual(detail_res.status_code, 200)
        self.assertEqual(detail_res.json()["priority"], "urgent")

        # 3. Update Task Status & Priority
        patch_res = self.client.patch(f"/api/v1/admin/tasks/{task_id}", json={
            "task_status": "completed",
            "priority": "high"
        }, headers=self.admin_headers)
        self.assertEqual(patch_res.status_code, 200)
        self.assertEqual(patch_res.json()["status"], "completed")
        self.assertEqual(patch_res.json()["priority"], "high")

        # 4. Search & Filter Tasks
        search_res = self.client.get("/api/v1/admin/tasks?search=للاختبار", headers=self.admin_headers)
        self.assertEqual(search_res.status_code, 200)
        self.assertTrue(len(search_res.json()["tasks"]) >= 1)

        # 5. Delete Task
        del_res = self.client.delete(f"/api/v1/admin/tasks/{task_id}", headers=self.admin_headers)
        self.assertEqual(del_res.status_code, 204)

    # ==================== 5. Debts & Ledger Management ====================
    def test_debts_management_and_ledger(self):
        # 1. List Debts
        list_res = self.client.get("/api/v1/admin/debts", headers=self.admin_headers)
        self.assertEqual(list_res.status_code, 200)
        self.assertTrue(list_res.json()["total"] >= 1)
        debt = list_res.json()["debts"][0]
        debt_id = debt["id"]
        initial_remaining = Decimal(debt["remaining_amount"])

        # 2. Get Debt Detail
        detail_res = self.client.get(f"/api/v1/admin/debts/{debt_id}", headers=self.admin_headers)
        self.assertEqual(detail_res.status_code, 200)
        self.assertEqual(detail_res.json()["id"], debt_id)

        # 3. Record Debt Payment (Exact Minor Units Decimal Calculation)
        pay_amount = "500.00"
        pay_res = self.client.post(f"/api/v1/admin/debts/{debt_id}/payments", json={
            "amount": pay_amount
        }, headers=self.admin_headers)
        self.assertEqual(pay_res.status_code, 200)
        expected_remaining = initial_remaining - Decimal(pay_amount)
        self.assertEqual(Decimal(pay_res.json()["remaining_amount"]), expected_remaining)

    # ==================== 6. Reminders Management ====================
    def test_reminders_management(self):
        list_res = self.client.get("/api/v1/admin/reminders", headers=self.admin_headers)
        self.assertEqual(list_res.status_code, 200)
        self.assertTrue(list_res.json()["total"] >= 1)
        rem = list_res.json()["reminders"][0]
        self.assertIn("occurrence_key", rem)
        self.assertIn("trigger_type", rem)

    # ==================== 7. Sync Monitor & End-to-End Stream ====================
    def test_sync_monitor_and_bidirectional_stream(self):
        # 1. Query Sync Monitor
        sync_res = self.client.get("/api/v1/admin/sync", headers=self.admin_headers)
        self.assertEqual(sync_res.status_code, 200)
        self.assertTrue(sync_res.json()["total_events"] >= 1)
        self.assertTrue(sync_res.json()["last_server_sequence"] >= 100)

        # 2. Simulate Mobile Sync Push
        op_id = str(uuid.uuid4())
        task_id = str(uuid.uuid4())
        ws_id = "018e3a2b-0002-7000-8000-000000000002"
        push_res = self.client.post("/api/v1/sync/push", json={
            "client_installation_id": "client-test-device-42",
            "operations": [
                {
                    "operation_id": op_id,
                    "entity_type": "task",
                    "entity_id": task_id,
                    "operation_type": "insert",
                    "payload": {
                        "id": task_id,
                        "workspace_id": ws_id,
                        "title": "مهمة واردة عبر المزامنة الحية"
                    },
                    "base_version": 1
                }
            ]
        }, headers={
            "Authorization": f"Bearer {self.admin_token}",
            "x-user-id": self.admin_user_id,
            "x-workspace-id": ws_id
        })
        self.assertEqual(push_res.status_code, 200)
        self.assertIn(push_res.json()["acks"][0]["status"], ["success", "applied"])

        # 3. Verify Sync Monitor records recent sequence operations
        sync_after = self.client.get("/api/v1/admin/sync", headers=self.admin_headers)
        self.assertEqual(sync_after.status_code, 200)
        self.assertTrue(sync_after.json()["total_events"] >= 1)

    # ==================== 8. Admin Dashboard HTML SPA ====================
    def test_admin_dashboard_spa_html(self):
        res = self.client.get("/admin")
        self.assertEqual(res.status_code, 200)
        self.assertIn("text/html", res.headers["content-type"])
        self.assertIn("مركز الإدارة والتحكم", res.text)
        self.assertIn("لوحة المؤشرات", res.text)
        self.assertIn("مراقب المزامنة", res.text)

        res2 = self.client.get("/admin/dashboard")
        self.assertEqual(res2.status_code, 200)

if __name__ == "__main__":
    unittest.main()
