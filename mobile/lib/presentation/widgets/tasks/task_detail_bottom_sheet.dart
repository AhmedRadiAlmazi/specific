// Task Detail & Edit Bottom Sheet — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/core/services/voice_recorder_service.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';

class TaskDetailBottomSheet extends StatefulWidget {
  final Item task;
  final String workspaceId;
  final TaskBloc taskBloc;

  const TaskDetailBottomSheet({
    super.key,
    required this.task,
    required this.workspaceId,
    required this.taskBloc,
  });

  static Future<void> show(
    BuildContext context, {
    required Item task,
    required String workspaceId,
    required TaskBloc taskBloc,
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
  DateTime? _dueDate;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _summaryController = TextEditingController(text: widget.task.summary ?? '');
    _selectedPriority = widget.task.priority;
    _isCompleted = widget.task.isCompleted;
    _dueDate = widget.task.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    final path = widget.task.voiceFilePath;
    if (path == null) return;
    if (_isPlayingAudio) {
      await VoiceRecorderService.stopAudio();
      setState(() => _isPlayingAudio = false);
    } else {
      setState(() => _isPlayingAudio = true);
      final ok = await VoiceRecorderService.playAudio(path);
      if (!ok && mounted) setState(() => _isPlayingAudio = false);
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? now),
      );
      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    final updated = widget.task.copyWith(
      title: _titleController.text.trim(),
      summary: _summaryController.text.trim().isNotEmpty ? _summaryController.text.trim() : null,
      priority: _selectedPriority,
      isCompleted: _isCompleted,
      dueDate: _dueDate,
    );
    await widget.taskBloc.updateTask(widget.workspaceId, updated);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ تم حفظ تعديلات المهمة والتنبيه بنجاح')),
      );
    }
  }

  Future<void> _deleteTask() async {
    await widget.taskBloc.deleteTask(widget.workspaceId, widget.task.id);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ تم حذف المهمة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('تفاصيل وتعديل المهمة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _deleteTask),
              ],
            ),
            const SizedBox(height: 8),

            // Voice Memo Playback Banner if task has voice recording
            if (widget.task.voiceFilePath != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Row(
                  children: [
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                      icon: Icon(_isPlayingAudio ? Icons.pause : Icons.play_arrow, color: Colors.white),
                      onPressed: _toggleAudio,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🎙️ التسجيل الصوتي المرفق بالمهمة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('اضغط للاستماع إلى المقطع الصوتي الخاص بك', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'عنوان المهمة', prefixIcon: Icon(Icons.title)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _summaryController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'ملاحظات وتفاصيل إضافية', prefixIcon: Icon(Icons.notes)),
            ),
            const SizedBox(height: 12),

            // Priority Chips
            const Text('مستوى الأولوية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: Priority.values.map((p) {
                  final isSelected = p == _selectedPriority;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(p.arabicLabel),
                      selected: isSelected,
                      selectedColor: Color(p.colorValue).withOpacity(0.2),
                      onSelected: (v) {
                        if (v) setState(() => _selectedPriority = p);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Date & Reminder Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alarm, color: Color(0xFF0D9488)),
              title: Text(
                _dueDate != null
                    ? 'التنبيه: ${_dueDate!.year}/${_dueDate!.month}/${_dueDate!.day} الساعة ${_dueDate!.hour}:${_dueDate!.minute.toString().padLeft(2, '0')}'
                    : 'تحديد موعد للتنبيه والتذكير',
                style: const TextStyle(fontSize: 13),
              ),
              trailing: TextButton(
                onPressed: _pickDateTime,
                child: Text(_dueDate != null ? 'تغيير' : 'ضبط'),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check),
              label: const Text('حفظ التعديلات والتنبيه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: _saveChanges,
            ),
          ],
        ),
      ),
    );
  }
}
