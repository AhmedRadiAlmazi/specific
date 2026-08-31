// Phase 5.4 Documents Page Tests — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/presentation/theme/mouin_theme.dart';
import 'package:mouin/presentation/pages/documents/documents_page.dart';

void main() {
  group('Phase 5.4 Documents Page Tests', () {
    testWidgets('Renders documents list with expiry status badges and search', (tester) async {
      final now = DateTime.now();
      final docActive = Item.createDocument(
        id: 'doc-1',
        workspaceId: 'ws-1',
        title: 'جواز السفر اليمني',
        documentType: 'passport',
        documentNumber: 'P1234567',
        expiryDate: now.add(const Duration(days: 300)),
      );

      final docExpiring = Item.createDocument(
        id: 'doc-2',
        workspaceId: 'ws-1',
        title: 'رخصة القيادة',
        documentType: 'driver_license',
        documentNumber: 'DL987654',
        expiryDate: now.add(const Duration(days: 20)),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: DocumentsPage(
              workspaceId: 'ws-1',
              initialDocs: [docActive, docExpiring],
            ),
          ),
        ),
      );

      expect(find.text('الوثائق وتتبع الانتهاء'), findsOneWidget);
      expect(find.text('جواز السفر اليمني'), findsOneWidget);
      expect(find.text('رخصة القيادة'), findsOneWidget);
      expect(find.text('سارية'), findsOneWidget);
      expect(find.text('تنتهي قريباً'), findsOneWidget);
    });

    testWidgets('Renders empty state when no documents exist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MouinTheme.light,
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: DocumentsPage(
              workspaceId: 'ws-1',
              initialDocs: [],
            ),
          ),
        ),
      );

      expect(find.text('لم تسجل أي وثيقة بعد'), findsOneWidget);
    });
  });
}
