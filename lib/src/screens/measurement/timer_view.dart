import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/state_providers.dart';
import '../../models/work_item.dart';
import '../../models/measurement_session.dart';
import '../../models/cycle_record.dart';
import '../../models/session_event.dart';
import '../../services/cycle_analytics.dart';
import '../../utils/cycle_constants.dart';

class MeasurementScreen extends ConsumerStatefulWidget {
  final WorkItem? preselectedWorkItem;

  const MeasurementScreen({
    super.key,
    this.preselectedWorkItem,
  });

  @override
  ConsumerState<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends ConsumerState<MeasurementScreen>
    with WidgetsBindingObserver {
  WorkItem? _selectedWorkItem;
  String? _lotCode;
  String _timingMode = AppConstants.timingModeActive;
  MeasurementSession? _currentSession;
  final List<CycleRecord> _cycles = [];
  int _cycleSequence = 0;

  // State tracking
  bool _isStarted = false;
  bool _isPaused = false;
  DateTime? _lastBackgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedWorkItem = widget.preselectedWorkItem;
    _checkForActiveSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isStarted) {
      if (state == AppLifecycleState.paused) {
        _lastBackgroundTime = DateTime.now();
        _saveSession(); // Save state when going to background
      } else if (state == AppLifecycleState.resumed) {
        // Timer service automatically recalculates elapsed time
        // No manual adjustment needed due to monotonic clock
        _lastBackgroundTime = null;
      }
    }
  }

  Future<void> _checkForActiveSession() async {
    final activeSession = await ref.read(sessionRepoProvider).getActiveSession();
    if (activeSession != null && mounted) {
      // Restore active session
      setState(() {
        _currentSession = activeSession;
        _isStarted = true;
        _isPaused = activeSession.status == AppConstants.statusPaused;
      });

      // Restore timing service state
      final timingService = ref.read(timingServiceProvider);
      timingService.restoreState(
        sessionStartedAt: activeSession.startedAt!,
        accumulatedActiveMs: activeSession.activeMs,
        accumulatedPausedMs: activeSession.pausedMs,
        isPaused: _isPaused,
      );

      // Load existing cycles
      final cycles = await ref.read(sessionRepoProvider).getCycles(activeSession.id);
      _cycles.clear();
      _cycles.addAll(cycles);
      _cycleSequence = cycles.length;

      if (mounted) {
        setState(() {});
      }
    }
  }

  void _startSession() {
    if (_selectedWorkItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a pour job first')),
      );
      return;
    }

    final sessionId = const Uuid().v4();
    final now = DateTime.now();

    setState(() {
      _currentSession = MeasurementSession(
        id: sessionId,
        workItemId: _selectedWorkItem!.id,
        workItemNameSnapshot: _selectedWorkItem!.name,
        lotCode: _lotCode,
        status: AppConstants.statusInProgress,
        timingMode: _timingMode,
        startedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      _isStarted = true;
      _isPaused = false;
      _cycles.clear();
      _cycleSequence = 0;
    });

    // Start timing service
    final timingService = ref.read(timingServiceProvider);
    timingService.start();

    // Save session to database
    _saveSession();

    // Record start event
    _recordEvent(AppConstants.eventTypeStart, 'Sitting opened');
  }

  Future<void> _recordCycle() async {
    if (!_isStarted || _isPaused) return;

    final timingService = ref.read(timingServiceProvider);

    try {
      final cycleData = timingService.recordCycle();

      // Vibration feedback
      final settings = await ref.read(settingsProvider.future);
      if (settings.enableVibration) {
        HapticFeedback.mediumImpact();
      }

      final cycleId = const Uuid().v4();
      _cycleSequence++;

      final cycle = CycleRecord(
        id: cycleId,
        sessionId: _currentSession!.id,
        sequenceNumber: _cycleSequence,
        durationMs: cycleData.durationMs,
        startedOffsetMs: cycleData.startedOffsetMs,
        endedOffsetMs: cycleData.endedOffsetMs,
        createdAt: DateTime.now(),
      );

      setState(() {
        _cycles.add(cycle);
      });

      // Immediately save cycle to database
      await ref.read(sessionRepoProvider).insertCycle(cycle);

      // Update session
      await _saveSession();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Vessel ${cycle.sequenceNumber}: ${StatisticsService.formatDuration(cycle.durationMs)}s'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _pauseSession() {
    if (!_isStarted || _isPaused) return;

    setState(() {
      _isPaused = true;
      _currentSession = _currentSession!.copyWith(
        status: AppConstants.statusPaused,
      );
    });

    final timingService = ref.read(timingServiceProvider);
    timingService.pause();

    _saveSession();
    _recordEvent(AppConstants.eventTypePause, 'Pour resting');
  }

  void _resumeSession() {
    if (!_isStarted || !_isPaused) return;

    setState(() {
      _isPaused = false;
      _currentSession = _currentSession!.copyWith(
        status: AppConstants.statusInProgress,
      );
    });

    final timingService = ref.read(timingServiceProvider);
    timingService.resume();

    _saveSession();
    _recordEvent(AppConstants.eventTypeResume, 'Pouring again');
  }

  Future<void> _markEvent() async {
    if (!_isStarted) return;

    final timingService = ref.read(timingServiceProvider);
    final offsetMs = timingService.markEvent();

    // Show dialog to add event label
    final label = await showDialog<String>(
      context: context,
      builder: (context) => _EventDialog(),
    );

    if (label != null && label.isNotEmpty) {
      final event = SessionEvent(
        id: const Uuid().v4(),
        sessionId: _currentSession!.id,
        eventType: AppConstants.eventTypeMark,
        offsetMs: offsetMs,
        label: label,
        createdAt: DateTime.now(),
      );

      await ref.read(sessionRepoProvider).insertEvent(event);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note saved: $label')),
        );
      }
    }
  }

  Future<void> _endSession() async {
    if (!_isStarted) return;

    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close this sitting?'),
        content: Text(
          _cycles.isEmpty
              ? 'No vessels logged. Close this sitting?'
              : 'Close this sitting with ${_cycles.length} vessel(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close sitting'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final timingService = ref.read(timingServiceProvider);
    final endedAt = DateTime.now();
    final elapsedMs = timingService.elapsedMs;
    final activeMs = timingService.activeMs;
    final pausedMs = timingService.pausedMs;

    setState(() {
      _currentSession = _currentSession!.copyWith(
        status: AppConstants.statusCompleted,
        endedAt: endedAt,
        elapsedMs: elapsedMs,
        activeMs: activeMs,
        pausedMs: pausedMs,
        updatedAt: endedAt,
      );
    });

    // Save final session state
    await _saveSession();
    _recordEvent(AppConstants.eventTypeEnd, 'Sitting closed');

    // Stop timing service
    timingService.stop();
    timingService.reset();

    // Navigate to summary
    if (mounted) {
      _showSummary();
    }
  }

  Future<void> _saveSession() async {
    if (_currentSession == null) return;

    final timingService = ref.read(timingServiceProvider);

    final updatedSession = _currentSession!.copyWith(
      elapsedMs: timingService.elapsedMs,
      activeMs: timingService.activeMs,
      pausedMs: timingService.pausedMs,
      updatedAt: DateTime.now(),
    );

    try {
      final existing =
          await ref.read(sessionRepoProvider).getById(_currentSession!.id);
      if (existing == null) {
        await ref.read(sessionRepoProvider).insert(updatedSession);
      } else {
        await ref.read(sessionRepoProvider).update(updatedSession);
      }

      setState(() {
        _currentSession = updatedSession;
      });
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  Future<void> _recordEvent(String eventType, String label) async {
    if (_currentSession == null) return;

    final timingService = ref.read(timingServiceProvider);
    final event = SessionEvent(
      id: const Uuid().v4(),
      sessionId: _currentSession!.id,
      eventType: eventType,
      offsetMs: timingService.activeMs,
      label: label,
      createdAt: DateTime.now(),
    );

    await ref.read(sessionRepoProvider).insertEvent(event);
  }

  void _showSummary() {
    final stats = StatisticsService.calculateStatistics(_cycles);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sitting closed'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vessels: ${stats.count}'),
              Text(
                  'Hands-on time: ${StatisticsService.formatTimeDisplay(_currentSession!.activeMs)}'),
              if (stats.count > 0) ...[
                const Divider(),
                Text(
                    'Average: ${StatisticsService.formatDuration(stats.mean.round())}s'),
                Text(
                    'Median: ${StatisticsService.formatDuration(stats.median.round())}s'),
                Text(
                    'Fastest: ${StatisticsService.formatDuration(stats.fastest)}s'),
                Text(
                    'Slowest: ${StatisticsService.formatDuration(stats.slowest)}s'),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
              refreshSessions(ref);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timingService = ref.watch(timingServiceProvider);
    final workItems = ref.watch(workItemsProvider);

    return PopScope(
      canPop: !_isStarted,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _isStarted) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Leave the pour?'),
              content: const Text(
                  'This sitting is still open. It stays saved so you can come back.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );

          if (shouldExit == true && context.mounted) {
            await _saveSession();
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pour clock'),
          actions: _isStarted
              ? null
              : [
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () {
                      // Show history
                    },
                  ),
                ],
        ),
        body: _isStarted
            ? _buildActiveSession(timingService)
            : _buildSetup(workItems),
      ),
    );
  }

  Widget _buildSetup(AsyncValue<List<WorkItem>> workItemsAsync) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Set up the sitting',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Task selection
        workItemsAsync.when(
          data: (items) => DropdownButtonFormField<WorkItem>(
            key: const ValueKey('task_dropdown'),
            value: _selectedWorkItem,
            decoration: const InputDecoration(
              labelText: 'Pour job *',
              hintText: 'Choose a pour job',
            ),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item.name),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedWorkItem = value),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('Could not load pour jobs'),
        ),
        const SizedBox(height: 16),

        // Lot code
        TextField(
          key: const ValueKey('lot_code_field'),
          decoration: const InputDecoration(
            labelText: 'Wax lot (optional)',
          ),
          onChanged: (value) => _lotCode = value.isEmpty ? null : value,
        ),
        const SizedBox(height: 16),

        // Timing mode
        const Text('Clock mode'),
        RadioListTile<String>(
          title: const Text('Hands-on time'),
          subtitle: const Text('Leave pauses out of each vessel'),
          value: AppConstants.timingModeActive,
          groupValue: _timingMode,
          onChanged: (value) => setState(() => _timingMode = value!),
        ),
        RadioListTile(
          title: const Text('Full span'),
          subtitle: const Text('Count pauses inside each vessel'),
          value: AppConstants.timingModeTotal,
          groupValue: _timingMode,
          onChanged: (value) => setState(() => _timingMode = value!),
        ),
        const SizedBox(height: 24),

        // Start button
        FilledButton.icon(
          key: const ValueKey('start_button'),
          onPressed: _startSession,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Begin sitting'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSession(timingService) {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Task info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _currentSession!.workItemNameSnapshot,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (_currentSession!.lotCode != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Wax lot: ${_currentSession!.lotCode}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Timer display
              Text(
                StatisticsService.formatTimeDisplay(timingService.activeMs),
                key: const ValueKey('timer_display'),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isPaused ? 'RESTING' : 'POURING',
                style: TextStyle(
                  fontSize: 16,
                  color: _isPaused ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Cycles count
              Text(
                'Vessels: ${_cycles.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_cycles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Last: ${StatisticsService.formatDuration(_cycles.last.durationMs)}s',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),

        // Control buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('record_cycle_button'),
                      onPressed: _isPaused ? null : _recordCycle,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Log vessel'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPaused ? _resumeSession : _pauseSession,
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(_isPaused ? 'Resume' : 'Pause'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('mark_event_button'),
                      onPressed: _isStarted ? _markEvent : null,
                      icon: const Icon(Icons.flag),
                      label: const Text('Bench note'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('end_session_button'),
                onPressed: _endSession,
                icon: const Icon(Icons.stop),
                label: const Text('Close sitting'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EventDialog extends StatefulWidget {
  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bench note'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Note',
          hintText: 'e.g. Fragrance add, wick swap',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
