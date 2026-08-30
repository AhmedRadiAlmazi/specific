// Main Mobile Entry Point — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';
import 'package:mouin/infrastructure/repositories/local_item_repository.dart';
import 'package:mouin/infrastructure/network/remote_sync_api.dart';
import 'package:mouin/infrastructure/sync/sync_engine.dart';
import 'package:mouin/application/use_cases/task_use_cases.dart';
import 'package:mouin/application/use_cases/debt_use_cases.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'package:mouin/presentation/bloc/sync_bloc.dart';
import 'package:mouin/presentation/pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Composition Root
  final db = LocalSqliteDb();
  final itemRepo = LocalItemRepository(db);
  final debtRepo = LocalDebtRepository(db);
  final outboxRepo = LocalOutboxRepository(db);
  final remoteSyncApi = RemoteSyncApi();

  final taskUseCases = TaskUseCases(itemRepository: itemRepo, outboxRepository: outboxRepo);
  final debtUseCases = DebtUseCases(debtRepository: debtRepo, outboxRepository: outboxRepo);
  final syncEngine = SyncEngine(
    localDb: db,
    outboxRepository: outboxRepo,
    itemRepository: itemRepo,
    remoteSyncApi: remoteSyncApi,
  );

  final taskBloc = TaskBloc(useCases: taskUseCases, repository: itemRepo);
  final debtBloc = DebtBloc(useCases: debtUseCases, repository: debtRepo);
  final syncBloc = SyncBloc(syncEngine: syncEngine);

  runApp(MouinApp(taskBloc: taskBloc, debtBloc: debtBloc, syncBloc: syncBloc));
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(taskBloc: taskBloc, debtBloc: debtBloc, syncBloc: syncBloc),
      ),
    );
  }
}
