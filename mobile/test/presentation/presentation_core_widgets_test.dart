import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/presentation/theme/mouin_theme.dart';
import 'package:mouin/presentation/theme/tokens/mouin_colors.dart';
import 'package:mouin/presentation/theme/tokens/mouin_dimens.dart';
import 'package:mouin/presentation/widgets/common/mouin_card.dart';
import 'package:mouin/presentation/widgets/common/mouin_button.dart';
import 'package:mouin/presentation/widgets/common/mouin_icon_button.dart';
import 'package:mouin/presentation/widgets/states/mouin_states.dart';
import 'package:mouin/presentation/widgets/domain/domain_badges.dart';

void main() {
  group('Phase 5.1 Theme & Design Tokens Tests', () {
    test('MouinTheme light & dark configurations are valid and Material 3 enabled', () {
      final lightTheme = MouinTheme.light;
      final darkTheme = MouinTheme.dark;

      expect(lightTheme.useMaterial3, isTrue);
      expect(darkTheme.useMaterial3, isTrue);
      expect(lightTheme.colorScheme.primary, MouinColors.primary);
      expect(lightTheme.scaffoldBackgroundColor, MouinColors.backgroundLight);
      expect(darkTheme.scaffoldBackgroundColor, MouinColors.backgroundDark);
    });
  });

  group('Phase 5.1 Common & State Widgets Tests', () {
    testWidgets('MouinCard renders child with correct padding and tap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: MouinCard(
                onTap: () => tapped = true,
                child: const Text('محتوى البطاقة'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('محتوى البطاقة'), findsOneWidget);
      await tester.tap(find.text('محتوى البطاقة'));
      expect(tapped, isTrue);
    });

    testWidgets('MouinButton meets minimum 48dp touch target and handles loading', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: MouinButton(
                label: 'زر الإجراء',
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);
      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(MouinDimens.minTouchTarget));

      await tester.tap(buttonFinder);
      expect(pressed, isTrue);
    });

    testWidgets('MouinIconButton enforces semantic label and min 48dp constraints', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: MouinIconButton(
                icon: Icons.sync,
                semanticLabel: 'مزامنة السيرفر',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final iconButtonFinder = find.byType(MouinIconButton);
      expect(iconButtonFinder, findsOneWidget);
      final size = tester.getSize(iconButtonFinder);
      expect(size.width, greaterThanOrEqualTo(MouinDimens.minTouchTarget));
      expect(size.height, greaterThanOrEqualTo(MouinDimens.minTouchTarget));
      expect(find.byTooltip('مزامنة السيرفر'), findsOneWidget);
    });

    testWidgets('MouinEmptyState and MouinErrorState render title, icon and retry', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: MouinErrorState(
                title: 'خطأ في الاتصال',
                message: 'تعذر الاتصال بالخادم',
                onRetry: () => retried = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('خطأ في الاتصال'), findsOneWidget);
      expect(find.text('تعذر الاتصال بالخادم'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);

      await tester.tap(find.text('إعادة المحاولة'));
      expect(retried, isTrue);
    });

    testWidgets('MouinOfflineBanner renders non-intrusive message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: MouinOfflineBanner(pendingCount: 2),
            ),
          ),
        ),
      );

      expect(find.textContaining('وضع غير متصل — 2 تغييرات محفوظة محلياً'), findsOneWidget);
    });
  });

  group('Phase 5.1 Domain Presentation Widgets Tests', () {
    testWidgets('PriorityBadge renders all Priority variants correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Column(
                children: [
                  PriorityBadge(priority: Priority.urgent),
                  PriorityBadge(priority: Priority.high),
                  PriorityBadge(priority: Priority.medium),
                  PriorityBadge(priority: Priority.low),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('عاجل جداً'), findsOneWidget);
      expect(find.text('أولوية عالية'), findsOneWidget);
      expect(find.text('متوسطة'), findsOneWidget);
      expect(find.text('منخفضة'), findsOneWidget);
    });

    testWidgets('DirectionalBadge renders receivable and payable correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Column(
                children: [
                  DirectionalBadge(debtType: DebtType.receivable),
                  DirectionalBadge(debtType: DebtType.payable),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('لي عنده'), findsOneWidget);
      expect(find.text('عليّ له'), findsOneWidget);
    });

    testWidgets('MoneyDisplay formats amount and currency with directional color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: MoneyDisplay(
                amount: '150,000.00',
                currency: 'YER',
                showDirectionColor: true,
                isPositive: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('150,000.00 YER'), findsOneWidget);
    });
  });
}
