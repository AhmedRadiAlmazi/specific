# PHASE 7 — FULL SYSTEM BASELINE & INVENTORY v1.0
## مشروع «مُعين» (Mouin) — Baseline Architecture & Asset Registry

### 1. Executive Baseline Overview
* **System**: Mouin (مُعين) — Offline-First Productivity & Financial Management System
* **Architecture**: Clean Architecture + Domain-Driven Design (DDD) + CQRS
* **Synchronization Model**: Bidirectional Asynchronous Replication with Client UUIDv7, Transactional Outbox, Monotonic Server Sequence, and Deterministic Deduplication.
* **Audit Baseline Date**: 2026-08-29

---

### 2. Backend Layer Inventory (ackend/app/)

#### A. Domain Layer (ackend/app/domain/)
* **Aggregates & Entities**:
  - Item (entities/item.py): Root entity with subtypes: Task, Appointment, Note, Document, ShoppingList. Subtype 
eminder is strictly rejected.
  - Debt & DebtTransaction (entities/debt.py): Append-only financial ledger with calculate remaining amount logic.
  - ReminderRule & ReminderInstance (entities/reminder.py): Deterministic trigger and occurrence scheduling.
  - InboxItem (entities/inbox.py), Attachment (entities/attachment.py), MasterTag (entities/master.py).
* **Value Objects**:
  - EntityId (alue_objects/identity.py): RFC 9562 UUIDv7 with time-ordered monotonic validation.
  - Money (alue_objects/money.py): Minor-units exact decimal representation using Decimal (zero floating-point).
  - Enums (alue_objects/types.py): ItemType, PrivacyClassification, Priority, TaskStatus, DebtType, DebtStatus, DebtTransactionType, ReminderTriggerType, ReminderStatus, SyncStatus.
* **Domain Services**:
  - DebtCalculatorService (services/debt_calculator.py)
  - ReminderOccurrenceService (services/reminder_service.py)
* **Domain Events & Exceptions**:
  - DomainEvent, ItemCreatedEvent, DebtCreatedEvent, DebtPaymentRecordedEvent (events/domain_events.py).
  - DomainException, InvariantViolationException, EntityNotFoundException (domain/exceptions.py).

#### B. Application Layer (ackend/app/application/)
* **Commands**:
  - CreateItemCommand, UpdateItemCommand, CompleteTaskCommand, SoftDeleteItemCommand (commands/item_commands.py).
  - CreateDebtCommand, RecordDebtTransactionCommand (commands/debt_commands.py).
  - CreateReminderRuleCommand, TriggerReminderCommand (commands/reminder_commands.py).
* **Handlers**:
  - ItemCommandHandler (handlers/item_handlers.py)
  - DebtCommandHandler (handlers/debt_handlers.py)
  - ReminderCommandHandler (handlers/reminder_handlers.py)
* **Ports (Interfaces)**:
  - IItemRepository, IDebtRepository, IReminderRepository, IOutboxRepository, ISyncRepository (ports/repositories.py).
  - IUnitOfWork (ports/unit_of_work.py).
  - IEventPublisher (ports/event_publisher.py).

#### C. Infrastructure Layer (ackend/app/infrastructure/)
* **PostgreSQL Persistence Adapters**:
  - PostgresItemRepository, PostgresDebtRepository, PostgresReminderRepository, PostgresUnitOfWork, PostgresConnection (infrastructure/persistence/postgres/).
  - Mappers: PostgresItemMapper, PostgresDebtMapper.
* **SQLite Persistence Adapters**:
  - SqliteItemRepository, SqliteDebtRepository, SqliteReminderRepository, SqliteOutboxRepository, SqliteUnitOfWork, SqliteConnection (infrastructure/persistence/sqlite/).
  - Mappers: LocalItemMapper.

#### D. Delivery / REST API Layer (ackend/app/presentation/api/)
* **FastAPI Application**: pp.py, config.py.
* **Routers**:
  - health_router (
outers/health.py): /health/live, /health/ready
  - items_router (
outers/items.py): POST /items/tasks, GET /items/tasks, PATCH /items/tasks/{id}/complete, DELETE /items/{id}
  - debts_router (
outers/debts.py): POST /debts, GET /debts, POST /debts/{id}/transactions
  - 
