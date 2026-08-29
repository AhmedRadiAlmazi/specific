"""
SQLite Local Connection Provider — مشروع «مُعين» (Mouin)
Enforces PRAGMA foreign_keys = ON and Row factory.
"""

import sqlite3
from typing import Optional

class SqliteConnectionManager:
    def __init__(self, db_path: str = ":memory:"):
        self.db_path = db_path
        self._conn = None

    def get_connection(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(self.db_path)
            self._conn.row_factory = sqlite3.Row
            self._conn.execute("PRAGMA foreign_keys = ON;")
        return self._conn

    def close(self):
        if self._conn is not None:
            self._conn.close()
            self._conn = None
