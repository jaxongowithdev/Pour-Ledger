class WorkItem {
  final String id;
  final String name;
  final String? code;
  final String? category;
  final String? description;
  final int? targetCycleMs;
  final String productUnit;
  final int? colorValue;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkItem({
    required this.id,
    required this.name,
    this.code,
    this.category,
    this.description,
    this.targetCycleMs,
    this.productUnit = 'product',
    this.colorValue,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'category': category,
      'description': description,
      'target_cycle_ms': targetCycleMs,
      'product_unit': productUnit,
      'color_value': colorValue,
      'is_pinned': isPinned ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WorkItem.fromMap(Map<String, dynamic> map) {
    return WorkItem(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String?,
      category: map['category'] as String?,
      description: map['description'] as String?,
      targetCycleMs: map['target_cycle_ms'] as int?,
      productUnit: map['product_unit'] as String? ?? 'product',
      colorValue: map['color_value'] as int?,
      isPinned: (map['is_pinned'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  WorkItem copyWith({
    String? id,
    String? name,
    String? code,
    String? category,
    String? description,
    int? targetCycleMs,
    String? productUnit,
    int? colorValue,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkItem(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      description: description ?? this.description,
      targetCycleMs: targetCycleMs ?? this.targetCycleMs,
      productUnit: productUnit ?? this.productUnit,
      colorValue: colorValue ?? this.colorValue,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
