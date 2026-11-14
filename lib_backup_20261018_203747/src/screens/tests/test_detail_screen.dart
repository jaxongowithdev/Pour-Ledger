import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/storage_manager.dart';
import '../../models/experiment_record.dart';
import '../../models/sample_tile.dart';
import '../../models/evaluation_result.dart';
import 'result_entry_screen.dart';
import '../firing/firing_session_screen.dart';
import 'photo_gallery_screen.dart';
import '../../services/pdf_export_service.dart';

class TestDetailScreen extends ConsumerStatefulWidget {
  final int testId;

  const TestDetailScreen({
    super.key,
    required this.testId,
  });

  @override
  ConsumerState<TestDetailScreen> createState() => _TestDetailScreenState();
}

class _TestDetailScreenState extends ConsumerState<TestDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ExperimentRecord? _test;
  List<SampleTile> _tiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final storage = StorageManager.instance;
      final test = await storage.getExperimentRecordById(widget.testId);
      final tiles = await storage.getTilesByTestId(widget.testId);

      setState(() {
        _test = test;
        _tiles = tiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'preparing':
        return Colors.orange;
      case 'firing':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _test == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_test!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () async {
              try {
                await PdfExportService.exportTest(_test!.id!);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error exporting PDF: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Tiles'),
            Tab(text: 'Results'),
            Tab(text: 'Timeline'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTilesTab(),
          _buildResultsTab(),
          _buildTimelineTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status Card
        Card(
          color: _getStatusColor(_test!.status).withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _test!.status == 'completed' ? Icons.check_circle : Icons.pending,
                  color: _getStatusColor(_test!.status),
                  size: 48,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _test!.status.toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _getStatusColor(_test!.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Test Info
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Test Date'),
                trailing: Text(
                  '${_test!.testDate.day}/${_test!.testDate.month}/${_test!.testDate.year}',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.thermostat),
                title: const Text('Target Cone'),
                trailing: Text('Cone ${_test!.targetCone}'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.local_fire_department),
                title: const Text('Kiln'),
                trailing: Text(_test!.kilnId.isEmpty ? 'Not set' : _test!.kilnId),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.grid_on),
                title: const Text('Sample Tiles'),
                trailing: Text('${_tiles.length}'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Notes
        if (_test!.notes.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_test!.notes),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Action Buttons
        if (_test!.status != 'completed') ...[
          ElevatedButton.icon(
            key: const ValueKey('manage_firing_button'),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FiringSessionScreen(
                    testId: _test!.id!,
                    testName: _test!.name,
                  ),
                ),
              );
              _loadData();
            },
            icon: const Icon(Icons.local_fire_department),
            label: Text(_test!.status == 'preparing' ? 'Start Firing' : 'Manage Firing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Photo Gallery Button
        OutlinedButton.icon(
          key: const ValueKey('view_photos_button'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoGalleryScreen(
                  testId: _test!.id!,
                  testName: _test!.name,
                ),
              ),
            );
          },
          icon: const Icon(Icons.photo_library),
          label: const Text('Photo Gallery'),
        ),
      ],
    );
  }

  Widget _buildTilesTab() {
    if (_tiles.isEmpty) {
      return const Center(child: Text('No tiles'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tiles.length,
      itemBuilder: (context, index) {
        final tile = _tiles[index];
        return FutureBuilder<EvaluationResult?>(
          future: StorageManager.instance.getResultByTileId(tile.id!),
          builder: (context, snapshot) {
            final result = snapshot.data;
            final hasResult = result != null;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: hasResult ? Colors.green : Colors.grey,
                  child: Text(
                    '${tile.number}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text('Tile ${tile.number}'),
                subtitle: Text(
                  hasResult
                      ? 'Rating: ${'★' * result.rating} • ${result.statusText}'
                      : '${tile.layerCount} layers • ${tile.applicationMethod}',
                ),
                trailing: Icon(
                  hasResult ? Icons.check_circle : Icons.edit,
                  color: hasResult ? Colors.green : null,
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultEntryScreen(
                        tileId: tile.id!,
                        tileNumber: tile.number,
                        testName: _test!.name,
                      ),
                    ),
                  );
                  _loadData();
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResultsTab() {
    return FutureBuilder<List<EvaluationResult>>(
      future: _loadAllResults(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!;
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text('No results yet'),
                const SizedBox(height: 8),
                const Text('Tap on tiles to add evaluation'),
              ],
            ),
          );
        }

        final avgRating = results.fold<double>(0, (sum, r) => sum + r.rating) / results.length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Average Rating',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: avgRating >= 4 ? Colors.green : Colors.orange,
                      ),
                    ),
                    Text(
                      '★' * avgRating.round(),
                      style: TextStyle(
                        fontSize: 24,
                        color: avgRating >= 4 ? Colors.amber : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results List
            ...results.map((result) {
              final tile = _tiles.firstWhere((t) => t.id == result.tileId);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: result.rating >= 4 ? Colors.green : Colors.orange,
                    child: Text('${tile.number}'),
                  ),
                  title: Text('Tile ${tile.number} • ${'★' * result.rating}'),
                  subtitle: Text('${result.color} • ${result.surface}'),
                  trailing: result.isBest ? const Icon(Icons.star, color: Colors.amber) : null,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultEntryScreen(
                          tileId: tile.id!,
                          tileNumber: tile.number,
                          testName: _test!.name,
                        ),
                      ),
                    );
                    _loadData();
                  },
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildTimelineTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle),
                title: const Text('Test Created'),
                subtitle: Text(
                  '${_test!.testDate.day}/${_test!.testDate.month}/${_test!.testDate.year}',
                ),
              ),
              if (_test!.status == 'firing' || _test!.status == 'pending' || _test!.status == 'completed')
                const ListTile(
                  leading: Icon(Icons.local_fire_department, color: Colors.orange),
                  title: Text('Firing Started'),
                  subtitle: Text('In progress'),
                ),
              if (_test!.status == 'pending' || _test!.status == 'completed')
                const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Firing Completed'),
                  subtitle: Text('Ready for evaluation'),
                ),
              if (_test!.status == 'completed')
                const ListTile(
                  leading: Icon(Icons.analytics, color: Colors.blue),
                  title: Text('Results Recorded'),
                  subtitle: Text('Test completed'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<List<EvaluationResult>> _loadAllResults() async {
    final storage = StorageManager.instance;
    final results = <EvaluationResult>[];

    for (final tile in _tiles) {
      final result = await storage.getResultByTileId(tile.id!);
      if (result != null) {
        results.add(result);
      }
    }

    return results;
  }
}
