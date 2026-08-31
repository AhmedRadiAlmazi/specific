// Unified Search Page — مشروع «مُعين» (Mouin)
// Global search across all Item subtypes (tasks, notes, documents, shopping, appointments).
// For Debts and Reminders, the search operates on the local database and BLoC state.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mouin/domain/entities/debt.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/application/use_cases/item_use_cases.dart';
import 'package:mouin/presentation/bloc/debt_bloc.dart';
import 'package:mouin/presentation/bloc/sync_bloc.dart';
import 'package:mouin/presentation/bloc/task_bloc.dart';
import 'package:mouin/infrastructure/network/remote_sync_api.dart';
import 'package:mouin/presentation/theme/tokens/mouin_colors.dart';
import 'package:mouin/presentation/theme/tokens/mouin_spacing.dart';
import 'package:mouin/presentation/widgets/common/mouin_card.dart';
import 'package:mouin/presentation/widgets/common/mouin_scaffold.dart';
import 'package:mouin/presentation/widgets/common/mouin_search_field.dart';
import 'package:mouin/presentation/widgets/common/mouin_section_header.dart';
import 'package:mouin/presentation/widgets/states/mouin_states.dart';
import 'package:mouin/presentation/widgets/domain/domain_badges.dart';
import 'package:mouin/presentation/pages/search/search_categories.dart';
import 'package:mouin/presentation/pages/search/search_result_model.dart';
import 'package:mouin/presentation/pages/debts/debts_page.dart';
import 'package:mouin/presentation/pages/documents/documents_page.dart';
import 'package:mouin/presentation/pages/notes/notes_page.dart';
import 'package:mouin/presentation/pages/shopping/shopping_page.dart';
import 'package:mouin/presentation/pages/home_page.dart';

class UnifiedSearchPage extends StatefulWidget {
  final TaskBloc taskBloc;
  final DebtBloc debtBloc;
  final SyncBloc syncBloc;
  final String workspaceId;
  final ItemUseCases? itemUseCases;
  final RemoteSyncApi? remoteSyncApi;

  const UnifiedSearchPage({
    super.key,
    required this.taskBloc,
    required this.debtBloc,
    required this.syncBloc,
    required this.workspaceId,
    this.itemUseCases,
    this.remoteSyncApi,
  });

  @override
  State<UnifiedSearchPage> createState() => _UnifiedSearchPageState();
}

