import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/measurement_session.dart';
import '../../models/cycle_record.dart';
import '../../models/session_event.dart';
import '../../repositories/session_repository.dart';
import '../../services/statistics_service.dart';
import '../../services/export_csv_service.dart';
import '../../services/export_pdf_service.dart';
import '../../utils/app_constants.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const SessionDetailScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  MeasurementSession? _session;
  List<CycleRecord> _cycles = [];
  List<SessionEvent> _events = [];
  bool _isLoading = true;
  bool _excludeFlagged = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(SessionRepository() as dynamic);
      final session = await repo.getById(widget.sessionId);
      final cycles = await repo.getCycles(widget.sessionId);
      final events = await repo.getEvents(widget.sessionId);

      if (mounted) {
        setState(() {
          _session = session;
          _cycles = cycles;
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading session: $e')),
        );
      }
    }
  }

  Future<void> _deleteCycle(CycleRecord cycle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cycle?'),
        content: Text(
          'Delete cycle #${cycle.sequenceNumber}?\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = SessionRepository();
        await repo.deleteCycle(cycle.id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cycle deleted')),
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
  }

  Future<void> _toggleFlagCycle(CycleRecord cycle) async {
    try {
      final repo = SessionRepository();
      final updated = cycle.copyWith(isFlagged: !cycle.isFlagged);
      await repo.updateCycle(updated);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _addCycleNote(CycleRecord cycle) async {
    final controller = TextEditingController(text: cycle.notes ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cycle Notes'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final repo = SessionRepository();
        final updated = cycle.copyWith(notes: result.isEmpty ? null : result);
        await repo.updateCycle(updated);
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    controller.dispose();
  }

  Future<void> _exportCSV() async {
    if (_session == null) return;

    try {
      await ExportCsvService.exportCycles(
        session: _session!,
        cycles: _cycles,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportPDF() async {
    if (_session == null) return;

    try {
      await ExportPdfService.exportSessionReport(
        session: _session!,
        cycles: _cycles,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session Details')),
        body: const Center(child: Text('Session not found')),
      );
    }

    final stats = StatisticsService.calculateStatistics(
      _cycles,
      excludeFlagged: _excludeFlagged,
    );

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'csv') _exportCSV();
              if (value == 'pdf') _exportPDF();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Export PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Session Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _session!.workItemNameSnapshot,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_session!.lotCode != null)
                    Text('Batch: ${_session!.lotCode}'),
                  const SizedBox(height: 4),
                  Text('Status: ${_formatStatus(_session!.status)}'),
                  const SizedBox(height: 4),
                  if (_session!.startedAt != null)
                    Text('Started: ${dateFormat.format(_session!.startedAt!)}'),
                  if (_session!.endedAt != null)
                    Text('Ended: ${dateFormat.format(_session!.endedAt!)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Time Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Total Elapsed',
                    StatisticsService.formatTimeDisplay(_session!.elapsedMs),
                  ),
                  _buildInfoRow(
                    'Active Time',
                    StatisticsService.formatTimeDisplay(_session!.activeMs),
                  ),
                  _buildInfoRow(
                    'Paused Time',
                    StatisticsService.formatTimeDisplay(_session!.pausedMs),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Statistics',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Row(
                        children: [
                          Text(
                            'Exclude flagged',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Switch(
                            value: _excludeFlagged,
                            onChanged: (value) {
                              setState(() => _excludeFlagged = value);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Cycles', '${stats.count}'),
                  if (stats.count > 0) ...[
                    _buildInfoRow(
                      'Average',
                      '${StatisticsService.formatDuration(stats.mean.round())} s',
                    ),
                    _buildInfoRow(
                      'Median',
                      '${StatisticsService.formatDuration(stats.median.round())} s',
                    ),
                    _buildInfoRow(
                      'Fastest',
                      '${StatisticsService.formatDuration(stats.fastest)} s',
                    ),
                    _buildInfoRow(
                      'Slowest',
                      '${StatisticsService.formatDuration(stats.slowest)} s',
                    ),
                    _buildInfoRow(
                      'Range',
                      '${StatisticsService.formatDuration(stats.range)} s',
                    ),
                    if (stats.standardDeviation != null)
                      _buildInfoRow(
                        'Std Dev',
                        '${StatisticsService.formatDuration(stats.standardDeviation!.round())} s',
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cycles List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cycles (${_cycles.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_cycles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No cycles recorded')),
                    )
                  else
                    ..._cycles.map((cycle) => _buildCycleItem(cycle, stats)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Events
          if (_events.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Events',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ..._events.map(_buildEventItem),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleItem(CycleRecord cycle, CycleStatistics stats) {
    final deviation = stats.count > 0
        ? StatisticsService.calculateDeviation(cycle.durationMs, stats.mean)
        : 0.0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cycle.isFlagged
            ? Colors.orange
            : Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          '${cycle.sequenceNumber}',
          style: TextStyle(
            color: cycle.isFlagged
                ? Colors.white
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        '${StatisticsService.formatDuration(cycle.durationMs)} s',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stats.count > 0)
            Text(
              deviation >= 0
                  ? '+${StatisticsService.formatDuration(deviation.round())} s'
                  : '${StatisticsService.formatDuration(deviation.round())} s',
              style: TextStyle(
                color: deviation.abs() > stats.mean * 0.2
                    ? Colors.orange
                    : Colors.grey,
              ),
            ),
          if (cycle.notes != null) Text(cycle.notes!),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'flag') _toggleFlagCycle(cycle);
          if (value == 'note') _addCycleNote(cycle);
          if (value == 'delete') _deleteCycle(cycle);
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'flag',
            child: Row(
              children: [
                Icon(cycle.isFlagged ? Icons.flag_outlined : Icons.flag),
                const SizedBox(width: 8),
                Text(cycle.isFlagged ? 'Unflag' : 'Flag'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'note',
            child: Row(
              children: [
                Icon(Icons.note),
                SizedBox(width: 8),
                Text('Add Note'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(SessionEvent event) {
    return ListTile(
      leading: const Icon(Icons.event),
      title: Text(event.label ?? event.eventType),
      subtitle: Text(
        StatisticsService.formatTimeDisplay(event.offsetMs),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case AppConstants.statusCompleted:
        return 'Completed';
      case AppConstants.statusInProgress:
        return 'In Progress';
      case AppConstants.statusPaused:
        return 'Paused';
      default:
        return status;
    }
  }
}
