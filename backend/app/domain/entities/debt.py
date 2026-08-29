"""
Debt Aggregate & Append-Only Financial Ledger — مشروع «مُعين» (Mouin)
Strictly immutable approved payments. Reversals and Adjustments are appended.
"""

from dataclasses import dataclass, field
from datetime import datetime, date, timezone
from decimal import Decimal
from typing import List, Optional
from backend.app.domain.entities.base import AggregateRoot, BaseEntity
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId
from backend.app.domain.value_objects.money import Money
from backend.app.domain.value_objects.types import DebtType, DebtStatus, DebtTransactionType
from backend.app.domain.exceptions import InvariantViolationError, InvalidStateTransitionError, ImmutableTransactionError
from backend.app.domain.events.domain_events import (
    DebtCreatedEvent, DebtPaymentRecordedEvent, DebtTransactionReversedEvent
)

@dataclass
class DebtTransaction(BaseEntity):
    debt_id: EntityId = field(default_factory=EntityId.new)
    transaction_type: DebtTransactionType = DebtTransactionType.PAYMENT
    amount: Money = field(default_factory=lambda: Money(Decimal("0.00")))
    transaction_date: date = field(default_factory=lambda: datetime.now(timezone.utc).date())
    notes: Optional[str] = None
    reference_transaction_id: Optional[EntityId] = None

    def __post_init__(self):
        if not self.amount.is_positive():
            raise InvariantViolationError("Transaction amount must be strictly greater than 0.")
        if self.transaction_type == DebtTransactionType.REVERSAL and self.reference_transaction_id is None:
            raise InvariantViolationError("Reversal transaction must reference an existing transaction.")

    def mutate_attempt(self):
        raise ImmutableTransactionError("Approved financial transactions are strictly immutable and cannot be updated in-place. Use a Reversal or Adjustment instead.")

@dataclass
class Debt(AggregateRoot):
    debt_type: DebtType = DebtType.PAYABLE
    person_id: EntityId = field(default_factory=EntityId.new)
    total_amount: Money = field(default_factory=lambda: Money(Decimal("0.00")))
    due_date: Optional[date] = None
    status: DebtStatus = DebtStatus.ACTIVE
    _transactions: List[DebtTransaction] = field(default_factory=list)

    def __post_init__(self):
        if not self.total_amount.is_positive():
            raise InvariantViolationError("Debt total_amount must be strictly positive.")

    @classmethod
    def create(
        cls,
        id: EntityId,
        workspace_id: WorkspaceId,
        person_id: EntityId,
        debt_type: DebtType,
        total_amount: Money,
        due_date: Optional[date] = None
    ) -> "Debt":
        debt = cls(
            id=id,
            workspace_id=workspace_id,
            person_id=person_id,
            debt_type=debt_type,
            total_amount=total_amount,
            due_date=due_date,
            status=DebtStatus.ACTIVE
        )
        debt.record_event(DebtCreatedEvent(
            event_id=str(EntityId.new()),
            workspace_id=str(workspace_id),
            event_type="debt.created",
            aggregate_type="debt",
            aggregate_id=str(id),
            payload={
                "total_amount": str(total_amount.amount),
                "currency": str(total_amount.currency),
                "debt_type": debt_type.value
            }
        ))
        return debt

    @property
    def transactions(self) -> List[DebtTransaction]:
        return [tx for tx in self._transactions if not tx.is_deleted()]

    def record_payment(
        self,
        tx_id: EntityId,
        amount: Money,
        transaction_date: date,
        notes: Optional[str] = None
    ) -> DebtTransaction:
        if self.status in (DebtStatus.SETTLED, DebtStatus.CANCELLED):
            raise InvalidStateTransitionError(f"Cannot record payment on a {self.status.value} debt.")
        if amount.currency != self.total_amount.currency:
            raise InvariantViolationError(f"Payment currency {amount.currency} does not match debt currency {self.total_amount.currency}.")
        
        tx = DebtTransaction(
            id=tx_id,
            workspace_id=self.workspace_id,
            debt_id=self.id,
            transaction_type=DebtTransactionType.PAYMENT,
            amount=amount,
            transaction_date=transaction_date,
            notes=notes
        )
        self._transactions.append(tx)
        self.touch()
        self._recalculate_status()
        self.record_event(DebtPaymentRecordedEvent(
            event_id=str(EntityId.new()),
            workspace_id=str(self.workspace_id),
            event_type="debt.payment_recorded",
            aggregate_type="debt",
            aggregate_id=str(self.id),
            payload={"transaction_id": str(tx_id), "amount": str(amount.amount)}
        ))
        return tx

    def reverse_transaction(
        self,
        tx_id: EntityId,
        target_tx_id: EntityId,
        notes: Optional[str] = None
    ) -> DebtTransaction:
        target = next((t for t in self.transactions if t.id == target_tx_id), None)
        if not target:
            raise InvariantViolationError(f"Transaction {target_tx_id} not found on this debt.")
        if target.transaction_type == DebtTransactionType.REVERSAL:
            raise InvariantViolationError("Cannot reverse an already reversed transaction.")

        # Check if already reversed
        already_reversed = any(t.reference_transaction_id == target_tx_id for t in self.transactions)
        if already_reversed:
            raise InvariantViolationError(f"Transaction {target_tx_id} has already been reversed.")

        rev_tx = DebtTransaction(
            id=tx_id,
            workspace_id=self.workspace_id,
            debt_id=self.id,
            transaction_type=DebtTransactionType.REVERSAL,
            amount=target.amount,
            transaction_date=datetime.now(timezone.utc).date(),
            notes=notes or f"Reversal of transaction {target_tx_id}",
            reference_transaction_id=target_tx_id
        )
        self._transactions.append(rev_tx)
        self.touch()
        self._recalculate_status()
        self.record_event(DebtTransactionReversedEvent(
            event_id=str(EntityId.new()),
            workspace_id=str(self.workspace_id),
            event_type="debt.transaction_reversed",
            aggregate_type="debt",
            aggregate_id=str(self.id),
            payload={"reversal_id": str(tx_id), "target_id": str(target_tx_id)}
        ))
        return rev_tx

    def calculate_remaining_amount(self) -> Money:
        paid = Decimal("0.00")
        for tx in self.transactions:
            if tx.transaction_type == DebtTransactionType.PAYMENT:
                paid += tx.amount.amount
            elif tx.transaction_type == DebtTransactionType.REVERSAL:
                paid -= tx.amount.amount
            elif tx.transaction_type == DebtTransactionType.ADJUSTMENT:
                paid += tx.amount.amount
        remaining = self.total_amount.amount - paid
        return Money(remaining, self.total_amount.currency)

    def _recalculate_status(self):
        rem = self.calculate_remaining_amount()
        if rem.amount <= Decimal("0.00"):
            self.status = DebtStatus.SETTLED
        elif self.status == DebtStatus.SETTLED and rem.amount > Decimal("0.00"):
            self.status = DebtStatus.ACTIVE
