import '../database/app_database.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<AppSettings> getSettings() async {
    final db = await _db.database;
    final result = await db.query('app_settings', where: 'id = 1');
    if (result.isEmpty) {
      // Return default settings if not found
      return AppSettings();
    }
    return AppSettings.fromMap(result.first);
  }

  Future<void> updateSettings(AppSettings settings) async {
    final db = await _db.database;
    await db.update(
      'app_settings',
      settings.toMap(),
      where: 'id = 1',
    );
  }
}
