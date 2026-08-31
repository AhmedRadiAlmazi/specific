"""
Phase 4.1 Unified Items Domain & API Verification Suite — مشروع «مُعين» (Mouin)
"""

import unittest
from datetime import datetime, timezone
from fastapi.testclient import TestClient
from backend.app.presentation.api.app import app
from backend.app.domain.entities.item import Item
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId
from backend.app.domain.value_objects.types import ItemType, Priority, PrivacyClassification

class TestPhase41UnifiedItems(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)
        self.ws_id = "018e3a2b-0002-7000-8000-000000000002"
        self.user_id = "018e3a2b-0001-7000-8000-000000000001"
        self.headers = {
            "x-user-id": self.user_id,
            "x-workspace-id": self.ws_id
        }

    def test_domain_item_subtypes_creation(self):
        """Unified Item aggregate creates Task, Note, Appointment, Document correctly."""
        ws = WorkspaceId(self.ws_id)
        
        # 1. Task
        task = Item.create_task(
            id=EntityId.new(), workspace_id=ws, title="مهمة دومين",
            due_date=datetime.now(timezone.utc), priority=Priority.HIGH
        )
        self.assertEqual(task.item_type, ItemType.TASK)
        self.assertIsNotNone(task.task_detail)
        self.assertEqual(task.task_detail.priority, Priority.HIGH)

        # 2. Note
        note = Item.create_note(
            id=EntityId.new(), workspace_id=ws, title="ملاحظة دومين",
            content="محتوى ملاحظة تجريبي", content_format="plain_text"
        )
        self.assertEqual(note.item_type, ItemType.NOTE)
        self.assertIsNotNone(note.note_detail)
        self.assertEqual(note.note_detail.content, "محتوى ملاحظة تجريبي")

        # 3. Appointment
        appt = Item.create_appointment(
            id=EntityId.new(), workspace_id=ws, title="موعد دومين",
            start_time=datetime.now(timezone.utc), location="المقر الرئيسي"
        )
        self.assertEqual(appt.item_type, ItemType.APPOINTMENT)
        self.assertIsNotNone(appt.appointment_detail)
        self.assertEqual(appt.appointment_detail.location, "المقر الرئيسي")

        # 4. Document
        doc = Item.create_document(
            id=EntityId.new(), workspace_id=ws, title="وثيقة عقد العمل",
            document_type="contract", document_number="CNT-2026-001"
        )
        self.assertEqual(doc.item_type, ItemType.DOCUMENT)
        self.assertIsNotNone(doc.document_detail)
        self.assertEqual(doc.document_detail.document_number, "CNT-2026-001")

    def test_api_create_and_list_unified_items(self):
        """POST & GET /api/v1/workspaces/{workspace_id}/items handles all subtypes."""
        # 1. Create Note via API
        note_res = self.client.post(
            f"/api/v1/workspaces/{self.ws_id}/items",
            headers=self.headers,
            json={
                "item_type": "note",
                "title": "ملاحظة عبر الـ API",
                "summary": "ملخص الملاحظة",
                "note_detail": {
                    "content": "تفاصيل الملاحظة بالكامل",
                    "content_format": "plain_text"
                }
            }
        )
        self.assertEqual(note_res.status_code, 201)
        note_data = note_res.json()
        self.assertEqual(note_data["item_type"], "note")
        self.assertEqual(note_data["title"], "ملاحظة عبر الـ API")
        self.assertIsNotNone(note_data["note_detail"])
        self.assertEqual(note_data["note_detail"]["content"], "تفاصيل الملاحظة بالكامل")

        # 2. Create Appointment via API
        appt_res = self.client.post(
            f"/api/v1/workspaces/{self.ws_id}/items",
            headers=self.headers,
            json={
                "item_type": "appointment",
                "title": "موعد الطبيب الاستشاري",
                "appointment_detail": {
                    "start_time": datetime.now(timezone.utc).isoformat(),
                    "location": "العيادة المركزية"
                }
            }
        )
        self.assertEqual(appt_res.status_code, 201)
        appt_data = appt_res.json()
        self.assertEqual(appt_data["item_type"], "appointment")
        self.assertEqual(appt_data["appointment_detail"]["location"], "العيادة المركزية")

        # 3. List items with type filter
        list_res = self.client.get(
            f"/api/v1/workspaces/{self.ws_id}/items?item_type=note",
            headers=self.headers
        )
        self.assertEqual(list_res.status_code, 200)
        items_list = list_res.json()["items"]
        for it in items_list:
            self.assertEqual(it["item_type"], "note")

    def test_backward_compatibility_task_endpoints(self):
        """POST /tasks and /tasks/{id}/complete remain fully functional."""
        create_res = self.client.post(
            f"/api/v1/workspaces/{self.ws_id}/tasks",
            headers=self.headers,
            json={
                "title": "مهمة توافقية قديمة",
                "priority": "urgent"
            }
        )
        self.assertEqual(create_res.status_code, 201)
        task_id = create_res.json()["id"]

        # Complete task
        comp_res = self.client.post(
            f"/api/v1/workspaces/{self.ws_id}/tasks/{task_id}/complete",
            headers=self.headers
        )
        self.assertEqual(comp_res.status_code, 200)
        self.assertEqual(comp_res.json()["task_detail"]["status"], "completed")

    def test_sync_push_unified_items(self):
        """Sync Push accepts and acks generic item subtypes."""
        import uuid
        op_id = str(uuid.uuid4())
        item_id = str(uuid.uuid4())

        push_res = self.client.post(
            "/api/v1/sync/push",
            headers=self.headers,
            json={
                "client_installation_id": "client-test-41",
                "operations": [{
                    "operation_id": op_id,
                    "entity_type": "item",
                    "entity_id": item_id,
                    "operation_type": "insert",
                    "payload": {
                        "id": item_id,
                        "workspace_id": self.ws_id,
                        "item_type": "note",
                        "title": "ملاحظة متزامنة"
                    },
                    "base_version": 1
                }]
            }
        )
        self.assertEqual(push_res.status_code, 200)
        acks = push_res.json()["acks"]
        self.assertEqual(len(acks), 1)
        self.assertEqual(acks[0]["operation_id"], op_id)
        self.assertEqual(acks[0]["status"], "success")

if __name__ == "__main__":
    unittest.main()
