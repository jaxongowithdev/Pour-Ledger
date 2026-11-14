import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/storage_manager.dart';
import '../../models/experiment_record.dart';
import '../../models/sample_tile.dart';
import '../../utils/app_constants.dart';
import '../../core/app_providers.dart';

class CreateTestScreen extends ConsumerStatefulWidget {
  final int versionId;
  final String glazeName;
  final String versionName;

  const CreateTestScreen({
    super.key,
    required this.versionId,
    required this.glazeName,
    required this.versionName,
  });

  @override
  ConsumerState<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends ConsumerState<CreateTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _testNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _kilnController = TextEditingController();

  String _selectedCone = '6';
  int _tileCount = 6;
  String _status = 'preparing';

  @override
  void initState() {
    super.initState();
    _testNameController.text = '${widget.glazeName} ${widget.versionName} - Cone $_selectedCone';
  }

  @override
  void dispose() {
    _testNameController.dispose();
    _notesController.dispose();
    _kilnController.dispose();
    super.dispose();
  }

  void _updateTestName() {
    _testNameController.text = '${widget.glazeName} ${widget.versionName} - Cone $_selectedCone';
  }

  Future<void> _createTest() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final storage = StorageManager.instance;

      // Create test record
      final test = ExperimentRecord(
        versionId: widget.versionId,
        name: _testNameController.text,
        testDate: DateTime.now(),
        targetCone: _selectedCone,
        kilnId: _kilnController.text,
        status: _status,
        notes: _notesController.text,
      );

      final testId = await storage.createExperimentRecord(test);

      // Create sample tiles
      for (int i = 1; i <= _tileCount; i++) {
        await storage.createSampleTile(
          SampleTile(
            testId: testId,
            number: i,
            clayBody: 'Stoneware',
            applicationMethod: 'dip',
            layerCount: 2,
            thickness: 'medium',
          ),
        );
      }

      // Refresh providers
      ref.invalidate(allTestsProvider);
      ref.invalidate(activeTestsProvider);
      ref.invalidate(completedTestsProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test created: ${_testNameController.text}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Glaze Test'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Test Name
            TextFormField(
              key: const ValueKey('test_name_field'),
              controller: _testNameController,
              decoration: const InputDecoration(
                labelText: 'Test Name',
                hintText: 'Blue Ash V3 - Cone 6',
                prefixIcon: Icon(Icons.science),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter test name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Glaze Info (read-only)
            Card(
              child: ListTile(
                leading: const Icon(Icons.palette),
                title: Text(widget.glazeName),
                subtitle: Text('Version: ${widget.versionName}'),
              ),
            ),

            const SizedBox(height: 16),

            // Cone Selection
            DropdownButtonFormField<String>(
              key: const ValueKey('cone_dropdown'),
              value: _selectedCone,
              decoration: const InputDecoration(
                labelText: 'Target Cone',
                prefixIcon: Icon(Icons.thermostat),
              ),
              items: AppConstants.commonCones.map((cone) {
                return DropdownMenuItem(
                  value: cone,
                  child: Text('Cone $cone'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCone = value;
                    _updateTestName();
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Kiln
            TextFormField(
              key: const ValueKey('kiln_field'),
              controller: _kilnController,
              decoration: const InputDecoration(
                labelText: 'Kiln',
                hintText: 'Kiln A',
                prefixIcon: Icon(Icons.local_fire_department),
              ),
            ),

            const SizedBox(height: 16),

            // Tile Count
            Row(
              children: [
                const Icon(Icons.grid_on),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sample Tiles',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '$_tileCount tiles',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _tileCount > 1
                      ? () => setState(() => _tileCount--)
                      : null,
                ),
                Text('$_tileCount'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _tileCount++),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<String>(
              key: const ValueKey('status_dropdown'),
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.flag),
              ),
              items: AppConstants.statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_capitalizeFirst(status)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              key: const ValueKey('notes_field'),
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Testing improved formula...',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // Create Button
            ElevatedButton.icon(
              key: const ValueKey('create_test_button'),
              onPressed: _createTest,
              icon: const Icon(Icons.add),
              label: const Text('Create Test'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
