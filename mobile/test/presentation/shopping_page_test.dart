// Phase 5.4 Shopping Page Tests — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/presentation/theme/mouin_theme.dart';
import 'package:mouin/presentation/pages/shopping/shopping_page.dart';

void main() {
  group('Phase 5.4 Shopping Page Tests', () {
    testWidgets('Renders checklist items and allows toggling completion and fast add', (tester) async {
      final item1 = ShoppingItemModel(id: '1', title: 'حليب طازج', isDone: false);
      final item2 = ShoppingItemModel(id: '2', title: 'خبز أبيض', isDone: true);

      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ShoppingPage(
              workspaceId: 'ws-1',
              initialItems: [item1, item2],
            ),
          ),
        ),
      );

      expect(find.text('قائمة المشتريات والتسوق'), findsOneWidget);
      expect(find.text('حليب طازج'), findsOneWidget);
      expect(find.text('خبز أبيض'), findsOneWidget);

      // Toggle item1 checkbox
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      // Add new item via input
      await tester.enterText(find.byType(TextField).first, 'بيض بلدي');
      await tester.tap(find.text('إضافة'));
      await tester.pump();

      expect(find.text('بيض بلدي'), findsOneWidget);
    });
  });
}
