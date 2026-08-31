// Phase 5.3 Today Command Center Test Suite — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/entities/debt.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';
import 'package:mouin/presentation/theme/mouin_theme.dart';
import 'package:mouin/presentation/widgets/today/today_header.dart';
import 'package:mouin/presentation/widgets/today/today_urgent_section.dart';
import 'package:mouin/presentation/widgets/today/today_timeline.dart';
import 'package:mouin/presentation/widgets/today/today_timeline_entry.dart';
import 'package:mouin/presentation/widgets/today/upcoming_48h_section.dart';
import 'package:mouin/presentation/widgets/quick_capture/quick_capture_types.dart';

void main() {
  group('Phase 5.3 Today Header & Date Helper Tests', () {
    test('Greeting changes dynamically with time of day', () {
      final morning = DateTime(2026, 8, 30, 8, 30);
      final afternoon = DateTime(2026, 8, 30, 14, 0);
      final night = DateTime(2026, 8, 30, 21, 0);

      expect(TodayHeader.getGreeting(morning), contains('صباح الخير'));
      expect(TodayHeader.getGreeting(afternoon), contains('مساء الخير'));
      expect(TodayHeader.getGreeting(night), contains('مساء الخير'));
    });

    test('Formatted Arabic date contains day and month names', () {
      final date = DateTime(2026, 8, 30);
      final formatted = TodayHeader.formatArabicDate(date);
      expect(formatted, contains('الأحد'));
      expect(formatted, contains('أغسطس'));
      expect(formatted, contains('2026'));
    });

    testWidgets('TodayHeader renders user greeting and buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: TodayHeader(),
            ),
          ),
        ),
      );

      expect(find.byType(TodayHeader), findsOneWidget);
    });
  });

  group('Phase 5.3 Today Urgent Section Tests', () {
    testWidgets('Renders urgent card when overdue tasks exist', (tester) async {
      final overdueTask = Item.createTask(
        id: 'task-overdue-1',
        workspaceId: 'ws-1',
        title: 'سداد فاتورة الكهرباء المتأخرة',
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        priority: Priority.urgent,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: TodayUrgentSection(
                tasks: [overdueTask],
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('العواجل'), findsOneWidget);
      expect(find.text('سداد فاتورة الكهرباء المتأخرة'), findsOneWidget);
    });

    testWidgets('Hides urgent section when no overdue/urgent tasks exist', (tester) async {
      final normalTask = Item.createTask(
        id: 'task-normal-1',
        workspaceId: 'ws-1',
        title: 'مهمة عادية قادمة',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        priority: Priority.low,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: TodayUrgentSection(
                tasks: [normalTask],
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('العواجل'), findsNothing);
    });
  });

  group('Phase 5.3 Today Timeline & Upcoming Tests', () {
    testWidgets('TodayTimeline renders items sorted chronologically', (tester) async {
      final now = DateTime.now();
      final taskMorning = Item.createTask(
        id: 'task-m-1',
        workspaceId: 'ws-1',
        title: 'مراجعة التقرير المالي',
        dueDate: DateTime(now.year, now.month, now.day, 9, 0),
        priority: Priority.high,
      );

      final debtAfternoon = Debt(
        id: 'debt-1',
        workspaceId: 'ws-1',
        personId: 'سالم',
        debtType: DebtType.receivable,
        totalAmount: Money.fromDecimalString('50000.00'),
        dueDate: DateTime(now.year, now.month, now.day, 16, 0),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                child: TodayTimeline(
                  tasks: [taskMorning],
                  debts: [debtAfternoon],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('جدول اليوم'), findsOneWidget);
      expect(find.text('مراجعة التقرير المالي'), findsOneWidget);
      expect(find.textContaining('تحصيل دين من سالم'), findsOneWidget);
    });

    testWidgets('TodayTimeline renders empty state when no items exist today', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: TodayTimeline(
                tasks: [],
                debts: [],
              ),
            ),
          ),
        ),
      );

      expect(find.text('يومك هادئ ومكتمل!'), findsOneWidget);
      expect(find.text('لا توجد التزامات مجدولة لليوم.'), findsOneWidget);
    });

    testWidgets('Upcoming48hSection displays tasks due tomorrow and next day', (tester) async {
      final now = DateTime.now();
      final tomorrowTask = Item.createTask(
        id: 'task-tom-1',
        workspaceId: 'ws-1',
        title: 'تجديد اشتراك الإنترنت',
        dueDate: now.add(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Upcoming48hSection(
                tasks: [tomorrowTask],
              ),
            ),
          ),
        ),
      );

      expect(find.text('القادم خلال 48 ساعة'), findsOneWidget);
      expect(find.text('تجديد اشتراك الإنترنت'), findsOneWidget);
      expect(find.text('غداً'), findsOneWidget);
    });
  });
}
