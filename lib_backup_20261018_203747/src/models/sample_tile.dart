class SampleTile {
  final int? id;
  final int testId;
  final int number;
  final String clayBody;
  final String applicationMethod;
  final int layerCount;
  final String thickness;
  final String notes;

  SampleTile({
    this.id,
    required this.testId,
    required this.number,
    this.clayBody = '',
    this.applicationMethod = 'brush',
    this.layerCount = 2,
    this.thickness = 'medium',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testId': testId,
      'number': number,
      'clayBody': clayBody,
      'applicationMethod': applicationMethod,
      'layerCount': layerCount,
      'thickness': thickness,
      'notes': notes,
    };
  }

  factory SampleTile.fromMap(Map<String, dynamic> map) {
    return SampleTile(
      id: map['id'] as int?,
      testId: map['testId'] as int,
      number: map['number'] as int,
      clayBody: map['clayBody'] as String? ?? '',
      applicationMethod: map['applicationMethod'] as String? ?? 'brush',
      layerCount: map['layerCount'] as int? ?? 2,
      thickness: map['thickness'] as String? ?? 'medium',
      notes: map['notes'] as String? ?? '',
    );
  }

  SampleTile copyWith({
    int? id,
    int? testId,
    int? number,
    String? clayBody,
    String? applicationMethod,
    int? layerCount,
    String? thickness,
    String? notes,
  }) {
    return SampleTile(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      number: number ?? this.number,
      clayBody: clayBody ?? this.clayBody,
      applicationMethod: applicationMethod ?? this.applicationMethod,
      layerCount: layerCount ?? this.layerCount,
      thickness: thickness ?? this.thickness,
      notes: notes ?? this.notes,
    );
  }
}
