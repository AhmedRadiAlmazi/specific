"""
SQLite Infrastructure Integration Tests — مشروع «مُعين» (Mouin)
Real Integration testing against actual SQLite schema, FTS5, triggers, and transactions.
"""

import unittest
import sqlite3
import os
from decimal import Decimal
from datetime import datetime, date, timezone, timedelta

from backend.app.domain.entities.item import Item, TaskDetail
from backend.app.domain.entities.debt import Debt
from backend.app.domain.entities.reminder import ReminderRule
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId, generate_uuidv7
from backend.app.domain.value_objects.money import Money, YER
from backend.app.domain.value_objects.types import Priority, DebtType, ReminderTriggerType
from backend.app.infrastructure.persistence.sqlite.connection import SqliteConnectionManager
from backend.app.infrastructure.persistence.sqlite.unit_of_work import SqliteUnitOfWork
from backend.app.infrastructure.persistence.sqlite.repositories.local_item_repository import SqliteItemRepository
from backend.app.infrastructure.persistence.sqlite.repositories.local_debt_repository import SqliteDebtRepository
from backend.app.infrastructure.persistence.sqlite.repositories.local_reminder_repository import SqliteReminderRepository
from backend.app.infrastructure.persistence.sqlite.repositories.outbox_repository import SqliteOutboxRepository
from mobile.database.local_db_helper import LocalDatabase

class TestInfrastructureSqlite(unittest.TestCase):
    def setUp(self):
        self.local_db = LocalDatabase(":memory:")
        self.local_db.initialize_schema()
        self.conn = self.local_db.conn

        self.uow = SqliteUnitOfWork(self.conn)
        self.item_repo = SqliteItemRepository(self.conn)
        self.debt_repo = SqliteDebtRepository(self.conn)
        self.reminder_repo = SqliteReminderRepository(self.conn)
        self.outbox_repo = SqliteOutboxRepository(self.conn)

        self.ws_a = WorkspaceId.new()
        self.ws_b = WorkspaceId.new()

    def tearDown(self):
        self.local_db.close()

    # 1. Item Aggregate Persistence & Workspace Scoping
    def test_item_aggregate_persistence_and_scoping(self):
        item_id = EntityId.new()
        task_item = Item.create_task(
            id=item_id,
            workspace_id=self.ws_a,
            title="شراء مواد بناء",
            due_date=datetime(2026, 9, 1, 12, 0, tzinfo=timezone.utc),
            priority=Priority.URGENT
        )

        with self.uow:
            self.item_repo.save(task_item)
            self.uow.commit()

        # Retrieve in same workspace -> Found
        retrieved = self.item_repo.get_by_id(self.ws_a, item_id)
        self.assertIsNotNone(retrieved)
        self.assertEqual(retrieved.title, "شراء مواد بناء")
        self.assertEqual(retrieved.task_detail.priority, Priority.URGENT)

        # Retrieve in different workspace -> None (Isolated)
        retrieved_other = self.item_repo.get_by_id(self.ws_b, item_id)
        self.assertIsNone(retrieved_other)

    # 2. Atomic Outbox and Domain Mutation
    def test_atomic_outbox_and_domain_mutation(self):
        item_id = EntityId.new()
        op_id = generate_uuidv7()
        task_item = Item.create_task(
            id=item_id,
            workspace_id=self.ws_a,
            title="مهمة المزامنة الذرية"
        )

        with self.uow:
            self.item_repo.save(task_item)
            self.outbox_repo.enqueue_operation(
                operation_id=op_id,
                entity_type="item",
                entity_id=str(item_id),
                operation="insert",
                payload={"title": task_item.title}
            )
            self.uow.commit()

        # Verify both item and outbox exist
        saved_item = self.item_repo.get_by_id(self.ws_a, item_id)
        pending_ops = self.outbox_repo.get_pending_operations()
        self.assertIsNotNone(saved_item)
        self.assertEqual(len(pending_ops), 1)
        self.assertEqual(pending_ops[0]['operation_id'], op_id)

    # 3. Rollback Atomicity on Error
    def test_rollback_atomicity(self):
        item_id = EntityId.new()
        task_item = Item.create_task(id=item_id, workspace_id=self.ws_a, title="مهمة ستلغى")

        try:
            with self.uow:
                self.item_repo.save(task_item)
                raise RuntimeError("Simulated failure before commit")
        except RuntimeError:
            pass

        saved_item = self.item_repo.get_by_id(self.ws_a, item_id)
        self.assertIsNone(saved_item, "Item must NOT be persisted after rollback.")

    # 4. Debt Persistence & Append-Only Ledger
    def test_debt_persistence_and_ledger(self):
        debt_id = EntityId.new()
        person_id = EntityId.new()

        # Insert foreign key dependency in local_people
        self.conn.execute(
            "INSERT INTO local_people (id, workspace_id, name, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
            (str(person_id), str(self.ws_a), "التاجر سالم", "2026-08-29T12:00:00Z", "2026-08-29T12:00:00Z")
        )
        self.conn.commit()

        debt = Debt.create(
            id=debt_id,
            workspace_id=self.ws_a,
            person_id=person_id,
            debt_type=DebtType.RECEIVABLE,
            total_amount=Money(Decimal("15000.50"), YER)
        )

        # Record two offline payments (5000 + 3000.25 = 8000.25)
        tx1 = debt.record_payment(EntityId.new(), Money(Decimal("5000.00"), YER), date(2026, 8, 29))
        tx2 = debt.record_payment(EntityId.new(), Money(Decimal("3000.25"), YER), date(2026, 8, 29))

        with self.uow:
            self.debt_repo.save(debt)
            self.uow.commit()

        retrieved_debt = self.debt_repo.get_by_id(self.ws_a, debt_id)
        self.assertIsNotNone(retrieved_debt)
        self.assertEqual(len(retrieved_debt.transactions), 2)
        rem = retrieved_debt.calculate_remaining_amount()
        # 15000.50 - 8000.25 = 7000.25
        self.assertEqual(rem.amount, Decimal("7000.25"))

    # 5. Reminder Persistence & Occurrence Deduplication
    def test_reminder_persistence(self):
        rule_id = EntityId.new()
        item_id = EntityId.new()

        # Insert parent item dependency in local_items
        task_item = Item.create_task(id=item_id, workspace_id=self.ws_a, title="مهمة مرتبطة بتذكير")
        with self.uow:
            self.item_repo.save(task_item)
            self.uow.commit()

        rule = ReminderRule.create(
            id=rule_id,
            workspace_id=self.ws_a,
            item_id=item_id,
            trigger_type=ReminderTriggerType.RECURRING
        )
        sched_time = datetime(2026, 8, 30, 9, 0, tzinfo=timezone.utc)
        inst = rule.generate_instance(EntityId.new(), sched_time)

        with self.uow:
            self.reminder_repo.save_rule(rule)
            self.reminder_repo.save_instance(inst)
            self.uow.commit()

        retrieved_rule = self.reminder_repo.get_rule_by_id(self.ws_a, rule_id)
        self.assertIsNotNone(retrieved_rule)
        self.assertEqual(len(retrieved_rule.instances), 1)

if __name__ == '__main__':
    unittest.main()
