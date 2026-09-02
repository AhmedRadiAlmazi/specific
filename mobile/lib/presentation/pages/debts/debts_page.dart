// Debts Ledger Page — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/core/theme/app_colors.dart';
import 'package:mouin/domain/entities/debt.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'package:mouin/presentation/widgets/quick_capture/quick_capture_bottom_sheet.dart';
import 'package:mouin/presentation/widgets/quick_capture/quick_capture_types.dart';

class DebtsPage extends StatefulWidget {
  final DebtBloc debtBloc;
  final String workspaceId;

  const DebtsPage({super.key, required this.debtBloc, required this.workspaceId});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    widget.debtBloc.loadDebts(widget.workspaceId);
  }

  void _openAddDebt() {
    QuickCaptureBottomSheet.show(
      context,
      workspaceId: widget.workspaceId,
      debtBloc: widget.debtBloc,
      initialType: QuickCaptureType.debt,
      onSaved: (_, __) => widget.debtBloc.loadDebts(widget.workspaceId),
    );
  }

  void _showRecordPayment(Debt debt) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('سداد دفعة لـ ${debt.personId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'المبلغ المدفوع (YER)', prefixIcon: Icon(Icons.payment_rounded)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondaryLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                widget.debtBloc.recordPayment(
                  widget.workspaceId,
                  debt.id,
                  Money.fromDecimalString(text),
                  DateTime.now(),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('تأكيد السداد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر الديون والالتزامات'),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), tooltip: 'تسجيل دين', onPressed: _openAddDebt),
          IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: 'تحديث', onPressed: () => widget.debtBloc.loadDebts(widget.workspaceId)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _openAddDebt,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('تسجيل دين', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DebtState>(
        stream: widget.debtBloc.state,
        initialData: widget.debtBloc.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data;
          final List<Debt> debts = (state is DebtLoaded) ? state.debts : [];

          if (debts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: AppColors.goldAccentLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.account_balance_wallet_rounded, size: 48, color: AppColors.goldDark),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('دفتر الديون نظيف ومكتمل!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
                    const SizedBox(height: 8),
                    const Text(
                      'لا توجد ديون أو مطالبات مسجلة حالياً.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
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
                      label: const Text('تسجيل أول دين'),
                      onPressed: _openAddDebt,
                    ),
                  ],
                ),
              ),
            );
          }

          final filtered = debts.where((d) {
            if (_filter == 'receivable') return d.debtType == DebtType.receivable;
            if (_filter == 'payable') return d.debtType == DebtType.payable;
            return true;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('الكل (${debts.length})'),
                      selected: _filter == 'all',
                      selectedColor: AppColors.primarySubtle,
                      onSelected: (_) => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('لي عندهم (${debts.where((d) => d.debtType == DebtType.receivable).length})'),
                      selected: _filter == 'receivable',
                      selectedColor: AppColors.financeMintLight,
                      onSelected: (_) => setState(() => _filter = 'receivable'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('عليّ لهم (${debts.where((d) => d.debtType == DebtType.payable).length})'),
                      selected: _filter == 'payable',
                      selectedColor: AppColors.urgentLight,
                      onSelected: (_) => setState(() => _filter = 'payable'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final d = filtered[idx];
                    final isReceivable = d.debtType == DebtType.receivable;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isReceivable ? AppColors.financeMintLight : AppColors.urgentLight,
                          child: Icon(
                            isReceivable ? Icons.south_west_rounded : Icons.north_east_rounded,
                            color: isReceivable ? AppColors.financeMint : AppColors.urgent,
                          ),
                        ),
                        title: Text(d.personId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text(
                          isReceivable ? 'مطلوب منه: ${d.totalAmount}' : 'مستحق له: ${d.totalAmount}',
                          style: TextStyle(
                            color: isReceivable ? AppColors.financeMint : AppColors.urgent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primarySubtle,
                            foregroundColor: AppColors.primaryDark,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onPressed: () => _showRecordPayment(d),
                          child: const Text('سداد', style: TextStyle(fontWeight: FontWeight.bold)),
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
