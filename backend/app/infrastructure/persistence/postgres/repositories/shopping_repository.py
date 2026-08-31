"""
PostgreSQL Shopping Repository Implementation — مشروع «مُعين» (Mouin)
Implements IShoppingRepository for managing Shopping Lists and Shopping Entries.
"""

from typing import Optional, List, Any
from decimal import Decimal
import psycopg2

from backend.app.application.ports.repositories import IShoppingRepository
from backend.app.domain.entities.shopping import ShoppingList, ShoppingEntry
from backend.app.domain.value_objects.identity import WorkspaceId, EntityId

class PostgresShoppingRepository(IShoppingRepository):
    def __init__(self, connection: Any):
        self.connection = connection

    def save(self, shopping_list: ShoppingList) -> None:
        """Upserts ShoppingList and its associated ShoppingEntries."""
        cursor = self.connection.cursor()
        
        # 1. Upsert Shopping List
        sql_list = """
            INSERT INTO shopping_lists (id, workspace_id, is_archived, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                is_archived = EXCLUDED.is_archived,
                updated_at = EXCLUDED.updated_at;
        """
        cursor.execute(sql_list, (
            str(shopping_list.id),
            str(shopping_list.workspace_id),
            shopping_list.is_archived,
            shopping_list.created_at,
            shopping_list.updated_at
        ))

        # 2. Upsert Shopping Entries
        sql_entry = """
            INSERT INTO shopping_entries (id, workspace_id, shopping_list_id, item_name, quantity, unit, is_checked, checked_at, sort_order, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                item_name = EXCLUDED.item_name,
                quantity = EXCLUDED.quantity,
                unit = EXCLUDED.unit,
                is_checked = EXCLUDED.is_checked,
                checked_at = EXCLUDED.checked_at,
                sort_order = EXCLUDED.sort_order,
                updated_at = EXCLUDED.updated_at;
        """
        for entry in shopping_list.entries:
            cursor.execute(sql_entry, (
                str(entry.id),
                str(entry.workspace_id),
                str(entry.shopping_list_id),
                entry.item_name,
                entry.quantity,
                entry.unit,
                entry.is_checked,
                entry.checked_at,
                entry.sort_order,
                entry.created_at,
                entry.updated_at
            ))

    def get_by_id(self, workspace_id: WorkspaceId, list_id: EntityId) -> Optional[ShoppingList]:
        """Retrieves ShoppingList with all its entries within workspace boundary."""
        cursor = self.connection.cursor()
        sql_list = """
            SELECT id, workspace_id, is_archived, created_at, updated_at
            FROM shopping_lists
            WHERE workspace_id = %s AND id = %s;
        """
        cursor.execute(sql_list, (str(workspace_id), str(list_id)))
        row = cursor.fetchone()
        if not row:
            return None

        # Fetch entries
        sql_entries = """
            SELECT id, workspace_id, shopping_list_id, item_name, quantity, unit, is_checked, checked_at, sort_order, created_at, updated_at
            FROM shopping_entries
            WHERE workspace_id = %s AND shopping_list_id = %s
            ORDER BY sort_order ASC;
        """
        cursor.execute(sql_entries, (str(workspace_id), str(list_id)))
        entry_rows = cursor.fetchall()
        entries = [
            ShoppingEntry(
                id=EntityId(e[0]),
                workspace_id=WorkspaceId(e[1]),
                shopping_list_id=EntityId(e[2]),
                item_name=e[3],
                quantity=Decimal(str(e[4])),
                unit=e[5],
                is_checked=e[6],
                checked_at=e[7],
                sort_order=e[8]
            )
            for e in entry_rows
        ]

        shopping_list = ShoppingList(
            id=EntityId(row[0]),
            workspace_id=WorkspaceId(row[1]),
            is_archived=row[2],
            created_at=row[3],
            updated_at=row[4],
            _entries=entries
        )
        return shopping_list
