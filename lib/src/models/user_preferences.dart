class UserPreferences {
  final String themeMode;
  final String timeUnit;
  final int decimalPlaces;
  final bool enableVibration;
  final String pauseHandling;

  UserPreferences({
    this.themeMode = 'system',
    this.timeUnit = 'seconds',
    this.decimalPlaces = 1,
    this.enableVibration = true,
    this.pauseHandling = 'exclude',
  });

  Map<String, dynamic> toMap() {
    return {
      'theme_mode': themeMode,
      'time_unit': timeUnit,
      'decimal_places': decimalPlaces,
      'enable_vibration': enableVibration ? 1 : 0,
      'pause_handling': pauseHandling,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      themeMode: map['theme_mode'] as String? ?? 'system',
      timeUnit: map['time_unit'] as String? ?? 'seconds',
      decimalPlaces: map['decimal_places'] as int? ?? 1,
      enableVibration: (map['enable_vibration'] as int?) == 1,
      pauseHandling: map['pause_handling'] as String? ?? 'exclude',
    );
  }

  UserPreferences copyWith({
    String? themeMode,
    String? timeUnit,
    int? decimalPlaces,
    bool? enableVibration,
    String? pauseHandling,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      timeUnit: timeUnit ?? this.timeUnit,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      enableVibration: enableVibration ?? this.enableVibration,
      pauseHandling: pauseHandling ?? this.pauseHandling,
    );
  }
}
