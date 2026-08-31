// Shopping & Checklists Dedicated Sub-Screen — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/application/commands/item_commands.dart';
import 'package:mouin/application/use_cases/item_use_cases.dart';
import '../../theme/tokens/mouin_spacing.dart';
import '../../widgets/common/mouin_card.dart';
import '../../widgets/states/mouin_states.dart';

class ShoppingItemModel {
  final String id;
  final String title;
  final bool isDone;

  const ShoppingItemModel({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  ShoppingItemModel copyWith({bool? isDone}) {
    return ShoppingItemModel(
      id: id,
      title: title,
      isDone: isDone ?? this.isDone,
    );
  }
}

class ShoppingPage extends StatefulWidget {
  final ItemUseCases? itemUseCases;
  final String workspaceId;
  final List<ShoppingItemModel>? initialItems;

  const ShoppingPage({
    super.key,
    this.itemUseCases,
    required this.workspaceId,
    this.initialItems,
  });

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final TextEditingController _addItemController = TextEditingController();
  List<ShoppingItemModel> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialItems != null) {
      _items = List.from(widget.initialItems!);
    } else {
      _loadShoppingItems();
    }
  }

  @override
  void dispose() {
    _addItemController.dispose();
    super.dispose();
  }

  Future<void> _loadShoppingItems() async {
    if (widget.itemUseCases != null) {
      final res = await widget.itemUseCases!.listItems(widget.workspaceId, itemType: ItemType.task);
      if (res.isSuccess) {
        final shoppingTasks = res.value.where((i) => i.title.startsWith('[قائمة]') || i.title.startsWith('شراء')).toList();
        setState(() {
          _items = shoppingTasks.map((t) {
            return ShoppingItemModel(
              id: t.id,
              title: t.title.replaceAll('[قائمة]', '').trim(),
              isDone: t.taskDetail?.status == TaskStatus.completed,
            );
          }).toList();
        });
      }
    }
  }

  void _addNewItem() {
    final title = _addItemController.text.trim();
    if (title.isNotEmpty) {
      setState(() {
        _items.add(ShoppingItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
        ));
      });
      if (widget.itemUseCases != null) {
        widget.itemUseCases!.createTask(
          CreateTaskCommand(
            workspaceId: widget.workspaceId,
            title: '[قائمة] $title',
          ),
        );
      }
      _addItemController.clear();
    }
  }

  void _toggleItem(int index) {
    setState(() {
      _items[index] = _items[index].copyWith(isDone: !_items[index].isDone);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة المشتريات والتسوق'),
      ),
      body: Column(
        children: [
          // Inline Fast Add Input
          Padding(
            padding: MouinSpacing.paddingMd,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addItemController,
                    decoration: const InputDecoration(
                      hintText: 'أضف غرضاً للقائمة (مثال: حليب، خبز)...',
                      prefixIcon: Icon(Icons.add_shopping_cart),
                    ),
                    onSubmitted: (_) => _addNewItem(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addNewItem,
                  child: const Text('إضافة'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const MouinEmptyState(
                    icon: Icons.checklist,
                    title: 'قائمة التسوق فارغة',
                    subtitle: 'اكتب الأغراض أعلاه لإضافتها للقائمة فوراً.',
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (ctx, index) {
                      final item = _items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: 3),
                        child: MouinCard(
                          child: Row(
                            children: [
                              Checkbox(
                                value: item.isDone,
                                onChanged: (_) => _toggleItem(index),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    decoration: item.isDone ? TextDecoration.lineThrough : null,
                                    color: item.isDone ? Theme.of(context).colorScheme.onSurfaceVariant : null,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                tooltip: 'حذف الغرض',
                                onPressed: () {
                                  setState(() => _items.removeAt(index));
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
