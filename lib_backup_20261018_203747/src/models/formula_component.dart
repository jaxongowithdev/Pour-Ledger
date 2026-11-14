class FormulaComponent {
  final int? id;
  final int versionId;
  final int ingredientId;
  final double weight;
  final double percentage;

  FormulaComponent({
    this.id,
    required this.versionId,
    required this.ingredientId,
    required this.weight,
    required this.percentage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'versionId': versionId,
      'ingredientId': ingredientId,
      'weight': weight,
      'percentage': percentage,
    };
  }

  factory FormulaComponent.fromMap(Map<String, dynamic> map) {
    return FormulaComponent(
      id: map['id'] as int?,
      versionId: map['versionId'] as int,
      ingredientId: map['ingredientId'] as int,
      weight: (map['weight'] as num).toDouble(),
      percentage: (map['percentage'] as num).toDouble(),
    );
  }

  FormulaComponent copyWith({
    int? id,
    int? versionId,
    int? ingredientId,
    double? weight,
    double? percentage,
  }) {
    return FormulaComponent(
      id: id ?? this.id,
      versionId: versionId ?? this.versionId,
      ingredientId: ingredientId ?? this.ingredientId,
      weight: weight ?? this.weight,
      percentage: percentage ?? this.percentage,
    );
  }
}