class _UnifiedSearchPageState extends State<UnifiedSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Search results grouped by category
  final Map<SearchCategory, List<SearchResultModel>> _itemResults = {};
  List<Debt> _debtResults = [];

  bool _isLoading = false;
  String _errorMessage = '';
  String _query = '';

  // Selected filter category (null or all = show all)
  SearchCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        _clearResults();
        return;
      }
      _performSearch(query);
    });
  }

  void _clearResults() {
    setState(() {
      _query = '';
      _itemResults.clear();
      _debtResults.clear();
      _isLoading = false;
      _errorMessage = '';
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _query = query;
      _isLoading = true;
      _errorMessage = '';
      _itemResults.clear();
      _debtResults.clear();
    });

    try {
      // 1. Search Items via ItemUseCases or TaskBloc repository (tasks, notes, documents, shopping, appointments)
      final itemsFuture = widget.itemUseCases != null
          ? widget.itemUseCases!.searchItems(widget.workspaceId, query)
          : widget.taskBloc.repository.searchArabic(widget.workspaceId, query);

      final res = await itemsFuture;
      if (res.isSuccess) {
        for (final item in res.value) {
          final result = SearchResultModel.fromItem(item);
          if (result != null) {
            _itemResults.putIfAbsent(result.category, () => []).add(result);
          }
        }
      }

      // 2. Search Debts from the already-loaded DebtBloc state
      final debtState = widget.debtBloc.currentState;
      if (debtState is DebtLoaded) {
        final q = query.toLowerCase();
        _debtResults = debtState.debts.where((d) {
          return d.personId.toLowerCase().contains(q) ||
              d.transactions.any((tx) =>
                  tx.notes?.toLowerCase().contains(q) ?? false);
        }).toList();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر إتمام البحث: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    _clearResults();
  }

  void _onCategoryChanged(SearchCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _navigateToCategory(SearchCategory category) {
    switch (category) {
      case SearchCategory.tasks:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Directionality(
              textDirection: TextDirection.rtl,
              child: HomePage(
                taskBloc: widget.taskBloc,
                debtBloc: widget.debtBloc,
                syncBloc: widget.syncBloc,
                workspaceId: widget.workspaceId,
              ),
            ),
          ),
        );
        break;
      case SearchCategory.debts:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Directionality(
              textDirection: TextDirection.rtl,
              child: DebtsPage(
                debtBloc: widget.debtBloc,
                workspaceId: widget.workspaceId,
              ),
            ),
          ),
        );
        break;
      case SearchCategory.documents:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Directionality(
              textDirection: TextDirection.rtl,
              child: DocumentsPage(
                itemUseCases: widget.itemUseCases,
                workspaceId: widget.workspaceId,
              ),
            ),
          ),
        );
        break;
      case SearchCategory.notes:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Directionality(
              textDirection: TextDirection.rtl,
              child: NotesPage(
                itemUseCases: widget.itemUseCases,
                workspaceId: widget.workspaceId,
              ),
            ),
          ),
        );
        break;
      case SearchCategory.shopping:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Directionality(
              textDirection: TextDirection.rtl,
              child: ShoppingPage(
                itemUseCases: widget.itemUseCases,
                workspaceId: widget.workspaceId,
              ),
            ),
          ),
        );
        break;
      case SearchCategory.reminders:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('قائمة التذكيرات غير متوفرة حالياً')),
        );
        break;
      case SearchCategory.all:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouinScaffold(
      appBar: AppBar(
        title: const Text('البحث الموحد'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'رجوع',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MouinSpacing.md,
              vertical: MouinSpacing.sm,
            ),
            child: MouinSearchField(
              controller: _searchController,
              hintText: 'ابحث عن المهام، الديون، الملاحظات، الوثائق...',
              onClear: _clearSearch,
            ),
          ),

          // Category filter chips (only when there's a query)
          if (_query.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md),
              child: Row(
                children: [
                  _categoryChip(SearchCategory.all, null),
                  const SizedBox(width: MouinSpacing.xs),
                  _categoryChip(SearchCategory.tasks, SearchCategory.tasks),
                  const SizedBox(width: MouinSpacing.xs),
                  _categoryChip(SearchCategory.debts, SearchCategory.debts),
                  const SizedBox(width: MouinSpacing.xs),
                  _categoryChip(SearchCategory.documents, SearchCategory.documents),
                  const SizedBox(width: MouinSpacing.xs),
                  _categoryChip(SearchCategory.notes, SearchCategory.notes),
                  const SizedBox(width: MouinSpacing.xs),
                  _categoryChip(SearchCategory.shopping, SearchCategory.shopping),
                ],
              ),
            ),

          const SizedBox(height: MouinSpacing.sm),

          // Content based on search state
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(SearchCategory category, SearchCategory? selectedFor) {
    final isSelected = _selectedCategory == selectedFor;
    return FilterChip(
      label: Text(category.label),
      selected: isSelected,
      onSelected: (_) => _onCategoryChanged(selectedFor),
      avatar: isSelected ? null : Icon(category.icon, size: 16),
      labelStyle: TextStyle(
        fontSize: 13,
        color: isSelected ? Colors.white : MouinColors.primary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: MouinColors.surfaceLight,
      selectedColor: MouinColors.primary,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const MouinLoadingState(message: 'جارٍ البحث...');
    }

    if (_errorMessage.isNotEmpty) {
      return MouinErrorState(
        title: 'خطأ في البحث',
        message: _errorMessage,
        onRetry: () => _performSearch(_query),
      );
    }

    if (_query.isEmpty) {
      return _buildInitialContent();
    }

    return _buildResultsList();
  }

  Widget _buildInitialContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MouinSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ابحث في مُعين',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: MouinSpacing.xs),
          Text(
            'اكتب كلمة للبحث في جميع العناصر: المهام، الديون، الملاحظات، الوثائق، وقوائم التسوق.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: MouinSpacing.lg),
          Text(
            'بحث سريع حسب التصنيف',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: MouinSpacing.sm),
          _buildQuickCategoryTile(
            Icons.check_circle_outline,
            'المهام',
            'البحث في المهام والتذكيرات',
            MouinColors.primary,
            () => _navigateToCategory(SearchCategory.tasks),
          ),
          _buildQuickCategoryTile(
            Icons.account_balance_wallet_outlined,
            'الديون',
            'البحث في سجل الديون والمطالبات',
            MouinColors.debtReceivable,
            () => _navigateToCategory(SearchCategory.debts),
          ),
          _buildQuickCategoryTile(
            Icons.description_outlined,
            'الوثائق',
            'البحث في الوثائق وتتبع الانتهاء',
            MouinColors.secondary,
            () => _navigateToCategory(SearchCategory.documents),
          ),
          _buildQuickCategoryTile(
            Icons.note_outlined,
            'الملاحظات',
            'البحث في الملاحظات والأفكار',
            MouinColors.tertiary,
            () => _navigateToCategory(SearchCategory.notes),
          ),
          _buildQuickCategoryTile(
            Icons.shopping_cart_outlined,
            'قوائم التسوق',
            'البحث في قوائم المشتريات',
            MouinColors.info,
            () => _navigateToCategory(SearchCategory.shopping),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCategoryTile(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MouinSpacing.sm),
      child: MouinCard(
        onTap: onTap,
        child: ListTile(
          leading: Icon(icon, color: color, size: 28),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    final hasItemResults = _itemResults.isNotEmpty || _debtResults.isNotEmpty;

    if (!hasItemResults) {
      return MouinEmptyState(
        icon: Icons.search_off,
        title: 'لم نجد نتائج مطابقة',
        subtitle: 'حاول كتابة كلمة أخرى أو تحقق من الإملاء',
        actionLabel: 'مسح البحث',
        onAction: _clearSearch,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _performSearch(_query),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tasks section
            if (_shouldShowCategory(SearchCategory.tasks))
              _buildItemSection(SearchCategory.tasks),

            // Documents section
            if (_shouldShowCategory(SearchCategory.documents))
              _buildItemSection(SearchCategory.documents),

            // Notes section
            if (_shouldShowCategory(SearchCategory.notes))
              _buildItemSection(SearchCategory.notes),

            // Shopping section
            if (_shouldShowCategory(SearchCategory.shopping))
              _buildItemSection(SearchCategory.shopping),

            // Debts section
            if (_shouldShowCategory(SearchCategory.debts)) _buildDebtSection(),

            // Reminders section
            if (_shouldShowCategory(SearchCategory.reminders))
              _buildRemindersPlaceholder(),

            const SizedBox(height: MouinSpacing.xxl),
          ],
        ),
      ),
    );
  }

  bool _shouldShowCategory(SearchCategory cat) {
    if (_selectedCategory != null && _selectedCategory != SearchCategory.all) {
      return _selectedCategory == cat;
    }
    // Show section only if it has results
    if (cat == SearchCategory.debts) return _debtResults.isNotEmpty;
    return (_itemResults[cat]?.isNotEmpty ?? false);
  }

  Widget _buildItemSection(SearchCategory category) {
    final results = _itemResults[category] ?? [];

    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouinSectionHeader(
          title: category.label,
          count: results.length,
          trailing: TextButton(
            onPressed: () => _navigateToCategory(category),
            child: const Text('عرض الكل'),
          ),
        ),
        ...results.take(5).map((r) => _buildItemCard(r)),
        if (results.length > 5)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md),
            child: TextButton(
              onPressed: () => _navigateToCategory(category),
              child: Text('+ عرض ${results.length - 5} نتائج أخرى'),
            ),
          ),
      ],
    );
  }

  Widget _buildItemCard(SearchResultModel result) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MouinSpacing.md,
        vertical: 4,
      ),
      child: MouinCard(
        onTap: () => _navigateToCategory(result.category),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Icon(result.icon, color: MouinColors.primary, size: 24),
          title: Text(
            result.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: result.subtitle != null
              ? Text(
                  result.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          trailing: result.metadata != null
              ? PriorityBadge(priority: _parsePriority(result.metadata!))
              : const Icon(Icons.chevron_left, size: 20),
        ),
      ),
    );
  }

  Priority _parsePriority(String p) {
    switch (p.toLowerCase()) {
      case 'urgent':
        return Priority.urgent;
      case 'high':
        return Priority.high;
      case 'low':
        return Priority.low;
      default:
        return Priority.medium;
    }
  }

  Widget _buildDebtSection() {
    if (_debtResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouinSectionHeader(
          title: 'الديون',
          count: _debtResults.length,
          trailing: TextButton(
            onPressed: () => _navigateToCategory(SearchCategory.debts),
            child: const Text('عرض الكل'),
          ),
        ),
        ..._debtResults.take(3).map((d) => _buildDebtCard(d)),
        if (_debtResults.length > 3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md),
            child: TextButton(
              onPressed: () => _navigateToCategory(SearchCategory.debts),
              child: Text('+ عرض ${_debtResults.length - 3} نتائج أخرى'),
            ),
          ),
      ],
    );
  }

  Widget _buildDebtCard(Debt debt) {
    final remaining = debt.calculateRemainingAmount();
    final isReceivable = debt.debtType == DebtType.receivable;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MouinSpacing.md,
        vertical: 4,
      ),
      child: MouinCard(
        onTap: () => _navigateToCategory(SearchCategory.debts),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Icon(
            isReceivable
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: isReceivable
                ? MouinColors.debtReceivable
                : MouinColors.debtPayable,
          ),
          title: Text(
            debt.personId,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            'المتبقي: ${remaining.toDecimalString()} ${remaining.currency}',
            style: TextStyle(
              fontSize: 12,
              color: isReceivable
                  ? MouinColors.debtReceivable
                  : MouinColors.debtPayable,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: DirectionalBadge(debtType: debt.debtType),
        ),
      ),
    );
  }

  Widget _buildRemindersPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MouinSpacing.md,
        vertical: MouinSpacing.sm,
      ),
      child: MouinCard(
        child: ListTile(
          leading: Icon(
            Icons.access_time_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          title: const Text('التذكيرات'),
          subtitle: const Text('قائمة التذكيرات غير متوفرة حالياً في البحث الموحد'),
          trailing: const Icon(Icons.chevron_left, size: 20),
        ),
      ),
    );
  }
}
