import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'package:mouin/presentation/bloc/sync_bloc.dart';
import 'package:mouin/main.dart';

void main() {
  testWidgets('MouinApp renders login screen initially', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    final localDb = LocalSqliteDb();
    final taskBloc = TaskBloc(localDb: localDb);
    final debtBloc = DebtBloc(localDb: localDb);
    final syncBloc = SyncBloc();

    await tester.pumpWidget(MouinApp(
      taskBloc: taskBloc,
      debtBloc: debtBloc,
      syncBloc: syncBloc,
    ));

    expect(find.byType(MouinApp), findsOneWidget);
    expect(find.textContaining('مُعين'), findsWidgets);
  });
}
