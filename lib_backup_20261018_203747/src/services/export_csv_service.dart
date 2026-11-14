import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/measurement_session.dart';
import '../models/cycle_record.dart';
import '../services/statistics_service.dart';

class ExportCsvService {
  /// Export cycles to CSV
  static Future<void> exportCycles({
    required MeasurementSession session,
    required List<CycleRecord> cycles,
  }) async {
    final rows = <List<String>>[];

    // Header
    rows.add([
      'Session ID',
      'Task',
      'Date',
      'Sequence',
      'Duration (s)',
      'Duration (ms)',
      'Flagged',
      'Notes',
    ]);

    // Data rows
    for (final cycle in cycles) {
      rows.add([
        session.id,
        session.workItemNameSnapshot,
        session.createdAt.toIso8601String(),
        cycle.sequenceNumber.toString(),
        StatisticsService.formatDuration(cycle.durationMs, unit: 'seconds'),
        cycle.durationMs.toString(),
        cycle.isFlagged ? 'Yes' : 'No',
        cycle.notes ?? '',
      ]);
    }

    await _writeCsvFile(rows, 'cycles_${session.id}.csv');
  }

  /// Export session summary to CSV
  static Future<void> exportSessionSummary({
    required MeasurementSession session,
    required List<CycleRecord> cycles,
  }) async {
    final stats = StatisticsService.calculateStatistics(cycles);
    final rows = <List<String>>[];

    // Session info
    rows.add(['Field', 'Value']);
    rows.add(['Session ID', session.id]);
    rows.add(['Task', session.workItemNameSnapshot]);
    rows.add(['Task Code', session.lotCode ?? '']);
    rows.add(['Status', session.status]);
    rows.add(['Started', session.startedAt?.toIso8601String() ?? '']);
    rows.add(['Ended', session.endedAt?.toIso8601String() ?? '']);
    rows.add([]);

    // Time metrics
    rows.add(['Time Metrics', '']);
    rows.add([
      'Total Elapsed',
      StatisticsService.formatDuration(session.elapsedMs, unit: 'seconds')
    ]);
    rows.add([
      'Active Time',
      StatisticsService.formatDuration(session.activeMs, unit: 'seconds')
    ]);
    rows.add([
      'Paused Time',
      StatisticsService.formatDuration(session.pausedMs, unit: 'seconds')
    ]);
    rows.add([]);

    // Cycle statistics
    rows.add(['Cycle Statistics', '']);
    rows.add(['Total Cycles', stats.count.toString()]);
    rows.add([
      'Average',
      StatisticsService.formatDuration(stats.mean.round(), unit: 'seconds')
    ]);
    rows.add([
      'Median',
      StatisticsService.formatDuration(stats.median.round(), unit: 'seconds')
    ]);
    rows.add([
      'Fastest',
      StatisticsService.formatDuration(stats.fastest, unit: 'seconds')
    ]);
    rows.add([
      'Slowest',
      StatisticsService.formatDuration(stats.slowest, unit: 'seconds')
    ]);
    rows.add([
      'Range',
      StatisticsService.formatDuration(stats.range, unit: 'seconds')
    ]);
    if (stats.standardDeviation != null) {
      rows.add([
        'Std Dev',
        StatisticsService.formatDuration(stats.standardDeviation!.round(),
            unit: 'seconds')
      ]);
    }

    await _writeCsvFile(rows, 'summary_${session.id}.csv');
  }

  /// Export multiple sessions to CSV
  static Future<void> exportMultipleSessions(
      List<MeasurementSession> sessions) async {
    final rows = <List<String>>[];

    // Header
    rows.add([
      'Session ID',
      'Task',
      'Date',
      'Status',
      'Cycles',
      'Active Time (s)',
      'Avg Cycle (s)',
    ]);

    // Data rows
    for (final session in sessions) {
      rows.add([
        session.id,
        session.workItemNameSnapshot,
        session.createdAt.toIso8601String(),
        session.status,
        '', // Will need cycle count from repository
        StatisticsService.formatDuration(session.activeMs, unit: 'seconds'),
        '', // Will need avg from statistics
      ]);
    }

    await _writeCsvFile(rows, 'sessions_export.csv');
  }

  static Future<void> _writeCsvFile(
      List<List<String>> rows, String filename) async {
    try {
      final csvData = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$filename';
      final file = File(path);

      await file.writeAsString(csvData);

      // Share the file
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'CycleTime Export',
      );
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }
}
