class ExperimentRecord {
  final int? id;
  final int versionId;
  final String name;
  final DateTime testDate;
  final String targetCone;
  final String kilnId;
  final String status;
  final String notes;

  ExperimentRecord({
    this.id,
    required this.versionId,
    required this.name,
    DateTime? testDate,
    required this.targetCone,
    this.kilnId = '',
    this.status = 'preparing',
    this.notes = '',
  }) : testDate = testDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'versionId': versionId,
      'name': name,
      'testDate': testDate.toIso8601String(),
      'targetCone': targetCone,
      'kilnId': kilnId,
      'status': status,
      'notes': notes,
    };
  }

  factory ExperimentRecord.fromMap(Map<String, dynamic> map) {
    return ExperimentRecord(
      id: map['id'] as int?,
      versionId: map['versionId'] as int,
      name: map['name'] as String,
      testDate: DateTime.parse(map['testDate'] as String),
      targetCone: map['targetCone'] as String,
      kilnId: map['kilnId'] as String? ?? '',
      status: map['status'] as String? ?? 'preparing',
      notes: map['notes'] as String? ?? '',
    );
  }

  ExperimentRecord copyWith({
    int? id,
    int? versionId,
    String? name,
    DateTime? testDate,
    String? targetCone,
    String? kilnId,
    String? status,
    String? notes,
  }) {
    return ExperimentRecord(
      id: id ?? this.id,
      versionId: versionId ?? this.versionId,
      name: name ?? this.name,
      testDate: testDate ?? this.testDate,
      targetCone: targetCone ?? this.targetCone,
      kilnId: kilnId ?? this.kilnId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
