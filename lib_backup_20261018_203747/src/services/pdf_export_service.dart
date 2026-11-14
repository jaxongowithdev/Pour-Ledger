import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../database/storage_manager.dart';
import '../models/experiment_record.dart';
import '../models/formula_version.dart';
import '../models/glaze_entity.dart';
import '../models/formula_component.dart';
import '../models/ingredient_item.dart';
import '../models/sample_tile.dart';
import '../models/evaluation_result.dart';
import '../models/kiln_session.dart';

class PdfExportService {
  static Future<void> exportTest(int testId) async {
    final storage = StorageManager.instance;

    // Load test data
    final test = await storage.getExperimentRecordById(testId);
    if (test == null) return;

    final version = await storage.getFormulaVersionById(test.versionId);
    if (version == null) return;

    final glaze = await storage.getGlazeById(version.glazeId);
    if (glaze == null) return;

    final components = await storage.getComponentsByVersionId(version.id!);
    final ingredients = await storage.getAllIngredients();
    final tiles = await storage.getTilesByTestId(testId);
    final sessions = await storage.getKilnSessionsByTestId(testId);
    final results = await _loadResults(tiles);

    // Create PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title
              pw.Center(
                child: pw.Text(
                  'CycleTime REPORT',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Test Info
              pw.Text(
                test.name,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildInfoRow('Glaze:', '${glaze.name} ${version.version}'),
              _buildInfoRow('Test Date:', '${test.testDate.day}/${test.testDate.month}/${test.testDate.year}'),
              _buildInfoRow('Cone:', test.targetCone),
              _buildInfoRow('Kiln:', test.kilnId.isEmpty ? 'Not specified' : test.kilnId),
              _buildInfoRow('Status:', test.status.toUpperCase()),

              pw.SizedBox(height: 20),

              // Formula
              pw.Text(
                'Formula',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildTableCell('Ingredient', bold: true),
                      _buildTableCell('Weight (g)', bold: true),
                      _buildTableCell('Percentage', bold: true),
                    ],
                  ),
                  ...components.map((component) {
                    final ingredient = ingredients.firstWhere(
                      (ing) => ing.id == component.ingredientId,
                      orElse: () => IngredientItem(name: 'Unknown', category: ''),
                    );
                    return pw.TableRow(
                      children: [
                        _buildTableCell(ingredient.name),
                        _buildTableCell(component.weight.toStringAsFixed(1)),
                        _buildTableCell('${component.percentage.toStringAsFixed(1)}%'),
                      ],
                    );
                  }).toList(),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Total', bold: true),
                      _buildTableCell(
                        components.fold(0.0, (sum, c) => sum + c.weight).toStringAsFixed(1),
                        bold: true,
                      ),
                      _buildTableCell('100%', bold: true),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Firing Profile
              if (sessions.isNotEmpty) ...[
                pw.Text(
                  'Firing Profile',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                _buildInfoRow('Target Temperature:', '${sessions.first.targetTemperature}°C'),
                if (sessions.first.peakTemperature > 0)
                  _buildInfoRow('Peak Temperature:', '${sessions.first.peakTemperature}°C'),
                _buildInfoRow('Hold Time:', '${sessions.first.holdMinutes} minutes'),
                _buildInfoRow('Atmosphere:', sessions.first.atmosphere),
                pw.SizedBox(height: 20),
              ],

              // Results Summary
              pw.Text(
                'Results Summary',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              if (results.isEmpty)
                pw.Text('No results yet')
              else ...[
                _buildInfoRow('Total Tiles:', '${tiles.length}'),
                _buildInfoRow('Evaluated:', '${results.length}'),
                _buildInfoRow('Average Rating:', '${(results.fold<double>(0, (sum, r) => sum + r.rating) / results.length).toStringAsFixed(1)} / 5'),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _buildTableCell('Tile', bold: true),
                        _buildTableCell('Rating', bold: true),
                        _buildTableCell('Color', bold: true),
                        _buildTableCell('Surface', bold: true),
                      ],
                    ),
                    ...results.map((result) {
                      final tile = tiles.firstWhere((t) => t.id == result.tileId);
                      return pw.TableRow(
                        children: [
                          _buildTableCell('Tile ${tile.number}'),
                          _buildTableCell('${result.rating}/5'),
                          _buildTableCell(result.color.isEmpty ? '-' : result.color),
                          _buildTableCell(result.surface.isEmpty ? '-' : result.surface),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],

              // Notes
              if (test.notes.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'Notes',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text(test.notes),
              ],

              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Generated by CycleTime',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Show print dialog
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${test.name}.pdf',
    );
  }

  static Future<List<EvaluationResult>> _loadResults(List<SampleTile> tiles) async {
    final storage = StorageManager.instance;
    final results = <EvaluationResult>[];

    for (final tile in tiles) {
      final result = await storage.getResultByTileId(tile.id!);
      if (result != null) {
        results.add(result);
      }
    }

    return results;
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
      ),
    );
  }
}
