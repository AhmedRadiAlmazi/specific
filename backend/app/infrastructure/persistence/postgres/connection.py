"""
PostgreSQL Connection Provider & Pool Management — مشروع «مُعين» (Mouin)
Provides high-performance ThreadedConnectionPool for PostgreSQL 16+.
"""

import os
from typing import Optional, Any
import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor

class PostgresConnectionManager:
    """Manages thread-safe PostgreSQL connection pooling and standalone lifecycle."""
    
    _pool: Optional[pool.ThreadedConnectionPool] = None

    def __init__(
        self,
        dsn: Optional[str] = None,
        min_conn: int = 2,
        max_conn: int = 20
    ):
        self.dsn = dsn or os.getenv(
            "DATABASE_URL",
            "postgresql://postgres:postgres@localhost:5432/mouin_db"
        )
        self.min_conn = int(os.getenv("DATABASE_POOL_MIN", str(min_conn)))
        self.max_conn = int(os.getenv("DATABASE_POOL_SIZE", str(max_conn)))
        self._conn = None

    def initialize_pool(self):
        """Initializes the global ThreadedConnectionPool if not already active."""
        if PostgresConnectionManager._pool is None:
            try:
                PostgresConnectionManager._pool = pool.ThreadedConnectionPool(
                    minconn=self.min_conn,
                    maxconn=self.max_conn,
                    dsn=self.dsn
                )
            except Exception:
                # Standalone fallback if pool fails in constrained/mock test environments
                PostgresConnectionManager._pool = None

    def get_connection(self):
        """Acquires a connection from the pool or creates a standalone connection."""
        if PostgresConnectionManager._pool is not None:
            try:
                return PostgresConnectionManager._pool.getconn()
            except Exception:
                pass
        
        if self._conn is None or self._conn.closed:
            self._conn = psycopg2.connect(self.dsn)
        return self._conn

    def release_connection(self, conn: Any):
        """Returns a connection back to the pool or closes it if standalone."""
        if conn is None:
            return
        if PostgresConnectionManager._pool is not None:
            try:
                PostgresConnectionManager._pool.putconn(conn)
                return
            except Exception:
                pass
        if not conn.closed:
            conn.close()

    def close(self):
        """Closes all connections and shuts down the connection pool."""
        if self._conn is not None and not self._conn.closed:
            self._conn.close()
            self._conn = None
        if PostgresConnectionManager._pool is not None:
            try:
                PostgresConnectionManager._pool.closeall()
            except Exception:
                pass
            PostgresConnectionManager._pool = None
