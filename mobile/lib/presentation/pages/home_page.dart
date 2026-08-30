// Main Home Dashboard — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'package:mouin/presentation/bloc/sync_bloc.dart';

class HomePage extends StatefulWidget {
  final TaskBloc taskBloc;
  final DebtBloc debtBloc;
  final SyncBloc syncBloc;
  final String workspaceId;

  const HomePage({
    super.key,
    required this.taskBloc,
    required this.debtBloc,
    required this.syncBloc,
    this.workspaceId = '018e3a2b-0002-7000-8000-000000000002',
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    widget.taskBloc.loadTasks(widget.workspaceId);
    widget.debtBloc.loadDebts(widget.workspaceId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    Priority selectedPriority = Priority.medium;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة مهمة جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'عنوان المهمة',
                  hintText: 'مثال: شراء مواد بناء',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButton<Priority>(
                value: selectedPriority,
                isExpanded: true,
                items: Priority.values.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(_getPriorityLabel(p)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedPriority = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  widget.taskBloc.createTask(
                    widget.workspaceId,
                    title,
                    priority: selectedPriority,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDebtDialog() {
    final personController = TextEditingController();
    final amountController = TextEditingController();
    DebtType selectedDebtType = DebtType.payable;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تسجيل دين جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: personController,
                decoration: const InputDecoration(labelText: 'معرف الشخص أو الاسم'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ (YER)'),
              ),
              const SizedBox(height: 12),
              DropdownButton<DebtType>(
                value: selectedDebtType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: DebtType.payable, child: Text('عليّ دين (مستحق للدفع)')),
                  DropdownMenuItem(value: DebtType.receivable, child: Text('لي دين (مستحق للتحصيل)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedDebtType = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final person = personController.text.trim();
                final amountStr = amountController.text.trim();
                if (person.isNotEmpty && amountStr.isNotEmpty) {
                  widget.debtBloc.createDebt(
                    widget.workspaceId,
                    person,
                    selectedDebtType,
                    Money.fromDecimalString(amountStr),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  String _getPriorityLabel(Priority p) {
    switch (p) {
      case Priority.urgent: return 'عاجل جداً';
      case Priority.high: return 'أولوية عالية';
      case Priority.medium: return 'أولوية متوسطة';
      case Priority.low: return 'أولوية منخفضة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مُعين — المساعد الذكي دون اتصال'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.check_circle_outline), text: 'المهام'),
            Tab(icon: Icon(Icons.account_balance_wallet_outlined), text: 'الديون'),
            Tab(icon: Icon(Icons.alarm), text: 'التذكيرات'),
          ],
        ),
        actions: [
          StreamBuilder<SyncState>(
            stream: widget.syncBloc.state,
            initialData: widget.syncBloc.currentState,
            builder: (context, snapshot) {
              final state = snapshot.data;
              if (state is SyncInProgress) {
                return const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'مزامنة ثنائية الاتجاه',
                onPressed: () {
                  widget.syncBloc.triggerSync(widget.workspaceId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('بدأت المزامنة السحابية...')),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Tasks Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث عربي سريع (FTS5)...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              widget.taskBloc.loadTasks(widget.workspaceId);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (query) {
                    widget.taskBloc.searchTasks(widget.workspaceId, query);
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<TaskState>(
                  stream: widget.taskBloc.state,
                  initialData: widget.taskBloc.currentState,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    if (state is TaskLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is TaskEmpty) {
                      return const Center(
                        child: Text('لا توجد مهام حالياً. اضغط + لإضافة مهمة جديدة.'),
                      );
                    } else if (state is TaskLoaded) {
                      return ListView.builder(
                        itemCount: state.tasks.length,
                        itemBuilder: (ctx, index) {
                          final item = state.tasks[index];
                          final isCompleted = item.taskDetail?.status == TaskStatus.completed;
                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) {
                              widget.taskBloc.deleteTask(widget.workspaceId, item.id);
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: Checkbox(
                                  value: isCompleted,
                                  onChanged: (val) {
                                    if (val == true) {
                                      widget.taskBloc.completeTask(widget.workspaceId, item.id);
                                    }
                                  },
                                ),
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'الأولوية: ',
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else if (state is TaskError) {
                      return Center(
                        child: Text('حدث خطأ: ', style: const TextStyle(color: Colors.red)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),

          // 2. Debts Tab
          StreamBuilder<DebtState>(
            stream: widget.debtBloc.state,
            initialData: widget.debtBloc.currentState,
            builder: (context, snapshot) {
              final state = snapshot.data;
              if (state is DebtLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is DebtEmpty) {
                return const Center(child: Text('لا توجد ديون مسجلة.'));
              } else if (state is DebtLoaded) {
                return ListView.builder(
                  itemCount: state.debts.length,
                  itemBuilder: (ctx, index) {
                    final debt = state.debts[index];
                    final remaining = debt.calculateRemainingAmount();
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          debt.debtType == DebtType.payable ? Icons.arrow_upward : Icons.arrow_downward,
                          color: debt.debtType == DebtType.payable ? Colors.red : Colors.green,
                        ),
                        title: Text('الشخص: ${debt.personId}'),
                        subtitle: Text('المبلغ الإجمالي: ${debt.totalAmount}\nالمتبقي: $remaining'),
                        trailing: Text(
                          debt.status.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                );
              } else if (state is DebtError) {
                return Center(child: Text('خطأ: ', style: const TextStyle(color: Colors.red)));
              }
              return const SizedBox.shrink();
            },
          ),

          // 3. Reminders Tab
          const Center(
            child: Text('نظام التذكيرات المستقل نشط ويعمل بآلية occurrence_key.'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddTaskDialog();
          } else if (_tabController.index == 1) {
            _showAddDebtDialog();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
