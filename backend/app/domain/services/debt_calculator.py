"""
Debt Calculation Domain Service — مشروع «مُعين» (Mouin)
Pure domain calculations for multi-currency summaries and settlement projections.
"""

from decimal import Decimal
from typing import List, Dict
from backend.app.domain.entities.debt import Debt
from backend.app.domain.value_objects.money import Money, Currency

class DebtCalculatorService:
    @staticmethod
    def calculate_total_outstanding_by_currency(debts: List[Debt]) -> Dict[str, Money]:
        """Calculates total remaining balances grouped by currency."""
        totals: Dict[str, Decimal] = {}
        for debt in debts:
            if debt.is_deleted() or debt.status.value == "cancelled":
                continue
            cur = str(debt.total_amount.currency)
            rem = debt.calculate_remaining_amount()
            totals[cur] = totals.get(cur, Decimal("0.00")) + rem.amount
        
        return {cur: Money(amount, Currency(cur)) for cur, amount in totals.items()}
