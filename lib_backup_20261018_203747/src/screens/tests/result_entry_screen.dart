import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/storage_manager.dart';
import '../../models/evaluation_result.dart';
import '../../utils/app_constants.dart';

class ResultEntryScreen extends ConsumerStatefulWidget {
  final int tileId;
  final int tileNumber;
  final String testName;

  const ResultEntryScreen({
    super.key,
    required this.tileId,
    required this.tileNumber,
    required this.testName,
  });

  @override
  ConsumerState<ResultEntryScreen> createState() => _ResultEntryScreenState();
}

class _ResultEntryScreenState extends ConsumerState<ResultEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _colorController = TextEditingController();
  final _surfaceController = TextEditingController();
  final _textureController = TextEditingController();
  final _glossController = TextEditingController();
  final _opacityController = TextEditingController();
  final _coverageController = TextEditingController();
  final _adhesionController = TextEditingController();
  final _notesController = TextEditingController();

  int _rating = 3;
  bool _isBest = false;
  final Set<String> _selectedDefects = {};
  EvaluationResult? _existingResult;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingResult();
  }

  @override
  void dispose() {
    _colorController.dispose();
    _surfaceController.dispose();
    _textureController.dispose();
    _glossController.dispose();
    _opacityController.dispose();
    _coverageController.dispose();
    _adhesionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingResult() async {
    try {
      final storage = StorageManager.instance;
      final result = await storage.getResultByTileId(widget.tileId);

      if (result != null) {
        setState(() {
          _existingResult = result;
          _colorController.text = result.color;
          _surfaceController.text = result.surface;
          _textureController.text = result.texture;
          _glossController.text = result.gloss;
          _opacityController.text = result.opacity;
          _coverageController.text = result.coverage;
          _adhesionController.text = result.adhesion;
          _notesController.text = result.notes;
          _rating = result.rating;
          _isBest = result.isBest;
        });

        // Load defects
        // TODO: Load defects from database
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveResult() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final storage = StorageManager.instance;

      final result = EvaluationResult(
        id: _existingResult?.id,
        tileId: widget.tileId,
        color: _colorController.text,
        surface: _surfaceController.text,
        texture: _textureController.text,
        gloss: _glossController.text,
        opacity: _opacityController.text,
        coverage: _coverageController.text,
        adhesion: _adhesionController.text,
        rating: _rating,
        notes: _notesController.text,
        isBest: _isBest,
      );

      if (_existingResult == null) {
        await storage.createEvaluationResult(result);
      } else {
        await storage.updateEvaluationResult(result);
      }

      // TODO: Save defects

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Result saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving result: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Tile ${widget.tileNumber} - Result'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Test Info
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${widget.tileNumber}'),
                ),
                title: Text(widget.testName),
                subtitle: Text('Tile ${widget.tileNumber}'),
              ),
            ),

            const SizedBox(height: 24),

            // Rating
            Text(
              'Overall Rating',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            size: 40,
                            color: index < _rating ? Colors.amber : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _rating = index + 1);
                          },
                        );
                      }),
                    ),
                    Text(
                      _getRatingText(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _getRatingColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Properties
            Text(
              'Properties',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Color',
                hintText: 'Deep Blue',
                prefixIcon: Icon(Icons.color_lens),
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _surfaceController,
              decoration: const InputDecoration(
                labelText: 'Surface',
                hintText: 'Glossy',
                prefixIcon: Icon(Icons.texture),
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _textureController,
              decoration: const InputDecoration(
                labelText: 'Texture',
                hintText: 'Smooth',
                prefixIcon: Icon(Icons.touch_app),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _glossController,
                    decoration: const InputDecoration(
                      labelText: 'Gloss',
                      hintText: 'High',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _opacityController,
                    decoration: const InputDecoration(
                      labelText: 'Opacity',
                      hintText: 'Opaque',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _coverageController,
                    decoration: const InputDecoration(
                      labelText: 'Coverage',
                      hintText: 'Excellent',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _adhesionController,
                    decoration: const InputDecoration(
                      labelText: 'Adhesion',
                      hintText: 'Strong',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Defects
            Text(
              'Defects',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.defectTypes.map((defect) {
                    final isSelected = _selectedDefects.contains(defect);
                    return FilterChip(
                      label: Text(_formatDefectName(defect)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDefects.add(defect);
                          } else {
                            _selectedDefects.remove(defect);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Additional observations...',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Best Result Toggle
            SwitchListTile(
              title: const Text('Mark as Best Result'),
              subtitle: const Text('This is one of the best results for this glaze'),
              value: _isBest,
              onChanged: (value) {
                setState(() => _isBest = value);
              },
              secondary: Icon(
                _isBest ? Icons.star : Icons.star_border,
                color: _isBest ? Colors.amber : null,
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton.icon(
              key: const ValueKey('save_result_button'),
              onPressed: _saveResult,
              icon: const Icon(Icons.check),
              label: Text(_existingResult == null ? 'Save Result' : 'Update Result'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Weak';
      case 3:
        return 'Acceptable';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Color _getRatingColor() {
    if (_rating >= 4) return Colors.green;
    if (_rating == 3) return Colors.orange;
    return Colors.red;
  }

  String _formatDefectName(String defect) {
    return defect.split('_').map((word) =>
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}
