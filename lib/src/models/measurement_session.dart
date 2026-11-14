class MeasurementSession {
  final String id;
  final String? workItemId;
  final String workItemNameSnapshot;
  final String? lotCode;
  final String status;
  final String timingMode;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int elapsedMs;
  final int activeMs;
  final int pausedMs;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MeasurementSession({
    required this.id,
    this.workItemId,
    required this.workItemNameSnapshot,
    this.lotCode,
    required this.status,
    required this.timingMode,
    this.startedAt,
    this.endedAt,
    this.elapsedMs = 0,
    this.activeMs = 0,
    this.pausedMs = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'work_item_id': workItemId,
      'work_item_name_snapshot': workItemNameSnapshot,
      'lot_code': lotCode,
      'status': status,
      'timing_mode': timingMode,
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'elapsed_ms': elapsedMs,
      'active_ms': activeMs,
      'paused_ms': pausedMs,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MeasurementSession.fromMap(Map<String, dynamic> map) {
    return MeasurementSession(
      id: map['id'] as String,
      workItemId: map['work_item_id'] as String?,
      workItemNameSnapshot: map['work_item_name_snapshot'] as String,
      lotCode: map['lot_code'] as String?,
      status: map['status'] as String,
      timingMode: map['timing_mode'] as String,
      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at'] as String)
          : null,
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
      elapsedMs: map['elapsed_ms'] as int? ?? 0,
      activeMs: map['active_ms'] as int? ?? 0,
      pausedMs: map['paused_ms'] as int? ?? 0,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  MeasurementSession copyWith({
    String? id,
    String? workItemId,
    String? workItemNameSnapshot,
    String? lotCode,
    String? status,
    String? timingMode,
    DateTime? startedAt,
    DateTime? endedAt,
    int? elapsedMs,
    int? activeMs,
    int? pausedMs,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeasurementSession(
      id: id ?? this.id,
      workItemId: workItemId ?? this.workItemId,
      workItemNameSnapshot: workItemNameSnapshot ?? this.workItemNameSnapshot,
      lotCode: lotCode ?? this.lotCode,
      status: status ?? this.status,
      timingMode: timingMode ?? this.timingMode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      activeMs: activeMs ?? this.activeMs,
      pausedMs: pausedMs ?? this.pausedMs,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
