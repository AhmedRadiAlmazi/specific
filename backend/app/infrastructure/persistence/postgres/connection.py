"""
PostgreSQL Connection Provider — مشروع «مُعين» (Mouin)
"""

import os
from typing import Optional, Any
import psycopg2
from psycopg2.extras import RealDictCursor

class PostgresConnectionManager:
    def __init__(self, dsn: Optional[str] = None):
        self.dsn = dsn or os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/mouin_db")
        self._conn = None

    def get_connection(self):
        if self._conn is None or self._conn.closed:
            self._conn = psycopg2.connect(self.dsn)
        return self._conn

    def close(self):
        if self._conn is not None and not self._conn.closed:
            self._conn.close()
            self._conn = None
