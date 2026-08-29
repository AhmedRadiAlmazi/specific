"""
Debt Command Handlers — مشروع «مُعين» (Mouin)
"""

from datetime import datetime, timezone
from typing import Optional
from backend.app.application.exceptions import NotFoundError
from backend.app.application.ports.unit_of_work import IUnitOfWork
from backend.app.application.ports.event_publisher import IDomainEventPublisher
from backend.app.application.ports.repositories import IDebtRepository
from backend.app.application.commands.debt_commands import (
    CreateDebtCommand, RecordDebtPaymentCommand, ReverseDebtTransactionCommand
)
from backend.app.domain.entities.debt import Debt
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId
from backend.app.domain.value_objects.money import Money
from backend.app.domain.value_objects.types import DebtType

class DebtCommandHandler:
    def __init__(self, debt_repo: IDebtRepository, uow: IUnitOfWork, event_publisher: Optional[IDomainEventPublisher] = None):
        self.debt_repo = debt_repo
        self.uow = uow
        self.event_publisher = event_publisher

    def handle_create(self, cmd: CreateDebtCommand) -> str:
        ws_id = WorkspaceId(cmd.workspace_id)
        debt_id = EntityId(cmd.debt_id) if cmd.debt_id else EntityId.new()
        person_id = EntityId(cmd.person_id)
        money = Money.from_str(cmd.total_amount, cmd.currency)
        debt_type = DebtType(cmd.debt_type)

        with self.uow:
            debt = Debt.create(
                id=debt_id,
                workspace_id=ws_id,
                person_id=person_id,
                debt_type=debt_type,
                total_amount=money,
                due_date=cmd.due_date
            )
            self.debt_repo.save(debt)
            if self.event_publisher:
                self.event_publisher.publish_all(debt.collect_events())
            self.uow.commit()

        return str(debt_id)

    def handle_record_payment(self, cmd: RecordDebtPaymentCommand) -> str:
        ws_id = WorkspaceId(cmd.workspace_id)
        debt_id = EntityId(cmd.debt_id)
        tx_id = EntityId(cmd.tx_id) if cmd.tx_id else EntityId.new()
        amount = Money.from_str(cmd.amount, cmd.currency)
        tx_date = cmd.transaction_date or datetime.now(timezone.utc).date()

        with self.uow:
            debt = self.debt_repo.get_by_id(ws_id, debt_id)
            if not debt or debt.is_deleted():
                raise NotFoundError(f"Debt {debt_id} not found in workspace {ws_id}")
            
            tx = debt.record_payment(
                tx_id=tx_id,
                amount=amount,
                transaction_date=tx_date,
                notes=cmd.notes
            )
            self.debt_repo.save(debt)
            if self.event_publisher:
                self.event_publisher.publish_all(debt.collect_events())
            self.uow.commit()

        return str(tx.id)

    def handle_reverse(self, cmd: ReverseDebtTransactionCommand) -> str:
        ws_id = WorkspaceId(cmd.workspace_id)
        debt_id = EntityId(cmd.debt_id)
        rev_id = EntityId(cmd.reversal_id) if cmd.reversal_id else EntityId.new()
        target_tx_id = EntityId(cmd.target_tx_id)

        with self.uow:
            debt = self.debt_repo.get_by_id(ws_id, debt_id)
            if not debt or debt.is_deleted():
                raise NotFoundError(f"Debt {debt_id} not found in workspace {ws_id}")
            
            rev_tx = debt.reverse_transaction(
                tx_id=rev_id,
                target_tx_id=target_tx_id,
                notes=cmd.notes
            )
            self.debt_repo.save(debt)
            if self.event_publisher:
                self.event_publisher.publish_all(debt.collect_events())
            self.uow.commit()

        return str(rev_tx.id)
