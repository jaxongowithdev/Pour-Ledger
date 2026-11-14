class KilnSession {
  final int? id;
  final int testId;
  final String kilnId;
  final int targetTemperature;
  final int peakTemperature;
  final int holdMinutes;
  final String atmosphere;
  final DateTime? startedAt;
  final DateTime? completedAt;

  KilnSession({
    this.id,
    required this.testId,
    this.kilnId = '',
    required this.targetTemperature,
    this.peakTemperature = 0,
    this.holdMinutes = 10,
    this.atmosphere = 'oxidation',
    this.startedAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testId': testId,
      'kilnId': kilnId,
      'targetTemperature': targetTemperature,
      'peakTemperature': peakTemperature,
      'holdMinutes': holdMinutes,
      'atmosphere': atmosphere,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory KilnSession.fromMap(Map<String, dynamic> map) {
    return KilnSession(
      id: map['id'] as int?,
      testId: map['testId'] as int,
      kilnId: map['kilnId'] as String? ?? '',
      targetTemperature: map['targetTemperature'] as int,
      peakTemperature: map['peakTemperature'] as int? ?? 0,
      holdMinutes: map['holdMinutes'] as int? ?? 10,
      atmosphere: map['atmosphere'] as String? ?? 'oxidation',
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt'] as String) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
    );
  }

  KilnSession copyWith({
    int? id,
    int? testId,
    String? kilnId,
    int? targetTemperature,
    int? peakTemperature,
    int? holdMinutes,
    String? atmosphere,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return KilnSession(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      kilnId: kilnId ?? this.kilnId,
      targetTemperature: targetTemperature ?? this.targetTemperature,
      peakTemperature: peakTemperature ?? this.peakTemperature,
      holdMinutes: holdMinutes ?? this.holdMinutes,
      atmosphere: atmosphere ?? this.atmosphere,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
