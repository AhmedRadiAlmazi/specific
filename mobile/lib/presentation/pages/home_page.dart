// Today Command Center & Main Home Page — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/core/session/session_manager.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/entities/debt.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/infrastructure/network/remote_sync_api.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'package:mouin/presentation/bloc/sync_bloc.dart';
import 'package:mouin/presentation/pages/login_page.dart';
import 'package:mouin/presentation/theme/tokens/mouin_colors.dart';
import 'package:mouin/presentation/theme/tokens/mouin_spacing.dart';
import 'package:mouin/presentation/widgets/common/mouin_card.dart';
import 'package:mouin/presentation/widgets/common/mouin_search_field.dart';
import 'package:mouin/presentation/widgets/states/mouin_states.dart';
import 'package:mouin/presentation/widgets/domain/domain_badges.dart';
import 'package:mouin/presentation/widgets/quick_capture/quick_capture_bottom_sheet.dart';
import 'package:mouin/presentation/widgets/today/today_header.dart';
import 'package:mouin/presentation/widgets/today/today_sync_status.dart';
import 'package:mouin/presentation/widgets/today/today_urgent_section.dart';
import 'package:mouin/presentation/widgets/today/today_timeline.dart';
import 'package:mouin/presentation/widgets/today/upcoming_48h_section.dart';
import 'package:mouin/presentation/pages/debts/debts_page.dart';
import 'package:mouin/presentation/pages/documents/documents_page.dart';
import 'package:mouin/presentation/pages/notes/notes_page.dart';
import 'package:mouin/presentation/pages/shopping/shopping_page.dart';
import 'package:mouin/presentation/pages/search/unified_search_page.dart';
import 'package:mouin/presentation/widgets/tasks/task_detail_bottom_sheet.dart';

class HomePage extends StatefulWidget {
  final TaskBloc taskBloc;
  final DebtBloc debtBloc;
  final SyncBloc syncBloc;
  final RemoteSyncApi? remoteSyncApi;
  final String workspaceId;

  const HomePage({
    super.key,
    required this.taskBloc,
    required this.debtBloc,
    required this.syncBloc,
    this.remoteSyncApi,
    this.workspaceId = '018e3a2b-0002-7000-8000-000000000002',
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  late String _currentWorkspaceId;

  @override
  void initState() {
    super.initState();
    _currentWorkspaceId = widget.workspaceId;
    widget.taskBloc.loadTasks(_currentWorkspaceId);
    widget.debtBloc.loadDebts(_currentWorkspaceId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openUnifiedSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: UnifiedSearchPage(
            taskBloc: widget.taskBloc,
            debtBloc: widget.debtBloc,
            syncBloc: widget.syncBloc,
            workspaceId: _currentWorkspaceId,
          ),
        ),
      ),
    );
  }

  void _openQuickCapture() {
    QuickCaptureBottomSheet.show(
      context,
      workspaceId: _currentWorkspaceId,
      taskBloc: widget.taskBloc,
      debtBloc: widget.debtBloc,
      onSaved: (type, title) {
        widget.taskBloc.loadTasks(_currentWorkspaceId);
        widget.debtBloc.loadDebts(_currentWorkspaceId);
      },
    );
  }

