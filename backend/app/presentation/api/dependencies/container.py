"""
Dependency Injection Composition Root — مشروع «مُعين» (Mouin)
Wires PostgreSQL Repositories, Unit of Work, and CQRS Handlers.
Completely decoupled from client-side mobile dependencies.
"""

from fastapi import Depends
import os
from typing import Generator, Optional
from backend.app.infrastructure.persistence.postgres.connection import PostgresConnectionManager
from backend.app.infrastructure.persistence.postgres.unit_of_work import PostgresUnitOfWork
from backend.app.infrastructure.persistence.postgres.repositories.item_repository import PostgresItemRepository
from backend.app.infrastructure.persistence.postgres.repositories.debt_repository import PostgresDebtRepository
from backend.app.infrastructure.persistence.postgres.repositories.reminder_repository import PostgresReminderRepository
from backend.app.infrastructure.persistence.postgres.repositories.sync_repository import PostgresSyncRepository
from backend.app.infrastructure.persistence.postgres.repositories.user_repository import PostgresUserRepository
from backend.app.infrastructure.persistence.postgres.repositories.inbox_repository import PostgresInboxRepository
from backend.app.infrastructure.persistence.postgres.repositories.attachment_repository import PostgresAttachmentRepository
from backend.app.infrastructure.persistence.postgres.repositories.shopping_repository import PostgresShoppingRepository
from backend.app.infrastructure.persistence.sqlite.connection import SqliteConnectionManager
from backend.app.infrastructure.persistence.sqlite.unit_of_work import SqliteUnitOfWork
from backend.app.infrastructure.persistence.sqlite.repositories.local_item_repository import SqliteItemRepository
from backend.app.infrastructure.persistence.sqlite.repositories.local_debt_repository import SqliteDebtRepository
from backend.app.infrastructure.persistence.sqlite.repositories.local_reminder_repository import SqliteReminderRepository
from backend.app.application.handlers.item_handlers import TaskCommandHandler
from backend.app.application.handlers.debt_handlers import DebtCommandHandler
from backend.app.application.handlers.reminder_handlers import ReminderCommandHandler
from backend.app.application.handlers.inbox_handlers import InboxCommandHandler
from backend.app.application.handlers.shopping_handlers import ShoppingCommandHandler
from backend.app.presentation.api.dependencies.sync_service import SyncApplicationService

# Global Singleton Managers
_postgres_manager: PostgresConnectionManager = None
_sqlite_manager: SqliteConnectionManager = None
_global_sync_service: SyncApplicationService = None

def get_postgres_manager() -> PostgresConnectionManager:
    """Returns the singleton PostgreSQL Connection Manager."""
    global _postgres_manager
    if _postgres_manager is None:
        _postgres_manager = PostgresConnectionManager()
        _postgres_manager.initialize_pool()
    return _postgres_manager

def get_sqlite_manager() -> SqliteConnectionManager:
    """Returns the backend SQLite Connection Manager for test/local mode."""
    global _sqlite_manager
    if _sqlite_manager is None:
        _sqlite_manager = SqliteConnectionManager(":memory:")
    return _sqlite_manager

class _DbHelperWrapper:
    """Provides a compatible wrapper for tests expecting db_helper interface."""
    def __init__(self, conn):
        self.conn = conn
    def initialize_schema(self):
        pass

def get_db_helper():
    """Compatibility helper for test suites accessing connection."""
    mgr = get_sqlite_manager()
    return _DbHelperWrapper(mgr.get_connection())

def _use_postgres() -> bool:
    """Determines whether to use PostgreSQL or SQLite fallback."""
    return os.getenv("USE_POSTGRES", "false").lower() in ("true", "1", "yes")

def get_uow(
    pg_mgr: PostgresConnectionManager = Depends(get_postgres_manager),
    sqlite_mgr: SqliteConnectionManager = Depends(get_sqlite_manager)
):
    """Provides the active Unit of Work."""
    if _use_postgres():
        conn = pg_mgr.get_connection()
        return PostgresUnitOfWork(conn)
    return SqliteUnitOfWork(sqlite_mgr.get_connection())

