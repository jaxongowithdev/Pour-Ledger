class SessionEvent {
  final String id;
  final String sessionId;
  final String eventType;
  final int offsetMs;
  final String? label;
  final String? notes;
  final DateTime createdAt;

  SessionEvent({
    required this.id,
    required this.sessionId,
    required this.eventType,
    required this.offsetMs,
    this.label,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'event_type': eventType,
      'offset_ms': offsetMs,
      'label': label,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SessionEvent.fromMap(Map<String, dynamic> map) {
    return SessionEvent(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      eventType: map['event_type'] as String,
      offsetMs: map['offset_ms'] as int,
      label: map['label'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SessionEvent copyWith({
    String? id,
    String? sessionId,
    String? eventType,
    int? offsetMs,
    String? label,
    String? notes,
    DateTime? createdAt,
  }) {
    return SessionEvent(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      eventType: eventType ?? this.eventType,
      offsetMs: offsetMs ?? this.offsetMs,
      label: label ?? this.label,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
