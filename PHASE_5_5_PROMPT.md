# MOUIN — PHASE 5.5

# UNIFIED SEARCH & SYSTEM INTEGRATION POLISH

## المرحلة الخامسة — توحيد البحث وصقل تكامل النظام

### STATUS: CONTROLLED IMPLEMENTATION — ARCHITECTURE FROZEN

أنت تعمل على مشروع **مُعين — Mouin**.

تم اجتياز المراحل التالية بنجاح:

* Phase 5.1 — Presentation Core Widgets & Theme
* Phase 5.2 — Unified Quick Capture Bottom Sheet
* Phase 5.3 — Today Command Center & Unified Timeline
* Phase 5.4 — Dedicated Sub-Screens

  * Debts Ledger
  * Documents Expiry
  * Notes
  * Shopping

جميع هذه المراحل اجتازت الاختبارات والـ Gates بنجاح.

الآن نفّذ:

# PHASE 5.5 — UNIFIED SEARCH & SYSTEM INTEGRATION POLISH

---

# 1. الهدف الرئيسي

إنشاء تجربة **بحث موحدة على مستوى تطبيق مُعين**، بحيث يستطيع المستخدم من نقطة بحث واحدة العثور على:

* المهام Tasks
* الديون Debts
* التذكيرات Reminders
* الوثائق Documents
* الملاحظات Notes
* قوائم التسوق Shopping
* أي Unified Items تدعمها البنية الحالية

مع تحسين التكامل بين:

* Today Command Center
* Quick Capture
* Debts
* Documents
* Notes
* Shopping
* Bottom Navigation
* Presentation Core
* Offline-First Local Data

دون إعادة بناء أي طبقة موجودة ودون تكرار Business Logic.

---

# 2. ARCHITECTURE FREEZE — قاعدة إلزامية

قبل أي تعديل:

## ممنوع منعاً باتاً:

* تعديل Domain Layer إلا إذا كان هناك مانع تقني حتمي ومثبت.
* تعديل Application Layer.
* تعديل Infrastructure Layer.
* تعديل SQLite schema.
* تعديل PostgreSQL schema.
* تعديل REST API contracts.
* تعديل FastAPI.
* تعديل Sync Engine.
* تعديل Outbox.
* تعديل Financial Ledger.
* تعديل Reminder Engine.
* إعادة كتابة BLoCs الموجودة.
* إنشاء Repository مكرر.
* إنشاء UseCase مكرر.
* نقل Business Logic إلى Widgets.
* إنشاء نظام بحث ثانٍ منفصل عن النطاق الحالي.
* حذف أي مكوّن ناجح من Phase 5.1–5.4 دون ضرورة مثبتة.

## المطلوب:

إعادة استخدام الموجود قدر الإمكان.

قاعدة:

```text
REUSE > EXTEND > ADAPT > CREATE NEW
```

ولا تنشئ abstraction جديدة إذا كان الموجود يؤدي الغرض.

---

# 3. PHASE 5.5 WORKFLOW

نفّذ العمل بهذا الترتيب فقط:

```text
STEP 1 — AUDIT
STEP 2 — GAP ANALYSIS
STEP 3 — ARCHITECTURE SAFETY CHECK
STEP 4 — IMPLEMENTATION
STEP 5 — TESTS
STEP 6 — REGRESSION
STEP 7 — GIT DIFF AUDIT
STEP 8 — PHASE GATE
```

لا تتجاوز خطوة.

---

# 4. STEP 1 — INITIAL AUDIT

افحص المشروع بالكامل، وبالأخص:

```text
mobile/lib/
mobile/test/
```

وابحث عن:

* Search widgets
* Search fields
* Search controllers
* Existing filtering
* Existing repositories
* Existing use cases
* Existing BLoCs
* Existing item queries
* Existing local database queries
* Existing navigation
* Existing route handling
* Existing search logic داخل الصفحات

افحص تحديداً:

```text
home_page.dart
debts_page.dart
documents_page.dart
notes_page.dart
shopping_page.dart
item_use_cases.dart
TaskBloc
DebtBloc
ReminderBloc
SyncBloc
Item
Debt
Money
```

وكذلك كل الملفات المتعلقة بالبحث أو الفلترة.

---

# 5. SEARCH ARCHITECTURE AUDIT

حدد هل النظام الحالي يمتلك:

1. Search abstraction
2. Local database search
3. Item-level search
4. Debt search
5. Document search
6. Note search
7. Shopping search
8. Task search
9. Filtering
10. Sorting
11. Empty search state
12. Search loading state
13. Search error state
14. Offline search
15. Navigation from search result to source entity

