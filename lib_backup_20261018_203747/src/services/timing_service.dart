import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service for accurate time measurement using monotonic clock
/// Critical: Uses Stopwatch (monotonic) not DateTime (wall clock)
class TimingService extends ChangeNotifier {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiUpdateTimer;

  // State tracking
  DateTime? _sessionStartedAt;
  DateTime? _lastPauseAt;
  DateTime? _lastResumeAt;

  int _accumulatedActiveMs = 0;
  int _accumulatedPausedMs = 0;
  int _currentCycleStartOffsetMs = 0;

  bool _isPaused = false;

  // Getters
  bool get isRunning => _stopwatch.isRunning;
  bool get isPaused => _isPaused;

  int get elapsedMs => _stopwatch.elapsedMilliseconds;

  int get activeMs {
    if (_isPaused) {
      return _accumulatedActiveMs;
    }
    return _accumulatedActiveMs + _stopwatch.elapsedMilliseconds;
  }

  int get pausedMs => _accumulatedPausedMs;

  DateTime? get sessionStartedAt => _sessionStartedAt;
  DateTime? get lastPauseAt => _lastPauseAt;
  DateTime? get lastResumeAt => _lastResumeAt;

  /// Start the timer
  void start() {
    if (_stopwatch.isRunning) return;

    _sessionStartedAt = DateTime.now();
    _stopwatch.start();
    _isPaused = false;

    // Update UI every 10ms for smooth display
    _uiUpdateTimer = Timer.periodic(
      const Duration(milliseconds: 10),
      (_) => notifyListeners(),
    );

    notifyListeners();
    debugPrint('Timer started at ${_sessionStartedAt}');
  }

  /// Pause the timer
  void pause() {
    if (!_stopwatch.isRunning || _isPaused) return;

    _lastPauseAt = DateTime.now();
    final currentElapsed = _stopwatch.elapsedMilliseconds;
    _accumulatedActiveMs += currentElapsed;

    _stopwatch.stop();
    _stopwatch.reset();
    _isPaused = true;

    notifyListeners();
    debugPrint(
        'Timer paused. Active: ${_accumulatedActiveMs}ms, Paused: ${_accumulatedPausedMs}ms');
  }

  /// Resume the timer
  void resume() {
    if (_stopwatch.isRunning || !_isPaused) return;

    _lastResumeAt = DateTime.now();

    // Calculate pause duration
    if (_lastPauseAt != null) {
      final pauseDuration =
          _lastResumeAt!.difference(_lastPauseAt!).inMilliseconds;
      _accumulatedPausedMs += pauseDuration;
    }

    _stopwatch.start();
    _isPaused = false;

    notifyListeners();
    debugPrint(
        'Timer resumed. Active: ${_accumulatedActiveMs}ms, Paused: ${_accumulatedPausedMs}ms');
  }

  /// Record a cycle and return its duration
  CycleTimingData recordCycle() {
    if (!_stopwatch.isRunning || _isPaused) {
      throw StateError('Cannot record cycle when timer is not running');
    }

    final endOffsetMs = activeMs;
    final durationMs = endOffsetMs - _currentCycleStartOffsetMs;

    if (durationMs <= 0) {
      throw ArgumentError('Cycle duration must be positive');
    }

    final cycleData = CycleTimingData(
      durationMs: durationMs,
      startedOffsetMs: _currentCycleStartOffsetMs,
      endedOffsetMs: endOffsetMs,
    );

    // Start next cycle
    _currentCycleStartOffsetMs = endOffsetMs;

    debugPrint('Cycle recorded: ${durationMs}ms');
    return cycleData;
  }

  /// Mark an event and return the offset
  int markEvent() {
    if (!_stopwatch.isRunning) {
      throw StateError('Cannot mark event when timer is not running');
    }

    final offsetMs = activeMs;
    debugPrint('Event marked at offset: ${offsetMs}ms');
    return offsetMs;
  }

  /// Stop and reset the timer
  void stop() {
    _stopwatch.stop();
    _stopwatch.reset();
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = null;
    _isPaused = false;

    notifyListeners();
    debugPrint('Timer stopped and reset');
  }

  /// Reset all state (for new session)
  void reset() {
    _stopwatch.stop();
    _stopwatch.reset();
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = null;

    _sessionStartedAt = null;
    _lastPauseAt = null;
    _lastResumeAt = null;
    _accumulatedActiveMs = 0;
    _accumulatedPausedMs = 0;
    _currentCycleStartOffsetMs = 0;
    _isPaused = false;

    notifyListeners();
    debugPrint('Timer fully reset');
  }

  /// Restore state from saved session (for app restart)
  void restoreState({
    required DateTime sessionStartedAt,
    required int accumulatedActiveMs,
    required int accumulatedPausedMs,
    required bool isPaused,
    DateTime? lastPauseAt,
  }) {
    _sessionStartedAt = sessionStartedAt;
    _accumulatedActiveMs = accumulatedActiveMs;
    _accumulatedPausedMs = accumulatedPausedMs;
    _isPaused = isPaused;
    _lastPauseAt = lastPauseAt;
    _currentCycleStartOffsetMs = accumulatedActiveMs;

    if (!isPaused) {
      _stopwatch.start();
      _uiUpdateTimer = Timer.periodic(
        const Duration(milliseconds: 10),
        (_) => notifyListeners(),
      );
    }

    notifyListeners();
    debugPrint('Timer state restored. Active: ${accumulatedActiveMs}ms');
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}

class CycleTimingData {
  final int durationMs;
  final int startedOffsetMs;
  final int endedOffsetMs;

  CycleTimingData({
    required this.durationMs,
    required this.startedOffsetMs,
    required this.endedOffsetMs,
  });
}
