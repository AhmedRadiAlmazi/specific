"""
Application Layer Comprehensive Tests — مشروع «مُعين» (Mouin)
Tests Application Commands, Handlers, Ports, and Unit of Work orchestrations.
"""

import unittest
from datetime import datetime, date, timezone
from decimal import Decimal
from typing import Dict, List, Optional

from backend.app.application.exceptions import NotFoundError, UnauthorizedWorkspaceAccessError
from backend.app.application.ports.unit_of_work import IUnitOfWork
from backend.app.application.ports.event_publisher import IDomainEventPublisher
from backend.app.application.ports.repositories import (
    IItemRepository, IDebtRepository, IReminderRepository
)
from backend.app.application.commands.item_commands import (
    CreateTaskCommand, CompleteTaskCommand, SoftDeleteItemCommand
)
from backend.app.application.commands.debt_commands import (
    CreateDebtCommand, RecordDebtPaymentCommand, ReverseDebtTransactionCommand
)
from backend.app.application.commands.reminder_commands import (
    CreateReminderRuleCommand, GenerateReminderInstanceCommand
)
from backend.app.application.handlers import (
    TaskCommandHandler, DebtCommandHandler, ReminderCommandHandler
)
from backend.app.domain.entities.item import Item
from backend.app.domain.entities.debt import Debt
from backend.app.domain.entities.reminder import ReminderRule, ReminderInstance
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId, generate_uuidv7
from backend.app.domain.events.domain_events import DomainEvent

# --------------------------------------------------------------------------
# Test In-Memory Implementations for Ports
# --------------------------------------------------------------------------

class InMemoryUnitOfWork(IUnitOfWork):
    def __init__(self):
        self.committed = False
        self.rolled_back = False

    def __enter__(self):
        self.committed = False
        self.rolled_back = False
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            self.rollback()

    def commit(self):
        self.committed = True

    def rollback(self):
        self.rolled_back = True

class InMemoryEventPublisher(IDomainEventPublisher):
    def __init__(self):
        self.published_events: List[DomainEvent] = []

    def publish(self, event: DomainEvent):
        self.published_events.append(event)

    def publish_all(self, events: List[DomainEvent]):
        self.published_events.extend(events)

class InMemoryItemRepository(IItemRepository):
    def __init__(self):
        self.items: Dict[str, Item] = {}

    def save(self, item: Item) -> None:
        self.items[f"{item.workspace_id}:{item.id}"] = item

    def get_by_id(self, workspace_id: WorkspaceId, item_id: EntityId) -> Optional[Item]:
        return self.items.get(f"{workspace_id}:{item_id}")

    def list_by_workspace(self, workspace_id: WorkspaceId, limit: int = 50, offset: int = 0) -> List[Item]:
        return [item for k, item in self.items.items() if k.startswith(f"{workspace_id}:")]

class InMemoryDebtRepository(IDebtRepository):
    def __init__(self):
        self.debts: Dict[str, Debt] = {}

    def save(self, debt: Debt) -> None:
        self.debts[f"{debt.workspace_id}:{debt.id}"] = debt

    def get_by_id(self, workspace_id: WorkspaceId, debt_id: EntityId) -> Optional[Debt]:
        return self.debts.get(f"{workspace_id}:{debt_id}")

    def list_by_workspace(self, workspace_id: WorkspaceId) -> List[Debt]:
        return [debt for k, debt in self.debts.items() if k.startswith(f"{workspace_id}:")]

class InMemoryReminderRepository(IReminderRepository):
    def __init__(self):
        self.rules: Dict[str, ReminderRule] = {}
        self.instances: Dict[str, ReminderInstance] = {}

    def save_rule(self, rule: ReminderRule) -> None:
        self.rules[f"{rule.workspace_id}:{rule.id}"] = rule

    def get_rule_by_id(self, workspace_id: WorkspaceId, rule_id: EntityId) -> Optional[ReminderRule]:
        return self.rules.get(f"{workspace_id}:{rule_id}")

    def save_instance(self, instance: ReminderInstance) -> None:
        self.instances[f"{instance.workspace_id}:{instance.id}"] = instance

    def get_instance_by_id(self, workspace_id: WorkspaceId, instance_id: EntityId) -> Optional[ReminderInstance]:
        return self.instances.get(f"{workspace_id}:{instance_id}")

    def list_pending_instances(self, workspace_id: WorkspaceId) -> List[ReminderInstance]:
        return [inst for k, inst in self.instances.items() if k.startswith(f"{workspace_id}:")]

