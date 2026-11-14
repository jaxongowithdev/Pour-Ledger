class ExperimentPhoto {
  final int? id;
  final int testId;
  final int? tileId;
  final String stage;
  final String path;
  final String caption;

  ExperimentPhoto({
    this.id,
    required this.testId,
    this.tileId,
    required this.stage,
    required this.path,
    this.caption = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testId': testId,
      'tileId': tileId,
      'stage': stage,
      'path': path,
      'caption': caption,
    };
  }

  factory ExperimentPhoto.fromMap(Map<String, dynamic> map) {
    return ExperimentPhoto(
      id: map['id'] as int?,
      testId: map['testId'] as int,
      tileId: map['tileId'] as int?,
      stage: map['stage'] as String,
      path: map['path'] as String,
      caption: map['caption'] as String? ?? '',
    );
  }

  ExperimentPhoto copyWith({
    int? id,
    int? testId,
    int? tileId,
    String? stage,
    String? path,
    String? caption,
  }) {
    return ExperimentPhoto(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      tileId: tileId ?? this.tileId,
      stage: stage ?? this.stage,
      path: path ?? this.path,
      caption: caption ?? this.caption,
    );
  }
}
