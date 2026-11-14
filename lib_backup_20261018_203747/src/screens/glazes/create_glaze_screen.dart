import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/storage_manager.dart';
import '../../models/glaze_entity.dart';
import '../../models/formula_version.dart';
import '../../core/app_providers.dart';
import 'formula_builder_screen.dart';

class CreateGlazeScreen extends ConsumerStatefulWidget {
  const CreateGlazeScreen({super.key});

  @override
  ConsumerState<CreateGlazeScreen> createState() => _CreateGlazeScreenState();
}

class _CreateGlazeScreenState extends ConsumerState<CreateGlazeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _favorite = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGlaze() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final storage = StorageManager.instance;

      // Create glaze
      final glaze = GlazeEntity(
        name: _nameController.text,
        description: _descriptionController.text,
        favorite: _favorite,
      );

      final glazeId = await storage.createGlaze(glaze);

      // Create first version
      final version = FormulaVersion(
        glazeId: glazeId,
        version: 'V1',
        notes: 'Initial formula',
      );

      final versionId = await storage.createFormulaVersion(version);

      // Refresh providers
      ref.invalidate(glazesProvider);

      if (mounted) {
        // Navigate to formula builder
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FormulaBuilderScreen(
              versionId: versionId,
              glazeName: _nameController.text,
              versionName: 'V1',
            ),
          ),
        );

        if (result == true && mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating glaze: $e'),
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
        title: const Text('New Glaze'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              key: const ValueKey('glaze_name_field'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Glaze Name',
                hintText: 'Blue Ash',
                prefixIcon: Icon(Icons.palette),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter glaze name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              key: const ValueKey('glaze_description_field'),
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Rich blue glaze with ash',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Favorite
            SwitchListTile(
              key: const ValueKey('favorite_switch'),
              title: const Text('Favorite'),
              subtitle: const Text('Mark as favorite glaze'),
              value: _favorite,
              onChanged: (value) {
                setState(() => _favorite = value);
              },
              secondary: Icon(
                _favorite ? Icons.star : Icons.star_border,
                color: _favorite ? Colors.amber : null,
              ),
            ),

            const SizedBox(height: 32),

            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 8),
                        Text(
                          'Next Step',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'After creating the glaze, you\'ll build the formula by adding ingredients.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Create Button
            ElevatedButton.icon(
              key: const ValueKey('create_glaze_button'),
              onPressed: _createGlaze,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue to Formula'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
