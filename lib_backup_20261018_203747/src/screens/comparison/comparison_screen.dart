import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/storage_manager.dart';
import '../../models/glaze_entity.dart';
import '../../models/formula_version.dart';
import '../../models/experiment_record.dart';
import '../../models/evaluation_result.dart';

class ComparisonScreen extends ConsumerStatefulWidget {
  final int glazeId;

  const ComparisonScreen({
    super.key,
    required this.glazeId,
  });

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  GlazeEntity? _glaze;
  List<FormulaVersion> _versions = [];
  Map<int, List<ExperimentRecord>> _testsByVersion = {};
  Map<int, double> _avgRatingsByTest = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final storage = StorageManager.instance;
      final glaze = await storage.getGlazeById(widget.glazeId);
      final versions = await storage.getVersionsByGlazeId(widget.glazeId);

      // Load tests for each version
      final testsByVersion = <int, List<ExperimentRecord>>{};
      final avgRatingsByTest = <int, double>{};

      for (final version in versions) {
        final tests = await storage.getExperimentsByVersionId(version.id!);
        testsByVersion[version.id!] = tests;

        // Calculate average ratings for each test
        for (final test in tests) {
          final tiles = await storage.getTilesByTestId(test.id!);
          final results = <EvaluationResult>[];

          for (final tile in tiles) {
            final result = await storage.getResultByTileId(tile.id!);
            if (result != null) {
              results.add(result);
            }
          }

          if (results.isNotEmpty) {
            final avgRating = results.fold<double>(0, (sum, r) => sum + r.rating) / results.length;
            avgRatingsByTest[test.id!] = avgRating;
          }
        }
      }

      setState(() {
        _glaze = glaze;
        _versions = versions;
        _testsByVersion = testsByVersion;
        _avgRatingsByTest = avgRatingsByTest;
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
        title: Text('${_glaze!.name} - Comparison'),
      ),
      body: _versions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.compare_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('No versions to compare'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Version Comparison',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_versions.length} versions • ${_getTotalTests()} tests',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Comparison Table
                Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Version')),
                        DataColumn(label: Text('Tests')),
                        DataColumn(label: Text('Best Rating')),
                        DataColumn(label: Text('Avg Rating')),
                      ],
                      rows: _versions.map((version) {
                        final tests = _testsByVersion[version.id!] ?? [];
                        final completedTests = tests.where((t) => t.status == 'completed').toList();

                        double? bestRating;
                        double? avgRating;

                        if (completedTests.isNotEmpty) {
                          final ratings = completedTests
                              .map((t) => _avgRatingsByTest[t.id!])
                              .where((r) => r != null)
                              .cast<double>()
                              .toList();

                          if (ratings.isNotEmpty) {
                            bestRating = ratings.reduce((a, b) => a > b ? a : b);
                            avgRating = ratings.fold(0.0, (sum, r) => sum + r) / ratings.length;
                          }
                        }

                        return DataRow(
                          cells: [
                            DataCell(Text(version.version)),
                            DataCell(Text('${completedTests.length}')),
                            DataCell(Text(
                              bestRating != null ? bestRating.toStringAsFixed(1) : '-',
                            )),
                            DataCell(Text(
                              avgRating != null ? avgRating.toStringAsFixed(1) : '-',
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Detailed Results
                ..._versions.map((version) {
                  final tests = _testsByVersion[version.id!] ?? [];
                  final completedTests = tests.where((t) => t.status == 'completed').toList();

                  if (completedTests.isEmpty) return const SizedBox();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title: Text('${_glaze!.name} ${version.version}'),
                      subtitle: Text('${completedTests.length} completed tests'),
                      children: completedTests.map((test) {
                        final avgRating = _avgRatingsByTest[test.id!];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getRatingColor(avgRating),
                            child: Text(test.targetCone),
                          ),
                          title: Text(test.name),
                          subtitle: Text(
                            avgRating != null
                                ? 'Avg Rating: ${avgRating.toStringAsFixed(1)} ★'
                                : 'No results',
                          ),
                          trailing: avgRating != null && avgRating >= 4.5
                              ? const Icon(Icons.star, color: Colors.amber)
                              : null,
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }

  int _getTotalTests() {
    return _testsByVersion.values.fold(0, (sum, tests) => sum + tests.length);
  }

  Color _getRatingColor(double? rating) {
    if (rating == null) return Colors.grey;
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }
}
