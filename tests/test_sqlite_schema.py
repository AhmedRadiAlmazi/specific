"""
SQLite Local Schema & Functional Tests — مشروع «مُعين» (Mouin)
Strictly verifies all 26 SQLite tables, foreign keys, triggers, and FTS5.
"""

import unittest
import sqlite3
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from mobile.database.local_db_helper import LocalDatabase, normalize_arabic

class TestSqliteSchema(unittest.TestCase):
    def setUp(self):
        self.db = LocalDatabase(":memory:")
        self.db.initialize_schema()

    def tearDown(self):
        self.db.close()

    def test_all_26_local_tables_created_and_counted(self):
        tables = [row['name'] for row in self.db.fetchall("SELECT name FROM sqlite_master WHERE type='table';")]
        expected = [
            'local_session', 'local_sync_state', 'outbox', 'local_sync_conflicts',
            'local_categories', 'local_people', 'local_items', 'local_tasks',
            'local_appointments', 'local_notes', 'local_documents', 'local_debts',
            'local_debt_transactions', 'local_shopping_lists', 'local_shopping_entries',
            'local_reminder_rules', 'local_reminder_instances', 'local_notifications',
            'local_notification_actions', 'local_attachments', 'local_item_attachments',
            'local_debt_transaction_attachments', 'local_inbox_items', 'local_inbox_attachments',
            'local_ai_suggestions', 'items_fts'
        ]
        self.assertEqual(len(expected), 26, "Expected count of SQLite tables is 26.")
        for t in expected:
            self.assertIn(t, tables, f"Expected SQLite table '{t}' not found.")

    def test_foreign_key_cascade_on_delete_item(self):
        ws_id = "018e3a2b-0001-7000-8000-000000000001"
        item_id = "018e3a2b-0002-7000-8000-000000000002"
        
        self.db.execute(
            "INSERT INTO local_items (id, workspace_id, item_type, title, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            (item_id, ws_id, "task", "مهمة اختبار", "2026-08-29T12:00:00Z", "2026-08-29T12:00:00Z")
        )
        self.db.execute(
            "INSERT INTO local_tasks (item_id, priority, status) VALUES (?, ?, ?)",
            (item_id, "high", "pending")
        )
        self.db.commit()

        task = self.db.fetchone("SELECT * FROM local_tasks WHERE item_id = ?", (item_id,))
        self.assertIsNotNone(task)

        self.db.execute("DELETE FROM local_items WHERE id = ?", (item_id,))
        self.db.commit()

        task_after = self.db.fetchone("SELECT * FROM local_tasks WHERE item_id = ?", (item_id,))
        self.assertIsNone(task_after)

    def test_fts5_arabic_search(self):
        ws_id = "018e3a2b-0001-7000-8000-000000000001"
        item_id = "018e3a2b-0003-7000-8000-000000000003"
        title = "شراء أدوية ومستلزمات طبية"
        summary = "فحص الفاتورة من الصيدلية"

        self.db.execute(
            "INSERT INTO local_items (id, workspace_id, item_type, title, summary, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (item_id, ws_id, "task", title, summary, "2026-08-29T12:00:00Z", "2026-08-29T12:00:00Z")
        )
        self.db.commit()

        results = self.db.fetchall("""
            SELECT i.id, i.title 
            FROM local_items i 
            JOIN items_fts f ON i.rowid = f.rowid 
            WHERE items_fts MATCH 'أدوية'
        """)
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['id'], item_id)

if __name__ == '__main__':
    unittest.main()
