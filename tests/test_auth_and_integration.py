"""
Phase 1 Integration Tests: Authentication, Token Lifecycle & Sync Integration
مشروع «مُعين» (Mouin)
"""

import unittest
from fastapi.testclient import TestClient
import json

from backend.app.presentation.api.app import app

class TestAuthAndIntegration(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)
        self.valid_email = "admin@mouin.app"
        self.valid_pass = "Password123!"
        self.user_email = "user@mouin.app"

    def test_login_success_admin(self):
        res = self.client.post("/api/v1/auth/login", json={
            "username": self.valid_email,
            "password": self.valid_pass
        })
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("access_token", data)
        self.assertEqual(data["token_type"], "bearer")
        self.assertEqual(data["user"]["email"], self.valid_email)
        self.assertEqual(data["user"]["role"], "admin")
        self.assertTrue(len(data["workspaces"]) >= 1)

    def test_login_success_regular_user(self):
        res = self.client.post("/api/v1/auth/login", json={
            "username": self.user_email,
            "password": self.valid_pass
        })
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["user"]["email"], self.user_email)
        self.assertEqual(data["user"]["role"], "member")

    def test_login_invalid_credentials(self):
        res = self.client.post("/api/v1/auth/login", json={
            "username": self.valid_email,
            "password": "wrongpassword1"
        })
        self.assertEqual(res.status_code, 401)
        self.assertIn("error", res.json())
        self.assertEqual(res.json()["error"]["code"], "UNAUTHORIZED")

    def test_get_me_with_bearer_token(self):
        login_res = self.client.post("/api/v1/auth/login", json={
            "username": self.valid_email,
            "password": self.valid_pass
        })
        token = login_res.json()["access_token"]
        
        me_res = self.client.get("/api/v1/auth/me", headers={
            "Authorization": f"Bearer {token}"
        })
        self.assertEqual(me_res.status_code, 200)
        self.assertEqual(me_res.json()["email"], self.valid_email)

    def test_get_me_unauthorized(self):
        me_res = self.client.get("/api/v1/auth/me")
        self.assertEqual(me_res.status_code, 401)

    def test_authenticated_sync_push_flow(self):
        login_res = self.client.post("/api/v1/auth/login", json={
            "username": self.valid_email,
            "password": self.valid_pass
        })
        token = login_res.json()["access_token"]
        ws_id = login_res.json()["workspaces"][0]["id"]
        user_id = login_res.json()["user"]["id"]

        push_res = self.client.post("/api/v1/sync/push", json={
            "client_installation_id": "test-client-inst-01",
            "operations": [
                {
                    "operation_id": "018e3a2b-9999-7000-8000-000000000001",
                    "entity_type": "task",
                    "entity_id": "018e3a2b-8888-7000-8000-000000000002",
                    "operation_type": "insert",
                    "payload": {
                        "id": "018e3a2b-8888-7000-8000-000000000002",
                        "workspace_id": ws_id,
                        "title": "مهمة تكاملية من الفحص الحي"
                    },
                    "base_version": 1
                }
            ]
        }, headers={
            "Authorization": f"Bearer {token}",
            "x-user-id": user_id,
            "x-workspace-id": ws_id
        })
        self.assertEqual(push_res.status_code, 200)
        self.assertIn(push_res.json()["acks"][0]["status"], ["success", "applied"])

if __name__ == "__main__":
    unittest.main()
