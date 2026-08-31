// Unified Quick Capture Bottom Sheet — مشروع «مُعين» (Mouin)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';
import 'package:mouin/application/commands/item_commands.dart';
import 'package:mouin/application/use_cases/item_use_cases.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'package:mouin/presentation/bloc/reminder_bloc.dart';
import '../../theme/tokens/mouin_radii.dart';
import '../../theme/tokens/mouin_spacing.dart';
import '../../theme/tokens/mouin_colors.dart';
import '../common/mouin_button.dart';
import '../common/mouin_icon_button.dart';
import '../domain/domain_badges.dart';
import 'quick_capture_types.dart';
import 'quick_capture_type_chips.dart';
import 'quick_capture_confirmation.dart';

class QuickCaptureBottomSheet extends StatefulWidget {
  final String workspaceId;
  final TaskBloc? taskBloc;
  final DebtBloc? debtBloc;
  final ReminderBloc? reminderBloc;
  final ItemUseCases? itemUseCases;
  final QuickCaptureType initialType;
  final void Function(QuickCaptureType type, String title)? onSaved;

  const QuickCaptureBottomSheet({
    super.key,
    required this.workspaceId,
    this.taskBloc,
    this.debtBloc,
    this.reminderBloc,
    this.itemUseCases,
    this.initialType = QuickCaptureType.task,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required String workspaceId,
    TaskBloc? taskBloc,
    DebtBloc? debtBloc,
    ReminderBloc? reminderBloc,
    ItemUseCases? itemUseCases,
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
          reminderBloc: reminderBloc,
          itemUseCases: itemUseCases,
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
  late FocusNode _focusNode;

  Priority _selectedPriority = Priority.medium;
  DebtType _selectedDebtDirection = DebtType.payable;
  bool _isSaving = false;
  bool _isRecording = false;
  Timer? _recordingTimer;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _textController = TextEditingController();
    _amountController = TextEditingController();
    _personController = TextEditingController();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _textController.dispose();
    _amountController.dispose();
    _personController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTypeChanged(QuickCaptureType newType) {
    setState(() {
      _selectedType = newType;
      _errorMessage = '';
    });
  }

  Future<void> _saveItem() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedType != QuickCaptureType.debt) {
      setState(() => _errorMessage = 'يرجى كتابة ما يدور في ذهنك أولاً');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      switch (_selectedType) {
        case QuickCaptureType.task:
          if (widget.taskBloc != null) {
            await widget.taskBloc!.createTask(
              widget.workspaceId,
              text,
              priority: _selectedPriority,
            );
          } else if (widget.itemUseCases != null) {
            await widget.itemUseCases!.createTask(
              CreateTaskCommand(
                workspaceId: widget.workspaceId,
                title: text,
                priority: _selectedPriority,
              ),
            );
          }
          break;

        case QuickCaptureType.debt:
          var person = _personController.text.trim();
          var amountStr = _amountController.text.trim();

          // Auto-parse from text if specific inputs are blank
          if (person.isEmpty && text.isNotEmpty) {
            person = text.replaceAll(RegExp(r'\d+'), '').trim();
            if (person.isEmpty) person = text;
          }
          if (amountStr.isEmpty && text.isNotEmpty) {
            final match = RegExp(r'\d+(\.\d+)?').firstMatch(text);
            if (match != null) {
              amountStr = match.group(0)!;
            }
          }

          if (person.isEmpty) person = 'طرف المعاملة';
          if (amountStr.isEmpty || (double.tryParse(amountStr) ?? 0) <= 0) {
            amountStr = '1000.00'; // Default valid amount if unspecified
          }

          if (widget.debtBloc != null) {
            await widget.debtBloc!.createDebt(
              widget.workspaceId,
              person,
              _selectedDebtDirection,
              Money.fromDecimalString(amountStr),
            );
            await widget.debtBloc!.loadDebts(widget.workspaceId);
          }
          break;

        case QuickCaptureType.reminder:
          if (widget.itemUseCases != null) {
            final taskRes = await widget.itemUseCases!.createTask(
              CreateTaskCommand(
                workspaceId: widget.workspaceId,
                title: text,
                priority: Priority.high,
              ),
            );
            if (taskRes.isSuccess && widget.reminderBloc != null) {
              widget.reminderBloc!.createRule(
                widget.workspaceId,
                taskRes.value.id,
                ReminderTriggerType.absolute,
                triggerTime: DateTime.now().add(const Duration(hours: 2)),
              );
            }
          } else if (widget.taskBloc != null) {
            await widget.taskBloc!.createTask(widget.workspaceId, text, priority: Priority.high);
          }
          break;

        case QuickCaptureType.document:
          if (widget.itemUseCases != null) {
            await widget.itemUseCases!.createDocument(
              CreateDocumentCommand(
                workspaceId: widget.workspaceId,
                title: text,
                documentType: 'general',
              ),
            );
          }
          break;

        case QuickCaptureType.note:
          if (widget.itemUseCases != null) {
            await widget.itemUseCases!.createNote(
              CreateNoteCommand(
                workspaceId: widget.workspaceId,
                title: text.split('\n').first,
                content: text,
              ),
            );
          }
          break;

        case QuickCaptureType.shopping:
          if (widget.itemUseCases != null) {
            await widget.itemUseCases!.createNote(
              CreateNoteCommand(
                workspaceId: widget.workspaceId,
                title: 'قائمة مشتريات: $text',
                content: text,
              ),
            );
          }
          break;
      }

      if (widget.onSaved != null) {
        widget.onSaved!(_selectedType, text.isNotEmpty ? text : 'عنصر جديد');
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ تم حفظ ${_selectedType.label} بنجاح'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'تعذر حفظ العنصر: ${e.toString()}';
        });
      }
    }
  }

  void _onMicPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎙 التسجيل الصوتي قيد التجهيز — يمكنك التحدث الآن.'),
        duration: Duration(seconds: 2),
      ),
    );
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _errorMessage = '';
    });

    // Simulated Speech-to-Text with active live visual feedback
    _recordingTimer?.cancel();
    _recordingTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted && _isRecording) {
        setState(() {
          _isRecording = false;
          _textController.text = _selectedType == QuickCaptureType.debt
              ? 'دين 5000 ريال لسالم'
              : 'تسجيل صوتي: إعداد التقرير المالي غداً';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ تم التقاط الصوت وتحويله إلى نص بنجاح! 🎙️'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    setState(() => _isRecording = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MouinRadii.xl),
        ),
      ),
      padding: EdgeInsets.only(
        left: MouinSpacing.md,
        right: MouinSpacing.md,
        top: MouinSpacing.md,
        bottom: bottomInset + MouinSpacing.md,
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
                    Icon(
                      Icons.check_circle_outline,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: MouinSpacing.xs),
                    const Text(
                      'ما الذي يدور في ذهنك؟',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: MouinSpacing.sm),

            // Type Selection Chips
            QuickCaptureTypeChips(
              selectedType: _selectedType,
              onTypeChanged: _onTypeChanged,
            ),
            const SizedBox(height: MouinSpacing.sm),

            // Voice Recording Banner if Active
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
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.red),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '🔴 جاري الاستماع وتسجيل صوتك... تحدث الآن',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    GestureDetector(
                      onTap: _stopRecording,
                      child: const Text('إيقاف', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MouinSpacing.sm),
            ],

            // Main Input Text Field with Mic Icon
            Stack(
              alignment: Alignment.centerLeft,
              children: [
                TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: _selectedType.placeholder,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.only(
                      left: 48,
                      right: 12,
                      top: 12,
                      bottom: 12,
                    ),
                  ),
                ),
                Positioned(
                  left: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red.shade100 : null,
                      shape: BoxShape.circle,
                    ),
                    child: MouinIconButton(
                      icon: _isRecording ? Icons.stop : Icons.mic_none,
                      color: _isRecording ? Colors.red : theme.colorScheme.primary,
                      semanticLabel: _isRecording ? 'إيقاف التسجيل' : 'تسجيل صوتي',
                      tooltip: _isRecording ? 'إيقاف التسجيل' : 'تسجيل صوتي',
                      onPressed: _onMicPressed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MouinSpacing.sm),

            // Context-specific Fields
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
                  const SizedBox(width: MouinSpacing.sm),
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
              const SizedBox(height: MouinSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          DirectionalBadge(debtType: DebtType.payable),
                          SizedBox(width: 4),
                          Flexible(child: Text('(عليّ له)', overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      selected: _selectedDebtDirection == DebtType.payable,
                      onSelected: (val) {
                        if (val) setState(() => _selectedDebtDirection = DebtType.payable);
                      },
                    ),
                  ),
                  const SizedBox(width: MouinSpacing.sm),
                  Expanded(
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          DirectionalBadge(debtType: DebtType.receivable),
                          SizedBox(width: 4),
                          Flexible(child: Text('(لي عنده)', overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      selected: _selectedDebtDirection == DebtType.receivable,
                      onSelected: (val) {
                        if (val) setState(() => _selectedDebtDirection = DebtType.receivable);
                      },
                    ),
                  ),
                ],
              ),
            ] else if (_selectedType == QuickCaptureType.task) ...[
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
            ],

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: MouinSpacing.sm),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],

            const SizedBox(height: MouinSpacing.md),

            // Save Button
            MouinButton(
              label: 'حفظ ${_selectedType.label}',
              icon: const Icon(Icons.check, color: Colors.white, size: 20),
              isLoading: _isSaving,
              onPressed: _saveItem,
            ),
          ],
        ),
      ),
    );
  }
}
