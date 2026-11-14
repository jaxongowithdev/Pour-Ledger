class AppConstants {
  // Session status
  static const String statusNotStarted = 'not_started';
  static const String statusInProgress = 'in_progress';
  static const String statusPaused = 'paused';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Timing modes
  static const String timingModeTotal = 'total_duration';
  static const String timingModeActive = 'active_duration';

  // Event types
  static const String eventTypeStart = 'start';
  static const String eventTypePause = 'pause';
  static const String eventTypeResume = 'resume';
  static const String eventTypeEnd = 'end';
  static const String eventTypeMark = 'mark';

  // Time units
  static const String unitSeconds = 'seconds';
  static const String unitMinutes = 'minutes';
  static const String unitHours = 'hours';
  static const String unitMilliseconds = 'milliseconds';

  // Theme modes
  static const String themeSystem = 'system';
  static const String themeLight = 'light';
  static const String themeDark = 'dark';

  // Pause handling
  static const String pauseInclude = 'include';
  static const String pauseExclude = 'exclude';

  // Validation
  static const int minCycleDurationMs = 1;
  static const int maxDecimalPlaces = 3;
  static const int minDecimalPlaces = 0;

  // UI
  static const int recentSessionsLimit = 5;
  static const double cardElevation = 2;
  static const double borderRadius = 12;
}
