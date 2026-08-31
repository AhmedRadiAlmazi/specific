"""Initial schema migration — 30 PostgreSQL Tables DDL

Revision ID: 001_initial_schema
Revises: 
Create Date: 2026-08-29 18:30:00.000000

"""
from typing import Sequence, Union
import os
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    """Executes the complete 30-table production schema DDL."""
    schema_path = os.path.join(os.path.dirname(__file__), '..', '..', 'postgres_schema.sql')
    if os.path.exists(schema_path):
        with open(schema_path, 'r', encoding='utf-8') as f:
            sql = f.read()
        op.execute(sql)

def downgrade() -> None:
    """Drops all created tables in reverse dependency order."""
    tables = [
        "sync_conflicts", "sync_idempotency", "sync_changes", "events",
        "ai_suggestions", "inbox_attachments", "inbox_items",
        "debt_transaction_attachments", "item_attachments", "attachments",
        "notification_actions", "notifications", "reminder_instances", "reminder_rules",
        "shopping_entries", "shopping_lists", "debt_transactions", "debts",
        "documents", "notes", "appointments", "tasks", "items",
        "people", "categories", "workspace_members", "workspaces",
        "installations", "devices", "users"
    ]
    for table in tables:
        op.execute(f"DROP TABLE IF EXISTS {table} CASCADE;")
