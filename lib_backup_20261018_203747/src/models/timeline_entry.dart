class TimelineEntry {
  final int? id;
  final int testId;
  final String action;
  final String description;
  final DateTime createdAt;

  TimelineEntry({
    this.id,
    required this.testId,
    required this.action,
    required this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testId': testId,
      'action': action,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TimelineEntry.fromMap(Map<String, dynamic> map) {
    return TimelineEntry(
      id: map['id'] as int?,
      testId: map['testId'] as int,
      action: map['action'] as String,
      description: map['description'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  TimelineEntry copyWith({
    int? id,
    int? testId,
    String? action,
    String? description,
    DateTime? createdAt,
  }) {
    return TimelineEntry(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      action: action ?? this.action,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
