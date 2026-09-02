// Main Home Dashboard Page — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/core/services/voice_recorder_service.dart';
import 'package:mouin/core/theme/app_colors.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'package:mouin/presentation/bloc/sync_bloc.dart';
import 'package:mouin/presentation/pages/debts/debts_page.dart';
import 'package:mouin/presentation/widgets/brand/mouin_logo.dart';
import 'package:mouin/presentation/widgets/quick_capture/quick_capture_bottom_sheet.dart';
import 'package:mouin/presentation/widgets/quick_capture/quick_capture_types.dart';
import 'package:mouin/presentation/widgets/tasks/task_detail_bottom_sheet.dart';

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
    required this.workspaceId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String? _currentlyPlayingVoicePath;

  @override
  void initState() {
    super.initState();
    widget.taskBloc.loadTasks(widget.workspaceId);
    widget.debtBloc.loadDebts(widget.workspaceId);
  }

  void _openQuickCapture() {
    QuickCaptureBottomSheet.show(
      context,
      workspaceId: widget.workspaceId,
      taskBloc: widget.taskBloc,
      debtBloc: widget.debtBloc,
      initialType: _currentIndex == 1 ? QuickCaptureType.debt : QuickCaptureType.task,
      onSaved: (_, __) {
        widget.taskBloc.loadTasks(widget.workspaceId);
        widget.debtBloc.loadDebts(widget.workspaceId);
      },
    );
  }

  Future<void> _playVoice(String path) async {
    if (_currentlyPlayingVoicePath == path) {
      await VoiceRecorderService.stopAudio();
      setState(() => _currentlyPlayingVoicePath = null);
    } else {
      setState(() => _currentlyPlayingVoicePath = path);
      final ok = await VoiceRecorderService.playAudio(path);
      if (!ok && mounted) setState(() => _currentlyPlayingVoicePath = null);
    }
  }

  Widget _buildTasksList(List<Item> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.task_alt_rounded, size: 48, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              const Text('لا توجد مهام حالية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
              const SizedBox(height: 8),
              const Text(
                'اضغط على زر الإضافة السريع لتسجيل مهمة، مقطع صوتي أو دين جديد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('أضف أول مهمة الآن'),
                onPressed: _openQuickCapture,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: tasks.length,
      itemBuilder: (ctx, index) {
        final task = tasks[index];
        final isPlaying = _currentlyPlayingVoicePath == task.voiceFilePath;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => TaskDetailBottomSheet.show(
              context,
              task: task,
              workspaceId: widget.workspaceId,
              taskBloc: widget.taskBloc,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Checkbox(
                    value: task.isCompleted,
                    activeColor: AppColors.primary,
                    onChanged: (_) => widget.taskBloc.completeTask(widget.workspaceId, task.id),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted ? AppColors.textMutedLight : AppColors.textPrimaryLight,
                          ),
                        ),
                        if (task.dueDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.alarm_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${task.dueDate!.hour}:${task.dueDate!.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (task.voiceFilePath != null)
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: AppColors.primary, size: 30),
                      onPressed: () => _playVoice(task.voiceFilePath!),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Color(task.priority.colorValue).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      task.priority.arabicLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(task.priority.colorValue)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const MouinLogo(
              size: MouinLogoSize.small,
              showText: false,
              showSubtitle: false,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('مساء الخير، أحمد! 🌤️', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('مُعين — مساعدك الشخصي الذكي', style: TextStyle(fontSize: 11, color: Color(0xFFA7F3D0))),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'مزامنة فورية',
            onPressed: () {
              widget.taskBloc.loadTasks(widget.workspaceId);
              widget.debtBloc.loadDebts(widget.workspaceId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primaryDark,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  content: Row(
                    children: const [
                      Icon(Icons.check_circle, color: AppColors.financeMint, size: 20),
                      SizedBox(width: 8),
                      Text('تمت المزامنة وتحديث البيانات بنجاح'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _openQuickCapture,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('إضافة سريعة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline_rounded),
            selectedIcon: Icon(Icons.check_circle_rounded),
            label: 'المهام',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'الديون والمستحقات',
          ),
        ],
      ),
      body: _currentIndex == 0
          ? StreamBuilder<TaskState>(
              stream: widget.taskBloc.state,
              initialData: widget.taskBloc.currentState,
              builder: (ctx, snap) {
                final tasks = (snap.data is TaskLoaded) ? (snap.data as TaskLoaded).tasks : <Item>[];
                return _buildTasksList(tasks);
              },
            )
          : DebtsPage(debtBloc: widget.debtBloc, workspaceId: widget.workspaceId),
    );
  }
}
