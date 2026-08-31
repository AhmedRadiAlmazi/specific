
# MOUIN — PHASE 5.5

## UNIFIED SEARCH & SYSTEM INTEGRATION POLISH

### تنفيذ صارم فوق المعمارية الحالية — لا تغيّر أي طبقة سابقة

نفّذ الآن **Phase 5.5 — Unified Search & System Integration Polish** في مشروع مُعين (Mouin).

## قاعدة أساسية غير قابلة للتفاوض

المعمارية الحالية مجمدة.

ممنوع تعديل:

* Domain Layer
* Application Layer
* Infrastructure Layer
* FastAPI
* REST API Contracts
* PostgreSQL / SQLite schemas
* Sync Engine
* Outbox
* Financial Ledger
* Reminder Engine
* أي BLoC أو UseCase قائم إلا إذا كان التعديل ضرورياً جداً لربط Presentation فقط، وعندها يجب إثبات أنه لا يغير السلوك الحالي.

لا تعِد بناء أي شيء موجود في Phases 5.1–5.4.

استخدم المكونات الموجودة بدلاً من إنشاء بدائل لها.

---

# 1. ابدأ بـ AUDIT فقط

قبل تعديل أي ملف:

افحص:

```text
mobile/lib/
mobile/test/
```

وافحص تحديداً:

```text
presentation/pages/
presentation/widgets/
presentation/theme/
application/
domain/
infrastructure/
```

حدد:

* مصادر البيانات المتاحة للبحث.
* BLoCs الموجودة.
* UseCases الموجودة.
* Repositories الموجودة.
* Item types الموجودة.
* طريقة الوصول إلى البيانات المحلية.
* Navigation الحالية.
* المكونات المشتركة من Phase 5.1.
* QuickCapture من Phase 5.2.
* Today Command Center من Phase 5.3.
* Debts/Documents/Notes/Shopping من Phase 5.4.

لا تنفذ تغييرات قبل فهم البنية الحالية.

---

# 2. Unified Search

أنشئ واجهة بحث موحدة داخل Presentation فقط.

المطلوب:

```text
بحث موحد
│
├── المهام
├── الديون
├── التذكيرات
├── الوثائق
├── الملاحظات
└── قوائم التسوق
```

يجب أن تعرض النتائج بشكل واضح حسب النوع.

مثال:

```text
🔎 ابحث في مُعين

┌────────────────────────────────────┐
│ التقرير المالي                 ×  │
└────────────────────────────────────┘

المهام (2)

▣ إرسال التقرير المالي
   غداً • أولوية عالية

▣ مراجعة التقرير المالي
   اليوم • 09:00 ص


الديون (1)

💳 سالم
   لي عنده • 50,000 YER


الوثائق (1)

📄 جواز السفر
   ساري حتى 15/12/2027


الملاحظات (2)

📝 اجتماع الغد
📝 أفكار المشروع
```

لا تستخدم بيانات وهمية.

يجب استخدام البيانات الحقيقية الموجودة في المشروع.

---

# 3. Search Architecture

اجعل البحث:

* Local-first.
* سريعاً.
* حتمياً.
* لا ينتظر الشبكة.
* لا يضيف Business Logic إلى Widgets.

إذا كان هناك Repository أو UseCase مناسب بالفعل، أعد استخدامه.

إذا كانت هناك آلية موحدة موجودة للقراءة من SQLite، استخدمها.

لا تنشئ Repository مكرراً.

لا تنشئ Database access داخل Widget.

لا تضع SQL داخل Presentation.

---

# 4. Arabic / RTL Search

يجب دعم البحث العربي بشكل جيد.

استفد من أدوات التطبيع الموجودة بالفعل في المشروع، إن وجدت، مثل:

```text
arabic_normalizer
```

يجب أن يعمل البحث مع الاختلافات الشائعة مثل:

```text
أ / إ / آ
ة / ه
ى / ي
التشكيل
```

لكن:

**لا تعدّل أداة التطبيع الأساسية الموجودة دون سبب واضح.**

إذا كانت موجودة ومناسبة، أعد استخدامها.

