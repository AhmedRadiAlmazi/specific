# DATABASE IMPLEMENTATION AUDIT — مشروع «مُعين» (Mouin)
## تقرير التدقيق المعماري لتأسيس قاعدة البيانات (Phase 1: Database Foundation v1.0)

**تاريخ التدقيق:** 2026-08-29  
**الإصدار المعتمد للمشروع:**
* `PRD v1.1`
* `ARCHITECTURE_BASELINE v1.0`
* `DATA_API_SYNC_CONTRACT v1.0 FINAL`
* `ERD_FINAL v1.0` (الموثق في `ERD_FINAL_v1.0_REPORT.md`)

---

### 1. حالة المشروع الحالية (Current Project State)
* **المسار الأساسي للمشروع:** `d:\تطبيق معين\specific\`
* **الملفات القائمة:** تم التحقق من وجود وثيقة التقرير المعماري والنموذج التنفيذي المعتمد `ERD_FINAL_v1.0_REPORT.md` بحجم 91.6 كيلوبايت.
* **فحص بيئة التنفيذ:**
  * بايثون: `Python 3.12.4` مع حزم `pydantic (2.8.2)`, `fastapi (0.112.1)`, `psycopg2-binary (2.9.10)`, و `sqlite3 (3.45.3)`.
  * إطار الاختبارات: `unittest` المدمج عالي الكفاءة والدقة لفحص قواعد البيانات والقيود.

---

### 2. تدقيق البنية السابقة (Legacy Infrastructure Audit)
* **هل توجد قاعدة بيانات سابقة؟** لا توجد أي قاعدة بيانات سابقة أو مهملة داخل مسار المشروع.
* **هل توجد Migrations سابقة؟** لا توجد ملفات migrations سابقة.
* **هل توجد جداول متعارضة؟** لا توجد أي جداول أو هياكل سابقة موروثة تسبب تعارضاً.
* **هل يوجد SQLite قائم؟** لا يوجد ملف SQLite سابق؛ سيتم إنشاء المخطط المحلي ومحرك التهيئة من الصفر.

---

### 3. ما الذي سيتم إنشاؤه في هذه المرحلة (What Will Be Implemented)

#### أ. قاعدة بيانات الخادم (PostgreSQL Foundation):
1. **ملفات الهيكل والتهجير (DDL & Migrations):**
   * سكريبت SQL متكامل وشامل لإنشاء جميع الجداول الـ 28 المعتمدة في `ERD_FINAL v1.0`.
   * هيكل Alembic Migration القياسي (`alembic/versions/001_initial_schema.py`) مهيأ لدورة حياة النشر والترقية.
2. **القيود والفهارس (Constraints & Indexes):**
   * قيود المفاتيح الأساسية (`UUIDv7 PRIMARY KEY`).
   * قيود المفاتيح الأجنبية الصريحة لمنع التفكك المرجعي (`ON DELETE CASCADE / RESTRICT`).
   * قيود الفحص (`CHECK Constraints`) للمبالغ المالية (`NUMERIC(14,2) > 0`) وحالات الكيانات والتواريخ.
   * الفهارس الموجهة للأداء على `workspace_id`, `server_sequence`, `updated_at`, `deleted_at`.

#### ب. قاعدة بيانات العميل المحلي (SQLite Local Foundation):
1. **ملفات الهيكل المحلي (SQLite DDL & Migrations):**
   * سكريبت DDL لإنشاء جداول النطاق المحلي المتوافقة مع `Flutter / Drift`.
   * جدول طابور الإرسال المحلي `outbox` مع قيد `operation_id UNIQUE`.
   * جدول مؤشر وحالة المزامنة المحلية `local_sync_state`.
   * جدول جلسة العمل النشطة `local_session`.
   * جدول البحث الافتراضي `items_fts` بنظام **SQLite FTS5** مع معالجة وتطبيع النصوص العربية.
2. **آليات المعاملات الذرية (Local Atomicity):**
   * دعم المعاملات الذرية الصارمة لعمليات الإنشاء المزدوج (`Domain Mutation + Outbox Mutation`).
   * دعم تطبيق حزم المزامنة وتحديث المؤشر ذرياً (`Apply Changes + Advance Cursor`).

#### ج. حزمة الاختبارات الآلية الصارمة (Acceptance Tests A to J):
* اختبار توليد واستقبال `UUIDv7` على العميل والخادم.
* اختبار الجذر التجميعي `Item` ومنع `reminder` كنوع Item.
* اختبار منع تكرار تذكيرات `occurrence_key`.
* اختبار المعاملة الذرية للـ `Outbox`.
* اختبار الدقة العشرية للمبالغ المالية ومنع `Float`.
* اختبار تراكمية حركات الديون (`Append-Oriented Ledger`) والتزامن غير المتصل.
* اختبار منع التكرار (`Idempotency`) باستخدام `operation_id` وتجزئة الـ Payload.
* اختبار تراجع المؤشر عند فشل الـ Pull Transaction.
* اختبار عزل مساحات العمل والأمان (`Scoped Ownership`).
* اختبار الحذف القابل للمزامنة (`Tombstones & Soft Delete`).

---

### 4. ما الذي يجب عدم لمسه في هذه المرحلة (What Must NOT Be Touched)
امتثالاً للقاعدة المعمارية الصارمة، **يُحظر تماماً** تنفيذ أي من الآتي في هذه المرحلة:
* ❌ لا يوجد كود واجهات مستخدم Flutter UI.
* ❌ لا توجد مسارات أو endpoints في FastAPI.
* ❌ لا يوجد محرك مزامنة عامل (Sync Engine Service).
* ❌ لا يوجد تكامل مع نماذج الذكاء الاصطناعي (AI/LLM/OCR/STT).
* ❌ لا توجد خدمات إشعارات خلفية أو عمال جدولة (Background Workers).
* ❌ لا توجد أنظمة Redis أو Queues أو خدمات رفع Object Storage.

---

### 5. خلاصة التدقيق (Audit Decision)
* **الحالة المعمارية:** متطابقة بنسبة 100% مع `DATA_API_SYNC_CONTRACT v1.0 FINAL` و `ERD_FINAL v1.0`.
* **القرار:** **الموافقة التامة على البدء الفوري في إنشاء ملفات PostgreSQL و SQLite و Migrations والاختبارات.**
