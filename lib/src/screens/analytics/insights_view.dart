import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/state_providers.dart';
import '../../repositories/measurement_data_store.dart';
import '../../models/cycle_record.dart';
import '../../services/cycle_analytics.dart';
import '../calculator/production_calculator_screen.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          IconButton(
            key: const ValueKey('calculator_button'),
            icon: const Icon(Icons.calculate),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductionCalculatorScreen(),
                ),
              );
            },
            tooltip: 'Bench planner',
          ),
        ],
      ),
      body: sessions.when(
        data: (sessionsList) {
          if (sessionsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insights_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nothing to review yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Close a sitting to see how the bench is pouring',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ProductionCalculatorScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calculate),
                    label: const Text('Bench planner'),
                  ),
                ],
              ),
            );
          }

          final completedSessions =
              sessionsList.where((s) => s.status == 'completed').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Overview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow(
                        'Sittings',
                        '${completedSessions.length}',
                        Icons.history,
                      ),
                      _buildStatRow(
                        'Pour jobs',
                        '${sessionsList.map((s) => s.workItemId).toSet().length}',
                        Icons.work,
                      ),
                      _buildStatRow(
                        'Bench time',
                        StatisticsService.formatDuration(
                          completedSessions.fold<int>(
                            0,
                            (sum, s) => sum + s.activeMs,
                          ),
                          unit: 'hours',
                          decimalPlaces: 1,
                        ) + ' hrs',
                        Icons.timer,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recent Sessions Chart
              if (completedSessions.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sittings by day',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: _buildSessionsChart(completedSessions),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Cycle Time Distribution
              if (completedSessions.isNotEmpty)
                FutureBuilder<List<CycleRecord>>(
                  future: _getAllCycles(completedSessions),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vessel time spread',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 200,
                                child: _buildDistributionChart(snapshot.data!),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              const SizedBox(height: 16),

              // Production Calculator CTA
              Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProductionCalculatorScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bench planner',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Estimate how many vessels fit the day',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsChart(List sessions) {
    // Group by date
    final Map<DateTime, int> sessionsByDate = {};
    for (var session in sessions) {
      final date = DateTime(
        session.createdAt.year,
        session.createdAt.month,
        session.createdAt.day,
      );
      sessionsByDate[date] = (sessionsByDate[date] ?? 0) + 1;
    }

    final sortedDates = sessionsByDate.keys.toList()..sort();
    final last7Days = sortedDates.length > 7
        ? sortedDates.sublist(sortedDates.length - 7)
        : sortedDates;

    if (last7Days.isEmpty) {
      return const Center(child: Text('No data'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (sessionsByDate.values.reduce((a, b) => a > b ? a : b) + 1)
            .toDouble(),
        barGroups: last7Days
            .asMap()
            .entries
            .map((entry) => BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: sessionsByDate[entry.value]!.toDouble(),
                      color: Theme.of(context).colorScheme.primary,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ))
            .toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < last7Days.length) {
                  final date = last7Days[value.toInt()];
                  return Text(
                    '${date.month}/${date.day}',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildDistributionChart(List<CycleRecord> cycles) {
    if (cycles.isEmpty) {
      return const Center(child: Text('No vessel times yet'));
    }

    final durations = cycles.map((c) => c.durationMs / 1000).toList()..sort();
    final min = durations.first;
    final max = durations.last;
    final range = max - min;

    if (range == 0) {
      return const Center(child: Text('Every vessel took the same time'));
    }

    // Create histogram buckets
    const bucketCount = 8;
    final bucketSize = range / bucketCount;
    final buckets = List<int>.filled(bucketCount, 0);

    for (var duration in durations) {
      var bucket = ((duration - min) / bucketSize).floor();
      if (bucket >= bucketCount) bucket = bucketCount - 1;
      buckets[bucket]++;
    }

    final maxCount = buckets.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxCount + 1).toDouble(),
        barGroups: buckets
            .asMap()
            .entries
            .map((entry) => BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble(),
                      color: Theme.of(context).colorScheme.secondary,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ))
            .toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < bucketCount) {
                  final bucketStart = min + (value * bucketSize);
                  return Text(
                    bucketStart.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Future<List<CycleRecord>> _getAllCycles(List sessions) async {
    final repo = SessionRepository();
    final allCycles = <CycleRecord>[];

    for (var session in sessions) {
      final cycles = await repo.getCycles(session.id);
      allCycles.addAll(cycles);
    }

    return allCycles;
  }
}
