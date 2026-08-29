"""
SQLite Unit of Work — مشروع «مُعين» (Mouin)
Coordinates atomic local transactions (Domain Mutation + Outbox Mutation).
"""

import sqlite3
from typing import Any, Optional
from backend.app.application.ports.unit_of_work import IUnitOfWork

class SqliteUnitOfWork(IUnitOfWork):
    def __init__(self, connection: sqlite3.Connection):
        self.connection = connection
        self._in_transaction = False

    def __enter__(self) -> "SqliteUnitOfWork":
        self._in_transaction = True
        return self

    def __exit__(self, exc_type: Any, exc_val: Any, exc_tb: Any):
        if exc_type is not None:
            self.rollback()
        self._in_transaction = False

    def commit(self):
        if self.connection:
            self.connection.commit()

    def rollback(self):
        if self.connection:
            self.connection.rollback()