لا تفترض وجود أي شيء.

افحص الكود الحقيقي.

---

# 6. REQUIRED AUDIT REPORT

قبل التنفيذ، أنشئ تقريراً واضحاً داخل walkthrough أو التقرير النهائي يوضح:

```text
AVAILABLE
REUSABLE
PARTIAL
MISSING
DUPLICATED
LEGACY
DO NOT TOUCH
```

ثم حدد:

```text
SEARCH GAP MATRIX
```

مثال:

| Entity    | Search Exists | Local | Unified | Navigation | Status |
| --------- | ------------- | ----- | ------- | ---------- | ------ |
| Tasks     | ?             | ?     | ?       | ?          | ?      |
| Debts     | ?             | ?     | ?       | ?          | ?      |
| Documents | ?             | ?     | ?       | ?          | ?      |
| Notes     | ?             | ?     | ?       | ?          | ?      |
| Shopping  | ?             | ?     | ?       | ?          | ?      |
| Reminders | ?             | ?     | ?       | ?          | ?      |

لا تضع PASS إلا بعد التحقق الفعلي.

---

# 7. TARGET SEARCH EXPERIENCE

إذا لم يكن هناك نظام بحث موحد جاهز، أنشئ:

```text
UnifiedSearchPage
```

داخل:

```text
mobile/lib/presentation/pages/search/
```

واستخدم مكونات Phase 5.1 الموجودة:

* MouinScaffold
* MouinSearchField
* MouinCard
* MouinSectionHeader
* MouinBadge
* MouinEmptyState
* MouinLoadingState
* MouinErrorState
* MouinIconButton
* MouinSpacing
* MouinRadii
* MouinColors
* MouinDimens

ولا تنشئ بدائل لها.

---

# 8. SEARCH UX

يجب أن يكون البحث:

### RTL First

النص العربي هو الحالة الأساسية.

### Local First

نتائج البيانات المحلية تظهر دون انتظار الشبكة.

### Debounced

لا تنفذ بحثاً جديداً عند كل حرف بشكل غير ضروري.

استخدم debounce مناسباً، مثلاً:

```text
250–350ms
```

إلا إذا كانت البنية الحالية توفر آلية أفضل.

### Empty Query

عند عدم وجود نص بحث:

اعرض:

* عمليات بحث حديثة إن كان النظام يدعمها فعلياً، أو
* تصنيفات البحث الرئيسية، أو
* اقتراحات مفيدة.

لا تنشئ تخزيناً جديداً لعمليات البحث الحديثة فقط من أجل الشكل.

---

# 9. SEARCH RESULT MODEL

إذا احتجت Model للعرض فقط، أنشئ Presentation Search Result Model.

يجب أن يحتوي على الأقل على:

```text
type
title
subtitle
icon
status
metadata
entity identifier
navigation target
```

لكن:

**لا تنشئ Domain Entity جديدة لمجرد عرض نتائج البحث.**

---

# 10. SEARCH CATEGORIES

قسّم النتائج بصرياً إلى:

```text
كل النتائج
المهام
الديون
التذكيرات
الوثائق
الملاحظات
قوائم التسوق
```

ولا تعرض Category إذا كانت لا تحتوي نتائج.

مثال:

```text
🔎 نتائج البحث

المهام (3)
────────────────
مراجعة التقرير
إرسال المستندات
...

الديون (1)
────────────────
دين سالم
50,000 YER

الوثائق (2)
────────────────
جواز السفر
بطاقة الهوية
```

---

# 11. FILTERING

إذا كانت الفلاتر موجودة بالفعل، أعد استخدامها.

إذا لم تكن موجودة وكان تنفيذها Presentation-only:

يمكن توفير:

```text
الكل
المهام
الديون
الوثائق
الملاحظات
التسوق
التذكيرات
```

ولا تنشئ نظام Filter مستقل داخل كل Widget.

---

# 12. SEARCH MATCHING

ابحث في الحقول المتاحة فعلياً لكل Entity.

مثلاً:

### Task

```text
title
description
```

### Debt

```text
person/name
description
```

### Document

```text
title
description
```

### Note

```text
title
content
```

### Shopping

```text
item name
list name
```

استخدم فقط الحقول الموجودة فعلياً في Models.

**لا تفترض حقولاً غير موجودة.**

---

# 13. SEARCH RESULT NAVIGATION

كل نتيجة يجب أن تكون قابلة للنقر.

عند الضغط:

```text
Task       → Task detail / existing task screen
Debt       → DebtsPage / existing debt detail
Document   → DocumentsPage / existing document detail
Note       → NotesPage / existing note detail
Shopping   → ShoppingPage
Reminder   → existing reminder destination
```

