"""
SQLite Local Database Helper v1.0 — مشروع «مُعين» (Mouin)
Provides SQLite database connection, migration execution, and transactional helpers.
"""

import sqlite3
import os
import re
import unicodedata
from typing import Optional, List, Tuple, Any

def normalize_arabic(text: str) -> str:
    """Normalize Arabic text for full text search (FTS5)."""
    if not text:
        return ""
    # Normalize unicode
    text = unicodedata.normalize('NFKD', text)
    # Remove tashkeel / diacritics
    text = re.sub(r'[ً-ْٰـ]', '', text)
    # Normalize Alef variations (أ, إ, آ -> ا)
    text = re.sub(r'[إأآا]', 'ا', text)
    # Normalize Teh Marbuta (ة -> ه)
    text = re.sub(r'ة', 'ه', text)
    # Normalize Yeh variations (ى -> ي)
    text = re.sub(r'ى', 'ي', text)
    return text.strip().lower()

class LocalDatabase:
    def __init__(self, db_path: str = ":memory:"):
        self.db_path = db_path
        self.conn = sqlite3.connect(self.db_path)
        self.conn.execute("PRAGMA foreign_keys = ON;")
        self.conn.row_factory = sqlite3.Row

    def initialize_schema(self, schema_sql: Optional[str] = None):
        """Execute SQLite DDL migration."""
        if schema_sql is None:
            schema_file = os.path.join(os.path.dirname(__file__), "sqlite_schema.sql")
            with open(schema_file, "r", encoding="utf-8") as f:
                schema_sql = f.read()
        self.conn.executescript(schema_sql)
        self.conn.commit()

    def execute(self, sql: str, params: Tuple[Any, ...] = ()):
        return self.conn.execute(sql, params)

    def executemany(self, sql: str, params_list: List[Tuple[Any, ...]]):
        return self.conn.executemany(sql, params_list)

    def fetchone(self, sql: str, params: Tuple[Any, ...] = ()):
        cursor = self.conn.execute(sql, params)
        return cursor.fetchone()

    def fetchall(self, sql: str, params: Tuple[Any, ...] = ()):
        cursor = self.conn.execute(sql, params)
        return cursor.fetchall()

    def commit(self):
        self.conn.commit()

    def rollback(self):
        self.conn.rollback()

    def close(self):
        self.conn.close()
