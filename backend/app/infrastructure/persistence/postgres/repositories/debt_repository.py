"""
PostgreSQL Debt Repository Implementation — مشروع «مُعين» (Mouin)
Handles Debts & Append-Only Debt Transactions with Decimal Precision.
"""

from typing import List, Optional, Any
from backend.app.application.ports.repositories import IDebtRepository
from backend.app.domain.entities.debt import Debt, DebtTransaction
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId
from backend.app.infrastructure.persistence.postgres.mappers.debt_mapper import PostgresDebtMapper

class PostgresDebtRepository(IDebtRepository):
    def __init__(self, connection: Any):
        self.connection = connection

    def save(self, debt: Debt) -> None:
        cursor = self.connection.cursor()
        
        # 1. Ensure item root row exists for debt
        sql_item = """
            INSERT INTO items (id, workspace_id, item_type, title, privacy_classification, created_at, updated_at, deleted_at, entity_version)
            VALUES (%s, %s, 'debt', %s, 'sensitive', %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                updated_at = EXCLUDED.updated_at,
                deleted_at = EXCLUDED.deleted_at,
                entity_version = EXCLUDED.entity_version;
        """
        cursor.execute(sql_item, (
            str(debt.id), str(debt.workspace_id), f"دين {debt.person_id}",
            debt.created_at, debt.updated_at, debt.deleted_at, debt.entity_version
        ))

        # 2. Upsert debts row
        sql_debt = """
            INSERT INTO debts (item_id, debt_type, person_id, total_amount, currency, due_date, status)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (item_id) DO UPDATE SET
                due_date = EXCLUDED.due_date,
                status = EXCLUDED.status;
        """
        cursor.execute(sql_debt, (
            str(debt.id), debt.debt_type.value, str(debt.person_id),
            str(debt.total_amount.amount), str(debt.total_amount.currency),
            debt.due_date, debt.status.value
        ))

        # 3. Insert append-only transactions
        for tx in debt.transactions:
            sql_tx = """
                INSERT INTO debt_transactions (
                    id, debt_id, workspace_id, transaction_type, amount, transaction_date,
                    notes, reference_transaction_id, created_at, updated_at, deleted_at, entity_version
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO UPDATE SET
                    deleted_at = EXCLUDED.deleted_at,
                    entity_version = EXCLUDED.entity_version;
            """
            cursor.execute(sql_tx, (
                str(tx.id), str(debt.id), str(debt.workspace_id), tx.transaction_type.value,
                str(tx.amount.amount), tx.transaction_date, tx.notes,
                str(tx.reference_transaction_id) if tx.reference_transaction_id else None,
                tx.created_at, tx.updated_at, tx.deleted_at, tx.entity_version
            ))

    def get_by_id(self, workspace_id: WorkspaceId, debt_id: EntityId) -> Optional[Debt]:
        cursor = self.connection.cursor()
        sql = """
            SELECT i.id AS item_id, i.workspace_id, i.created_at, i.updated_at, i.deleted_at, i.entity_version,
                   d.debt_type, d.person_id, d.total_amount, d.currency, d.due_date, d.status
            FROM items i
            JOIN debts d ON i.id = d.item_id
            WHERE i.workspace_id = %s AND i.id = %s;
        """
        cursor.execute(sql, (str(workspace_id), str(debt_id)))
        row = cursor.fetchone()
        if not row:
            return None
        cols = [desc[0] for desc in cursor.description]
        debt_dict = dict(zip(cols, row))

        # Fetch transactions
        cursor.execute(
            "SELECT * FROM debt_transactions WHERE debt_id = %s ORDER BY created_at ASC;",
            (str(debt_id),)
        )
        tx_rows = cursor.fetchall()
        tx_cols = [desc[0] for desc in cursor.description]
        tx_dicts = [dict(zip(tx_cols, r)) for r in tx_rows]

        return PostgresDebtMapper.to_domain(debt_dict, tx_dicts)

    def list_by_workspace(self, workspace_id: WorkspaceId) -> List[Debt]:
        cursor = self.connection.cursor()
        cursor.execute(
            "SELECT id FROM items WHERE workspace_id = %s AND item_type = 'debt' AND deleted_at IS NULL;",
            (str(workspace_id),)
        )
        rows = cursor.fetchall()
        return [self.get_by_id(workspace_id, EntityId(str(r[0]))) for r in rows if r]
