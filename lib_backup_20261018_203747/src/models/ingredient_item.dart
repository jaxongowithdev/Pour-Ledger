class IngredientItem {
  final int? id;
  final String name;
  final String category;
  final String defaultUnit;

  IngredientItem({
    this.id,
    required this.name,
    required this.category,
    this.defaultUnit = 'g',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'defaultUnit': defaultUnit,
    };
  }

  factory IngredientItem.fromMap(Map<String, dynamic> map) {
    return IngredientItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      defaultUnit: map['defaultUnit'] as String? ?? 'g',
    );
  }

  IngredientItem copyWith({
    int? id,
    String? name,
    String? category,
    String? defaultUnit,
  }) {
    return IngredientItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      defaultUnit: defaultUnit ?? this.defaultUnit,
    );
  }
}
