import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/state_providers.dart';
import '../../models/work_item.dart';
import '../../utils/visual_theme.dart';

class WorkItemsScreen extends ConsumerStatefulWidget {
  const WorkItemsScreen({super.key});

  @override
  ConsumerState<WorkItemsScreen> createState() => _WorkItemsScreenState();
}

class _WorkItemsScreenState extends ConsumerState<WorkItemsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final workItemsAsync = ref.watch(workItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pour jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search
            },
          ),
        ],
      ),
      body: workItemsAsync.when(
        data: (items) {
          final filteredItems = _searchQuery.isEmpty
              ? items
              : items
                  .where((item) =>
                      item.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      (item.code
                              ?.toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ??
                          false))
                  .toList();

          if (filteredItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pour jobs yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Add a pour job before you open a sitting'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredItems.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        AppTheme.getWorkItemColor(item.colorValue),
                    child: const Icon(Icons.work, color: Colors.white),
                  ),
                  title: Text(item.name),
                  subtitle: item.code != null ? Text(item.code!) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.isPinned)
                        const Icon(Icons.push_pin, size: 16),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    _showItemDetails(item);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemForm(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showItemDetails(WorkItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (item.code != null) ...[
              const SizedBox(height: 8),
              Text('Code: ${item.code}'),
            ],
            if (item.category != null) ...[
              const SizedBox(height: 4),
              Text('Category: ${item.category}'),
            ],
            if (item.description != null) ...[
              const SizedBox(height: 8),
              Text(item.description!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showItemForm(item);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await ref
                          .read(workItemRepoProvider)
                          .togglePin(item.id);
                      refreshWorkItems(ref);
                    },
                    icon: Icon(item.isPinned
                        ? Icons.push_pin_outlined
                        : Icons.push_pin),
                    label: Text(item.isPinned ? 'Unpin' : 'Pin'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showItemForm(WorkItem? item) {
    showDialog(
      context: context,
      builder: (context) => _WorkItemFormDialog(item: item),
    );
  }
}

class _WorkItemFormDialog extends ConsumerStatefulWidget {
  final WorkItem? item;

  const _WorkItemFormDialog({this.item});

  @override
  ConsumerState<_WorkItemFormDialog> createState() =>
      _WorkItemFormDialogState();
}

class _WorkItemFormDialogState extends ConsumerState<_WorkItemFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  int _selectedColor = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _codeController = TextEditingController(text: widget.item?.code ?? '');
    _categoryController =
        TextEditingController(text: widget.item?.category ?? '');
    _descriptionController =
        TextEditingController(text: widget.item?.description ?? '');
    _selectedColor = widget.item?.colorValue ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a pour job name')),
      );
      return;
    }

    final now = DateTime.now();
    final workItem = widget.item == null
        ? WorkItem(
            id: const Uuid().v4(),
            name: _nameController.text.trim(),
            code: _codeController.text.trim().isEmpty
                ? null
                : _codeController.text.trim(),
            category: _categoryController.text.trim().isEmpty
                ? null
                : _categoryController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            colorValue: _selectedColor,
            createdAt: now,
            updatedAt: now,
          )
        : widget.item!.copyWith(
            name: _nameController.text.trim(),
            code: _codeController.text.trim().isEmpty
                ? null
                : _codeController.text.trim(),
            category: _categoryController.text.trim().isEmpty
                ? null
                : _categoryController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            colorValue: _selectedColor,
            updatedAt: now,
          );

    try {
      if (widget.item == null) {
        await ref.read(workItemRepoProvider).insert(workItem);
      } else {
        await ref.read(workItemRepoProvider).update(workItem);
      }

      refreshWorkItems(ref);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.item == null
                  ? 'Pour job saved'
                  : 'Pour job updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'New pour job' : 'Edit pour job'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Pour job name *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Bench code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Wax family',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Pour notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            const Text('Color:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(
                AppTheme.workItemColors.length,
                (index) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = index),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.workItemColors[index],
                      shape: BoxShape.circle,
                      border: _selectedColor == index
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
