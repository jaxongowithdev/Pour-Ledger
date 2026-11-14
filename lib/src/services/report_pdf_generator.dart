import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/measurement_session.dart';
import '../models/cycle_record.dart';
import '../services/cycle_analytics.dart';
import 'package:intl/intl.dart';

class ExportPdfService {
  /// Export session report to PDF
  static Future<void> exportSessionReport({
    required MeasurementSession session,
    required List<CycleRecord> cycles,
  }) async {
    final pdf = pw.Document();
    final stats = StatisticsService.calculateStatistics(cycles);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Text(
              'Pour Ledger Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),

          // Session Information
          pw.Text(
            'Sitting',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Pour job', session.workItemNameSnapshot),
          if (session.lotCode != null)
            _buildInfoRow('Wax lot', session.lotCode!),
          _buildInfoRow('Status', _formatStatus(session.status)),
          _buildInfoRow('Timing Mode', _formatTimingMode(session.timingMode)),
          if (session.startedAt != null)
            _buildInfoRow('Started', dateFormat.format(session.startedAt!)),
          if (session.endedAt != null)
            _buildInfoRow('Ended', dateFormat.format(session.endedAt!)),
          pw.SizedBox(height: 20),

          // Time Metrics
          pw.Text(
            'Time Metrics',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow(
            'Total Elapsed',
            StatisticsService.formatTimeDisplay(session.elapsedMs),
          ),
          _buildInfoRow(
            'Active Time',
            StatisticsService.formatTimeDisplay(session.activeMs),
          ),
          _buildInfoRow(
            'Paused Time',
            StatisticsService.formatTimeDisplay(session.pausedMs),
          ),
          pw.SizedBox(height: 20),

          // Cycle Statistics
          pw.Text(
            'Vessel times',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Vessels', stats.count.toString()),
          _buildInfoRow(
            'Average vessel',
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
              'Standard Deviation',
              '${StatisticsService.formatDuration(stats.standardDeviation!.round())} s',
            ),
          pw.SizedBox(height: 20),

          // Cycles Table
          if (cycles.isNotEmpty) ...[
            pw.Text(
              'Each vessel',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: [
                '#',
                'Duration (s)',
                'Deviation',
                'Status',
              ],
              data: cycles.map((cycle) {
                final deviation =
                    StatisticsService.calculateDeviation(cycle.durationMs, stats.mean);
                final deviationStr = deviation >= 0
                    ? '+${StatisticsService.formatDuration(deviation.round())}'
                    : StatisticsService.formatDuration(deviation.round());

                return [
                  cycle.sequenceNumber.toString(),
                  StatisticsService.formatDuration(cycle.durationMs),
                  deviationStr,
                  cycle.isFlagged ? 'Flagged' : 'OK',
                ];
              }).toList(),
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellPadding: const pw.EdgeInsets.all(5),
            ),
          ],

          // Notes
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Notes',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(session.notes!),
          ],

          // Footer
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text(
            'Generated by Pour Ledger on ${dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
          pw.Text(
            'Each vessel time is the value recorded on the bench.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );

    await _savePdf(pdf, 'sitting_${session.id}.pdf');
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static String _formatStatus(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  static String _formatTimingMode(String mode) {
    return mode == 'total_duration'
        ? 'Full span (includes pauses)'
        : 'Hands-on time (excludes pauses)';
  }

  static Future<void> _savePdf(pw.Document pdf, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$filename';
      final file = File(path);

      await file.writeAsBytes(await pdf.save());

      // Open print dialog
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }
}