# --------------------------------------------------------------------------
# Test Cases
# --------------------------------------------------------------------------

class TestApplicationLayer(unittest.TestCase):
    def setUp(self):
        self.ws_id = generate_uuidv7()
        self.uow = InMemoryUnitOfWork()
        self.event_pub = InMemoryEventPublisher()
        self.item_repo = InMemoryItemRepository()
        self.debt_repo = InMemoryDebtRepository()
        self.reminder_repo = InMemoryReminderRepository()

        self.task_handler = TaskCommandHandler(self.item_repo, self.uow, self.event_pub)
        self.debt_handler = DebtCommandHandler(self.debt_repo, self.uow, self.event_pub)
        self.reminder_handler = ReminderCommandHandler(self.reminder_repo, self.uow, self.event_pub)

    # 1. Single Mutation Path: Create Task Command -> Domain -> Repo -> UoW -> Events
    def test_create_and_complete_task_command_flow(self):
        cmd_create = CreateTaskCommand(
            workspace_id=self.ws_id,
            title="إنهاء توثيق المعمارية",
            priority="high"
        )
        task_id = self.task_handler.handle_create(cmd_create)
        self.assertTrue(self.uow.committed)
        self.assertEqual(len(self.event_pub.published_events), 1)

        # Verify saved in repository
        item = self.item_repo.get_by_id(WorkspaceId(self.ws_id), EntityId(task_id))
        self.assertIsNotNone(item)
        self.assertEqual(item.title, "إنهاء توثيق المعمارية")

        # Complete task via command
        cmd_complete = CompleteTaskCommand(workspace_id=self.ws_id, item_id=task_id)
        self.task_handler.handle_complete(cmd_complete)
        self.assertEqual(item.task_detail.status.value, "completed")
        self.assertEqual(len(self.event_pub.published_events), 2)

    # 2. Workspace Scoping & Isolation
    def test_workspace_isolation_enforcement(self):
        other_ws = generate_uuidv7()
        cmd_create = CreateTaskCommand(
            workspace_id=self.ws_id,
            title="مهمة خاصة بـ A"
        )
        task_id = self.task_handler.handle_create(cmd_create)

        # Other workspace tries to complete item belonging to ws_id
        cmd_wrong = CompleteTaskCommand(workspace_id=other_ws, item_id=task_id)
        with self.assertRaises(NotFoundError):
            self.task_handler.handle_complete(cmd_wrong)

    # 3. Debt Command Flow
    def test_debt_command_orchestration(self):
        person_id = generate_uuidv7()
        cmd_create = CreateDebtCommand(
            workspace_id=self.ws_id,
            person_id=person_id,
            debt_type="payable",
            total_amount="10000.00",
            currency="YER"
        )
        debt_id = self.debt_handler.handle_create(cmd_create)
        self.assertTrue(self.uow.committed)

        # Record payment of 4000
        cmd_pay = RecordDebtPaymentCommand(
            workspace_id=self.ws_id,
            debt_id=debt_id,
            amount="4000.00",
            currency="YER"
        )
        tx_id = self.debt_handler.handle_record_payment(cmd_pay)
        
        debt = self.debt_repo.get_by_id(WorkspaceId(self.ws_id), EntityId(debt_id))
        self.assertEqual(debt.calculate_remaining_amount().amount, Decimal("6000.00"))

        # Reverse payment
        cmd_rev = ReverseDebtTransactionCommand(
            workspace_id=self.ws_id,
            debt_id=debt_id,
            target_tx_id=tx_id
        )
        self.debt_handler.handle_reverse(cmd_rev)
        self.assertEqual(debt.calculate_remaining_amount().amount, Decimal("10000.00"))

if __name__ == '__main__':
    unittest.main()