إذا لم توجد شاشة Detail مستقلة:

لا تنشئ شاشة Detail جديدة في Phase 5.5 إلا إذا كانت ضرورية جداً.

يمكن الرجوع إلى الشاشة الحالية مع تحديد العنصر، إذا كان ذلك مدعوماً بالبنية الحالية.

---

# 14. HOME INTEGRATION

اربط زر البحث الموجود في:

```text
TodayHeader
```

بـ:

```text
UnifiedSearchPage
```

بحيث يصبح:

```text
Today
   ↓
Search
   ↓
Unified Search
   ↓
Entity Result
   ↓
Existing Destination
```

لا تكسر Navigation الحالية.

---

# 15. SEARCH FROM OTHER SCREENS

راجع الصفحات:

```text
DebtsPage
DocumentsPage
NotesPage
ShoppingPage
```

إذا كانت تحتوي بحثاً داخلياً ضرورياً، لا تحذفه.

القاعدة:

```text
Global Search = discovery
Local Search = page-specific filtering
```

ويجب أن يبقيا واضحين.

---

# 16. OFFLINE-FIRST

البحث الأساسي يجب أن يعمل دون إنترنت.

لا تجعل:

```text
Search → API → wait → results
```

هو المسار الأساسي.

المسار المطلوب:

```text
User Input
    ↓
Local Data
    ↓
Immediate Search
    ↓
Results
```

إذا كانت المزامنة متاحة لاحقاً، لا تجعلها شرطاً لظهور النتائج المحلية.

---

# 17. PERFORMANCE

تجنب:

* إعادة بناء شجرة Widgets كاملة لكل حرف.
* استعلامات متكررة غير ضرورية.
* إنشاء Controllers داخل build().
* إنشاء BLoC جديد لكل نتيجة.
* عمليات Sorting متكررة بلا داعٍ.
* تحميل جميع البيانات من الشبكة.

استخدم debounce وفلترة مناسبة حسب البنية الحالية.

---

# 18. ACCESSIBILITY

يجب أن يحافظ البحث على:

```text
Touch Target >= 48dp
```

ويجب توفير:

* semanticLabel
* tooltip للأزرار الأيقونية
* وضوح حالة البحث
* دعم قارئات الشاشة
* RTL
* تباين WCAG AA

---

# 19. SEARCH STATES

استخدم مكونات Phase 5.1.

يجب دعم:

### Initial

```text
ابحث عن أي شيء في مُعين
```

### Searching

```text
جارٍ البحث...
```

### Empty

```text
لم نجد نتائج مطابقة
```

### Error

```text
تعذر إتمام البحث
[إعادة المحاولة]
```

### Offline

يجب أن يظهر بوضوح أن النتائج محلية إذا كان الاتصال غير متاح.

---

# 20. DO NOT DUPLICATE UI PRIMITIVES

ممنوع إنشاء:

```text
CustomSearchCard
CustomButton
CustomBadge
CustomEmptyState
CustomLoading
```

إذا كانت مكونات Mouin الحالية تكفي.

استخدم:

```text
MouinSearchField
MouinCard
MouinBadge
MouinEmptyState
MouinLoadingState
MouinErrorState
```

---

# 21. TESTING REQUIREMENTS

أنشئ اختبارات Phase 5.5.

يفضل:

```text
mobile/test/presentation/unified_search_page_test.dart
```

واختبر على الأقل:

### Search

* ظهور الصفحة
* إدخال النص
* debounce
* النتائج
* عدم وجود نتائج
* مسح البحث

### Categories

* Tasks
* Debts
* Documents
* Notes
* Shopping
* Reminders

### Navigation

اختبر أن نتيجة البحث توجه إلى الوجهة الصحيحة باستخدام الـ navigation الحالي.

### RTL

تحقق من:

```text
Directionality.rtl
```

### Accessibility

تحقق من:

```text
>= 48dp
semantic labels
tooltips
```

### Offline

تحقق من أن البحث لا يعتمد على اتصال الشبكة.

---

# 22. REGRESSION TESTS

بعد التنفيذ:

```bash
dart analyze
flutter test --no-pub
python -m unittest discover -s tests -v
```

ولا تكتفِ باختبار Phase 5.5 فقط.

يجب تشغيل Regression كامل.

---

# 23. GIT AUDIT

نفّذ:

```bash
git status
git diff --stat
git diff
```

وتأكد من:

* عدم تعديل ملفات غير مرتبطة.
* عدم وجود ملفات مؤقتة.
* عدم وجود Scripts مؤقتة داخل المشروع.
* عدم وجود Debug code.
* عدم وجود TODO غير مقصود.
* عدم وجود imports غير مستخدمة.
* عدم وجود duplicate widgets.
* عدم وجود duplicate search engines.

