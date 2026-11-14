class UserPreferences {
  final int? id;
  final String themeMode;
  final String temperatureUnit;
  final String weightUnit;
  final String language;
  final bool notificationsEnabled;

  UserPreferences({
    this.id,
    this.themeMode = 'system',
    this.temperatureUnit = 'celsius',
    this.weightUnit = 'g',
    this.language = 'en',
    this.notificationsEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'themeMode': themeMode,
      'temperatureUnit': temperatureUnit,
      'weightUnit': weightUnit,
      'language': language,
      'notificationsEnabled': notificationsEnabled ? 1 : 0,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      id: map['id'] as int?,
      themeMode: map['themeMode'] as String? ?? 'system',
      temperatureUnit: map['temperatureUnit'] as String? ?? 'celsius',
      weightUnit: map['weightUnit'] as String? ?? 'g',
      language: map['language'] as String? ?? 'en',
      notificationsEnabled: (map['notificationsEnabled'] as int?) == 1,
    );
  }

  UserPreferences copyWith({
    int? id,
    String? themeMode,
    String? temperatureUnit,
    String? weightUnit,
    String? language,
    bool? notificationsEnabled,
  }) {
    return UserPreferences(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      weightUnit: weightUnit ?? this.weightUnit,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
