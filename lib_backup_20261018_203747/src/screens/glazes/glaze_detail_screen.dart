import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/storage_manager.dart';
import '../../models/glaze_entity.dart';
import '../../models/formula_version.dart';
import '../../models/formula_component.dart';
import '../../models/ingredient_item.dart';
import 'formula_builder_screen.dart';
import '../tests/create_test_screen.dart';
import '../comparison/comparison_screen.dart';

class GlazeDetailScreen extends ConsumerStatefulWidget {
  final int glazeId;

  const GlazeDetailScreen({
    super.key,
    required this.glazeId,
  });

  @override
  ConsumerState<GlazeDetailScreen> createState() => _GlazeDetailScreenState();
}

class _GlazeDetailScreenState extends ConsumerState<GlazeDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GlazeEntity? _glaze;
  List<FormulaVersion> _versions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final storage = StorageManager.instance;
      final glaze = await storage.getGlazeById(widget.glazeId);
      final versions = await storage.getVersionsByGlazeId(widget.glazeId);

      setState(() {
        _glaze = glaze;
        _versions = versions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _glaze == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_glaze!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare),
            tooltip: 'Compare Versions',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComparisonScreen(
                    glazeId: widget.glazeId,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(_glaze!.favorite ? Icons.star : Icons.star_border),
            onPressed: () async {
              final updated = _glaze!.copyWith(favorite: !_glaze!.favorite);
              await StorageManager.instance.updateGlaze(updated);
              _loadData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Versions'),
            Tab(text: 'Info'),
            Tab(text: 'Tests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVersionsTab(),
          _buildInfoTab(),
          _buildTestsTab(),
        ],
      ),
    );
  }

  Widget _buildVersionsTab() {
    if (_versions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text('No versions yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _versions.length,
      itemBuilder: (context, index) {
        final version = _versions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              child: Text(version.version),
            ),
            title: Text('${_glaze!.name} ${version.version}'),
            subtitle: Text(version.notes),
            children: [
              FutureBuilder<List<FormulaComponent>>(
                future: StorageManager.instance.getComponentsByVersionId(version.id!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final components = snapshot.data!;
                  if (components.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('No formula yet'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FormulaBuilderScreen(
                                    versionId: version.id!,
                                    glazeName: _glaze!.name,
                                    versionName: version.version,
                                  ),
                                ),
                              );
                              _loadData();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Build Formula'),
                          ),
                        ],
                      ),
                    );
                  }

                  return FutureBuilder<List<IngredientItem>>(
                    future: StorageManager.instance.getAllIngredients(),
                    builder: (context, ingredientsSnapshot) {
                      if (!ingredientsSnapshot.hasData) {
                        return const SizedBox();
                      }

                      final ingredients = ingredientsSnapshot.data!;

                      return Column(
                        children: [
                          ...components.map((component) {
                            final ingredient = ingredients.firstWhere(
                              (ing) => ing.id == component.ingredientId,
                              orElse: () => IngredientItem(name: 'Unknown', category: ''),
                            );

                            return ListTile(
                              dense: true,
                              title: Text(ingredient.name),
                              trailing: Text(
                                '${component.weight.toStringAsFixed(1)} g (${component.percentage.toStringAsFixed(1)}%)',
                              ),
                            );
                          }).toList(),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FormulaBuilderScreen(
                                          versionId: version.id!,
                                          glazeName: _glaze!.name,
                                          versionName: version.version,
                                        ),
                                      ),
                                    );
                                    _loadData();
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CreateTestScreen(
                                          versionId: version.id!,
                                          glazeName: _glaze!.name,
                                          versionName: version.version,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.science),
                                  label: const Text('Create Test'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _glaze!.description.isEmpty ? 'No description' : _glaze!.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.science),
                  title: const Text('Total Versions'),
                  trailing: Text('${_versions.length}'),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Created'),
                  trailing: Text(
                    '${_glaze!.createdAt.day}/${_glaze!.createdAt.month}/${_glaze!.createdAt.year}',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _loadTestsForGlaze(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tests = snapshot.data!;
        if (tests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text('No tests yet'),
                const SizedBox(height: 8),
                const Text('Create a version and start testing'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tests.length,
          itemBuilder: (context, index) {
            final test = tests[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(test.targetCone),
                ),
                title: Text(test.name),
                subtitle: Text(test.status),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('View ${test.name} - Coming soon')),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<dynamic>> _loadTestsForGlaze() async {
    final storage = StorageManager.instance;
    final allTests = await storage.getAllExperimentRecords();

    // Filter tests by versions of this glaze
    final versionIds = _versions.map((v) => v.id).toList();
    return allTests.where((test) => versionIds.contains(test.versionId)).toList();
  }
}
