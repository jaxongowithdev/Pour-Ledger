class VersionChange {
  final int? id;
  final int versionId;
  final String description;

  VersionChange({
    this.id,
    required this.versionId,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'versionId': versionId,
      'description': description,
    };
  }

  factory VersionChange.fromMap(Map<String, dynamic> map) {
    return VersionChange(
      id: map['id'] as int?,
      versionId: map['versionId'] as int,
      description: map['description'] as String,
    );
  }

  VersionChange copyWith({
    int? id,
    int? versionId,
    String? description,
  }) {
    return VersionChange(
      id: id ?? this.id,
      versionId: versionId ?? this.versionId,
      description: description ?? this.description,
    );
  }
}
