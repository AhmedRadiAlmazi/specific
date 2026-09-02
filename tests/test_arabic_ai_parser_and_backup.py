"""
Phase 7 Arabic AI Parser & Backup Recovery Test Suite — مشروع «مُعين» (Mouin)
"""

import unittest
import os
import shutil
import tempfile
from datetime import datetime, timezone
from decimal import Decimal

from backend.app.domain.services.arabic_ai_parser import ArabicAIParser
from backend.scripts.backup_restore import create_backup_snapshot, verify_and_read_backup

class TestArabicAIParserAndBackup(unittest.TestCase):
    def setUp(self):
        self.ref_time = datetime(2026, 9, 1, 8, 0, 0, tzinfo=timezone.utc)
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_parse_complex_debt_with_natural_arabic(self):
        input_text = "دين 5000 ريال لسالم لشراء المواد عاجل"
        parsed = ArabicAIParser.parse(input_text, reference_time=self.ref_time)

        self.assertEqual(parsed.item_type, "debt")
        self.assertEqual(parsed.amount, Decimal("5000"))
        self.assertEqual(parsed.currency, "YER")
        self.assertEqual(parsed.person_name, "سالم")
        self.assertEqual(parsed.priority, "high")

    def test_parse_reminder_with_time_and_urgency(self):
        input_text = "ذكرني غداً الساعة 10 صباحاً بموعد المستشفى عاجل جداً"
        parsed = ArabicAIParser.parse(input_text, reference_time=self.ref_time)

        self.assertEqual(parsed.item_type, "reminder")
        self.assertEqual(parsed.priority, "urgent")
        self.assertIsNotNone(parsed.due_date)
        self.assertEqual(parsed.due_date.day, 2)
        self.assertEqual(parsed.due_date.hour, 10)

    def test_parse_shopping_list(self):
        input_text = "قائمة مشتريات: حليب وخبز وجبن من السوبرماركت"
        parsed = ArabicAIParser.parse(input_text, reference_time=self.ref_time)

        self.assertEqual(parsed.item_type, "shopping")
        self.assertEqual(parsed.priority, "medium")

    def test_backup_and_verified_recovery(self):
        mock_data = {
            "workspace_id": "ws-001",
            "items": [{"id": "item-1", "title": "مهمة 1"}],
            "debts": [{"id": "debt-1", "amount": "5000"}]
        }

        backup_info = create_backup_snapshot(mock_data, self.test_dir)
        self.assertTrue(os.path.exists(backup_info["snapshot_file"]))
        self.assertTrue(os.path.exists(backup_info["manifest_file"]))

        restored_data = verify_and_read_backup(
            backup_info["snapshot_file"],
            backup_info["manifest_file"]
        )
        self.assertEqual(restored_data, mock_data)

    def test_backup_tampering_detection(self):
        mock_data = {"key": "original_data"}
        backup_info = create_backup_snapshot(mock_data, self.test_dir)

        # Tamper with snapshot file
        with open(backup_info["snapshot_file"], "w") as f:
            f.write('{"key": "tampered_data"}')

        with self.assertRaises(ValueError):
            verify_and_read_backup(
                backup_info["snapshot_file"],
                backup_info["manifest_file"]
            )

if __name__ == "__main__":
    unittest.main()
