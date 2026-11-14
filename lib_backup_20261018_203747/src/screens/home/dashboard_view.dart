import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_providers.dart';
import '../glazes/create_glaze_screen.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTests = ref.watch(activeTestsProvider);
    final completedTests = ref.watch(completedTestsProvider);
    final allTests = ref.watch(allTestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CycleTime'),
        actions: [
          IconButton(
            key: const ValueKey('add_test_button'),
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGlazeScreen(),
                ),
              );
              if (result == true) {
                ref.invalidate(allTestsProvider);
                ref.invalidate(activeTestsProvider);
                ref.invalidate(completedTestsProvider);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App title
          Text(
            'CycleTime',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),

          // Statistics cards
          activeTests.when(
            data: (active) {
              return completedTests.when(
                data: (completed) {
                  return allTests.when(
                    data: (all) {
                      final pending = active.where((t) => t.status == 'pending').length;
                      final bestResults = all.length; // TODO: Calculate from evaluation results

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Active Tests',
                                  value: active.length.toString(),
                                  icon: Icons.science,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  label: 'Completed',
                                  value: completed.length.toString(),
                                  icon: Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Pending Evaluation',
                                  value: pending.toString(),
                                  icon: Icons.pending_actions,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  label: 'Best Results',
                                  value: bestResults.toString(),
                                  icon: Icons.star,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('Error: $e'),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),

          const SizedBox(height: 32),

          // Recent section
          Text(
            'Recent',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          allTests.when(
            data: (tests) {
              if (tests.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tests yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create your first glaze test',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: tests.take(5).map((test) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(test.status),
                        child: Icon(
                          _getStatusIcon(test.status),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(test.name),
                      subtitle: Text('Cone ${test.targetCone} • ${test.status}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to test detail
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('View ${test.name}')),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'preparing':
        return Icons.science;
      case 'firing':
        return Icons.local_fire_department;
      case 'pending':
        return Icons.pending_actions;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.circle;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
