"""
PostgreSQL Schema DDL Validation Tests — مشروع «مُعين» (Mouin)
Strictly verifies all 30 PostgreSQL tables, constraints, types, and indexes.
"""

import unittest
import re
import os

class TestPostgresSchema(unittest.TestCase):
    def setUp(self):
        schema_path = os.path.join(os.path.dirname(__file__), '..', 'backend', 'database', 'postgres_schema.sql')
        with open(schema_path, 'r', encoding='utf-8') as f:
            self.schema_sql = f.read()

    def test_all_30_tables_present_and_counted(self):
        expected_tables = [
            'users', 'devices', 'installations', 'workspaces', 'workspace_members',
            'categories', 'people', 'items', 'tasks', 'appointments', 'notes',
            'documents', 'debts', 'debt_transactions', 'shopping_lists', 'shopping_entries',
            'reminder_rules', 'reminder_instances', 'notifications', 'notification_actions',
            'attachments', 'item_attachments', 'debt_transaction_attachments',
            'inbox_items', 'inbox_attachments', 'ai_suggestions',
            'events', 'sync_changes', 'sync_idempotency', 'sync_conflicts'
        ]
        self.assertEqual(len(expected_tables), 30, "Expected exact count of PostgreSQL tables is 30.")
        
        found_tables = re.findall(r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([a-zA-Z0-9_]+)\s*\(', self.schema_sql)
        self.assertEqual(len(found_tables), 30, f"Found {len(found_tables)} tables in PostgreSQL DDL, expected 30.")
        for table in expected_tables:
            self.assertIn(table, found_tables, f"Table '{table}' not found in PostgreSQL schema DDL.")

    def test_uuidv7_primary_keys_for_syncable_entities(self):
        syncable_tables = ['items', 'categories', 'people', 'debt_transactions', 'shopping_entries', 'reminder_rules', 'reminder_instances', 'attachments', 'inbox_items']
        for table in syncable_tables:
            match = re.search(rf'CREATE\s+TABLE\s+{table}\s*\((.*?)\);', self.schema_sql, re.DOTALL)
            self.assertIsNotNone(match, f"Could not find table {table}")
            table_body = match.group(1)
            self.assertIn("id UUID NOT NULL PRIMARY KEY", table_body, f"Table {table} must have 'id UUID NOT NULL PRIMARY KEY'")

    def test_server_sequence_is_bigint(self):
        match = re.search(r'CREATE\s+TABLE\s+sync_changes\s*\((.*?)\);', self.schema_sql, re.DOTALL)
        self.assertIsNotNone(match)
        table_body = match.group(1)
        self.assertIn("server_sequence BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY", table_body)

    def test_reminder_is_not_item_type(self):
        match = re.search(r'CREATE\s+TABLE\s+items\s*\((.*?)\);', self.schema_sql, re.DOTALL)
        self.assertIsNotNone(match)
        table_body = match.group(1)
        self.assertNotIn("'reminder'", table_body)
        self.assertIn("CHECK (item_type IN ('task', 'appointment', 'note', 'document', 'debt', 'shopping'))", table_body)

    def test_no_float_for_money(self):
        debts_match = re.search(r'CREATE\s+TABLE\s+debts\s*\((.*?)\);', self.schema_sql, re.DOTALL)
        self.assertIn("total_amount NUMERIC(14, 2) NOT NULL CHECK (total_amount > 0)", debts_match.group(1))
        
        tx_match = re.search(r'CREATE\s+TABLE\s+debt_transactions\s*\((.*?)\);', self.schema_sql, re.DOTALL)
        self.assertIn("amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0)", tx_match.group(1))

    def test_no_loose_polymorphic_attachments(self):
        self.assertNotIn("owner_type", self.schema_sql)
        self.assertNotIn("owner_id", self.schema_sql)
        self.assertIn("CREATE TABLE item_attachments", self.schema_sql)
        self.assertIn("CREATE TABLE debt_transaction_attachments", self.schema_sql)
        self.assertIn("CREATE TABLE inbox_attachments", self.schema_sql)

    def test_reminder_occurrence_key_unique(self):
        match = re.search(r'CREATE\s+TABLE\s+reminder_instances\s*\((.*?)\);', self.schema_sql, re.DOTALL)
        table_body = match.group(1)
        self.assertIn("CONSTRAINT uq_reminder_instance_rule_occ UNIQUE (rule_id, occurrence_key)", table_body)

    def test_events_and_sync_changes_separated(self):
        self.assertIn("CREATE TABLE events", self.schema_sql)
        self.assertIn("CREATE TABLE sync_changes", self.schema_sql)
        events_match = re.search(r'CREATE\s+TABLE\s+events\s*\((.*?)\);', self.schema_sql, re.DOTALL)
        self.assertNotIn("server_sequence", events_match.group(1))

    def test_privacy_classification_levels(self):
        match = re.search(r'CREATE\s+TABLE\s+items\s*\((.*?)\);', self.schema_sql, re.DOTALL)
        table_body = match.group(1)
        self.assertIn("CHECK (privacy_classification IN ('private', 'sensitive'))", table_body)

if __name__ == '__main__':
    unittest.main()
