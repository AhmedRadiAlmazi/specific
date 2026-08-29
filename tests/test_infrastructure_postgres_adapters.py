"""
PostgreSQL Persistence Adapters & Mappers Tests — مشروع «مُعين» (Mouin)
Validates PostgreSQL repository query mappings, UoW, and mapper conversions.
"""

import unittest
from decimal import Decimal
from datetime import datetime, date, timezone
from unittest.mock import MagicMock

from backend.app.domain.entities.item import Item, TaskDetail
from backend.app.domain.entities.debt import Debt
from backend.app.domain.value_objects.identity import EntityId, WorkspaceId
from backend.app.domain.value_objects.money import Money, YER
from backend.app.domain.value_objects.types import Priority, DebtType, ItemType
from backend.app.infrastructure.persistence.postgres.unit_of_work import PostgresUnitOfWork
from backend.app.infrastructure.persistence.postgres.mappers.item_mapper import PostgresItemMapper
from backend.app.infrastructure.persistence.postgres.mappers.debt_mapper import PostgresDebtMapper
from backend.app.infrastructure.persistence.postgres.repositories.item_repository import PostgresItemRepository
from backend.app.infrastructure.persistence.postgres.repositories.debt_repository import PostgresDebtRepository

class TestInfrastructurePostgresAdapters(unittest.TestCase):
    def setUp(self):
        self.mock_conn = MagicMock()
        self.mock_cursor = MagicMock()
        self.mock_conn.cursor.return_value = self.mock_cursor
        self.uow = PostgresUnitOfWork(self.mock_conn)
        self.item_repo = PostgresItemRepository(self.mock_conn)
        self.debt_repo = PostgresDebtRepository(self.mock_conn)
        self.ws_id = WorkspaceId.new()

    def test_postgres_unit_of_work_commit_and_rollback(self):
        with self.uow:
            self.uow.commit()
        self.mock_conn.commit.assert_called_once()

        try:
            with self.uow:
                raise ValueError("Force rollback")
        except ValueError:
            pass
        self.mock_conn.rollback.assert_called_once()

    def test_postgres_item_mapper(self):
        now = datetime.now(timezone.utc)
        item_row = {
            'id': str(EntityId.new()),
            'workspace_id': str(self.ws_id),
            'item_type': 'task',
            'title': 'مهمة خرائط',
            'summary': 'وصف المهمة',
            'category_id': None,
            'privacy_classification': 'private',
            'temporal_original_expression': 'غداً ظهراً',
            'temporal_resolved_at': now,
            'temporal_timezone': 'Asia/Aden',
            'temporal_locale': 'ar',
            'temporal_calendar': 'gregorian',
            'created_by_installation_id': None,
            'created_at': now,
            'updated_at': now,
            'deleted_at': None,
            'entity_version': 1
        }
        subtype_row = {
            'due_date': now,
            'priority': 'high',
            'status': 'pending',
            'completed_at': None,
            'estimated_duration_minutes': 30
        }
        item = PostgresItemMapper.to_domain(item_row, subtype_row)
        self.assertEqual(item.title, 'مهمة خرائط')
        self.assertEqual(item.task_detail.priority, Priority.HIGH)
        self.assertEqual(item.task_detail.estimated_duration_minutes, 30)

    def test_postgres_item_repository_save_executes_parameterized_sql(self):
        task_item = Item.create_task(
            id=EntityId.new(),
            workspace_id=self.ws_id,
            title="مهمة حقيقية",
            priority=Priority.URGENT
        )
        self.item_repo.save(task_item)
        # Verify two SQL statements executed (items root + tasks subtype)
        self.assertEqual(self.mock_cursor.execute.call_count, 2)
        first_call_sql = self.mock_cursor.execute.call_args_list[0][0][0]
        self.assertIn("INSERT INTO items", first_call_sql)
        second_call_sql = self.mock_cursor.execute.call_args_list[1][0][0]
        self.assertIn("INSERT INTO tasks", second_call_sql)

if __name__ == '__main__':
    unittest.main()
