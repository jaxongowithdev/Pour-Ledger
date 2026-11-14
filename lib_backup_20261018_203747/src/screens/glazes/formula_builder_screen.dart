import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/storage_manager.dart';
import '../../models/ingredient_item.dart';
import '../../models/formula_component.dart';
import '../../utils/app_constants.dart';

class FormulaBuilderScreen extends ConsumerStatefulWidget {
  final int versionId;
  final String glazeName;
  final String versionName;

  const FormulaBuilderScreen({
    super.key,
    required this.versionId,
    required this.glazeName,
    required this.versionName,
  });

  @override
  ConsumerState<FormulaBuilderScreen> createState() => _FormulaBuilderScreenState();
}

class _FormulaBuilderScreenState extends ConsumerState<FormulaBuilderScreen> {
  List<FormulaComponent> _components = [];
  List<IngredientItem> _ingredients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final storage = StorageManager.instance;
      final ingredients = await storage.getAllIngredients();
      final components = await storage.getComponentsByVersionId(widget.versionId);

      setState(() {
        _ingredients = ingredients;
        _components = components;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get _totalWeight {
    return _components.fold(0.0, (sum, component) => sum + component.weight);
  }

  void _recalculatePercentages() {
    final total = _totalWeight;
    if (total > 0) {
      _components = _components.map((component) {
        final percentage = AppConstants.calculatePercentage(component.weight, total);
        return component.copyWith(percentage: percentage);
      }).toList();
    }
  }

  Future<void> _addIngredient() async {
    final ingredientId = await showDialog<int>(
      context: context,
      builder: (context) => _IngredientPickerDialog(
        ingredients: _ingredients,
        usedIds: _components.map((c) => c.ingredientId).toList(),
      ),
    );

    if (ingredientId == null) return;

    final weight = await showDialog<double>(
      context: context,
      builder: (context) => _WeightInputDialog(),
    );

    if (weight == null) return;

    try {
      final storage = StorageManager.instance;
      final percentage = AppConstants.calculatePercentage(weight, _totalWeight + weight);

      final component = FormulaComponent(
        versionId: widget.versionId,
        ingredientId: ingredientId,
        weight: weight,
        percentage: percentage,
      );

      final id = await storage.createFormulaComponent(component);

      setState(() {
        _components.add(component.copyWith(id: id));
        _recalculatePercentages();
      });

      // Save all updated percentages
      for (var comp in _components) {
        if (comp.id != null) {
          await storage.updateFormulaComponent(comp);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding ingredient: $e')),
        );
      }
    }
  }

  String _getIngredientName(int ingredientId) {
    final ingredient = _ingredients.firstWhere(
      (ing) => ing.id == ingredientId,
      orElse: () => IngredientItem(name: 'Unknown', category: ''),
    );
    return ingredient.name;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.glazeName} ${widget.versionName}'),
        actions: [
          IconButton(
            key: const ValueKey('save_formula_button'),
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Formula saved'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Weight',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${_totalWeight.toStringAsFixed(1)} g',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Ingredients',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${_components.length}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Components List
          Expanded(
            child: _components.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ingredients yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add ingredients',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _components.length,
                    itemBuilder: (context, index) {
                      final component = _components[index];
                      final name = _getIngredientName(component.ingredientId);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${component.percentage.toStringAsFixed(0)}%'),
                          ),
                          title: Text(name),
                          subtitle: Text('${component.weight.toStringAsFixed(1)} g'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              // TODO: Delete component
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Delete - Coming soon')),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add_ingredient_button'),
        onPressed: _addIngredient,
        icon: const Icon(Icons.add),
        label: const Text('Add Ingredient'),
      ),
    );
  }
}

class _IngredientPickerDialog extends StatelessWidget {
  final List<IngredientItem> ingredients;
  final List<int> usedIds;

  const _IngredientPickerDialog({
    required this.ingredients,
    required this.usedIds,
  });

  @override
  Widget build(BuildContext context) {
    final availableIngredients = ingredients.where((ing) => !usedIds.contains(ing.id)).toList();

    return AlertDialog(
      title: const Text('Select Ingredient'),
      content: SizedBox(
        width: double.maxFinite,
        child: availableIngredients.isEmpty
            ? const Text('No more ingredients available')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: availableIngredients.length,
                itemBuilder: (context, index) {
                  final ingredient = availableIngredients[index];
                  return ListTile(
                    title: Text(ingredient.name),
                    subtitle: Text(ingredient.category),
                    onTap: () => Navigator.pop(context, ingredient.id),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _WeightInputDialog extends StatefulWidget {
  @override
  State<_WeightInputDialog> createState() => _WeightInputDialogState();
}

class _WeightInputDialogState extends State<_WeightInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Weight'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Weight (g)',
          hintText: '100',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final weight = double.tryParse(_controller.text);
            if (weight != null && weight > 0) {
              Navigator.pop(context, weight);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
