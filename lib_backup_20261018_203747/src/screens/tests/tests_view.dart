import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_providers.dart';
import 'test_detail_screen.dart';
import '../glazes/create_glaze_screen.dart';

class TestsView extends ConsumerStatefulWidget {
  const TestsView({super.key});

  @override
  ConsumerState<TestsView> createState() => _TestsViewState();
}

class _TestsViewState extends ConsumerState<TestsView> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final allTests = ref.watch(allTestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tests'),
        actions: [
          IconButton(
            key: const ValueKey('add_test_button_tests'),
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGlazeScreen(),
                ),
              );
              ref.invalidate(allTestsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == 'all',
                  onSelected: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Active',
                  selected: _filter == 'active',
                  onSelected: () => setState(() => _filter = 'active'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Completed',
                  selected: _filter == 'completed',
                  onSelected: () => setState(() => _filter = 'completed'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pending',
                  selected: _filter == 'pending',
                  onSelected: () => setState(() => _filter = 'pending'),
                ),
              ],
            ),
          ),

          // Tests list
          Expanded(
            child: allTests.when(
              data: (tests) {
                var filteredTests = tests;

                if (_filter == 'active') {
                  filteredTests = tests.where((t) =>
                    t.status == 'preparing' || t.status == 'firing'
                  ).toList();
                } else if (_filter == 'completed') {
                  filteredTests = tests.where((t) => t.status == 'completed').toList();
                } else if (_filter == 'pending') {
                  filteredTests = tests.where((t) => t.status == 'pending').toList();
                }

                if (filteredTests.isEmpty) {
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
                        Text(
                          'No tests found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTests.length,
                  itemBuilder: (context, index) {
                    final test = filteredTests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(test.status),
                          child: Text(
                            test.targetCone,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(test.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${test.kilnId} • ${test.status}'),
                            if (test.notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                test.notes,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        isThreeLine: test.notes.isNotEmpty,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TestDetailScreen(
                                testId: test.id!,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'preparing':
        return Colors.orange;
      case 'firing':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
