"""
SQLite Local Connection Provider — مشروع «مُعين» (Mouin)
Enforces PRAGMA foreign_keys = ON, Row factory, and Schema initialization.
"""

import sqlite3
import os
from typing import Optional

class SqliteConnectionManager:
    def __init__(self, db_path: str = ":memory:"):
        self.db_path = db_path
        self._conn = None

    def initialize_schema(self, conn: sqlite3.Connection):
        """Initializes schema tables for test/local environment."""
        schema_file = os.path.join(
            os.path.dirname(__file__), "..", "..", "..", "..", "..", "mobile", "database", "sqlite_schema.sql"
        )
        if os.path.exists(schema_file):
            with open(schema_file, "r", encoding="utf-8") as f:
                schema_sql = f.read()
            conn.executescript(schema_sql)
            conn.commit()

    def get_connection(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(self.db_path, check_same_thread=False)
            self._conn.row_factory = sqlite3.Row
            self._conn.execute("PRAGMA foreign_keys = ON;")
            if self.db_path == ":memory:":
                self.initialize_schema(self._conn)
        return self._conn

    def close(self):
        if self._conn is not None:
            self._conn.close()
            self._conn = None
