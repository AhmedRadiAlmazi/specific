// Phase 5.4 Notes Page Tests — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/presentation/theme/mouin_theme.dart';
import 'package:mouin/presentation/pages/notes/notes_page.dart';

void main() {
  group('Phase 5.4 Notes Page Tests', () {
    testWidgets('Renders notes list and allows searching notes', (tester) async {
      final note1 = Item.createNote(
        id: 'note-1',
        workspaceId: 'ws-1',
        title: 'أرقام حسابات البنك',
        content: 'الحساب الرئيسي: 123456789',
      );

      final note2 = Item.createNote(
        id: 'note-2',
        workspaceId: 'ws-1',
        title: 'فكرة تطبيق جديدة',
        content: 'مساعد شخصي عربي يدعم الأوفلاين',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: NotesPage(
              workspaceId: 'ws-1',
              initialNotes: [note1, note2],
            ),
          ),
        ),
      );

      expect(find.text('الملاحظات والأفكار'), findsOneWidget);
      expect(find.text('أرقام حسابات البنك'), findsOneWidget);
      expect(find.text('فكرة تطبيق جديدة'), findsOneWidget);

      // Search
      await tester.enterText(find.byType(TextField).first, 'البنك');
      await tester.pump();

      expect(find.text('أرقام حسابات البنك'), findsOneWidget);
      expect(find.text('فكرة تطبيق جديدة'), findsNothing);
    });

    testWidgets('Renders empty state when notes list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: NotesPage(
              workspaceId: 'ws-1',
              initialNotes: [],
            ),
          ),
        ),
      );

      expect(find.text('مساحة الملاحظات فارغة'), findsOneWidget);
    });
  });
}
