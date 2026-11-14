class CycleRecord {
  final String id;
  final String sessionId;
  final int sequenceNumber;
  final int durationMs;
  final int? startedOffsetMs;
  final int? endedOffsetMs;
  final bool isFlagged;
  final String? flagReason;
  final String? notes;
  final DateTime createdAt;

  CycleRecord({
    required this.id,
    required this.sessionId,
    required this.sequenceNumber,
    required this.durationMs,
    this.startedOffsetMs,
    this.endedOffsetMs,
    this.isFlagged = false,
    this.flagReason,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'sequence_number': sequenceNumber,
      'duration_ms': durationMs,
      'started_offset_ms': startedOffsetMs,
      'ended_offset_ms': endedOffsetMs,
      'is_flagged': isFlagged ? 1 : 0,
      'flag_reason': flagReason,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CycleRecord.fromMap(Map<String, dynamic> map) {
    return CycleRecord(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      sequenceNumber: map['sequence_number'] as int,
      durationMs: map['duration_ms'] as int,
      startedOffsetMs: map['started_offset_ms'] as int?,
      endedOffsetMs: map['ended_offset_ms'] as int?,
      isFlagged: (map['is_flagged'] as int?) == 1,
      flagReason: map['flag_reason'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  CycleRecord copyWith({
    String? id,
    String? sessionId,
    int? sequenceNumber,
    int? durationMs,
    int? startedOffsetMs,
    int? endedOffsetMs,
    bool? isFlagged,
    String? flagReason,
    String? notes,
    DateTime? createdAt,
  }) {
    return CycleRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      durationMs: durationMs ?? this.durationMs,
      startedOffsetMs: startedOffsetMs ?? this.startedOffsetMs,
      endedOffsetMs: endedOffsetMs ?? this.endedOffsetMs,
      isFlagged: isFlagged ?? this.isFlagged,
      flagReason: flagReason ?? this.flagReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
