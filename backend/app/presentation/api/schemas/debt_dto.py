"""
Debt & Financial DTO Schemas — مشروع «مُعين» (Mouin)
Strict Decimal enforcement (No float/double allowed).
"""

from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import date, datetime
from decimal import Decimal
from backend.app.domain.value_objects.types import DebtType, DebtStatus, DebtTransactionType

class CreateDebtRequest(BaseModel):
    person_id: str = Field(..., description="معرف الشخص المدين/الدائن")
    debt_type: DebtType = DebtType.PAYABLE
    total_amount: Decimal = Field(..., gt=Decimal("0.00"), description="المبلغ الإجمالي بالدقة العشرية")
    currency: str = Field(default="YER", min_length=3, max_length=3)
    due_date: Optional[date] = None

class RecordPaymentRequest(BaseModel):
    amount: Decimal = Field(..., gt=Decimal("0.00"), description="مبلغ الدفعة")
    currency: str = Field(default="YER", min_length=3, max_length=3)
    transaction_date: Optional[date] = None
    notes: Optional[str] = None

class ReversePaymentRequest(BaseModel):
    target_tx_id: str = Field(..., description="معرف الحركة المراد عكسها")
    notes: Optional[str] = None

class DebtTransactionDTO(BaseModel):
    id: str
    transaction_type: str
    amount: Decimal
    currency: str
    transaction_date: date
    notes: Optional[str] = None
    reference_transaction_id: Optional[str] = None
    created_at: datetime

class DebtResponseDTO(BaseModel):
    id: str
    workspace_id: str
    debt_type: str
    person_id: str
    total_amount: Decimal
    currency: str
    remaining_amount: Decimal
    status: str
    due_date: Optional[date] = None
    transactions: List[DebtTransactionDTO] = Field(default_factory=list)
