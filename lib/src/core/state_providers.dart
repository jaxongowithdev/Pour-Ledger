import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_preferences.dart';
import '../models/work_item.dart';
import '../models/measurement_session.dart';
import '../repositories/config_data_store.dart';
import '../repositories/task_data_store.dart';
import '../repositories/measurement_data_store.dart';
import '../services/cycle_timer.dart';

// Repositories
final settingsRepoProvider = Provider((ref) => SettingsRepository());
final workItemRepoProvider = Provider((ref) => WorkItemRepository());
final sessionRepoProvider = Provider((ref) => SessionRepository());

// Settings
final settingsProvider = FutureProvider<UserPreferences>((ref) async {
  final repo = ref.watch(settingsRepoProvider);
  return await repo.getSettings();
});

// Work Items
final workItemsProvider = FutureProvider<List<WorkItem>>((ref) async {
  final repo = ref.watch(workItemRepoProvider);
  return await repo.getAll();
});

final pinnedWorkItemsProvider = FutureProvider<List<WorkItem>>((ref) async {
  final repo = ref.watch(workItemRepoProvider);
  return await repo.getPinned();
});

// Sessions
final sessionsProvider = FutureProvider<List<MeasurementSession>>((ref) async {
  final repo = ref.watch(sessionRepoProvider);
  return await repo.getAll();
});

final recentSessionsProvider =
    FutureProvider<List<MeasurementSession>>((ref) async {
  final repo = ref.watch(sessionRepoProvider);
  return await repo.getRecent(limit: 5);
});

final activeSessionProvider =
    FutureProvider<MeasurementSession?>((ref) async {
  final repo = ref.watch(sessionRepoProvider);
  return await repo.getActiveSession();
});

final todayStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(sessionRepoProvider);
  return await repo.getTodayStats();
});

// Timing Service (for active measurements)
final timingServiceProvider =
    ChangeNotifierProvider<TimingService>((ref) => TimingService());

// Helper to refresh providers
void refreshWorkItems(WidgetRef ref) {
  ref.invalidate(workItemsProvider);
  ref.invalidate(pinnedWorkItemsProvider);
}

void refreshSessions(WidgetRef ref) {
  ref.invalidate(sessionsProvider);
  ref.invalidate(recentSessionsProvider);
  ref.invalidate(activeSessionProvider);
  ref.invalidate(todayStatsProvider);
}

void refreshSettings(WidgetRef ref) {
  ref.invalidate(settingsProvider);
}
