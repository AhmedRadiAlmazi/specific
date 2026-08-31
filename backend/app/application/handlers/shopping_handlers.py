"""
Shopping Application Handlers — مشروع «مُعين» (Mouin)
Coordinates creation and updates of ShoppingLists and ShoppingEntries.
"""

from decimal import Decimal
from typing import Optional
from backend.app.application.ports.repositories import IShoppingRepository
from backend.app.application.ports.unit_of_work import IUnitOfWork
from backend.app.application.commands.shopping_commands import (
    CreateShoppingListCommand,
    AddShoppingEntryCommand,
    CheckShoppingEntryCommand
)
from backend.app.domain.entities.shopping import ShoppingList, ShoppingEntry
from backend.app.domain.value_objects.identity import WorkspaceId, EntityId

class ShoppingCommandHandler:
    def __init__(self, shopping_repo: IShoppingRepository, uow: IUnitOfWork):
        self.shopping_repo = shopping_repo
        self.uow = uow

    def handle_create_list(self, cmd: CreateShoppingListCommand) -> str:
        """Creates a new ShoppingList aggregate."""
        ws_id = WorkspaceId(cmd.workspace_id)
        list_id = EntityId(cmd.list_id) if cmd.list_id else EntityId.new()

        shopping_list = ShoppingList(
            id=list_id,
            workspace_id=ws_id,
            is_archived=False
        )

        with self.uow:
            self.shopping_repo.save(shopping_list)
            self.uow.commit()

        return str(list_id)

    def handle_add_entry(self, cmd: AddShoppingEntryCommand) -> str:
        """Adds a new item entry to an existing shopping list."""
        ws_id = WorkspaceId(cmd.workspace_id)
        list_id = EntityId(cmd.shopping_list_id)
        entry_id = EntityId(cmd.entry_id) if cmd.entry_id else EntityId.new()
        qty = Decimal(cmd.quantity) if cmd.quantity else Decimal("1.00")

        with self.uow:
            shopping_list = self.shopping_repo.get_by_id(ws_id, list_id)
            if not shopping_list:
                raise ValueError(f"Shopping list {cmd.shopping_list_id} not found in workspace {cmd.workspace_id}.")

            shopping_list.add_entry(
                entry_id=entry_id,
                item_name=cmd.item_name,
                quantity=qty,
                unit=cmd.unit
            )

            self.shopping_repo.save(shopping_list)
            self.uow.commit()

        return str(entry_id)
