"""
PostgreSQL User & Workspace Authorization Repository — مشروع «مُعين» (Mouin)
Enforces multi-tenant workspace scoping and member role verification against users and workspace_members tables.
"""

from typing import Optional, List, Dict, Any
import psycopg2

class PostgresUserRepository:
    def __init__(self, connection: Any):
        self.connection = connection

    def get_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Finds user record by lowercase email."""
        cursor = self.connection.cursor()
        sql = """
            SELECT id, email, password_hash, full_name, is_active, is_verified, created_at
            FROM users
            WHERE email = %s AND is_active = true;
        """
        cursor.execute(sql, (email.strip().lower(),))
        row = cursor.fetchone()
        if not row:
            return None
        cols = [desc[0] for desc in cursor.description]
        return dict(zip(cols, row))

    def get_user_by_id(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Finds user record by UUID id."""
        cursor = self.connection.cursor()
        sql = """
            SELECT id, email, password_hash, full_name, is_active, is_verified, created_at
            FROM users
            WHERE id = %s AND is_active = true;
        """
        cursor.execute(sql, (user_id,))
        row = cursor.fetchone()
        if not row:
            return None
        cols = [desc[0] for desc in cursor.description]
        return dict(zip(cols, row))

    def get_user_workspaces(self, user_id: str) -> List[Dict[str, Any]]:
        """Returns all workspaces a user is an active member of."""
        cursor = self.connection.cursor()
        sql = """
            SELECT w.id, w.name, w.type, wm.role
            FROM workspaces w
            INNER JOIN workspace_members wm ON w.id = wm.workspace_id
            WHERE wm.user_id = %s
            ORDER BY w.created_at ASC;
        """
        cursor.execute(sql, (user_id,))
        rows = cursor.fetchall()
        if not rows:
            return []
        cols = [desc[0] for desc in cursor.description]
        return [dict(zip(cols, r)) for r in rows]

    def is_member_of_workspace(self, user_id: str, workspace_id: str) -> bool:
        """Verifies whether the user is an active member of the specified workspace."""
        cursor = self.connection.cursor()
        sql = """
            SELECT 1 FROM workspace_members
            WHERE workspace_id = %s AND user_id = %s
            LIMIT 1;
        """
        cursor.execute(sql, (workspace_id, user_id))
        return cursor.fetchone() is not None

    def get_workspace_role(self, user_id: str, workspace_id: str) -> Optional[str]:
        """Returns the specific membership role (owner, admin, member, viewer)."""
        cursor = self.connection.cursor()
        sql = """
            SELECT role FROM workspace_members
            WHERE workspace_id = %s AND user_id = %s
            LIMIT 1;
        """
        cursor.execute(sql, (workspace_id, user_id))
        row = cursor.fetchone()
        return row[0] if row else None
