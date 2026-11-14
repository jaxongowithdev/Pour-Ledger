import 'package:uuid/uuid.dart';
import '../models/work_item.dart';
import '../models/measurement_session.dart';
import '../models/cycle_record.dart';
import '../repositories/task_data_store.dart';
import '../repositories/measurement_data_store.dart';
import '../utils/cycle_constants.dart';

class SampleData {
  static const _uuid = Uuid();

  static Future<void> createSampleData() async {
    final workItemRepo = WorkItemRepository();
    final sessionRepo = SessionRepository();

    // Create sample work items
    final now = DateTime.now();

    final workItem1 = WorkItem(
      id: _uuid.v4(),
      name: 'Honey Pillar 8 oz',
      code: 'PIL-108',
      category: 'Pillars',
      description: 'Pour an 8 oz pillar with a cotton wick',
      targetCycleMs: 12000, // 12 seconds
      productUnit: 'vessel',
      colorValue: 0, // Honey
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now.subtract(const Duration(days: 7)),
    );

    final workItem2 = WorkItem(
      id: _uuid.v4(),
      name: 'Tin Travel Candle',
      code: 'TIN-204',
      category: 'Tins',
      description: 'Fill a travel tin and set the wick',
      targetCycleMs: 25000, // 25 seconds
      productUnit: 'vessel',
      colorValue: 4, // Sage
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now.subtract(const Duration(days: 5)),
    );

    final workItem3 = WorkItem(
      id: _uuid.v4(),
      name: 'Sampler Votive',
      code: 'VOT-015',
      category: 'Votives',
      description: 'Pour a small votive for the sampler tray',
      targetCycleMs: 18000, // 18 seconds
      productUnit: 'vessel',
      colorValue: 5, // Wax red
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 3)),
    );

    // Insert work items
    await workItemRepo.insert(workItem1);
    await workItemRepo.insert(workItem2);
    await workItemRepo.insert(workItem3);

    // Create sample sessions with cycles for each work item
    await _createSampleSession(
      sessionRepo,
      workItem1,
      [11800, 12200, 11900, 12400, 11700, 12100, 12300, 11600, 12000, 12200],
      now.subtract(const Duration(days: 2)),
    );

    await _createSampleSession(
      sessionRepo,
      workItem2,
      [24500, 25200, 24800, 25600, 24300, 25100, 25400, 24700, 25000, 25300],
      now.subtract(const Duration(days: 1)),
    );

    await _createSampleSession(
      sessionRepo,
      workItem3,
      [17800, 18200, 17900, 18400, 17600, 18100, 18300, 17700, 18000, 18200],
      now.subtract(const Duration(hours: 12)),
    );
  }

  static Future<void> _createSampleSession(
    SessionRepository sessionRepo,
    WorkItem workItem,
    List<int> cycleDurations,
    DateTime sessionStart,
  ) async {
    final sessionId = _uuid.v4();

    // Calculate total active time
    final totalActiveMs = cycleDurations.reduce((a, b) => a + b);

    final session = MeasurementSession(
      id: sessionId,
      workItemId: workItem.id,
      workItemNameSnapshot: workItem.name,
      lotCode: 'DEMO-${workItem.code}',
      status: AppConstants.statusCompleted,
      timingMode: AppConstants.timingModeActive,
      startedAt: sessionStart,
      endedAt: sessionStart.add(Duration(milliseconds: totalActiveMs + 60000)),
      elapsedMs: totalActiveMs + 60000,
      activeMs: totalActiveMs,
      pausedMs: 60000, // 1 minute pause
      notes: 'Sample sitting on the wax bench',
      createdAt: sessionStart,
      updatedAt: sessionStart.add(Duration(milliseconds: totalActiveMs)),
    );

    await sessionRepo.insert(session);

    // Create cycles
    int offsetMs = 0;
    for (int i = 0; i < cycleDurations.length; i++) {
      final durationMs = cycleDurations[i];
      final cycle = CycleRecord(
        id: _uuid.v4(),
        sessionId: sessionId,
        sequenceNumber: i + 1,
        durationMs: durationMs,
        startedOffsetMs: offsetMs,
        endedOffsetMs: offsetMs + durationMs,
        createdAt: sessionStart.add(Duration(milliseconds: offsetMs)),
      );

      await sessionRepo.insertCycle(cycle);
      offsetMs += durationMs;
    }
  }

  static Future<void> deleteSampleData() async {
    final workItemRepo = WorkItemRepository();
    final sessionRepo = SessionRepository();

    // Get all work items with DEMO lot code sessions
    final allSessions = await sessionRepo.getAll();
    final demoSessions =
        allSessions.where((s) => s.lotCode?.startsWith('DEMO-') ?? false);

    for (final session in demoSessions) {
      await sessionRepo.delete(session.id);
    }

    // Get all work items with demo codes
    final allItems = await workItemRepo.getAll();
    final demoItems = allItems.where((item) =>
        (item.code?.contains('PIL-108') ?? false) ||
        (item.code?.contains('TIN-204') ?? false) ||
        (item.code?.contains('VOT-015') ?? false));

    for (final item in demoItems) {
      await workItemRepo.delete(item.id);
    }
  }
}
