// Notes & Ideas Dedicated Sub-Screen — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/application/commands/item_commands.dart';
import 'package:mouin/application/use_cases/item_use_cases.dart';
import '../../theme/tokens/mouin_spacing.dart';
import '../../widgets/common/mouin_card.dart';
import '../../widgets/common/mouin_search_field.dart';
import '../../widgets/states/mouin_states.dart';
import '../../widgets/quick_capture/quick_capture_bottom_sheet.dart';

class NotesPage extends StatefulWidget {
  final ItemUseCases? itemUseCases;
  final String workspaceId;
  final List<Item>? initialNotes;

  const NotesPage({
    super.key,
    this.itemUseCases,
    required this.workspaceId,
    this.initialNotes,
  });

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Item> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialNotes != null) {
      _notes = widget.initialNotes!;
      _isLoading = false;
    } else {
      _loadNotes();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    if (widget.itemUseCases != null) {
      final res = await widget.itemUseCases!.listItems(widget.workspaceId, itemType: ItemType.note);
      if (res.isSuccess) {
        setState(() {
          _notes = res.value;
          _isLoading = false;
        });
        return;
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: MouinLoadingState(message: 'جاري تحميل الملاحظات...'));
    }

    if (_notes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('الملاحظات السريعة')),
        body: MouinEmptyState(
          icon: Icons.note_outlined,
          title: 'مساحة الملاحظات فارغة',
          subtitle: 'دوّن أفكارك، أرقامك، أو نصوصك المهمة بسرعة.',
          actionLabel: 'تدوين ملاحظة',
          onAction: () {
            QuickCaptureBottomSheet.show(
              context,
              workspaceId: widget.workspaceId,
              itemUseCases: widget.itemUseCases,
              onSaved: (type, title) => _loadNotes(),
            );
          },
        ),
      );
    }

    final filtered = _notes.where((note) {
      if (_searchQuery.isNotEmpty) {
        final matchTitle = note.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchContent = (note.noteDetail?.content ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
        return matchTitle || matchContent;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملاحظات والأفكار'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث الملاحظات',
            onPressed: _loadNotes,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: MouinSpacing.xs),
            child: MouinSearchField(
              controller: _searchController,
              hintText: 'بحث في الملاحظات...',
              onChanged: (q) => setState(() => _searchQuery = q.trim()),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا توجد ملاحظات تطابق البحث'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final note = filtered[index];
                      final content = note.noteDetail?.content ?? '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: 4),
                        child: MouinCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              if (content.isNotEmpty && content != note.title) ...[
                                const SizedBox(height: 4),
                                Text(
                                  content,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
            onSaved: (type, title) => _loadNotes(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('ملاحظة جديدة'),
      ),
    );
  }
}
