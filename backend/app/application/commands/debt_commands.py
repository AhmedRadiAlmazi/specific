"""
Debt Application Commands — مشروع «مُعين» (Mouin)
"""

from dataclasses import dataclass
from datetime import date
from typing import Optional

@dataclass(frozen=True)
class CreateDebtCommand:
    workspace_id: str
    person_id: str
    debt_type: str
    total_amount: str
    currency: str = "YER"
    debt_id: Optional[str] = None
    due_date: Optional[date] = None

@dataclass(frozen=True)
class RecordDebtPaymentCommand:
    workspace_id: str
    debt_id: str
    amount: str
    currency: str = "YER"
    transaction_date: Optional[date] = None
    notes: Optional[str] = None
    tx_id: Optional[str] = None

@dataclass(frozen=True)
class ReverseDebtTransactionCommand:
    workspace_id: str
    debt_id: str
    target_tx_id: str
    notes: Optional[str] = None
    reversal_id: Optional[str] = None
