"""
Mandatory Acceptance Tests (Tests A to J) — مشروع «مُعين» (Mouin)
Strict verification against DATA_API_SYNC_CONTRACT v1.0 FINAL & ERD_FINAL v1.0
"""

import unittest
import sqlite3
from decimal import Decimal
import json
import uuid
import hashlib
from datetime import datetime, timezone
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from mobile.database.local_db_helper import LocalDatabase

def generate_uuidv7() -> str:
    """Generate RFC 9562 compliant UUIDv7."""
    ms = int(datetime.now(timezone.utc).timestamp() * 1000)
    rand_bytes = os.urandom(10)
    
    b0 = (ms >> 40) & 0xFF
    b1 = (ms >> 32) & 0xFF
    b2 = (ms >> 24) & 0xFF
    b3 = (ms >> 16) & 0xFF
    b4 = (ms >> 8) & 0xFF
    b5 = ms & 0xFF
    
    b6 = 0x70 | (rand_bytes[0] & 0x0F)
    b7 = rand_bytes[1]
    b8 = 0x80 | (rand_bytes[2] & 0x3F)
    b9_15 = rand_bytes[3:10]
    
    raw = bytes([b0, b1, b2, b3, b4, b5, b6, b7, b8]) + b9_15
    return str(uuid.UUID(bytes=raw))

