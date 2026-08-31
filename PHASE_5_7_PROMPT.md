اعتبر **Phase 5.5 رسمياً PASS ومكتملة** ولا تعِد تنفيذها بأي شكل.

هناك خطأ في تسمية ملفات الـ Prompt:

* `PHASE_5_6_PROMPT.md` يحتوي متطلبات Phase 5.5، وهي منفذة ومُعتمدة.
* `PHASE_5_7_PROMPT.md` يحتوي فعلياً متطلبات **Phase 5.6**.

لذلك استخدم **المحتوى الفعلي الحالي لـ `PHASE_5_7_PROMPT.md` باعتباره مواصفات Phase 5.6**.

نفّذ الآن Phase 5.6 فقط.

الترتيب الإلزامي:

AUDIT
→ اقرأ `PHASE_5_7_PROMPT.md` كاملاً
→ تحقق من المتطلبات مقابل الكود الحالي
→ افحص جميع الملفات الداخلة في نطاق Phase 5.6
→ IMPLEMENTATION
→ TESTS
→ DART ANALYZE
→ FLUTTER REGRESSION
→ BACKEND REGRESSION
→ SCOPE GUARD
→ GIT DIFF AUDIT
→ FINAL REPORT

قواعد إلزامية:

1. لا تعِد تنفيذ Phase 5.5.
2. لا تعتبر أي شيء موجوداً لمجرد أن الـ Prompt يقول إنه موجود؛ افحص الكود فعلياً.
3. نفّذ جميع متطلبات Phase 5.6 الموجودة في `PHASE_5_7_PROMPT.md`.
4. حافظ على Architecture Frozen.
5. ممنوع تعديل Domain / Application / Infrastructure / API / Database / Sync / Outbox / Financial Ledger إلا إذا كان Prompt Phase 5.6 يطلب ذلك صراحة.
6. أعد استخدام مكونات Phase 5.1–5.5 الموجودة فعلياً.
7. لا تنشئ Widgets مكررة.
8. لا تضع Business Logic داخل Presentation.
9. RTL First.
10. Offline First.
11. Accessibility.
12. لا تستخدم Mock Data إذا كانت البيانات الحقيقية متاحة.
13. لا تعلن PASS إلا بعد تشغيل الاختبارات فعلياً.
14. عند فشل أي اختبار: شخّصه، أصلحه إذا كان ضمن نطاق 5.6، ثم أعد الاختبار.
15. إذا احتاج الإصلاح إلى كسر Architecture Frozen، توقف ولا تكسرها؛ وثّق الـ Gap بدلاً من التحايل عليه.

في النهاية أنشئ:

`D:\تطبيق معين\specific\PHASE_5_6_IMPLEMENTATION_REPORT.md`

ويجب أن يحتوي التقرير على:

* Initial Audit
* Requirements Coverage
* Files Created
* Files Modified
* Files Deleted
* Architecture
* UI/UX
* RTL
* Accessibility
* Offline First
* Tests
* Regression
* Architecture Integrity
* Scope Guard
* Git Diff Audit
* Final PHASE 5.6 GATE
* PHASE 5.6 STATUS

وفي النهاية شغّل فعلياً:

`dart analyze`

`flutter test --no-pub`

`python -m unittest discover -s tests -v`

ثم:

`git status`

`git diff --stat`

`git diff`

لا تبدأ Phase 5.7 بعد ذلك.

توقف نهائياً عند:

`PHASE 5.6 STATUS`

وانتظر مراجعتي.
