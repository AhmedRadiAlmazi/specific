"""
SQLite Local Debt Repository — مشروع «مُعين» (Mouin)
"""

import sqlite3
from datetime import datetime, date
from decimal import Decimal
from typing import List, Optional
from backend.app.application.ports.repositories import IDebtRepository
from backend.app.domain.entities.debt import Debt, DebtTransaction
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId
from backend.app.domain.value_objects.money import Money, Currency
from backend.app.domain.value_objects.types import DebtType, DebtStatus, DebtTransactionType

def iso(dt) -> Optional[str]:
    return dt.isoformat() if dt else None

class SqliteDebtRepository(IDebtRepository):
    def __init__(self, connection: sqlite3.Connection):
        self.connection = connection

    def save(self, debt: Debt) -> None:
        # 1. Root local_items
        sql_item = """
            INSERT INTO local_items (id, workspace_id, item_type, title, privacy_classification, created_at, updated_at, deleted_at, entity_version)
            VALUES (?, ?, 'debt', ?, 'sensitive', ?, ?, ?, ?)
            ON CONFLICT (id) DO UPDATE SET
                updated_at = excluded.updated_at,
                deleted_at = excluded.deleted_at,
                entity_version = excluded.entity_version;
        """
        self.connection.execute(sql_item, (
            str(debt.id), str(debt.workspace_id), f"دين {debt.person_id}",
            iso(debt.created_at), iso(debt.updated_at), iso(debt.deleted_at), debt.entity_version
        ))

        # 2. local_debts
        sql_debt = """
            INSERT INTO local_debts (item_id, debt_type, person_id, total_amount, currency, due_date, status)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT (item_id) DO UPDATE SET
                due_date = excluded.due_date,
                status = excluded.status;
        """
        self.connection.execute(sql_debt, (
            str(debt.id), debt.debt_type.value, str(debt.person_id),
            str(debt.total_amount.amount), str(debt.total_amount.currency),
            iso(debt.due_date), debt.status.value
        ))

        # 3. local_debt_transactions
        for tx in debt.transactions:
            sql_tx = """
                INSERT INTO local_debt_transactions (
                    id, debt_id, workspace_id, transaction_type, amount, transaction_date,
                    notes, reference_transaction_id, created_at, updated_at, deleted_at, entity_version
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT (id) DO UPDATE SET
                    deleted_at = excluded.deleted_at,
                    entity_version = excluded.entity_version;
            """
            self.connection.execute(sql_tx, (
                str(tx.id), str(debt.id), str(debt.workspace_id), tx.transaction_type.value,
                str(tx.amount.amount), iso(tx.transaction_date), tx.notes,
                str(tx.reference_transaction_id) if tx.reference_transaction_id else None,
                iso(tx.created_at), iso(tx.updated_at), iso(tx.deleted_at), tx.entity_version
            ))

    def get_by_id(self, workspace_id: WorkspaceId, debt_id: EntityId) -> Optional[Debt]:
        cursor = self.connection.cursor()
        sql = """
            SELECT i.id AS item_id, i.workspace_id, i.created_at, i.updated_at, i.deleted_at, i.entity_version,
                   d.debt_type, d.person_id, d.total_amount, d.currency, d.due_date, d.status
            FROM local_items i
            JOIN local_debts d ON i.id = d.item_id
            WHERE i.workspace_id = ? AND i.id = ?;
        """
        cursor.execute(sql, (str(workspace_id), str(debt_id)))
        row = cursor.fetchone()
        if not row:
            return None

        # Transactions
        cursor.execute("SELECT * FROM local_debt_transactions WHERE debt_id = ? ORDER BY created_at ASC;", (str(debt_id),))
        tx_rows = cursor.fetchall()

        transactions = []
        for tx in tx_rows:
            dtx = DebtTransaction(
                id=EntityId(str(tx['id'])),
                workspace_id=WorkspaceId(str(tx['workspace_id'])),
                debt_id=debt_id,
                transaction_type=DebtTransactionType(tx['transaction_type']),
                amount=Money(Decimal(str(tx['amount'])), Currency(row['currency'])),
                transaction_date=date.fromisoformat(tx['transaction_date']),
                notes=tx['notes'],
                reference_transaction_id=EntityId(str(tx['reference_transaction_id'])) if tx['reference_transaction_id'] else None,
                created_at=datetime.fromisoformat(tx['created_at'].replace("Z", "+00:00")),
                updated_at=datetime.fromisoformat(tx['updated_at'].replace("Z", "+00:00")),
                deleted_at=datetime.fromisoformat(tx['deleted_at'].replace("Z", "+00:00")) if tx['deleted_at'] else None,
                entity_version=tx['entity_version']
            )
            transactions.append(dtx)

        debt = Debt(
            id=debt_id,
            workspace_id=workspace_id,
            person_id=EntityId(str(row['person_id'])),
            debt_type=DebtType(row['debt_type']),
            total_amount=Money(Decimal(str(row['total_amount'])), Currency(row['currency'])),
            due_date=date.fromisoformat(row['due_date']) if row['due_date'] else None,
            status=DebtStatus(row['status']),
            _transactions=transactions,
            created_at=datetime.fromisoformat(row['created_at'].replace("Z", "+00:00")),
            updated_at=datetime.fromisoformat(row['updated_at'].replace("Z", "+00:00")),
            deleted_at=datetime.fromisoformat(row['deleted_at'].replace("Z", "+00:00")) if row['deleted_at'] else None,
            entity_version=row['entity_version']
        )
        return debt

    def list_by_workspace(self, workspace_id: WorkspaceId) -> List[Debt]:
        cursor = self.connection.cursor()
        cursor.execute(
            "SELECT id FROM local_items WHERE workspace_id = ? AND item_type = 'debt' AND deleted_at IS NULL;",
            (str(workspace_id),)
        )
        rows = cursor.fetchall()
        return [self.get_by_id(workspace_id, EntityId(str(r['id']))) for r in rows if r]
