// Unified Quick Capture Bottom Sheet — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';
import 'package:mouin/application/commands/item_commands.dart';
import 'package:mouin/application/use_cases/item_use_cases.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'package:mouin/presentation/bloc/reminder_bloc.dart';
import '../../theme/tokens/mouin_dimens.dart';
import '../../theme/tokens/mouin_radii.dart';
import '../../theme/tokens/mouin_spacing.dart';
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
  final void Function(QuickCaptureType type, String title)? onSaved;

  const QuickCaptureBottomSheet({
    super.key,
    required this.workspaceId,
    this.taskBloc,
    this.debtBloc,
    this.reminderBloc,
    this.itemUseCases,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required String workspaceId,
    TaskBloc? taskBloc,
    DebtBloc? debtBloc,
    ReminderBloc? reminderBloc,
    ItemUseCases? itemUseCases,
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
          onSaved: onSaved,
        ),
      ),
    );
  }

  @override
  State<QuickCaptureBottomSheet> createState() => _QuickCaptureBottomSheetState();
}

class _QuickCaptureBottomSheetState extends State<QuickCaptureBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();

  QuickCaptureType _selectedType = QuickCaptureType.task;
  Priority _selectedPriority = Priority.medium;
  DebtType _selectedDebtDirection = DebtType.payable;
  bool _isSaving = false;
  bool _showConfirmation = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _amountController.dispose();
    _personController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text;
    if (text.length >= 3 && !_showConfirmation) {
      final suggested = QuickCaptureSuggestor.suggestType(text);
      if (suggested != _selectedType) {
        setState(() => _selectedType = suggested);
      }
    }
  }

  Future<void> _handleSave() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
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
            widget.taskBloc!.createTask(
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
          final person = _personController.text.trim().isNotEmpty
              ? _personController.text.trim()
              : text;
          final amountStr = _amountController.text.trim().isNotEmpty
              ? _amountController.text.trim()
              : '0.00';

          if (widget.debtBloc != null) {
            widget.debtBloc!.createDebt(
              widget.workspaceId,
              person,
              _selectedDebtDirection,
              Money.fromDecimalString(amountStr),
            );
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
            widget.taskBloc!.createTask(widget.workspaceId, text, priority: Priority.high);
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
        widget.onSaved!(_selectedType, text);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ تم حفظ ${_selectedType.label} بنجاح محلياً'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'إغلاق',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'تعذر حفظ العنصر محلياً: ${e.toString()}';
        });
      }
    }
  }

  void _onMicPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎙 التسجيل الصوتي قيد التجهيز — يمكنك الكتابة بحرية الآن.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: MouinRadii.radiusXl),
      ),
      padding: EdgeInsets.only(
        top: MouinSpacing.md,
        left: MouinSpacing.md,
        right: MouinSpacing.md,
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
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: MouinRadii.borderPill,
                ),
              ),
            ),
            const SizedBox(height: MouinSpacing.md),

            // Header & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_selectedType.icon, color: theme.colorScheme.primary),
                    const SizedBox(width: MouinSpacing.sm),
                    Text(
                      'ما الذي يدور في ذهنك؟',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                MouinIconButton(
                  icon: Icons.close,
                  semanticLabel: 'إغلاق نافذة الإدخال السريع',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: MouinSpacing.sm),

            // Type Chips Row
            QuickCaptureTypeChips(
              selectedType: _selectedType,
              onTypeChanged: (type) => setState(() => _selectedType = type),
            ),
            const SizedBox(height: MouinSpacing.md),

            // Main Text Input Area with Mic
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                TextField(
                  controller: _textController,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(
                    hintText: _selectedType.placeholder,
                    contentPadding: const EdgeInsets.only(
                      top: MouinSpacing.md,
                      right: MouinSpacing.md,
                      left: 54.0, // Space for mic icon
                      bottom: MouinSpacing.md,
                    ),
                  ),
                ),
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: MouinIconButton(
                    icon: Icons.mic_none,
                    color: theme.colorScheme.primary,
                    semanticLabel: 'تسجيل صوتي ذكي',
                    tooltip: 'تسجيل صوتي',
                    onPressed: _onMicPressed,
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
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DirectionalBadge(debtType: DebtType.payable),
                          SizedBox(width: 4),
                          Text('(عليّ له)'),
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
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DirectionalBadge(debtType: DebtType.receivable),
                          SizedBox(width: 4),
                          Text('(لي عنده)'),
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
              Row(
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
            ],

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: MouinSpacing.sm),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],

            const SizedBox(height: MouinSpacing.md),

            // Confirmation or Save Action
            if (_showConfirmation) ...[
              QuickCaptureConfirmation(
                title: _textController.text.trim(),
                type: _selectedType,
                subtitle: _selectedType == QuickCaptureType.debt
                    ? 'المبلغ: ${_amountController.text} YER'
                    : 'الأولوية: ${_selectedPriority.name}',
                onEdit: () => setState(() => _showConfirmation = false),
                onSave: _handleSave,
              ),
            ] else ...[
              MouinButton(
                label: _isSaving ? 'جاري الحفظ محلياً...' : 'حفظ ${_selectedType.label}',
                isLoading: _isSaving,
                icon: const Icon(Icons.check),
                onPressed: _handleSave,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
