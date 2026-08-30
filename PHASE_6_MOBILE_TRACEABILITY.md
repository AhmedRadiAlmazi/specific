# PHASE 6 — MOBILE CLIENT TRACEABILITY MATRIX v1.0
## مشروع «مُعين» (Mouin) — Flutter Offline-First Client Traceability

| Contract / Architectural Requirement | Implementation File | Verification Test | Status |
| :--- | :--- | :--- | :--- |
| **Offline-First by Default** | mobile/lib/presentation/pages/home_page.dart<br>mobile/lib/infrastructure/repositories/local_item_repository.dart | mobile/test/presentation/task_bloc_test.dart | ✅ COMPLIANT |
| **UUIDv7 Client Generation** | mobile/lib/core/utils/uuidv7.dart | mobile/test/core/uuidv7_test.dart | ✅ COMPLIANT |
| **Arabic Normalization & FTS** | mobile/lib/core/utils/arabic_normalizer.dart<br>mobile/lib/infrastructure/repositories/local_item_repository.dart | mobile/test/core/arabic_normalizer_test.dart<br>mobile/test/infrastructure/local_repositories_test.dart | ✅ COMPLIANT |
| **Exact Money & Minor Units** | mobile/lib/domain/value_objects/money.dart | mobile/test/domain/money_test.dart | ✅ COMPLIANT |
| **Single Mutation + Outbox Atomicity** | mobile/lib/application/use_cases/task_use_cases.dart<br>mobile/lib/application/use_cases/debt_use_cases.dart | mobile/test/application/task_use_cases_test.dart | ✅ COMPLIANT |
| **Append-Only Debt Transactions** | mobile/lib/domain/entities/debt.dart<br>mobile/lib/application/use_cases/debt_use_cases.dart | mobile/test/domain/entity_test.dart | ✅ COMPLIANT |
| **Deterministic Reminder Deduplication** | mobile/lib/domain/entities/reminder.dart<br>mobile/lib/application/use_cases/reminder_use_cases.dart | mobile/test/presentation/debt_reminder_bloc_test.dart | ✅ COMPLIANT |
| **Bidirectional Sync Engine (Push/Pull/Bootstrap)** | mobile/lib/infrastructure/sync/sync_engine.dart<br>mobile/lib/infrastructure/network/remote_sync_api.dart | mobile/test/infrastructure/local_repositories_test.dart | ✅ COMPLIANT |
| **BLoC Presentation Layer State Machine** | mobile/lib/presentation/bloc/task_bloc.dart<br>mobile/lib/presentation/bloc/debt_bloc.dart<br>mobile/lib/presentation/bloc/sync_bloc.dart | mobile/test/presentation/task_bloc_test.dart<br>mobile/test/presentation/debt_reminder_bloc_test.dart | ✅ COMPLIANT |
| **Clean Architecture Purity Guards** | mobile/lib/domain/ -> mobile/lib/application/ -> mobile/lib/infrastructure/ -> mobile/lib/presentation/ | mobile/test/architecture/clean_architecture_guard_test.dart | ✅ COMPLIANT |

---
**Traceability Verdict**: 10/10 Core Mobile Pillars Fully Traceable and Verified.