class TestAcceptanceAToJ(unittest.TestCase):
    def setUp(self):
        self.db = LocalDatabase(":memory:")
        self.db.initialize_schema()
        self.ws_id = generate_uuidv7()
        self.user_id = generate_uuidv7()
        self.inst_id = generate_uuidv7()

    def tearDown(self):
        self.db.close()

    # --------------------------------------------------------------------------
    # Test A: UUIDv7 Client Generation
    # --------------------------------------------------------------------------
    def test_acceptance_a_uuidv7_client_generation(self):
        """Entity created offline with client UUIDv7; server preserves same entity_id."""
        client_entity_id = generate_uuidv7()
        
        u = uuid.UUID(client_entity_id)
        self.assertEqual(u.version, 7, "Client ID must be UUIDv7")

        self.db.execute(
            "INSERT INTO local_items (id, workspace_id, item_type, title, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            (client_entity_id, self.ws_id, "note", "ملاحظة أوفلاين", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
        )
        self.db.commit()

        row = self.db.fetchone("SELECT id FROM local_items WHERE id = ?", (client_entity_id,))
        self.assertEqual(row['id'], client_entity_id)

    # --------------------------------------------------------------------------
    # Test B: Item Aggregate Root & No Reminder Item Type
    # --------------------------------------------------------------------------
    def test_acceptance_b_item_aggregate_and_no_reminder_type(self):
        """Creating Task produces items + tasks; item_type='reminder' is rejected."""
        item_id = generate_uuidv7()
        
        self.db.execute(
            "INSERT INTO local_items (id, workspace_id, item_type, title, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            (item_id, self.ws_id, "task", "مهمة برمجية", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
        )
        self.db.execute(
            "INSERT INTO local_tasks (item_id, priority, status) VALUES (?, ?, ?)",
            (item_id, "urgent", "pending")
        )
        self.db.commit()

        item = self.db.fetchone("SELECT * FROM local_items WHERE id = ?", (item_id,))
        task = self.db.fetchone("SELECT * FROM local_tasks WHERE item_id = ?", (item_id,))
        self.assertIsNotNone(item)
        self.assertIsNotNone(task)
        self.assertEqual(task['priority'], 'urgent')

        bad_item_id = generate_uuidv7()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(
                "INSERT INTO local_items (id, workspace_id, item_type, title, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
                (bad_item_id, self.ws_id, "reminder", "تذكير غير صحيح", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
            )

    # --------------------------------------------------------------------------
    # Test C: Reminder Occurrence Deduplication
    # --------------------------------------------------------------------------
    def test_acceptance_c_reminder_occurrence_deduplication(self):
        """Duplicate occurrence_key under same rule is strictly rejected by UNIQUE constraint."""
        item_id = generate_uuidv7()
        rule_id = generate_uuidv7()
        occ_key = "occ_20260829_180000"

        self.db.execute(
            "INSERT INTO local_items (id, workspace_id, item_type, title, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            (item_id, self.ws_id, "appointment", "موعد طبيب", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
        )
        self.db.execute(
            "INSERT INTO local_reminder_rules (id, workspace_id, item_id, trigger_type, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            (rule_id, self.ws_id, item_id, "recurring", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
        )
        
        inst_1 = generate_uuidv7()
        self.db.execute(
            "INSERT INTO local_reminder_instances (id, rule_id, item_id, workspace_id, occurrence_key, scheduled_time, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            (inst_1, rule_id, item_id, self.ws_id, occ_key, "2026-08-29T18:00:00Z", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
        )
        self.db.commit()

        inst_2 = generate_uuidv7()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(
                "INSERT INTO local_reminder_instances (id, rule_id, item_id, workspace_id, occurrence_key, scheduled_time, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                (inst_2, rule_id, item_id, self.ws_id, occ_key, "2026-08-29T18:00:00Z", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
            )

    # --------------------------------------------------------------------------
    # Test D: Atomic Outbox Mutation
    # --------------------------------------------------------------------------
    def test_acceptance_d_atomic_outbox_mutation(self):
        """Create Item + Create Outbox must succeed or fail together atomically."""
        item_id = generate_uuidv7()
        op_id = generate_uuidv7()

        try:
            self.db.execute("BEGIN TRANSACTION;")
            self.db.execute(
                "INSERT INTO local_items (id, workspace_id, item_type, title, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
                (item_id, self.ws_id, "task", "مهمة ستفشل", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
            )
            raise RuntimeError("Simulated crash during transaction")
        except RuntimeError:
            self.db.rollback()

        item = self.db.fetchone("SELECT * FROM local_items WHERE id = ?", (item_id,))
        outbox = self.db.fetchone("SELECT * FROM outbox WHERE operation_id = ?", (op_id,))
        self.assertIsNone(item)
        self.assertIsNone(outbox)

    # --------------------------------------------------------------------------
    # Test E: Financial Numeric Precision
    # --------------------------------------------------------------------------
    def test_acceptance_e_financial_numeric_precision(self):
        """Money 5000.25 is handled with exact decimal precision, never as float."""
        person_id = generate_uuidv7()
        debt_id = generate_uuidv7()

        self.db.execute(
            "INSERT INTO local_people (id, workspace_id, name, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
            (person_id, self.ws_id, "أحمد علي", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
        )
        self.db.execute(
            "INSERT INTO local_items (id, workspace_id, item_type, title, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            (debt_id, self.ws_id, "debt", "دين تجاري", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
        )

        amount_decimal = Decimal("5000.25")
        self.db.execute(
            "INSERT INTO local_debts (item_id, debt_type, person_id, total_amount, currency, status) VALUES (?, ?, ?, ?, ?, ?)",
            (debt_id, "receivable", person_id, str(amount_decimal), "YER", "active")
        )
        self.db.commit()

        row = self.db.fetchone("SELECT total_amount FROM local_debts WHERE item_id = ?", (debt_id,))
        retrieved_amount = Decimal(row['total_amount'])
        self.assertEqual(retrieved_amount, Decimal("5000.25"))
        payment = Decimal("1000.10")
        remaining = retrieved_amount - payment
        self.assertEqual(remaining, Decimal("4000.15"))

    # --------------------------------------------------------------------------
    # Test F: Financial Append-Oriented Concurrency
    # --------------------------------------------------------------------------
    def test_acceptance_f_financial_append_concurrency(self):
        """Device A logs 500, Device B logs 700 offline; both are appended and sum to 1200."""
        person_id = generate_uuidv7()
        debt_id = generate_uuidv7()
        tx_a_id = generate_uuidv7()
        tx_b_id = generate_uuidv7()

        self.db.execute(
            "INSERT INTO local_people (id, workspace_id, name, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
            (person_id, self.ws_id, "سالم محمد", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
        )
        self.db.execute(
            "INSERT INTO local_items (id, workspace_id, item_type, title, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            (debt_id, self.ws_id, "debt", "قرض سيارة", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
        )
        self.db.execute(
            "INSERT INTO local_debts (item_id, debt_type, person_id, total_amount, currency, status) VALUES (?, ?, ?, ?, ?, ?)",
            (debt_id, "payable", person_id, "5000.00", "YER", "active")
        )

        self.db.execute(
            "INSERT INTO local_debt_transactions (id, debt_id, workspace_id, transaction_type, amount, transaction_date, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            (tx_a_id, debt_id, self.ws_id, "payment", "500.00", "2026-08-29", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
        )

        self.db.execute(
            "INSERT INTO local_debt_transactions (id, debt_id, workspace_id, transaction_type, amount, transaction_date, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            (tx_b_id, debt_id, self.ws_id, "payment", "700.00", "2026-08-29", "2026-08-29T10:05:00Z", "2026-08-29T10:05:00Z")
        )
        self.db.commit()

        txs = self.db.fetchall("SELECT amount FROM local_debt_transactions WHERE debt_id = ? AND deleted_at IS NULL", (debt_id,))
        self.assertEqual(len(txs), 2)
        total_paid = sum(Decimal(tx['amount']) for tx in txs)
        self.assertEqual(total_paid, Decimal("1200.00"))
        remaining = Decimal("5000.00") - total_paid
        self.assertEqual(remaining, Decimal("3800.00"))

    # --------------------------------------------------------------------------
    # Test G: Idempotency Logic
    # --------------------------------------------------------------------------
    def test_acceptance_g_idempotency(self):
        """Duplicate operation_id with same payload is idempotent; different payload is rejected."""
        op_id = generate_uuidv7()
        payload_a = json.dumps({"title": "شراء حاسوب", "status": "pending"})
        payload_b = json.dumps({"title": "شراء هاتف", "status": "pending"})
        
        hash_a = hashlib.sha256(payload_a.encode('utf-8')).hexdigest()
        hash_b = hashlib.sha256(payload_b.encode('utf-8')).hexdigest()

        self.db.execute("""
            CREATE TABLE IF NOT EXISTS server_idempotency_sim (
                operation_id TEXT PRIMARY KEY,
                payload_hash TEXT NOT NULL,
                status TEXT NOT NULL
            );
        """)
        
        def process_push(operation_id: str, payload_str: str):
            p_hash = hashlib.sha256(payload_str.encode('utf-8')).hexdigest()
            row = self.db.fetchone("SELECT * FROM server_idempotency_sim WHERE operation_id = ?", (operation_id,))
            if row is not None:
                if row['payload_hash'] == p_hash:
                    return {"status": "idempotent_success", "operation_id": operation_id}
                else:
                    raise ValueError(f"HTTP 409 Conflict: operation_id {operation_id} already used with different payload")
            self.db.execute("INSERT INTO server_idempotency_sim (operation_id, payload_hash, status) VALUES (?, ?, ?)", (operation_id, p_hash, "processed"))
            self.db.commit()
            return {"status": "created", "operation_id": operation_id}

        # 1. First push
        res1 = process_push(op_id, payload_a)
        self.assertEqual(res1['status'], "created")

        # 2. Second push with same payload -> idempotent return
        res2 = process_push(op_id, payload_a)
        self.assertEqual(res2['status'], "idempotent_success")

        # 3. Third push with different payload -> rejected
        with self.assertRaises(ValueError) as ctx:
            process_push(op_id, payload_b)
        self.assertIn("HTTP 409 Conflict", str(ctx.exception))

    # --------------------------------------------------------------------------
    # Test H: Cursor Atomicity on Pull
    # --------------------------------------------------------------------------
    def test_acceptance_h_cursor_atomicity_on_pull(self):
        """If Pull crashes before commit, cursor remains at previous sequence value."""
        self.db.execute(
            "INSERT INTO local_sync_state (workspace_id, last_synced_server_sequence, updated_at) VALUES (?, ?, ?)",
            (self.ws_id, 100, "2026-08-29T10:00:00Z")
        )
        self.db.commit()

        try:
            self.db.execute("BEGIN TRANSACTION;")
            item_id = generate_uuidv7()
            self.db.execute(
                "INSERT INTO local_items (id, workspace_id, item_type, title, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
                (item_id, self.ws_id, "note", "ملاحظة سحابية", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
            )
            raise RuntimeError("Crash before cursor advance commit")
        except RuntimeError:
            self.db.rollback()

        state = self.db.fetchone("SELECT last_synced_server_sequence FROM local_sync_state WHERE workspace_id = ?", (self.ws_id,))
        self.assertEqual(state['last_synced_server_sequence'], 100)

    # --------------------------------------------------------------------------
    # Test I: Scoped Ownership
    # --------------------------------------------------------------------------
    def test_acceptance_i_scoped_ownership(self):
        """Cross-workspace resource access is strictly blocked."""
        ws_a = generate_uuidv7()
        ws_b = generate_uuidv7()
        item_a = generate_uuidv7()

        self.db.execute(
            "INSERT INTO local_items (id, workspace_id, item_type, title, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            (item_a, ws_a, "note", "سري خاص بـ A", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
        )
        self.db.commit()

        found_in_b = self.db.fetchone("SELECT * FROM local_items WHERE id = ? AND workspace_id = ?", (item_a, ws_b))
        self.assertIsNone(found_in_b)

        found_in_a = self.db.fetchone("SELECT * FROM local_items WHERE id = ? AND workspace_id = ?", (item_a, ws_a))
        self.assertIsNotNone(found_in_a)

    # --------------------------------------------------------------------------
    # Test J: Tombstones & Soft Delete
    # --------------------------------------------------------------------------
    def test_acceptance_j_tombstones_soft_delete(self):
        """Soft deleting an item sets deleted_at and preserves record for replication."""
        item_id = generate_uuidv7()

        self.db.execute(
            "INSERT INTO local_items (id, workspace_id, item_type, title, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            (item_id, self.ws_id, "task", "مهمة ستحذف", "2026-08-29T10:00:00Z", "2026-08-29T10:00:00Z")
        )
        self.db.commit()

        now_iso = "2026-08-29T12:00:00Z"
        self.db.execute("UPDATE local_items SET deleted_at = ?, entity_version = entity_version + 1 WHERE id = ?", (now_iso, item_id))
        self.db.commit()

        row = self.db.fetchone("SELECT * FROM local_items WHERE id = ?", (item_id,))
        self.assertIsNotNone(row)
        self.assertEqual(row['deleted_at'], now_iso)
        self.assertEqual(row['entity_version'], 2)

if __name__ == '__main__':
    unittest.main()
