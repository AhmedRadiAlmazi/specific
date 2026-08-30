"""
Dependency Injection Composition Root — مشروع «مُعين» (Mouin)
Constructs repositories, unit of work, and command handlers cleanly.
"""

from fastapi import Depends
import sqlite3
from typing import Generator
from backend.app.infrastructure.persistence.sqlite.connection import SqliteConnectionManager
from backend.app.infrastructure.persistence.sqlite.unit_of_work import SqliteUnitOfWork
from backend.app.infrastructure.persistence.sqlite.repositories.local_item_repository import SqliteItemRepository
from backend.app.infrastructure.persistence.sqlite.repositories.local_debt_repository import SqliteDebtRepository
from backend.app.infrastructure.persistence.sqlite.repositories.local_reminder_repository import SqliteReminderRepository
from backend.app.application.handlers.item_handlers import TaskCommandHandler
from backend.app.application.handlers.debt_handlers import DebtCommandHandler
from backend.app.application.handlers.reminder_handlers import ReminderCommandHandler
from backend.app.presentation.api.dependencies.sync_service import SyncApplicationService
from mobile.database.local_db_helper import LocalDatabase

# Shared singleton in-memory database helper for API runtime
_global_db_helper = None
_global_sync_service = None

def get_db_helper() -> LocalDatabase:
    global _global_db_helper
    if _global_db_helper is None:
        _global_db_helper = LocalDatabase(":memory:")
        _global_db_helper.initialize_schema()
    return _global_db_helper

def get_item_repo(db: LocalDatabase = Depends(get_db_helper)) -> SqliteItemRepository:
    return SqliteItemRepository(db.conn)

def get_debt_repo(db: LocalDatabase = Depends(get_db_helper)) -> SqliteDebtRepository:
    return SqliteDebtRepository(db.conn)

def get_reminder_repo(db: LocalDatabase = Depends(get_db_helper)) -> SqliteReminderRepository:
    return SqliteReminderRepository(db.conn)

def get_uow(db: LocalDatabase = Depends(get_db_helper)) -> SqliteUnitOfWork:
    return SqliteUnitOfWork(db.conn)

def get_task_handler(
    repo: SqliteItemRepository = Depends(get_item_repo),
    uow: SqliteUnitOfWork = Depends(get_uow)
) -> TaskCommandHandler:
    return TaskCommandHandler(repo, uow)

def get_debt_handler(
    repo: SqliteDebtRepository = Depends(get_debt_repo),
    uow: SqliteUnitOfWork = Depends(get_uow)
) -> DebtCommandHandler:
    return DebtCommandHandler(repo, uow)

def get_reminder_handler(
    repo: SqliteReminderRepository = Depends(get_reminder_repo),
    uow: SqliteUnitOfWork = Depends(get_uow)
) -> ReminderCommandHandler:
    return ReminderCommandHandler(repo, uow)

def get_sync_service(
    item_repo: SqliteItemRepository = Depends(get_item_repo),
    debt_repo: SqliteDebtRepository = Depends(get_debt_repo),
    uow: SqliteUnitOfWork = Depends(get_uow)
) -> SyncApplicationService:
    global _global_sync_service
    if _global_sync_service is None:
        _global_sync_service = SyncApplicationService(item_repo, debt_repo, uow)
    return _global_sync_service
