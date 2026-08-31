// Debts Ledger Dedicated Sub-Screen — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/domain/entities/debt.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import '../../theme/tokens/mouin_colors.dart';
import '../../theme/tokens/mouin_spacing.dart';
import '../../widgets/common/mouin_card.dart';
import '../../widgets/common/mouin_button.dart';
import '../../widgets/common/mouin_search_field.dart';
import '../../widgets/states/mouin_states.dart';
import '../../widgets/domain/domain_badges.dart';
import '../../widgets/quick_capture/quick_capture_bottom_sheet.dart';
import '../../widgets/quick_capture/quick_capture_types.dart';

class DebtsPage extends StatefulWidget {
  final DebtBloc debtBloc;
  final String workspaceId;
  final VoidCallback? onAddDebt;

  const DebtsPage({
    super.key,
    required this.debtBloc,
    required this.workspaceId,
    this.onAddDebt,
  });

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all'; // 'all', 'receivable', 'payable'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    widget.debtBloc.loadDebts(widget.workspaceId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddDebtSheet() {
    QuickCaptureBottomSheet.show(
      context,
      workspaceId: widget.workspaceId,
      debtBloc: widget.debtBloc,
      initialType: QuickCaptureType.debt,
      onSaved: (type, title) {
        widget.debtBloc.loadDebts(widget.workspaceId);
      },
    );
  }

  void _showRecordPaymentDialog(Debt debt) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final remaining = debt.calculateRemainingAmount();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تسجيل دفعة لـ ${debt.personId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المبلغ المتبقي: ${remaining.toDecimalString()} ${remaining.currency}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: MouinSpacing.sm),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع',
                prefixIcon: Icon(Icons.payment),
              ),
            ),
            const SizedBox(height: MouinSpacing.sm),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
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
              final amountStr = amountController.text.trim();
              if (amountStr.isNotEmpty) {
                final money = Money.fromDecimalString(amountStr, currency: debt.totalAmount.currency);
                widget.debtBloc.recordPayment(
                  widget.workspaceId,
                  debt.id,
                  money,
                  DateTime.now(),
                  notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ تم تسجيل الدفعة وتحديث الرصيد محلياً')),
                );
              }
            },
            child: const Text('تأكيد السداد'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<Debt> debts) {
    var totalReceivable = Money.zero();
    var totalPayable = Money.zero();

    for (final debt in debts) {
      final rem = debt.calculateRemainingAmount();
      if (debt.debtType == DebtType.receivable) {
        totalReceivable = totalReceivable.add(rem);
      } else {
        totalPayable = totalPayable.add(rem);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: MouinSpacing.xs),
      child: MouinCard(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🟢 لي عندهم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: MouinColors.debtReceivable)),
                  const SizedBox(height: 2),
                  MoneyDisplay(
                    amount: totalReceivable.toDecimalString(),
                    currency: totalReceivable.currency,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: MouinColors.debtReceivable),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 35, color: Colors.grey.shade300),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔴 عليّ لهم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: MouinColors.debtPayable)),
                  const SizedBox(height: 2),
                  MoneyDisplay(
                    amount: totalPayable.toDecimalString(),
                    currency: totalPayable.currency,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: MouinColors.debtPayable),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر الديون والالتزامات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'تسجيل دين',
            onPressed: widget.onAddDebt ?? _openAddDebtSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث الديون',
            onPressed: () => widget.debtBloc.loadDebts(widget.workspaceId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onAddDebt ?? _openAddDebtSheet,
        icon: const Icon(Icons.add),
        label: const Text('تسجيل دين'),
      ),
      body: StreamBuilder<DebtState>(
        stream: widget.debtBloc.state,
        initialData: widget.debtBloc.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data;

          if (state is DebtLoading) {
            return const MouinLoadingState(message: 'جاري تحميل سجل الديون...');
          } else if (state is DebtError) {
            return MouinErrorState(
              title: 'تعذر تحميل الديون',
              message: state.message,
              onRetry: () => widget.debtBloc.loadDebts(widget.workspaceId),
            );
          }

          final List<Debt> allDebts = (state is DebtLoaded) ? state.debts : [];

          if (allDebts.isEmpty) {
            return MouinEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'دفتر الديون نظيف ومكتمل!',
              subtitle: 'لا توجد ديون أو مطالبات مسجلة حالياً.',
              actionLabel: 'تسجيل دين جديد',
              onAction: widget.onAddDebt ?? _openAddDebtSheet,
            );
          }

          // Apply filters
          final filtered = allDebts.where((d) {
            if (_filter == 'receivable' && d.debtType != DebtType.receivable) return false;
            if (_filter == 'payable' && d.debtType != DebtType.payable) return false;
            if (_searchQuery.isNotEmpty && !d.personId.toLowerCase().contains(_searchQuery.toLowerCase())) {
              return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              _buildSummaryCard(allDebts),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: MouinSpacing.xs),
                child: MouinSearchField(
                  controller: _searchController,
                  hintText: 'بحث باسم الشخص أو الجهة...',
                  onChanged: (q) => setState(() => _searchQuery = q.trim()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('الكل (${allDebts.length})'),
                      selected: _filter == 'all',
                      onSelected: (val) => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('لي عندهم (${allDebts.where((d) => d.debtType == DebtType.receivable).length})'),
                      selected: _filter == 'receivable',
                      onSelected: (val) => setState(() => _filter = 'receivable'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('عليّ لهم (${allDebts.where((d) => d.debtType == DebtType.payable).length})'),
                      selected: _filter == 'payable',
                      onSelected: (val) => setState(() => _filter = 'payable'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MouinSpacing.xs),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('لا توجد ديون مطابقة لمعايير البحث'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (ctx, index) {
                          final debt = filtered[index];
                          final isReceivable = debt.debtType == DebtType.receivable;
                          final isSettled = debt.isSettled();
                          final remaining = debt.calculateRemainingAmount();

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: 4),
                            child: MouinCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isReceivable ? Icons.arrow_downward : Icons.arrow_upward,
                                            color: isReceivable ? MouinColors.debtReceivable : MouinColors.debtPayable,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            debt.personId,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      if (isSettled)
                                        const Chip(
                                          label: Text('مكتمل السداد', style: TextStyle(fontSize: 11, color: Colors.green)),
                                          backgroundColor: Color(0xFFDCFCE7),
                                        )
                                      else
                                        DirectionalBadge(debtType: debt.debtType),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'أصل الدين: ${debt.totalAmount.toDecimalString()} ${debt.totalAmount.currency}',
                                            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                          ),
                                          Row(
                                            children: [
                                              const Text('المتبقي: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              MoneyDisplay(
                                                amount: remaining.toDecimalString(),
                                                currency: remaining.currency,
                                                showDirectionColor: true,
                                                isPositive: isReceivable,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      MouinButton(
                                        label: 'سداد دفعة',
                                        type: MouinButtonType.secondary,
                                        onPressed: () => _showRecordPaymentDialog(debt),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
