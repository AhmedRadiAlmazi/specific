"""
PostgreSQL Debt Data Mapper — مشروع «مُعين» (Mouin)
"""

from typing import Dict, Any, List
from decimal import Decimal
from backend.app.domain.entities.debt import Debt, DebtTransaction
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId
from backend.app.domain.value_objects.money import Money, Currency
from backend.app.domain.value_objects.types import DebtType, DebtStatus, DebtTransactionType

class PostgresDebtMapper:
    @staticmethod
    def to_domain(debt_row: Dict[str, Any], tx_rows: List[Dict[str, Any]]) -> Debt:
        debt_id = EntityId(str(debt_row['item_id']))
        ws_id = WorkspaceId(str(debt_row['workspace_id']))
        person_id = EntityId(str(debt_row['person_id']))
        total_money = Money(Decimal(str(debt_row['total_amount'])), Currency(debt_row['currency']))
        debt_type = DebtType(debt_row['debt_type'])
        status = DebtStatus(debt_row['status'])

        transactions = []
        for tx in tx_rows:
            t_id = EntityId(str(tx['id']))
            t_ws = WorkspaceId(str(tx['workspace_id']))
            t_money = Money(Decimal(str(tx['amount'])), Currency(debt_row['currency']))
            t_type = DebtTransactionType(tx['transaction_type'])
            ref_id = EntityId(str(tx['reference_transaction_id'])) if tx.get('reference_transaction_id') else None

            dtx = DebtTransaction(
                id=t_id,
                workspace_id=t_ws,
                debt_id=debt_id,
                transaction_type=t_type,
                amount=t_money,
                transaction_date=tx['transaction_date'],
                notes=tx.get('notes'),
                reference_transaction_id=ref_id,
                created_at=tx['created_at'],
                updated_at=tx['updated_at'],
                deleted_at=tx.get('deleted_at'),
                entity_version=tx.get('entity_version', 1)
            )
            transactions.append(dtx)

        debt = Debt(
            id=debt_id,
            workspace_id=ws_id,
            person_id=person_id,
            debt_type=debt_type,
            total_amount=total_money,
            due_date=debt_row.get('due_date'),
            status=status,
            _transactions=transactions,
            created_at=debt_row['created_at'],
            updated_at=debt_row['updated_at'],
            deleted_at=debt_row.get('deleted_at'),
            entity_version=debt_row.get('entity_version', 1)
        )
        return debt
