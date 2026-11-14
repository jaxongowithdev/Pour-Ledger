import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_providers.dart';
import '../../database/storage_manager.dart';
import 'create_glaze_screen.dart';
import 'glaze_detail_screen.dart';

class GlazesView extends ConsumerStatefulWidget {
  const GlazesView({super.key});

  @override
  ConsumerState<GlazesView> createState() => _GlazesViewState();
}

class _GlazesViewState extends ConsumerState<GlazesView> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final glazes = ref.watch(glazesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Glazes'),
        actions: [
          IconButton(
            key: const ValueKey('add_glaze_button'),
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGlazeScreen(),
                ),
              );
              if (result == true) {
                ref.invalidate(glazesProvider);
              }
            },
          ),
        ],
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
                  selected: _filter == 'all',
                  onSelected: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Favorite',
                  selected: _filter == 'favorite',
                  onSelected: () => setState(() => _filter = 'favorite'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Tested',
                  selected: _filter == 'tested',
                  onSelected: () => setState(() => _filter = 'tested'),
                ),
              ],
            ),
          ),

          // Glazes list
          Expanded(
            child: glazes.when(
              data: (glazesList) {
                var filteredGlazes = glazesList;

                if (_filter == 'favorite') {
                  filteredGlazes = glazesList.where((g) => g.favorite).toList();
                }

                if (filteredGlazes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No glazes found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create your first glaze',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredGlazes.length,
                  itemBuilder: (context, index) {
                    final glaze = filteredGlazes[index];
                    return FutureBuilder(
                      future: _getVersionCount(glaze.id!),
                      builder: (context, snapshot) {
                        final versionCount = snapshot.data ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Icon(
                                glaze.favorite ? Icons.star : Icons.palette,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(glaze.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('$versionCount versions'),
                                if (glaze.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    glaze.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            isThreeLine: glaze.description.isNotEmpty,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GlazeDetailScreen(
                                    glazeId: glaze.id!,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _getVersionCount(int glazeId) async {
    final storage = StorageManager.instance;
    final versions = await storage.getVersionsByGlazeId(glazeId);
    return versions.length;
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
