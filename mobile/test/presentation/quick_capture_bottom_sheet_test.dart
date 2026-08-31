// Phase 5.2 Quick Capture Bottom Sheet Test Suite — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/presentation/theme/mouin_theme.dart';
import 'package:mouin/presentation/theme/tokens/mouin_dimens.dart';
import 'package:mouin/presentation/widgets/quick_capture/quick_capture_bottom_sheet.dart';
import 'package:mouin/presentation/widgets/quick_capture/quick_capture_types.dart';
import 'package:mouin/presentation/widgets/quick_capture/quick_capture_type_chips.dart';

void main() {
  group('Phase 5.2 Quick Capture Heuristic Suggestion Tests', () {
    test('Suggests QuickCaptureType.debt when text contains debt keywords', () {
      expect(QuickCaptureSuggestor.suggestType('لي عند سالم 150000 ريال'), QuickCaptureType.debt);
      expect(QuickCaptureSuggestor.suggestType('سداد سلف لمحمد'), QuickCaptureType.debt);
      expect(QuickCaptureSuggestor.suggestType('عليّ ل خالد 5000'), QuickCaptureType.debt);
    });

    test('Suggests QuickCaptureType.reminder when text contains temporal/reminder keywords', () {
      expect(QuickCaptureSuggestor.suggestType('ذكرني بموعد الطبيب بعد غد'), QuickCaptureType.reminder);
      expect(QuickCaptureSuggestor.suggestType('تنبيه موعد الاجتماع الساعة 4'), QuickCaptureType.reminder);
    });

    test('Suggests QuickCaptureType.document when text contains document keywords', () {
      expect(QuickCaptureSuggestor.suggestType('تجديد جواز السفر'), QuickCaptureType.document);
      expect(QuickCaptureSuggestor.suggestType('رخصة القيادة تنتهي قريباً'), QuickCaptureType.document);
      expect(QuickCaptureSuggestor.suggestType('هوية وطنية وبطاقة البنك'), QuickCaptureType.document);
    });

    test('Suggests QuickCaptureType.shopping when text contains shopping keywords', () {
      expect(QuickCaptureSuggestor.suggestType('قائمة أغراض السوبرماركت'), QuickCaptureType.shopping);
      expect(QuickCaptureSuggestor.suggestType('شراء مستلزمات السوق'), QuickCaptureType.shopping);
    });

    test('Suggests QuickCaptureType.note when text contains note keywords', () {
      expect(QuickCaptureSuggestor.suggestType('ملاحظة فكرة تطبيق جديدة'), QuickCaptureType.note);
      expect(QuickCaptureSuggestor.suggestType('رقم الهاتف السري'), QuickCaptureType.note);
    });

    test('Defaults to QuickCaptureType.task for general actionable text', () {
      expect(QuickCaptureSuggestor.suggestType('إكمال كتابة التقرير الأسبوعي'), QuickCaptureType.task);
    });
  });

  group('Phase 5.2 Quick Capture Widget & UX Tests', () {
    testWidgets('Renders all 6 supported types in Type Chips with touch targets >= 48dp', (tester) async {
      QuickCaptureType selected = QuickCaptureType.task;

      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: QuickCaptureTypeChips(
                selectedType: selected,
                onTypeChanged: (type) => selected = type,
              ),
            ),
          ),
        ),
      );

      // Verify all 6 labels appear
      expect(find.text('مهمة'), findsOneWidget);
      expect(find.text('دين'), findsOneWidget);
      expect(find.text('تذكير'), findsOneWidget);
      expect(find.text('وثيقة'), findsOneWidget);
      expect(find.text('ملاحظة'), findsOneWidget);
      expect(find.text('قائمة'), findsOneWidget);

      // Verify chip touch target constraint
      final chipFinder = find.byType(ChoiceChip).first;
      final size = tester.getSize(chipFinder);
      expect(size.height, greaterThanOrEqualTo(MouinDimens.minTouchTarget));

      // Tap on 'دين'
      await tester.tap(find.text('دين'), warnIfMissed: false);
      expect(selected, QuickCaptureType.debt);
    });

    testWidgets('QuickCaptureBottomSheet renders header, text input, mic and save button', (tester) async {
      String savedTitle = '';
      QuickCaptureType savedType = QuickCaptureType.task;

      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: QuickCaptureBottomSheet(
                workspaceId: '018e3a2b-0002-7000-8000-000000000002',
                onSaved: (type, title) {
                  savedType = type;
                  savedTitle = title;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('ما الذي يدور في ذهنك؟'), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.text('حفظ مهمة'), findsOneWidget);

      // Attempt save with empty text -> shows validation error
      await tester.tap(find.text('حفظ مهمة'));
      await tester.pump();
      expect(find.text('يرجى كتابة ما يدور في ذهنك أولاً'), findsOneWidget);

      // Enter valid task text
      await tester.enterText(find.byType(TextField).first, 'مراجعة الميزانية السنوية');
      await tester.pump();

      // Tap save
      await tester.tap(find.text('حفظ مهمة'));
      await tester.pumpAndSettle();

      expect(savedTitle, 'مراجعة الميزانية السنوية');
      expect(savedType, QuickCaptureType.task);
    });

    testWidgets('Microphone button triggers informative Arabic snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: QuickCaptureBottomSheet(
                workspaceId: '018e3a2b-0002-7000-8000-000000000002',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pump();

      expect(find.textContaining('🎙 التسجيل الصوتي قيد التجهيز'), findsOneWidget);
    });
  });
}
