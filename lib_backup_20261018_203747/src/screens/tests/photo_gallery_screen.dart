import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../database/storage_manager.dart';
import '../../models/experiment_photo.dart';
import '../../utils/app_constants.dart';

class PhotoGalleryScreen extends ConsumerStatefulWidget {
  final int testId;
  final String testName;

  const PhotoGalleryScreen({
    super.key,
    required this.testId,
    required this.testName,
  });

  @override
  ConsumerState<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends ConsumerState<PhotoGalleryScreen> {
  List<ExperimentPhoto> _photos = [];
  String _filterStage = 'all';
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final storage = StorageManager.instance;
      final photos = await storage.getPhotosByTestId(widget.testId);

      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addPhoto() async {
    // Show stage selector
    final stage = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Photo Stage'),
        children: AppConstants.photoStages.map((s) {
          return SimpleDialogOption(
            child: Text(_formatStageName(s)),
            onPressed: () => Navigator.pop(context, s),
          );
        }).toList(),
      ),
    );

    if (stage == null) return;

    // Pick image
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      // Get caption
      final caption = await showDialog<String>(
        context: context,
        builder: (context) => _CaptionDialog(),
      );

      // Save photo
      final storage = StorageManager.instance;
      final photo = ExperimentPhoto(
        testId: widget.testId,
        stage: stage,
        path: image.path,
        caption: caption ?? '',
      );

      await storage.createExperimentPhoto(photo);
      _loadPhotos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    // Show stage selector
    final stage = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Photo Stage'),
        children: AppConstants.photoStages.map((s) {
          return SimpleDialogOption(
            child: Text(_formatStageName(s)),
            onPressed: () => Navigator.pop(context, s),
          );
        }).toList(),
      ),
    );

    if (stage == null) return;

    // Pick image from gallery
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      // Get caption
      final caption = await showDialog<String>(
        context: context,
        builder: (context) => _CaptionDialog(),
      );

      // Save photo
      final storage = StorageManager.instance;
      final photo = ExperimentPhoto(
        testId: widget.testId,
        stage: stage,
        path: image.path,
        caption: caption ?? '',
      );

      await storage.createExperimentPhoto(photo);
      _loadPhotos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding photo: $e'),
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

    var filteredPhotos = _photos;
    if (_filterStage != 'all') {
      filteredPhotos = _photos.where((p) => p.stage == _filterStage).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filterStage == 'all',
                  onSelected: () => setState(() => _filterStage = 'all'),
                ),
                const SizedBox(width: 8),
                ...AppConstants.photoStages.map((stage) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: _formatStageName(stage),
                      selected: _filterStage == stage,
                      onSelected: () => setState(() => _filterStage = stage),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Photos grid
          Expanded(
            child: filteredPhotos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No photos yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add photos',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: filteredPhotos.length,
                    itemBuilder: (context, index) {
                      final photo = filteredPhotos[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _PhotoDetailScreen(photo: photo),
                            ),
                          );
                        },
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Image
                              Image.file(
                                File(photo.path),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image, size: 48),
                                  );
                                },
                              ),
                              // Stage badge
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatStageName(photo.stage),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              // Caption (if exists)
                              if (photo.caption.isNotEmpty)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.7),
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      photo.caption,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            key: const ValueKey('add_photo_camera'),
            heroTag: 'camera',
            onPressed: _addPhoto,
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            key: const ValueKey('add_photo_gallery'),
            heroTag: 'gallery',
            onPressed: _pickFromGallery,
            child: const Icon(Icons.photo_library),
          ),
        ],
      ),
    );
  }

  String _formatStageName(String stage) {
    return stage.split('_').map((word) =>
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _CaptionDialog extends StatefulWidget {
  @override
  State<_CaptionDialog> createState() => _CaptionDialogState();
}

class _CaptionDialogState extends State<_CaptionDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Caption'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Caption (optional)',
          hintText: 'Describe this photo...',
        ),
        maxLines: 2,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: const Text('Skip'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PhotoDetailScreen extends StatelessWidget {
  final ExperimentPhoto photo;

  const _PhotoDetailScreen({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatStageName(photo.stage)),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            File(photo.path),
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 64, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Image not found',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: photo.caption.isNotEmpty
          ? Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(16),
              child: Text(
                photo.caption,
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  String _formatStageName(String stage) {
    return stage.split('_').map((word) =>
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}