---

# 5. Search UX

استخدم مكونات Phase 5.1:

```text
MouinScaffold
MouinCard
MouinSearchField
MouinSectionHeader
MouinBadge
MouinEmptyState
MouinLoadingState
MouinErrorState
MouinButton
MouinIconButton
```

لا تنشئ نسخاً بديلة منها.

يجب دعم:

```text
Initial State
Loading
Results
Empty Results
Error
Offline
```

---

# 6. Result Interaction

عند الضغط على نتيجة:

* افتح الشاشة المناسبة.
* لا تكسر Navigation الحالية.
* لا تنشئ Navigation architecture جديدة.

التوجيه يجب أن يكون منطقياً:

```text
Task       → Task details / existing task screen
Debt       → DebtsPage / existing debt details
Document   → DocumentsPage / existing document details
Note       → NotesPage / existing note details
Shopping   → ShoppingPage / existing item details
Reminder   → existing reminder destination
```

إذا لم توجد شاشة تفاصيل لكيان معين:

لا تخترع Business Logic جديدة.

استخدم أقرب شاشة موجودة أو وثّق أن التفاصيل خارج نطاق المرحلة.

---

# 7. Integration With Today

راجع:

```text
Today Command Center
```

وتأكد أن البحث يمكن الوصول إليه بسهولة من الشاشة الرئيسية.

زر البحث الموجود في:

```text
TodayHeader
```

يجب أن يفتح Unified Search.

لا تضف شاشة بحث ثانية.

يجب أن يكون هناك Search واحد للنظام كله.

---

# 8. Integration With Quick Capture

بعد البحث أو من الشاشات المناسبة:

```text
+ أضف شيئاً
```

يجب أن يستمر في فتح:

```text
QuickCaptureBottomSheet
```

من Phase 5.2.

لا تنشئ Quick Capture جديدة.

---

# 9. Navigation Polish

راجع Navigation الحالية بالكامل:

```text
Today
Tasks
Debts
More
```

وتأكد من:

* RTL.
* Back behavior.
* عدم إنشاء stack غير ضروري.
* عدم فقدان حالة الشاشة.
* عدم تكرار الصفحات.
* عدم وجود routes ميتة.
* عدم وجود زر يؤدي إلى شاشة غير موجودة.

لا تعيد تصميم Navigation بالكامل.

قم فقط بإصلاح التكامل إن كان ضرورياً.

---

# 10. Accessibility

تحقق من:

```text
Touch Target >= 48dp
semanticLabel
tooltip
RTL semantics
keyboard/focus behavior
color contrast
```

خصوصاً:

* Search field.
* Search clear button.
* Search result cards.
* NavigationBar.
* Back button.
* Empty state actions.

---

# 11. Responsive UI

اختبر الواجهة على:

```text
Small phone
Normal phone
Large phone
Tablet-like width
```

يجب ألا يحدث:

```text
Overflow
RenderFlex overflow
Clipped text
Broken RTL alignment
```

لا تستخدم حلولاً عشوائية مثل:

```text
!important
hardcoded absolute positioning
fixed widths
```

---

# 12. Offline Behavior

يجب أن يكون:

```text
Search → Local data → Immediate results
```

ولا يجب:

```text
Search → Network → wait → result
```

إذا كان التطبيق Offline:

اعرض النتائج المحلية بشكل طبيعي.

وإذا لم توجد نتائج:

استخدم:

```text
لا توجد نتائج مطابقة
```

مع اقتراح واضح للمستخدم.

---

# 13. Testing

أنشئ اختبارات Presentation مناسبة، مثلاً:

```text
mobile/test/presentation/unified_search_test.dart
mobile/test/presentation/integration_navigation_test.dart
```

اختبر على الأقل:

### Search

* البحث عن Task.
* البحث عن Debt.
* البحث عن Document.
* البحث عن Note.
* البحث عن Shopping item.
* البحث عن Reminder.
* البحث العربي.
* البحث الفارغ.
* عدم وجود نتائج.
* clear search.
* ترتيب النتائج.
* تصنيف النتائج.

### Navigation