  void _logout() {
    SessionManager().clearSession();
    final api = widget.remoteSyncApi ?? RemoteSyncApi();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: LoginPage(
            taskBloc: widget.taskBloc,
            debtBloc: widget.debtBloc,
            syncBloc: widget.syncBloc,
            remoteSyncApi: api,
          ),
        ),
      ),
    );
  }

  void _triggerSync() {
    widget.syncBloc.triggerSync(_currentWorkspaceId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 بدأت المزامنة الحية ثنائية الاتجاه مع السيرفر...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildTodayView(List<Item> tasks, List<Debt> debts) {
    return RefreshIndicator(
      onRefresh: () async {
        widget.taskBloc.loadTasks(_currentWorkspaceId);
        widget.debtBloc.loadDebts(_currentWorkspaceId);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TodaySyncStatus(
              syncBloc: widget.syncBloc,
              onTriggerSync: _triggerSync,
            ),
            TodayUrgentSection(
              tasks: tasks,
              onCompleteTask: (id) => widget.taskBloc.completeTask(_currentWorkspaceId, id),
            ),
            TodayTimeline(
              tasks: tasks,
              debts: debts,
              onCompleteTask: (id) => widget.taskBloc.completeTask(_currentWorkspaceId, id),
              onDeleteTask: (id) => widget.taskBloc.deleteTask(_currentWorkspaceId, id),
              onAddPressed: _openQuickCapture,
            ),
            Upcoming48hSection(tasks: tasks),
            const SizedBox(height: 80), // Padding for FAB & Bottom Nav
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab(List<Item> tasks) {
    return Column(
      children: [
        Padding(
          padding: MouinSpacing.paddingMd,
          child: MouinSearchField(
            controller: _searchController,
            hintText: 'بحث عربي سريع في المهام...',
            onChanged: (query) => widget.taskBloc.searchTasks(_currentWorkspaceId, query),
            onClear: () => widget.taskBloc.loadTasks(_currentWorkspaceId),
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? MouinEmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'لا توجد مهام حالياً',
                  subtitle: 'اضغط على زر + في الأسفل لإضافة مهمتك الأولى.',
                  actionLabel: 'إضافة مهمة',
                  onAction: _openQuickCapture,
                )
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (ctx, index) {
                    final item = tasks[index];
                    final isCompleted = item.taskDetail?.status == TaskStatus.completed;
                    final priority = item.taskDetail?.priority ?? Priority.medium;

                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: MouinColors.error,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        widget.taskBloc.deleteTask(_currentWorkspaceId, item.id);
                      },
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          TaskDetailBottomSheet.show(
                            context,
                            task: item,
                            workspaceId: _currentWorkspaceId,
                            taskBloc: widget.taskBloc,
                          );
                        },
                        child: MouinCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isCompleted,
                                onChanged: (val) {
                                  if (val == true) {
                                    widget.taskBloc.completeTask(_currentWorkspaceId, item.id);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'المعرف: ${item.id.substring(0, 8)}... | ${isCompleted ? "منجز" : "قيد التنفيذ"}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PriorityBadge(priority: priority),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDebtsTab(List<Debt> debts) {
    return DebtsPage(
      debtBloc: widget.debtBloc,
      workspaceId: _currentWorkspaceId,
      onAddDebt: _openQuickCapture,
    );
  }

  Widget _buildMoreTab() {
    return ListView(
      padding: MouinSpacing.paddingMd,
      children: [
        MouinCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: DocumentsPage(workspaceId: _currentWorkspaceId),
                ),
              ),
            );
          },
          child: const ListTile(
            leading: Icon(Icons.description_outlined, color: MouinColors.primary),
            title: Text('الوثائق والمستندات', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('تتبع الهويات، الجوازات، وتواريخ الانتهاء'),
            trailing: Icon(Icons.chevron_left),
          ),
        ),
        MouinCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: NotesPage(workspaceId: _currentWorkspaceId),
                ),
              ),
            );
          },
          child: const ListTile(
            leading: Icon(Icons.note_outlined, color: MouinColors.primary),
            title: Text('الملاحظات والأفكار', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('تدوين الأفكار والنصوص السريعة'),
            trailing: Icon(Icons.chevron_left),
          ),
        ),
        MouinCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: ShoppingPage(workspaceId: _currentWorkspaceId),
                ),
              ),
            );
          },
          child: const ListTile(
            leading: Icon(Icons.checklist, color: MouinColors.primary),
            title: Text('قوائم المشتريات والتسوق', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('قوائم التسوق ومربعات الاختيار السريعة'),
            trailing: Icon(Icons.chevron_left),
          ),
        ),
        MouinCard(
          onTap: _triggerSync,
          child: const ListTile(
            leading: Icon(Icons.sync, color: MouinColors.primary),
            title: Text('حالة المزامنة السحابية', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('مزامنة فورية ثنائية الاتجاه مع الخادم'),
            trailing: Icon(Icons.chevron_left),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<TaskState>(
        stream: widget.taskBloc.state,
        initialData: widget.taskBloc.currentState,
        builder: (context, taskSnapshot) {
          return StreamBuilder<DebtState>(
            stream: widget.debtBloc.state,
            initialData: widget.debtBloc.currentState,
            builder: (context, debtSnapshot) {
              final taskState = taskSnapshot.data;
              final debtState = debtSnapshot.data;

              final List<Item> tasks = (taskState is TaskLoaded) ? taskState.tasks : [];
              final List<Debt> debts = (debtState is DebtLoaded) ? debtState.debts : [];

              Widget currentTabBody;
              switch (_navIndex) {
                case 0:
                  currentTabBody = _buildTodayView(tasks, debts);
                  break;
                case 1:
                  currentTabBody = _buildTasksTab(tasks);
                  break;
                case 2:
                  currentTabBody = _buildDebtsTab(debts);
                  break;
                case 3:
                  currentTabBody = _buildMoreTab();
                  break;
                default:
                  currentTabBody = _buildTodayView(tasks, debts);
              }

              return Column(
                children: [
                  TodayHeader(
                    onSearchPressed: _openUnifiedSearch,
                    onSyncPressed: _triggerSync,
                    onLogoutPressed: _logout,
                  ),
                  Expanded(child: currentTabBody),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (index) => setState(() => _navIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'اليوم',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'المهام',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'الديون',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'المزيد',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQuickCapture,
        icon: const Icon(Icons.add),
        label: const Text('أضف شيئاً'),
      ),
    );
  }
}
