// Task Detail and Edit BottomSheet — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';
import 'package:mouin/presentation/bloc/reminder_bloc.dart';
import '../../theme/tokens/mouin_colors.dart';
import '../../theme/tokens/mouin_spacing.dart';
import '../../theme/tokens/mouin_radii.dart';
import '../common/mouin_button.dart';
import '../domain/domain_badges.dart';

class TaskDetailBottomSheet extends StatefulWidget {
  final Item task;
  final String workspaceId;
  final TaskBloc taskBloc;
  final ReminderBloc? reminderBloc;

  const TaskDetailBottomSheet({
    super.key,
    required this.task,
    required this.workspaceId,
    required this.taskBloc,
    this.reminderBloc,
  });

  static Future<void> show(
    BuildContext context, {
    required Item task,
    required String workspaceId,
    required TaskBloc taskBloc,
    ReminderBloc? reminderBloc,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: TaskDetailBottomSheet(
          task: task,
          workspaceId: workspaceId,
          taskBloc: taskBloc,
          reminderBloc: reminderBloc,
        ),
      ),
    );
  }

  @override
  State<TaskDetailBottomSheet> createState() => _TaskDetailBottomSheetState();
}

class _TaskDetailBottomSheetState extends State<TaskDetailBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late Priority _selectedPriority;
  late bool _isCompleted;
  DateTime? _selectedDueDate;
  String _selectedAlertPreset = 'none'; // 'none', '1h', 'tomorrow_morning', 'custom'

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _summaryController = TextEditingController(text: widget.task.summary ?? '');
    _selectedPriority = widget.task.taskDetail?.priority ?? Priority.medium;
    _isCompleted = widget.task.taskDetail?.status == TaskStatus.completed;
    _selectedDueDate = widget.task.taskDetail?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    widget.taskBloc.updateTask(
      widget.workspaceId,
      widget.task.id,
      title: title,
      summary: _summaryController.text.trim().isNotEmpty ? _summaryController.text.trim() : null,
      priority: _selectedPriority,
      dueDate: _selectedDueDate,
      status: _isCompleted ? TaskStatus.completed : TaskStatus.pending,
    );

    if (_selectedDueDate != null && widget.reminderBloc != null) {
      widget.reminderBloc!.createRule(
        widget.workspaceId,
        widget.task.id,
        ReminderTriggerType.absolute,
        triggerTime: _selectedDueDate,
      );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ تم حفظ تعديلات المهمة والتنبيه بنجاح'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteTask() {
    widget.taskBloc.deleteTask(widget.workspaceId, widget.task.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ تم حذف المهمة بنجاح'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickCustomDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDueDate ?? now.add(const Duration(hours: 1))),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _selectedAlertPreset = 'custom';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(MouinRadii.xl)),
      ),
      padding: EdgeInsets.only(
        left: MouinSpacing.lg,
        right: MouinSpacing.lg,
        top: MouinSpacing.md,
        bottom: bottomInset + MouinSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: MouinSpacing.md),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note, color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'تفاصيل وتعديل المهمة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: MouinColors.error),
                  tooltip: 'حذف المهمة',
                  onPressed: _deleteTask,
                ),
              ],
            ),
            const SizedBox(height: MouinSpacing.md),

            // Title Field
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'عنوان المهمة',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: MouinSpacing.sm),

            // Summary Field
            TextField(
              controller: _summaryController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'ملاحظات أو تفاصيل إضافية',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: MouinSpacing.md),

            // Status Checkbox
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_isCompleted ? 'المهمة مكتملة ومغلقة' : 'المهمة قيد التنفيذ'),
              value: _isCompleted,
              activeColor: MouinColors.success,
              onChanged: (val) => setState(() => _isCompleted = val ?? false),
            ),
            const SizedBox(height: MouinSpacing.sm),

            // Priority Selection
            const Text(
              'مستوى الأولوية:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: Priority.values.map((p) {
                  final isSelected = p == _selectedPriority;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: PriorityBadge(priority: p),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedPriority = p);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: MouinSpacing.md),

            // Alert / Reminder Settings
            const Text(
              'ضبط وقت التنبيه والتذكير:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('بدون تنبيه'),
                  selected: _selectedDueDate == null,
                  onSelected: (val) {
                    if (val) setState(() => _selectedDueDate = null);
                  },
                ),
                ChoiceChip(
                  label: const Text('بعد ساعة ⏱️'),
                  selected: _selectedAlertPreset == '1h',
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedAlertPreset = '1h';
                        _selectedDueDate = DateTime.now().add(const Duration(hours: 1));
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('غداً 9:00 ص 🌅'),
                  selected: _selectedAlertPreset == 'tomorrow_morning',
                  onSelected: (val) {
                    if (val) {
                      final now = DateTime.now();
                      setState(() {
                        _selectedAlertPreset = 'tomorrow_morning';
                        _selectedDueDate = DateTime(now.year, now.month, now.day + 1, 9, 0);
                      });
                    }
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.access_time, size: 16),
                  label: Text(_selectedDueDate != null && _selectedAlertPreset == 'custom'
                      ? '📅 ${_selectedDueDate!.day}/${_selectedDueDate!.month} ${_selectedDueDate!.hour}:${_selectedDueDate!.minute.toString().padLeft(2, '0')}'
                      : 'تحديد وقت مخصص...'),
                  onPressed: _pickCustomDateTime,
                ),
              ],
            ),
            const SizedBox(height: MouinSpacing.lg),

            // Save Button
            MouinButton(
              label: 'حفظ التعديلات والتنبيه',
              icon: const Icon(Icons.check, color: Colors.white, size: 20),
              onPressed: _saveChanges,
            ),
          ],
        ),
      ),
    );
  }
}
