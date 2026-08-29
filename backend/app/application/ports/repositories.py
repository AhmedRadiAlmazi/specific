"""
Repository Ports (Interfaces) — مشروع «مُعين» (Mouin)
Pure abstract ports defined in Application layer. Domain/Application has zero DB engine dependencies.
"""

from abc import ABC, abstractmethod
from typing import List, Optional
from backend.app.domain.entities.item import Item
from backend.app.domain.entities.debt import Debt, DebtTransaction
from backend.app.domain.entities.shopping import ShoppingList, ShoppingEntry
from backend.app.domain.entities.reminder import ReminderRule, ReminderInstance
from backend.app.domain.entities.inbox import InboxItem, AISuggestion
from backend.app.domain.entities.master import Category, Person
from backend.app.domain.entities.attachment import Attachment
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId

class IItemRepository(ABC):
    @abstractmethod
    def save(self, item: Item) -> None:
        pass

    @abstractmethod
    def get_by_id(self, workspace_id: WorkspaceId, item_id: EntityId) -> Optional[Item]:
        pass

    @abstractmethod
    def list_by_workspace(self, workspace_id: WorkspaceId, limit: int = 50, offset: int = 0) -> List[Item]:
        pass

class IDebtRepository(ABC):
    @abstractmethod
    def save(self, debt: Debt) -> None:
        pass

    @abstractmethod
    def get_by_id(self, workspace_id: WorkspaceId, debt_id: EntityId) -> Optional[Debt]:
        pass

    @abstractmethod
    def list_by_workspace(self, workspace_id: WorkspaceId) -> List[Debt]:
        pass

class IReminderRepository(ABC):
    @abstractmethod
    def save_rule(self, rule: ReminderRule) -> None:
        pass

    @abstractmethod
    def get_rule_by_id(self, workspace_id: WorkspaceId, rule_id: EntityId) -> Optional[ReminderRule]:
        pass

    @abstractmethod
    def save_instance(self, instance: ReminderInstance) -> None:
        pass

    @abstractmethod
    def get_instance_by_id(self, workspace_id: WorkspaceId, instance_id: EntityId) -> Optional[ReminderInstance]:
        pass

    @abstractmethod
    def list_pending_instances(self, workspace_id: WorkspaceId) -> List[ReminderInstance]:
        pass

class IShoppingRepository(ABC):
    @abstractmethod
    def save(self, shopping_list: ShoppingList) -> None:
        pass

    @abstractmethod
    def get_by_id(self, workspace_id: WorkspaceId, list_id: EntityId) -> Optional[ShoppingList]:
        pass

class IInboxRepository(ABC):
    @abstractmethod
    def save_inbox_item(self, item: InboxItem) -> None:
        pass

    @abstractmethod
    def get_inbox_item_by_id(self, workspace_id: WorkspaceId, item_id: EntityId) -> Optional[InboxItem]:
        pass

    @abstractmethod
    def save_suggestion(self, suggestion: AISuggestion) -> None:
        pass

    @abstractmethod
    def get_suggestion_by_id(self, workspace_id: WorkspaceId, suggestion_id: EntityId) -> Optional[AISuggestion]:
        pass

class ICategoryRepository(ABC):
    @abstractmethod
    def save(self, category: Category) -> None:
        pass

    @abstractmethod
    def get_by_id(self, workspace_id: WorkspaceId, category_id: EntityId) -> Optional[Category]:
        pass

class IPersonRepository(ABC):
    @abstractmethod
    def save(self, person: Person) -> None:
        pass

    @abstractmethod
    def get_by_id(self, workspace_id: WorkspaceId, person_id: EntityId) -> Optional[Person]:
        pass

class IAttachmentRepository(ABC):
    @abstractmethod
    def save(self, attachment: Attachment) -> None:
        pass

    @abstractmethod
    def get_by_id(self, workspace_id: WorkspaceId, attachment_id: EntityId) -> Optional[Attachment]:
        pass
