import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/cycle_time_database.dart';
import '../repositories/task_data_store.dart';
import '../repositories/measurement_data_store.dart';
import '../repositories/config_data_store.dart';

class BackupService {
  static final _workItemRepo = WorkItemRepository();
  static final _sessionRepo = SessionRepository();
  static final _settingsRepo = SettingsRepository();

  /// Create a JSON backup of all data
  static Future<void> createBackup() async {
    try {
      // Fetch all data
      final workItems = await _workItemRepo.getAll();
      final sessions = await _sessionRepo.getAll();
      final settings = await _settingsRepo.getSettings();

      // Collect cycles for all sessions
      final sessionsWithCycles = <Map<String, dynamic>>[];
      for (final session in sessions) {
        final cycles = await _sessionRepo.getCycles(session.id);
        final events = await _sessionRepo.getEvents(session.id);

        sessionsWithCycles.add({
          'session': session.toMap(),
          'cycles': cycles.map((c) => c.toMap()).toList(),
          'events': events.map((e) => e.toMap()).toList(),
        });
      }

      // Create backup object
      final backup = {
        'version': '1.0',
        'created_at': DateTime.now().toIso8601String(),
        'settings': settings.toMap(),
        'work_items': workItems.map((w) => w.toMap()).toList(),
        'sessions': sessionsWithCycles,
      };

      // Write to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'pourledger_backup_$timestamp.json';
      final path = '${directory.path}/$filename';
      final file = File(path);

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backup),
      );

      // Share the backup file
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Pour Ledger Backup',
        text: 'Backup created on ${DateTime.now()}',
      );
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  /// Restore data from JSON backup
  static Future<Map<String, dynamic>> restoreBackup(String jsonContent) async {
    try {
      final backup = jsonDecode(jsonContent) as Map<String, dynamic>;

      // Validate backup format
      if (!backup.containsKey('version') ||
          !backup.containsKey('work_items') ||
          !backup.containsKey('sessions')) {
        throw Exception('Invalid backup format');
      }

      int workItemsImported = 0;
      int sessionsImported = 0;
      int cyclesImported = 0;

      // Import work items
      if (backup['work_items'] != null) {
        final workItemsList = backup['work_items'] as List;
        for (final itemMap in workItemsList) {
          // Check if already exists
          final existingItem =
              await _workItemRepo.getById(itemMap['id'] as String);
          if (existingItem == null) {
            await _workItemRepo.insert(
              _workItemFromMap(itemMap as Map<String, dynamic>),
            );
            workItemsImported++;
          }
        }
      }

      // Import sessions with cycles
      if (backup['sessions'] != null) {
        final sessionsList = backup['sessions'] as List;
        for (final sessionData in sessionsList) {
          final sessionMap = sessionData['session'] as Map<String, dynamic>;
          final cyclesList = sessionData['cycles'] as List? ?? [];
          final eventsList = sessionData['events'] as List? ?? [];

          // Check if session already exists
          final existingSession =
              await _sessionRepo.getById(sessionMap['id'] as String);
          if (existingSession == null) {
            await _sessionRepo.insert(
              _sessionFromMap(sessionMap),
            );
            sessionsImported++;

            // Import cycles
            for (final cycleMap in cyclesList) {
              await _sessionRepo.insertCycle(
                _cycleFromMap(cycleMap as Map<String, dynamic>),
              );
              cyclesImported++;
            }

            // Import events
            for (final eventMap in eventsList) {
              await _sessionRepo.insertEvent(
                _eventFromMap(eventMap as Map<String, dynamic>),
              );
            }
          }
        }
      }

      // Import settings (update existing)
      if (backup['settings'] != null) {
        final settingsMap = backup['settings'] as Map<String, dynamic>;
        await _settingsRepo.updateSettings(_settingsFromMap(settingsMap));
      }

      return {
        'success': true,
        'work_items': workItemsImported,
        'sessions': sessionsImported,
        'cycles': cyclesImported,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Helper methods to reconstruct models from maps
  static dynamic _workItemFromMap(Map<String, dynamic> map) {
    // Import the model and use its fromMap
    return map; // Placeholder - will be handled by repository
  }

  static dynamic _sessionFromMap(Map<String, dynamic> map) {
    return map;
  }

  static dynamic _cycleFromMap(Map<String, dynamic> map) {
    return map;
  }

  static dynamic _eventFromMap(Map<String, dynamic> map) {
    return map;
  }

  static dynamic _settingsFromMap(Map<String, dynamic> map) {
    return map;
  }
}