eminders_router (
outers/reminders.py): POST /reminders/rules, GET /reminders/rules
  - sync_router (
outers/sync.py): POST /sync/push, GET /sync/pull, GET /sync/bootstrap
* **Dependencies & Boundaries**:
  - get_current_user (dependencies/auth.py)
  - get_current_workspace (dependencies/workspace.py)
  - get_container (dependencies/container.py)
  - get_sync_service (dependencies/sync_service.py)
* **Unified Error Handling**:
  - setup_exception_handlers (errors/handlers.py)

---

### 3. Mobile Client Layer Inventory (mobile/lib/)

#### A. Core Layer (mobile/lib/core/)
* UuidV7: RFC 9562 time-ordered UUIDv7 generator.
* ArabicNormalizer: Tashkeel removal + Alef / Teh Marbuta / Yeh normalization for FTS5.
* Result<T, Failure> & Failure taxonomy.
* AppConfig: Endpoint URLs, timeouts, sync batch configurations.

#### B. Domain Layer (mobile/lib/domain/)
* Entities: Item (with subtype details), Debt, DebtTransaction, ReminderRule, ReminderInstance.
* Value Objects: Money (exact minor units decimal), Types (enums).
* Ports: IItemRepository, IDebtRepository, IReminderRepository, IOutboxRepository.

#### C. Application Layer (mobile/lib/application/)
* TaskUseCases, DebtUseCases, ReminderUseCases.
* Outbox Atomicity: Guarantees single-transaction mutation + outbox record enqueue.

#### D. Infrastructure Layer (mobile/lib/infrastructure/)
* Local Store: LocalSqliteDb replicating 26 SQLite tables.
* Repositories: LocalItemRepository, LocalDebtRepository, LocalReminderRepository, LocalOutboxRepository.
* Network: RemoteSyncApi interfacing with /api/v1/sync/push, /pull, /bootstrap.
* Sync: SyncEngine with push batching, pull cursor advancement, and bootstrap snapshotting.

#### E. Presentation Layer (mobile/lib/presentation/)
* BLoCs: TaskBloc, DebtBloc, ReminderBloc, SyncBloc.
* UI: HomePage, MouinApp supporting RTL Arabic localization and Material 3 design.

---

### 4. Database & Migrations Inventory
* **PostgreSQL Schema**: ackend/database/postgres_schema.sql (30 tables).
* **SQLite Schema**: mobile/database/sqlite_schema.sql (26 tables with FTS5 virtual tables and sync triggers).
* **Alembic Migrations**: ackend/database/migrations/.

---

### 5. Verification & Testing Inventory

#### A. Backend Test Suite (55 Tests)
* 	est_acceptance_a_to_j.py (10 tests)
* 	est_application_layer.py (3 tests)
* 	est_architecture_guard.py (3 tests)
* 	est_delivery_api.py (14 tests)
* 	est_domain_layer.py (5 tests)
* 	est_infrastructure_postgres_adapters.py (3 tests)
* 	est_infrastructure_sqlite.py (5 tests)
* 	est_postgres_schema.py (9 tests)
* 	est_sqlite_schema.py (3 tests)

#### B. Mobile Test Suite (24 Tests)
* 	est/core/uuidv7_test.dart (2 tests)
* 	est/core/arabic_normalizer_test.dart (3 tests)
* 	est/domain/money_test.dart (3 tests)
* 	est/domain/entity_test.dart (2 tests)
* 	est/application/task_use_cases_test.dart (3 tests)
* 	est/infrastructure/local_repositories_test.dart (3 tests)
* 	est/presentation/task_bloc_test.dart (3 tests)
* 	est/presentation/debt_reminder_bloc_test.dart (3 tests)
* 	est/architecture/clean_architecture_guard_test.dart (2 tests)

---
**Baseline Verdict**: System Inventory Complete, All 79 Components Active and Cataloged.