def get_item_repo(
    pg_mgr: PostgresConnectionManager = Depends(get_postgres_manager),
    sqlite_mgr: SqliteConnectionManager = Depends(get_sqlite_manager)
):
    """Provides Item repository matching active persistence engine."""
    if _use_postgres():
        return PostgresItemRepository(pg_mgr.get_connection())
    return SqliteItemRepository(sqlite_mgr.get_connection())

def get_debt_repo(
    pg_mgr: PostgresConnectionManager = Depends(get_postgres_manager),
    sqlite_mgr: SqliteConnectionManager = Depends(get_sqlite_manager)
):
    """Provides Debt repository matching active persistence engine."""
    if _use_postgres():
        return PostgresDebtRepository(pg_mgr.get_connection())
    return SqliteDebtRepository(sqlite_mgr.get_connection())

def get_reminder_repo(
    pg_mgr: PostgresConnectionManager = Depends(get_postgres_manager),
    sqlite_mgr: SqliteConnectionManager = Depends(get_sqlite_manager)
):
    """Provides Reminder repository matching active persistence engine."""
    if _use_postgres():
        return PostgresReminderRepository(pg_mgr.get_connection())
    return SqliteReminderRepository(sqlite_mgr.get_connection())

def get_sync_repo(
    pg_mgr: PostgresConnectionManager = Depends(get_postgres_manager)
):
    """Provides PostgresSyncRepository when running against PostgreSQL."""
    if _use_postgres():
        return PostgresSyncRepository(pg_mgr.get_connection())
    return None

def get_user_repo(
    pg_mgr: PostgresConnectionManager = Depends(get_postgres_manager)
):
    """Provides PostgresUserRepository."""
    if _use_postgres():
        return PostgresUserRepository(pg_mgr.get_connection())
    return None

def get_inbox_repo(
    pg_mgr: PostgresConnectionManager = Depends(get_postgres_manager)
):
    """Provides PostgresInboxRepository."""
    if _use_postgres():
        return PostgresInboxRepository(pg_mgr.get_connection())
    return None

def get_attachment_repo(
    pg_mgr: PostgresConnectionManager = Depends(get_postgres_manager)
):
    """Provides PostgresAttachmentRepository."""
    if _use_postgres():
        return PostgresAttachmentRepository(pg_mgr.get_connection())
    return None

def get_shopping_repo(
    pg_mgr: PostgresConnectionManager = Depends(get_postgres_manager)
):
    """Provides PostgresShoppingRepository."""
    if _use_postgres():
        return PostgresShoppingRepository(pg_mgr.get_connection())
    return None

def get_task_handler(
    repo = Depends(get_item_repo),
    uow = Depends(get_uow)
) -> TaskCommandHandler:
    return TaskCommandHandler(repo, uow)

def get_debt_handler(
    repo = Depends(get_debt_repo),
    uow = Depends(get_uow)
) -> DebtCommandHandler:
    return DebtCommandHandler(repo, uow)

def get_reminder_handler(
    repo = Depends(get_reminder_repo),
    uow = Depends(get_uow)
) -> ReminderCommandHandler:
    return ReminderCommandHandler(repo, uow)

def get_inbox_handler(
    repo = Depends(get_inbox_repo),
    uow = Depends(get_uow),
    task_handler = Depends(get_task_handler)
) -> InboxCommandHandler:
    return InboxCommandHandler(repo, uow, task_handler)

def get_shopping_handler(
    repo = Depends(get_shopping_repo),
    uow = Depends(get_uow)
) -> ShoppingCommandHandler:
    return ShoppingCommandHandler(repo, uow)

def get_sync_service(
    item_repo = Depends(get_item_repo),
    debt_repo = Depends(get_debt_repo),
    uow = Depends(get_uow),
    sync_repo = Depends(get_sync_repo)
) -> SyncApplicationService:
    global _global_sync_service
    if _global_sync_service is None:
        _global_sync_service = SyncApplicationService(item_repo, debt_repo, uow, sync_repo)
    return _global_sync_service
