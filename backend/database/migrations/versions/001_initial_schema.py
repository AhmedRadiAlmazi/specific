"""Initial schema migration

Revision ID: 001_initial_schema
Revises: 
Create Date: 2026-08-29 18:30:00.000000

"""
from typing import Sequence, Union
import os

# revision identifiers, used by Alembic.
revision: str = '001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    schema_path = os.path.join(os.path.dirname(__file__), '..', '..', 'postgres_schema.sql')
    with open(schema_path, 'r', encoding='utf-8') as f:
        sql = f.read()
    # In alembic execution: op.execute(sql)

def downgrade() -> None:
    pass
