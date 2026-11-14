import 'dart:math';
import '../models/cycle_record.dart';

class CycleStatistics {
  final int count;
  final double mean;
  final double median;
  final int fastest;
  final int slowest;
  final int range;
  final double? standardDeviation;
  final int totalDuration;

  CycleStatistics({
    required this.count,
    required this.mean,
    required this.median,
    required this.fastest,
    required this.slowest,
    required this.range,
    this.standardDeviation,
    required this.totalDuration,
  });
}

class StatisticsService {
  /// Calculate comprehensive statistics from cycle records
  static CycleStatistics calculateStatistics(
    List<CycleRecord> cycles, {
    bool excludeFlagged = false,
  }) {
    // Filter cycles
    var validCycles = cycles;
    if (excludeFlagged) {
      validCycles = cycles.where((c) => !c.isFlagged).toList();
    }

    if (validCycles.isEmpty) {
      return CycleStatistics(
        count: 0,
        mean: 0,
        median: 0,
        fastest: 0,
        slowest: 0,
        range: 0,
        standardDeviation: null,
        totalDuration: 0,
      );
    }

    final durations = validCycles.map((c) => c.durationMs).toList();

    // Calculate mean
    final sum = durations.reduce((a, b) => a + b);
    final mean = sum / durations.length;

    // Calculate median
    final sortedDurations = List<int>.from(durations)..sort();
    final median = _calculateMedian(sortedDurations);

    // Calculate min/max
    final fastest = sortedDurations.first;
    final slowest = sortedDurations.last;
    final range = slowest - fastest;

    // Calculate standard deviation (sample)
    double? stdDev;
    if (durations.length >= 2) {
      final variance = durations
              .map((d) => pow(d - mean, 2))
              .reduce((a, b) => a + b) /
          (durations.length - 1);
      stdDev = sqrt(variance);
    }

    return CycleStatistics(
      count: validCycles.length,
      mean: mean,
      median: median.toDouble(),
      fastest: fastest,
      slowest: slowest,
      range: range,
      standardDeviation: stdDev,
      totalDuration: sum,
    );
  }

  static double _calculateMedian(List<int> sortedValues) {
    final length = sortedValues.length;
    if (length == 0) return 0;

    if (length % 2 == 1) {
      return sortedValues[length ~/ 2].toDouble();
    } else {
      final mid1 = sortedValues[length ~/ 2 - 1];
      final mid2 = sortedValues[length ~/ 2];
      return (mid1 + mid2) / 2;
    }
  }

  /// Calculate deviation from mean for a cycle
  static double calculateDeviation(int durationMs, double mean) {
    return durationMs - mean;
  }

  /// Calculate percentage deviation from mean
  static double calculatePercentageDeviation(int durationMs, double mean) {
    if (mean == 0) return 0;
    return ((durationMs - mean) / mean) * 100;
  }

  /// Format milliseconds to human-readable string
  static String formatDuration(
    int milliseconds, {
    int decimalPlaces = 1,
    String unit = 'seconds',
  }) {
    if (milliseconds < 0) return '0';

    switch (unit) {
      case 'milliseconds':
        return milliseconds.toString();
      case 'minutes':
        final minutes = milliseconds / 60000;
        return minutes.toStringAsFixed(decimalPlaces);
      case 'hours':
        final hours = milliseconds / 3600000;
        return hours.toStringAsFixed(decimalPlaces);
      case 'seconds':
      default:
        final seconds = milliseconds / 1000;
        return seconds.toStringAsFixed(decimalPlaces);
    }
  }

  /// Format time display (mm:ss.SSS or hh:mm:ss.SSS)
  static String formatTimeDisplay(int milliseconds) {
    if (milliseconds < 0) return '00:00.000';

    final hours = milliseconds ~/ 3600000;
    final minutes = (milliseconds % 3600000) ~/ 60000;
    final seconds = (milliseconds % 60000) ~/ 1000;
    final ms = milliseconds % 1000;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
    }
  }

  /// Parse formatted duration string back to milliseconds
  static int parseDuration(String value, String unit) {
    final numValue = double.tryParse(value) ?? 0;

    switch (unit) {
      case 'milliseconds':
        return numValue.round();
      case 'minutes':
        return (numValue * 60000).round();
      case 'hours':
        return (numValue * 3600000).round();
      case 'seconds':
      default:
        return (numValue * 1000).round();
    }
  }

  /// Get time unit label
  static String getUnitLabel(String unit) {
    switch (unit) {
      case 'milliseconds':
        return 'ms';
      case 'minutes':
        return 'min';
      case 'hours':
        return 'hr';
      case 'seconds':
      default:
        return 's';
    }
  }
}
