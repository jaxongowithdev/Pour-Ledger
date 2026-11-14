import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state_providers.dart';
import '../../services/cycle_analytics.dart';
import '../../database/demo_generator.dart';
import '../work_items/work_items_screen.dart';
import '../measurement/timer_view.dart';
import '../session/session_detail_screen.dart';
import '../history/history_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayStats = ref.watch(todayStatsProvider);
    final recentSessions = ref.watch(recentSessionsProvider);
    final pinnedItems = ref.watch(pinnedWorkItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pour Ledger'),
        actions: [
          IconButton(
            key: const ValueKey('tasks_button'),
            icon: const Icon(Icons.water_drop_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkItemsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          refreshSessions(ref);
          refreshWorkItems(ref);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quick start button
            Card(
              child: InkWell(
                key: const ValueKey('start_measurement_button'),
                onTap: () {
                  // The parent MainNavigator will handle tab switching
                  // For now, just navigate to measurement screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MeasurementScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Open a sitting',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time each vessel while the wax is on the bench.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Today's stats
            Text(
              'Today on the bench',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            todayStats.when(
              data: (stats) => _buildTodayStats(context, stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Could not load the bench'),
            ),
            const SizedBox(height: 24),

            // Pinned tasks
            pinnedItems.when(
              data: (items) => items.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pinned pours',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ...items.map((item) => Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  child: Icon(
                                    Icons.water_drop,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                                title: Text(item.name),
                                subtitle: item.code != null
                                    ? Text(item.code!)
                                    : null,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // Quick start with this task
                                },
                              ),
                            )),
                        const SizedBox(height: 24),
                      ],
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Recent sessions
            Text(
              'Recent sittings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            recentSessions.when(
              data: (sessions) => sessions.isEmpty
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.opacity,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No sittings yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Open a sitting to time the first vessel on the bench',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  await SampleData.createSampleData();
                                  refreshSessions(ref);
                                  refreshWorkItems(ref);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Sample bench loaded. Pull down to refresh.'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.science_outlined),
                              label: const Text('Load a sample bench'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: sessions
                          .map((session) =>
                              _buildSessionCard(context, ref, session))
                          .toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Could not load sittings'),
            ),
            const SizedBox(height: 16),

            // View all button
            recentSessions.when(
              data: (sessions) {
                if (sessions.isEmpty) return const SizedBox.shrink();
                return OutlinedButton(
                  key: const ValueKey('view_all_button'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                  child: const Text('Open the log'),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStats(BuildContext context, Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sittings',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats['session_count']}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bench',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    StatisticsService.formatDuration(
                      stats['total_time_ms'] as int,
                      unit: 'minutes',
                    ),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'min',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avg vessel',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    StatisticsService.formatDuration(
                      (stats['avg_cycle_ms'] as double).round(),
                      unit: 'seconds',
                    ),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    's',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(BuildContext context, WidgetRef ref, session) {
    final dateFormat = DateFormat('MMM d, HH:mm');
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            session.status == 'completed'
                ? Icons.check
                : Icons.timer,
          ),
        ),
        title: Text(session.workItemNameSnapshot),
        subtitle: Text(dateFormat.format(session.createdAt)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              StatisticsService.formatTimeDisplay(session.activeMs),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionDetailScreen(sessionId: session.id),
            ),
          );
        },
      ),
    );
  }
}
