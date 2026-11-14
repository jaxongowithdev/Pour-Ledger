class DefectRecord {
  final int? id;
  final int resultId;
  final String defectType;

  DefectRecord({
    this.id,
    required this.resultId,
    required this.defectType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'resultId': resultId,
      'defectType': defectType,
    };
  }

  factory DefectRecord.fromMap(Map<String, dynamic> map) {
    return DefectRecord(
      id: map['id'] as int?,
      resultId: map['resultId'] as int,
      defectType: map['defectType'] as String,
    );
  }

  DefectRecord copyWith({
    int? id,
    int? resultId,
    String? defectType,
  }) {
    return DefectRecord(
      id: id ?? this.id,
      resultId: resultId ?? this.resultId,
      defectType: defectType ?? this.defectType,
    );
  }
}
