// Mobile App Entry Point — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/core/theme/app_theme.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'package:mouin/presentation/bloc/sync_bloc.dart';
import 'package:mouin/presentation/pages/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final localDb = LocalSqliteDb();
  final taskBloc = TaskBloc(localDb: localDb);
  final debtBloc = DebtBloc(localDb: localDb);
  final syncBloc = SyncBloc();

  runApp(MouinApp(
    taskBloc: taskBloc,
    debtBloc: debtBloc,
    syncBloc: syncBloc,
  ));
}

class MouinApp extends StatelessWidget {
  final TaskBloc taskBloc;
  final DebtBloc debtBloc;
  final SyncBloc syncBloc;

  const MouinApp({
    super.key,
    required this.taskBloc,
    required this.debtBloc,
    required this.syncBloc,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مُعين',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: LoginPage(
          taskBloc: taskBloc,
          debtBloc: debtBloc,
          syncBloc: syncBloc,
        ),
      ),
    );
  }
}
