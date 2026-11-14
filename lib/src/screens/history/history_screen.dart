import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/measurement_session.dart';
import '../../models/work_item.dart';
import '../../repositories/measurement_data_store.dart';
import '../../repositories/task_data_store.dart';
import '../../services/cycle_analytics.dart';
import '../../utils/cycle_constants.dart';
import '../session/session_detail_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<MeasurementSession> _allSessions = [];
  List<MeasurementSession> _filteredSessions = [];
  List<WorkItem> _workItems = [];
  bool _isLoading = true;

  // Filters
  String? _selectedWorkItemId;
  String? _selectedStatus;
  DateTimeRange? _dateRange;
  String _searchQuery = '';
  String _sortBy = 'newest'; // newest, oldest, duration

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final sessionRepo = SessionRepository();
      final workItemRepo = WorkItemRepository();

      final sessions = await sessionRepo.getAll();
      final workItems = await workItemRepo.getAll();

      if (mounted) {
        setState(() {
          _allSessions = sessions;
          _workItems = workItems;
          _filteredSessions = sessions;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading data: $e')),
            );
          }
        });
      }
    }
  }

  void _applyFilters() {
    var filtered = List<MeasurementSession>.from(_allSessions);

    // Filter by work item
    if (_selectedWorkItemId != null) {
      filtered = filtered
          .where((s) => s.workItemId == _selectedWorkItemId)
          .toList();
    }

    // Filter by status
    if (_selectedStatus != null) {
      filtered = filtered.where((s) => s.status == _selectedStatus).toList();
    }

    // Filter by date range
    if (_dateRange != null) {
      filtered = filtered.where((s) {
        return s.createdAt.isAfter(_dateRange!.start) &&
            s.createdAt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Search by name or lot code
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) {
        return s.workItemNameSnapshot
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (s.lotCode?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false);
      }).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'duration':
        filtered.sort((a, b) => b.activeMs.compareTo(a.activeMs));
        break;
    }

    setState(() {
      _filteredSessions = filtered;
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedWorkItemId = null;
      _selectedStatus = null;
      _dateRange = null;
      _searchQuery = '';
      _sortBy = 'newest';
    });
    _applyFilters();
  }

  Future<void> _deleteSession(MeasurementSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete sitting?'),
        content: Text(
          'Delete the sitting for ${session.workItemNameSnapshot}?\nVessels and notes in it will be removed too.',
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
        await repo.delete(session.id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sitting deleted')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sitting log'),
        actions: [
          IconButton(
            key: const ValueKey('filter_button'),
            icon: Icon(
              _hasActiveFilters() ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const ValueKey('search_field'),
              decoration: InputDecoration(
                hintText: 'Search by pour job or wax lot',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _applyFilters();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
            ),
          ),

          // Active filters chips
          if (_hasActiveFilters())
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_selectedWorkItemId != null)
                    _buildFilterChip(
                      'Pour: ${_getWorkItemName(_selectedWorkItemId!)}',
                      () {
                        setState(() => _selectedWorkItemId = null);
                        _applyFilters();
                      },
                    ),
                  if (_selectedStatus != null)
                    _buildFilterChip(
                      'Status: ${_formatStatus(_selectedStatus!)}',
                      () {
                        setState(() => _selectedStatus = null);
                        _applyFilters();
                      },
                    ),
                  if (_dateRange != null)
                    _buildFilterChip(
                      'Date: ${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                      () {
                        setState(() => _dateRange = null);
                        _applyFilters();
                      },
                    ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),

          // Sessions list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _hasActiveFilters()
                                  ? 'No sittings match these filters'
                                  : 'The log is empty',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _hasActiveFilters()
                                  ? 'Try a different pour job or wax lot'
                                  : 'Close a sitting and it will show up here',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          itemCount: _filteredSessions.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            final session = _filteredSessions[index];
                            return _buildSessionCard(session);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        onDeleted: onDelete,
        deleteIcon: const Icon(Icons.close, size: 18),
      ),
    );
  }

  Widget _buildSessionCard(MeasurementSession session) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(session.status),
          child: Icon(
            _getStatusIcon(session.status),
            color: Colors.white,
          ),
        ),
        title: Text(session.workItemNameSnapshot),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(session.createdAt)),
            if (session.lotCode != null) Text('Wax lot: ${session.lotCode}'),
            Text(
              'Active: ${StatisticsService.formatTimeDisplay(session.activeMs)}',
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SessionDetailScreen(sessionId: session.id),
                ),
              );
            } else if (value == 'delete') {
              _deleteSession(session);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('Open sitting'),
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionDetailScreen(sessionId: session.id),
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Task filter
              const Text('Pour job'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _selectedWorkItemId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'All tasks',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All pour jobs'),
                  ),
                  ..._workItems.map((item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedWorkItemId = value);
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),

              // Status filter
              const Text('Status'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'All statuses',
                ),
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text('All statuses'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.statusCompleted,
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.statusInProgress,
                    child: Text('In Progress'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.statusPaused,
                    child: Text('Paused'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),

              // Date range
              const Text('Date Range'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _selectDateRange();
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _dateRange == null
                      ? 'Select date range'
                      : '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                ),
              ),
              const SizedBox(height: 16),

              // Sort by
              const Text('Sort By'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'newest',
                    label: Text('Newest'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: 'oldest',
                    label: Text('Oldest'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: 'duration',
                    label: Text('Duration'),
                    icon: Icon(Icons.timer),
                  ),
                ],
                selected: {_sortBy},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _sortBy = newSelection.first);
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _clearFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedWorkItemId != null ||
        _selectedStatus != null ||
        _dateRange != null;
  }

  String _getWorkItemName(String id) {
    final item = _workItems.where((w) => w.id == id).firstOrNull;
    return item?.name ?? 'Unknown';
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

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusCompleted:
        return Colors.green;
      case AppConstants.statusInProgress:
        return Colors.blue;
      case AppConstants.statusPaused:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.statusCompleted:
        return Icons.check;
      case AppConstants.statusInProgress:
        return Icons.play_arrow;
      case AppConstants.statusPaused:
        return Icons.pause;
      default:
        return Icons.circle;
    }
  }
}
