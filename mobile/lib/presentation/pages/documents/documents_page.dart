// Documents Expiry Tracker Dedicated Sub-Screen — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/application/use_cases/item_use_cases.dart';
import '../../theme/tokens/mouin_colors.dart';
import '../../theme/tokens/mouin_spacing.dart';
import '../../widgets/common/mouin_card.dart';
import '../../widgets/common/mouin_badge.dart';
import '../../widgets/common/mouin_search_field.dart';
import '../../widgets/states/mouin_states.dart';
import '../../widgets/quick_capture/quick_capture_bottom_sheet.dart';

enum DocumentExpiryStatus { expired, expiringSoon, active }

class DocumentsPage extends StatefulWidget {
  final ItemUseCases? itemUseCases;
  final String workspaceId;
  final List<Item>? initialDocs;

  const DocumentsPage({
    super.key,
    this.itemUseCases,
    required this.workspaceId,
    this.initialDocs,
  });

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Item> _docs = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'expiring_soon', 'expired', 'active'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialDocs != null) {
      _docs = widget.initialDocs!;
      _isLoading = false;
    } else {
      _loadDocuments();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    if (widget.itemUseCases != null) {
      final res = await widget.itemUseCases!.listItems(widget.workspaceId, itemType: ItemType.document);
      if (res.isSuccess) {
        setState(() {
          _docs = res.value;
          _isLoading = false;
        });
        return;
      }
    }
    setState(() => _isLoading = false);
  }

  DocumentExpiryStatus _getExpiryStatus(DateTime? expiryDate) {
    if (expiryDate == null) return DocumentExpiryStatus.active;
    final now = DateTime.now();
    if (expiryDate.isBefore(now)) return DocumentExpiryStatus.expired;
    if (expiryDate.isBefore(now.add(const Duration(days: 60)))) {
      return DocumentExpiryStatus.expiringSoon;
    }
    return DocumentExpiryStatus.active;
  }

  Widget _buildExpiryBadge(DocumentExpiryStatus status, DateTime? expiryDate) {
    switch (status) {
      case DocumentExpiryStatus.expired:
        return const MouinBadge(
          label: 'منتهية الصلاحية',
          textColor: MouinColors.error,
          backgroundColor: MouinColors.errorContainer,
          icon: Icons.error_outline,
        );
      case DocumentExpiryStatus.expiringSoon:
        return const MouinBadge(
          label: 'تنتهي قريباً',
          textColor: MouinColors.warning,
          backgroundColor: MouinColors.warningContainer,
          icon: Icons.warning_amber_rounded,
        );
      case DocumentExpiryStatus.active:
        return const MouinBadge(
          label: 'سارية',
          textColor: MouinColors.success,
          backgroundColor: MouinColors.successContainer,
          icon: Icons.check_circle_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: MouinLoadingState(message: 'جاري تحميل الوثائق والمستندات...'));
    }

    if (_docs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('الوثائق والمستندات')),
        body: MouinEmptyState(
          icon: Icons.description_outlined,
          title: 'لم تسجل أي وثيقة بعد',
          subtitle: 'احفظ بيانات جوازك، هويتك، رخصتك، أو عقودك مع تنبيهات الانتهاء التلقائية.',
          actionLabel: 'إضافة وثيقة',
          onAction: () {
            QuickCaptureBottomSheet.show(
              context,
              workspaceId: widget.workspaceId,
              itemUseCases: widget.itemUseCases,
              onSaved: (type, title) => _loadDocuments(),
            );
          },
        ),
      );
    }

    final filtered = _docs.where((doc) {
      final status = _getExpiryStatus(doc.documentDetail?.expiryDate);
      if (_filter == 'expiring_soon' && status != DocumentExpiryStatus.expiringSoon) return false;
      if (_filter == 'expired' && status != DocumentExpiryStatus.expired) return false;
      if (_filter == 'active' && status != DocumentExpiryStatus.active) return false;
      if (_searchQuery.isNotEmpty && !doc.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الوثائق وتتبع الانتهاء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث الوثائق',
            onPressed: _loadDocuments,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: MouinSpacing.xs),
            child: MouinSearchField(
              controller: _searchController,
              hintText: 'بحث في أسماء الوثائق...',
              onChanged: (q) => setState(() => _searchQuery = q.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('الكل'),
                    selected: _filter == 'all',
                    onSelected: (val) {
                      if (val) setState(() => _filter = 'all');
                    },
                  ),
                  const SizedBox(width: MouinSpacing.sm),
                  ChoiceChip(
                    label: const Text('🟠 تنتهي قريباً'),
                    selected: _filter == 'expiring_soon',
                    onSelected: (val) {
                      if (val) setState(() => _filter = 'expiring_soon');
                    },
                  ),
                  const SizedBox(width: MouinSpacing.sm),
                  ChoiceChip(
                    label: const Text('🔴 منتهية'),
                    selected: _filter == 'expired',
                    onSelected: (val) {
                      if (val) setState(() => _filter = 'expired');
                    },
                  ),
                  const SizedBox(width: MouinSpacing.sm),
                  ChoiceChip(
                    label: const Text('🟢 سارية'),
                    selected: _filter == 'active',
                    onSelected: (val) {
                      if (val) setState(() => _filter = 'active');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MouinSpacing.sm),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا توجد وثائق تطابق الفلتر المحدد'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final doc = filtered[index];
                      final detail = doc.documentDetail;
                      final status = _getExpiryStatus(detail?.expiryDate);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: 4),
                        child: MouinCard(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.badge_outlined, color: MouinColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      detail?.documentNumber != null && detail!.documentNumber!.isNotEmpty
                                          ? 'رقم الوثيقة: ${detail.documentNumber}'
                                          : 'وثيقة رسمية',
                                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                    if (detail?.expiryDate != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'تاريخ الانتهاء: ${detail!.expiryDate!.year}/${detail.expiryDate!.month}/${detail.expiryDate!.day}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              _buildExpiryBadge(status, detail?.expiryDate),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          QuickCaptureBottomSheet.show(
            context,
            workspaceId: widget.workspaceId,
            itemUseCases: widget.itemUseCases,
            onSaved: (type, title) => _loadDocuments(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة وثيقة'),
      ),
    );
  }
}
