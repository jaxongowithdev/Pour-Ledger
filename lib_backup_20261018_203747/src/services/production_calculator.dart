class ProductionCalculation {
  final int theoreticalOutput;
  final int estimatedOutput;
  final int timeRequiredMs;
  final int requiredCycleMs;
  final int outputDeficit;
  final bool isValid;
  final String? errorMessage;

  ProductionCalculation({
    required this.theoreticalOutput,
    required this.estimatedOutput,
    required this.timeRequiredMs,
    required this.requiredCycleMs,
    required this.outputDeficit,
    this.isValid = true,
    this.errorMessage,
  });

  factory ProductionCalculation.error(String message) {
    return ProductionCalculation(
      theoreticalOutput: 0,
      estimatedOutput: 0,
      timeRequiredMs: 0,
      requiredCycleMs: 0,
      outputDeficit: 0,
      isValid: false,
      errorMessage: message,
    );
  }
}

class ProductionCalculator {
  /// Calculate production output based on cycle time and working conditions
  ///
  /// Formulas:
  /// T_net = T_shift - T_break
  /// Q_theory = T_net / T_cycle
  /// Q_estimated = Q_theory * (E / 100)
  static ProductionCalculation calculate({
    required int avgCycleMs,
    required int shiftDurationMs,
    required int breakDurationMs,
    required double efficiency,
    int? targetQuantity,
  }) {
    // Validation
    if (avgCycleMs <= 0) {
      return ProductionCalculation.error('Cycle time must be greater than zero');
    }

    if (shiftDurationMs <= 0) {
      return ProductionCalculation.error('Shift duration must be greater than zero');
    }

    if (breakDurationMs < 0) {
      return ProductionCalculation.error('Break duration cannot be negative');
    }

    if (breakDurationMs >= shiftDurationMs) {
      return ProductionCalculation.error(
          'Break duration cannot exceed shift duration');
    }

    if (efficiency <= 0 || efficiency > 100) {
      return ProductionCalculation.error(
          'Efficiency must be between 0 and 100');
    }

    // Calculate net working time
    final netWorkingMs = shiftDurationMs - breakDurationMs;

    // Calculate theoretical output (rounded down to whole units)
    final theoreticalOutput = netWorkingMs ~/ avgCycleMs;

    // Calculate estimated output with efficiency (rounded down)
    final estimatedOutput = (theoreticalOutput * (efficiency / 100)).floor();

    // Calculate time required to reach target
    int timeRequiredMs = 0;
    int requiredCycleMs = 0;
    int outputDeficit = 0;

    if (targetQuantity != null && targetQuantity > 0) {
      // Time required for target quantity at current cycle time
      timeRequiredMs = (targetQuantity * avgCycleMs / (efficiency / 100)).ceil();

      // Required cycle time to meet target within net working time
      if (targetQuantity > 0) {
        requiredCycleMs =
            (netWorkingMs * (efficiency / 100) / targetQuantity).floor();
      }

      // Calculate deficit/surplus
      outputDeficit = targetQuantity - estimatedOutput;
    }

    return ProductionCalculation(
      theoreticalOutput: theoreticalOutput,
      estimatedOutput: estimatedOutput,
      timeRequiredMs: timeRequiredMs,
      requiredCycleMs: requiredCycleMs,
      outputDeficit: outputDeficit,
    );
  }

  /// Calculate required cycle time to meet target
  static int calculateRequiredCycleTime({
    required int targetQuantity,
    required int netWorkingMs,
    required double efficiency,
  }) {
    if (targetQuantity <= 0 || netWorkingMs <= 0 || efficiency <= 0) {
      return 0;
    }

    return (netWorkingMs * (efficiency / 100) / targetQuantity).floor();
  }

  /// Calculate output for given parameters
  static int calculateOutput({
    required int avgCycleMs,
    required int netWorkingMs,
    required double efficiency,
  }) {
    if (avgCycleMs <= 0 || netWorkingMs <= 0) {
      return 0;
    }

    final theoretical = netWorkingMs ~/ avgCycleMs;
    return (theoretical * (efficiency / 100)).floor();
  }

  /// Format time in hours and minutes
  static String formatTimeHoursMinutes(int milliseconds) {
    final totalMinutes = milliseconds ~/ 60000;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      return '$hours hr ${minutes} min';
    } else {
      return '$minutes min';
    }
  }
}