---

# 24. TEMP FILE CLEANUP

أي ملفات مثل:

```text
create_phase55_*.py
generate_p55_*.py
update_p55_*.py
fix_p55_*.py
scratch/*
```

تم إنشاؤها فقط أثناء التنفيذ يجب حذفها بعد استخدامها، ما لم تكن جزءاً دائماً من المشروع.

لا تترك أدوات التطوير المؤقتة في production tree.

---

# 25. ARCHITECTURE INTEGRITY CHECK

قبل Gate النهائي، تحقق حرفياً:

```text
Domain Layer modified:            NO
Application Layer modified:       NO
Infrastructure Layer modified:    NO
FastAPI modified:                 NO
Database Schema modified:         NO
REST API Contracts modified:      NO
Sync Engine modified:             NO
Outbox modified:                  NO
Financial Ledger modified:        NO
Reminder Engine modified:         NO
```

إذا اضطررت لتغيير أي بند:

**توقف ولا تعتبر Phase 5.5 PASS.**

سجل السبب والملف والتغيير المطلوب أولاً.

---

# 26. FINAL REPORT FORMAT

في نهاية التنفيذ أنشئ تقريراً بهذا الشكل:

```text
# PHASE 5.5 IMPLEMENTATION REPORT

# UNIFIED SEARCH & SYSTEM INTEGRATION POLISH
## مشروع مُعين — Mouin

## 1. Initial Audit

...

## 2. Search Gap Analysis

...

## 3. Files Created

...

## 4. Files Modified

...

## 5. Files Deleted

...

## 6. Unified Search Architecture

...

## 7. Search Result Mapping

...

## 8. Navigation Integration

...

## 9. Offline Behavior

...

## 10. RTL & Accessibility

...

## 11. Performance

...

## 12. Automated Tests

...

## 13. Regression

...

## 14. Architecture Integrity

...

## 15. Git Diff Audit
```

ثم Gate:

```text
========================================================
MOUIN — PHASE 5.5 GATE
========================================================

Initial Audit                  [ PASS ]
Gap Analysis                   [ PASS ]

Unified Search                [ PASS ]
Tasks Search                  [ PASS ]
Debts Search                  [ PASS ]
Documents Search              [ PASS ]
Notes Search                  [ PASS ]
Shopping Search               [ PASS ]
Reminders Search              [ PASS ]

Search Navigation              [ PASS ]
Filtering                      [ PASS ]
Empty State                    [ PASS ]
Loading State                  [ PASS ]
Error State                    [ PASS ]
Offline Search                 [ PASS ]

RTL                            [ PASS ]
Accessibility                  [ PASS ]
Touch Targets                 [ PASS ]
Responsive Layout              [ PASS ]

Existing Architecture Reused   [ PASS ]
No Duplicate Business Logic   [ PASS ]
No Duplicate UI Primitives    [ PASS ]

Domain Integrity              [ PASS ]
Application Integrity         [ PASS ]
Infrastructure Integrity      [ PASS ]
API Integrity                 [ PASS ]
Database Integrity            [ PASS ]
Sync Integrity                [ PASS ]

Widget Tests                  [ PASS ]
Dart Analyze                  [ PASS ]
Flutter Regression            [ PASS ]
Backend Regression            [ PASS ]

Git Diff Audit                [ PASS ]
Scope Guard                   [ PASS ]
Temporary Files Cleanup       [ PASS ]

========================================================
PHASE 5.5 STATUS: PASS
========================================================
```

---

# 27. FINAL RULE

لا تعتبر المرحلة ناجحة بسبب أن:

```text
flutter test = PASS
```

فقط.

النجاح الحقيقي يتطلب:

```text
FUNCTIONAL
+
ARCHITECTURAL
+
RTL
+
ACCESSIBILITY
+
OFFLINE
+
REGRESSION
+
SCOPE
+
GIT AUDIT
```

جميعها PASS.

إذا ظهرت مشكلة معمارية حقيقية أثناء التنفيذ، **لا تتجاوزها ولا تتحايل عليها**.

أوقف التنفيذ عند نقطة المشكلة، وثّقها، وحدد:

```text
Problem
Cause
Affected Layer
Why Existing Architecture Is Insufficient
Minimal Safe Fix
```

ثم لا تنفذ التغيير المعماري إلا بعد اعتماد صريح.

**ابدأ الآن بـ STEP 1 — INITIAL AUDIT فقط، ثم واصل وفق الـ workflow أعلاه.**
