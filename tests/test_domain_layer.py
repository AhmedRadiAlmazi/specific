"""
Domain Layer Comprehensive Unit Tests — مشروع «مُعين» (Mouin)
Verifies all pure domain logic, value objects, aggregates, and invariants.
"""

import unittest
from decimal import Decimal
from datetime import datetime, date, timezone, timedelta
import uuid

from backend.app.domain.exceptions import (
    InvariantViolationError, InvalidStateTransitionError, CurrencyMismatchError,
    OccurrenceAlreadyExistsError, ImmutableTransactionError
)
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId, generate_uuidv7
from backend.app.domain.value_objects.money import Money, Currency, YER, USD, SAR
from backend.app.domain.value_objects.types import (
    ItemType, PrivacyClassification, Priority, TaskStatus, DebtType, DebtStatus,
    DebtTransactionType, ReminderTriggerType, ReminderStatus
)
from backend.app.domain.entities.item import Item, TaskDetail
from backend.app.domain.entities.debt import Debt, DebtTransaction
from backend.app.domain.entities.reminder import ReminderRule, ReminderInstance
from backend.app.domain.services.debt_calculator import DebtCalculatorService
from backend.app.domain.services.reminder_service import ReminderOccurrenceService

class TestDomainLayer(unittest.TestCase):

    def setUp(self):
        self.ws_id = WorkspaceId.new()

    # 1. Identity & UUIDv7 Tests
    def test_uuidv7_generation_and_validation(self):
        val = generate_uuidv7()
        u = uuid.UUID(val)
        self.assertEqual(u.version, 7)

        eid = EntityId(val)
        self.assertEqual(str(eid), val)

        # Invalid UUID format should raise InvariantViolationError
        with self.assertRaises(InvariantViolationError):
            EntityId("invalid-uuid-string")

    # 2. Money Value Object Tests
    def test_money_decimal_precision_and_currency(self):
        m1 = Money(Decimal("5000.25"), YER)
        m2 = Money.from_str("1200.50", "YER")
        res = m1 + m2
        self.assertEqual(res.amount, Decimal("6200.75"))
        self.assertEqual(res.currency, YER)

        # Prohibit float types directly
        with self.assertRaises(InvariantViolationError):
            Money(5000.25, YER)

        # Currency mismatch test
        m_usd = Money(Decimal("100.00"), USD)
        with self.assertRaises(CurrencyMismatchError):
            _ = m1 + m_usd

    # 3. Item Aggregate Root & Subtypes
    def test_item_aggregate_and_reminder_rejection(self):
        task_item = Item.create_task(
            id=EntityId.new(),
            workspace_id=self.ws_id,
            title="مهمة اختبار النطاق",
            priority=Priority.HIGH
        )
        self.assertEqual(task_item.item_type, ItemType.TASK)
        self.assertIsNotNone(task_item.task_detail)
        self.assertEqual(task_item.task_detail.status, TaskStatus.PENDING)

        # Completing the task
        task_item.complete_task()
        self.assertEqual(task_item.task_detail.status, TaskStatus.COMPLETED)
        self.assertIsNotNone(task_item.task_detail.completed_at)
        self.assertEqual(task_item.entity_version, 2)

        # Events collected
        events = task_item.collect_events()
        self.assertEqual(len(events), 2)  # Created + Completed

        # Title mandatory invariant
        with self.assertRaises(InvariantViolationError):
            Item.create_task(id=EntityId.new(), workspace_id=self.ws_id, title="")

        # Reminder cannot be an Item type
        with self.assertRaises(InvariantViolationError):
            Item(id=EntityId.new(), workspace_id=self.ws_id, item_type="reminder", title="Invalid")

    # 4. Debt Aggregate & Append-Only Financial Ledger
    def test_debt_append_only_ledger_and_offline_concurrency(self):
        debt_id = EntityId.new()
        person_id = EntityId.new()
        debt = Debt.create(
            id=debt_id,
            workspace_id=self.ws_id,
            person_id=person_id,
            debt_type=DebtType.PAYABLE,
            total_amount=Money(Decimal("5000.00"), YER)
        )

        # Offline Device A logs 500
        tx_a = debt.record_payment(
            tx_id=EntityId.new(),
            amount=Money(Decimal("500.00"), YER),
            transaction_date=date(2026, 8, 29)
        )

        # Offline Device B logs 700
        tx_b = debt.record_payment(
            tx_id=EntityId.new(),
            amount=Money(Decimal("700.00"), YER),
            transaction_date=date(2026, 8, 29)
        )

        # Check total payments = 1200, remaining = 3800
        remaining = debt.calculate_remaining_amount()
        self.assertEqual(remaining.amount, Decimal("3800.00"))
        self.assertEqual(debt.status, DebtStatus.ACTIVE)

        # In-place transaction mutation is strictly forbidden
        with self.assertRaises(ImmutableTransactionError):
            tx_a.mutate_attempt()

        # Reversal test: Reverse tx_a (500)
        rev_tx = debt.reverse_transaction(
            tx_id=EntityId.new(),
            target_tx_id=tx_a.id,
            notes="خطأ في الإيداع"
        )
        self.assertEqual(rev_tx.transaction_type, DebtTransactionType.REVERSAL)

        # Remaining after reversal of 500 should be 5000 - 700 = 4300
        remaining_after_rev = debt.calculate_remaining_amount()
        self.assertEqual(remaining_after_rev.amount, Decimal("4300.00"))

    # 5. Reminder Subsystem & Occurrence Deduplication
    def test_reminder_occurrence_deduplication(self):
        item_id = EntityId.new()
        rule = ReminderRule.create(
            id=EntityId.new(),
            workspace_id=self.ws_id,
            item_id=item_id,
            trigger_type=ReminderTriggerType.RECURRING
        )

        sched_time = datetime(2026, 8, 30, 10, 0, tzinfo=timezone.utc)
        inst1 = rule.generate_instance(EntityId.new(), sched_time)
        self.assertEqual(inst1.status, ReminderStatus.PENDING)
        self.assertTrue(inst1.occurrence_key)

        # Attempting to generate instance with same scheduled time under same rule -> Rejected
        with self.assertRaises(OccurrenceAlreadyExistsError):
            rule.generate_instance(EntityId.new(), sched_time)

        # Snooze instance
        snooze_until = datetime.now(timezone.utc) + timedelta(minutes=15)
        inst1.snooze(snooze_until)
        self.assertEqual(inst1.status, ReminderStatus.SNOOZED)

if __name__ == '__main__':
    unittest.main()