* Today → Search.
* Search → result.
* Search → back.
* Today → Quick Capture.
* Bottom Navigation.
* More → Documents.
* More → Notes.
* More → Shopping.
* Debts navigation.

### Accessibility

* Touch targets.
* Semantics.
* Tooltips.

### Regression

شغّل:

```bash
dart analyze
flutter test --no-pub
python -m unittest discover -s tests -v
```

ثم نفذ:

```bash
git status
git diff --stat
git diff
```

---

# 14. Strict Scope Guard

بعد التنفيذ تحقق أن التغييرات محصورة في:

```text
mobile/lib/presentation/
mobile/test/presentation/
```

وأي ملف آخر يجب تبريره صراحة.

ممنوع تعديل:

```text
domain/
application/
infrastructure/
database/
backend/
API contracts
sync
ledger
```

إذا وجدت أنك تحتاج إلى تعديل طبقة محظورة:

**توقف ولا تنفذ التعديل.**

وثّق الـ Gap بدلاً من كسر المعمارية.

---

# 15. Do Not Overengineer

لا تنشئ:

* Search microservice.
* Search database جديدة.
* Search API جديدة.
* Elasticsearch.
* Full-text infrastructure جديدة.
* Repository جديد إذا كان الموجود يكفي.
* BLoC جديد إذا كان يمكن تنفيذ Presentation state بشكل نظيف دون تكرار architecture.

نفّذ أبسط حل صحيح ومتوافق مع المعمارية الحالية.

---

# 16. Required Final Audit

بعد الانتهاء أعطني تقريراً دقيقاً يتضمن:

```text
PHASE 5.5 IMPLEMENTATION REPORT

1. Initial Audit
2. Search Architecture
3. Files Created
4. Files Modified
5. Files Deleted
6. Unified Search Features
7. Arabic Search
8. Navigation Integration
9. Today Integration
10. Quick Capture Integration
11. Offline Behavior
12. RTL
13. Accessibility
14. Responsive Verification
15. Automated Tests
16. Regression Tests
17. Architecture Integrity
18. Scope Guard
19. Git Diff Audit
20. PHASE GATE
```

وفي النهاية:

```text
========================================================
MOUIN — PHASE 5.5 GATE
========================================================

Unified Search                 [ PASS/FAIL ]
Arabic Search                  [ PASS/FAIL ]
Tasks Search                   [ PASS/FAIL ]
Debts Search                   [ PASS/FAIL ]
Documents Search               [ PASS/FAIL ]
Notes Search                   [ PASS/FAIL ]
Shopping Search                [ PASS/FAIL ]
Reminders Search               [ PASS/FAIL ]

Today Integration              [ PASS/FAIL ]
Quick Capture Integration      [ PASS/FAIL ]
Navigation                     [ PASS/FAIL ]

Offline First                  [ PASS/FAIL ]
RTL                            [ PASS/FAIL ]
Accessibility                  [ PASS/FAIL ]
Responsive Layout              [ PASS/FAIL ]

Presentation Tests             [ PASS/FAIL ]
Dart Analyze                   [ PASS/FAIL ]
Flutter Regression             [ PASS/FAIL ]
Backend Regression             [ PASS/FAIL ]

Domain Integrity               [ PASS/FAIL ]
Application Integrity          [ PASS/FAIL ]
Infrastructure Integrity       [ PASS/FAIL ]
API Integrity                  [ PASS/FAIL ]
Database Integrity             [ PASS/FAIL ]
Sync Integrity                 [ PASS/FAIL ]

Scope Guard                    [ PASS/FAIL ]
Git Diff Audit                 [ PASS/FAIL ]

========================================================
PHASE 5.5 STATUS: PASS / FAIL
========================================================
```

## قاعدة الإيقاف

إذا فشل أي اختبار أو ظهر تغيير غير مقصود في طبقة محظورة:

لا تعلن PASS.

أصلح المشكلة إن كانت ضمن Presentation Scope.

أما إذا احتاج الإصلاح إلى كسر المعمارية المجمدة، فتوقف واذكر المشكلة بدلاً من تجاوزها.
