class GlazeEntity {
  final int? id;
  final String name;
  final String description;
  final bool favorite;
  final DateTime createdAt;

  GlazeEntity({
    this.id,
    required this.name,
    this.description = '',
    this.favorite = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'favorite': favorite ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GlazeEntity.fromMap(Map<String, dynamic> map) {
    return GlazeEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      favorite: (map['favorite'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  GlazeEntity copyWith({
    int? id,
    String? name,
    String? description,
    bool? favorite,
    DateTime? createdAt,
  }) {
    return GlazeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
