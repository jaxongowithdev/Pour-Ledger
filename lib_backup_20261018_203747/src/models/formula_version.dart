class FormulaVersion {
  final int? id;
  final int glazeId;
  final String version;
  final String notes;
  final DateTime createdAt;

  FormulaVersion({
    this.id,
    required this.glazeId,
    required this.version,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'glazeId': glazeId,
      'version': version,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FormulaVersion.fromMap(Map<String, dynamic> map) {
    return FormulaVersion(
      id: map['id'] as int?,
      glazeId: map['glazeId'] as int,
      version: map['version'] as String,
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  FormulaVersion copyWith({
    int? id,
    int? glazeId,
    String? version,
    String? notes,
    DateTime? createdAt,
  }) {
    return FormulaVersion(
      id: id ?? this.id,
      glazeId: glazeId ?? this.glazeId,
      version: version ?? this.version,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
