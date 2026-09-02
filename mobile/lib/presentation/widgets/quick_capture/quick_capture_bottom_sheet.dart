// Unified Quick Capture Bottom Sheet with Live Voice Recording — مشروع «مُعين» (Mouin)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mouin/core/ai/arabic_text_parser.dart';
import 'package:mouin/core/services/voice_recorder_service.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'quick_capture_types.dart';

class QuickCaptureBottomSheet extends StatefulWidget {
  final String workspaceId;
  final TaskBloc? taskBloc;
  final DebtBloc? debtBloc;
  final QuickCaptureType initialType;
  final void Function(QuickCaptureType type, String title)? onSaved;

  const QuickCaptureBottomSheet({
    super.key,
    required this.workspaceId,
    this.taskBloc,
    this.debtBloc,
    this.initialType = QuickCaptureType.task,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required String workspaceId,
    TaskBloc? taskBloc,
    DebtBloc? debtBloc,
    QuickCaptureType initialType = QuickCaptureType.task,
    void Function(QuickCaptureType type, String title)? onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: QuickCaptureBottomSheet(
          workspaceId: workspaceId,
          taskBloc: taskBloc,
          debtBloc: debtBloc,
          initialType: initialType,
          onSaved: onSaved,
        ),
      ),
    );
  }

  @override
  State<QuickCaptureBottomSheet> createState() => _QuickCaptureBottomSheetState();
}

class _QuickCaptureBottomSheetState extends State<QuickCaptureBottomSheet> {
  late QuickCaptureType _selectedType;
  late TextEditingController _textController;
  late TextEditingController _amountController;
  late TextEditingController _personController;

  Priority _selectedPriority = Priority.medium;
  DebtType _selectedDebtDirection = DebtType.payable;
  bool _isSaving = false;
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  VoiceRecordingResult? _recordedVoice;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _textController = TextEditingController();
    _amountController = TextEditingController();
    _personController = TextEditingController();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    _amountController.dispose();
    _personController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    await VoiceRecorderService.startRecording();
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _recordedVoice = null;
      _errorMessage = '';
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && _isRecording) {
        setState(() => _recordingSeconds++);
      }
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final result = await VoiceRecorderService.stopRecording();
    setState(() {
      _isRecording = false;
      _recordedVoice = result;
    });

    if (result != null && _textController.text.trim().isEmpty) {
      setState(() {
        _textController.text = 'ملاحظة صوتية مسجلة (${result.formattedDuration})';
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ تم تسجيل المقطع الصوتي بنجاح (${result?.formattedDuration ?? "جاهز"}) 🎙️'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleAudioPlayback() async {
    if (_recordedVoice == null) return;
    if (_isPlayingAudio) {
      await VoiceRecorderService.stopAudio();
      setState(() => _isPlayingAudio = false);
    } else {
      setState(() => _isPlayingAudio = true);
      final ok = await VoiceRecorderService.playAudio(_recordedVoice!.filePath);
      if (!ok && mounted) {
        setState(() => _isPlayingAudio = false);
      }
    }
  }

  Future<void> _saveItem() async {
    final rawText = _textController.text.trim();
    if (rawText.isEmpty && _recordedVoice == null && _selectedType != QuickCaptureType.debt) {
      setState(() => _errorMessage = 'يرجى كتابة نص أو تسجيل مقطع صوتي أولاً');
      return;
    }

    // Auto NLP Parsing
    final parsed = ArabicTextParser.parse(rawText.isNotEmpty ? rawText : 'تسجيل صوتي');

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      if (_selectedType == QuickCaptureType.debt) {
        var person = _personController.text.trim();
        var amountStr = _amountController.text.trim();

        if (person.isEmpty) person = parsed.personName ?? 'طرف المعاملة';
        if (amountStr.isEmpty) amountStr = parsed.amount ?? '1000.00';

        if (widget.debtBloc != null) {
          await widget.debtBloc!.createDebt(
            widget.workspaceId,
            person,
            _selectedDebtDirection,
            Money.fromDecimalString(amountStr),
          );
        }
      } else {
        final title = rawText.isNotEmpty ? rawText : 'مقطع صوتي مسجل';
        if (widget.taskBloc != null) {
          await widget.taskBloc!.createTask(
            widget.workspaceId,
            title,
            priority: _selectedPriority,
            dueDate: parsed.dueDate,
            voiceFilePath: _recordedVoice?.filePath,
            voiceDurationMs: _recordedVoice?.durationMs,
          );
        }
      }

      if (widget.onSaved != null) {
        widget.onSaved!(_selectedType, rawText);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ تم حفظ ${_selectedType.label} بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'تعذر الحفظ: $e';
        });
      }
    }
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: theme.colorScheme.primary, size: 24),
                    const SizedBox(width: 8),
                    const Text('ما الذي يدور في ذهنك؟', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 8),

            // Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: QuickCaptureType.values.map((t) {
                  final isSelected = t == _selectedType;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon, size: 16, color: isSelected ? Colors.white : null),
                          const SizedBox(width: 4),
                          Text(t.label),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF0D9488),
                      onSelected: (val) {
                        if (val) setState(() => _selectedType = t);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Live Recording Banner
            if (_isRecording) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '🔴 جاري تسجيل صوتك الآن... ${_formatTimer(_recordingSeconds)}',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: _stopRecording,
                      child: const Text('إيقاف وحفظ'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Recorded Audio Preview Card
            if (_recordedVoice != null) ...[
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
                      onPressed: _toggleAudioPlayback,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🎙️ مقطعك الصوتي المسجل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            'المدة: ${_recordedVoice!.formattedDuration}  •  الحجم: ${_recordedVoice!.formattedSize}',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        VoiceRecorderService.stopAudio();
                        setState(() {
                          _recordedVoice = null;
                          _isPlayingAudio = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Text Input with Mic Button
            Stack(
              alignment: Alignment.centerLeft,
              children: [
                TextField(
                  controller: _textController,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: _selectedType.placeholder,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.only(left: 48, right: 12, top: 12, bottom: 12),
                  ),
                ),
                Positioned(
                  left: 4,
                  child: IconButton(
                    icon: Icon(
                      _isRecording ? Icons.stop_circle : Icons.mic,
                      color: _isRecording ? Colors.red : const Color(0xFF0D9488),
                    ),
                    onPressed: _toggleRecording,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Debt extra fields
            if (_selectedType == QuickCaptureType.debt) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _personController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الشخص / الجهة',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ (YER)',
                        prefixIcon: Icon(Icons.money),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('🔴 عليّ له (دين)'),
                      selected: _selectedDebtDirection == DebtType.payable,
                      onSelected: (v) {
                        if (v) setState(() => _selectedDebtDirection = DebtType.payable);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('🟢 لي عنده (مطالبة)'),
                      selected: _selectedDebtDirection == DebtType.receivable,
                      onSelected: (v) {
                        if (v) setState(() => _selectedDebtDirection = DebtType.receivable);
                      },
                    ),
                  ),
                ],
              ),
            ],

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],

            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check),
              label: Text('حفظ ${_selectedType.label}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: _isSaving ? null : _saveItem,
            ),
          ],
        ),
      ),
    );
  }
}
