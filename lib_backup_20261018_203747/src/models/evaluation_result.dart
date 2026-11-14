class EvaluationResult {
  final int? id;
  final int tileId;
  final String color;
  final String surface;
  final String texture;
  final String gloss;
  final String opacity;
  final String coverage;
  final String adhesion;
  final int rating;
  final String notes;
  final bool isBest;

  EvaluationResult({
    this.id,
    required this.tileId,
    this.color = '',
    this.surface = '',
    this.texture = '',
    this.gloss = '',
    this.opacity = '',
    this.coverage = '',
    this.adhesion = '',
    this.rating = 3,
    this.notes = '',
    this.isBest = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tileId': tileId,
      'color': color,
      'surface': surface,
      'texture': texture,
      'gloss': gloss,
      'opacity': opacity,
      'coverage': coverage,
      'adhesion': adhesion,
      'rating': rating,
      'notes': notes,
      'isBest': isBest ? 1 : 0,
    };
  }

  factory EvaluationResult.fromMap(Map<String, dynamic> map) {
    return EvaluationResult(
      id: map['id'] as int?,
      tileId: map['tileId'] as int,
      color: map['color'] as String? ?? '',
      surface: map['surface'] as String? ?? '',
      texture: map['texture'] as String? ?? '',
      gloss: map['gloss'] as String? ?? '',
      opacity: map['opacity'] as String? ?? '',
      coverage: map['coverage'] as String? ?? '',
      adhesion: map['adhesion'] as String? ?? '',
      rating: map['rating'] as int? ?? 3,
      notes: map['notes'] as String? ?? '',
      isBest: (map['isBest'] as int?) == 1,
    );
  }

  EvaluationResult copyWith({
    int? id,
    int? tileId,
    String? color,
    String? surface,
    String? texture,
    String? gloss,
    String? opacity,
    String? coverage,
    String? adhesion,
    int? rating,
    String? notes,
    bool? isBest,
  }) {
    return EvaluationResult(
      id: id ?? this.id,
      tileId: tileId ?? this.tileId,
      color: color ?? this.color,
      surface: surface ?? this.surface,
      texture: texture ?? this.texture,
      gloss: gloss ?? this.gloss,
      opacity: opacity ?? this.opacity,
      coverage: coverage ?? this.coverage,
      adhesion: adhesion ?? this.adhesion,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      isBest: isBest ?? this.isBest,
    );
  }

  String get statusText {
    if (rating >= 4) return 'Good';
    if (rating == 3) return 'Review';
    return 'Needs Revision';
  }
}
