import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/core/utils/uuidv7.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/entities/debt.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';

void main() {
  group('Domain Entities', () {
    test('Item aggregate creation and soft deletion', () {
      final item = Item.createTask(
        id: UuidV7.generate(),
        workspaceId: '018e3a2b-0002-7000-8000-000000000002',
        title: 'شراء معدات',
        priority: Priority.high,
      );

      expect(item.isDeleted, isFalse);
      expect(item.entityVersion, equals(1));

      final deleted = item.markDeleted();
      expect(deleted.isDeleted, isTrue);
      expect(deleted.entityVersion, equals(2));
    });

    test('Debt aggregate calculates exact remaining amount with payments', () {
      final debt = Debt(
        id: UuidV7.generate(),
        workspaceId: '018e3a2b-0002-7000-8000-000000000002',
        personId: 'علي سالم',
        debtType: DebtType.payable,
        totalAmount: Money.fromDecimalString('1000.00', currency: 'YER'),
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      expect(debt.calculateRemainingAmount().toDecimalString(), equals('1000.00'));

      debt.transactions.add(DebtTransaction(
        id: UuidV7.generate(),
        debtId: debt.id,
        workspaceId: debt.workspaceId,
        transactionType: DebtTransactionType.payment,
        amount: Money.fromDecimalString('350.00', currency: 'YER'),
        transactionDate: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
      ));

      expect(debt.calculateRemainingAmount().toDecimalString(), equals('650.00'));
    });
  });
}
