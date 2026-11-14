import '../database/cycle_time_database.dart';
import '../models/user_preferences.dart';

class SettingsRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<UserPreferences> getSettings() async {
    final db = await _db.database;
    final result = await db.query('app_settings', where: 'id = 1');
    if (result.isEmpty) {
      // Return default settings if not found
      return UserPreferences();
    }
    return UserPreferences.fromMap(result.first);
  }

  Future<void> updateSettings(UserPreferences settings) async {
    final db = await _db.database;
    await db.update(
      'app_settings',
      settings.toMap(),
      where: 'id = 1',
    );
  }
}
