import '../database/app_database.dart';
import '../models/measurement_session.dart';
import '../models/cycle_record.dart';
import '../models/session_event.dart';

class SessionRepository {
  final AppDatabase _db = AppDatabase.instance;

  // Session CRUD
  Future<List<MeasurementSession>> getAll() async {
    final db = await _db.database;
    final result = await db.query(
      'measurement_sessions',
      orderBy: 'created_at DESC',
    );
    return result.map((map) => MeasurementSession.fromMap(map)).toList();
  }

  Future<MeasurementSession?> getById(String id) async {
    final db = await _db.database;
    final result = await db.query(
      'measurement_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return MeasurementSession.fromMap(result.first);
  }

  Future<List<MeasurementSession>> getByWorkItem(String workItemId) async {
    final db = await _db.database;
    final result = await db.query(
      'measurement_sessions',
      where: 'work_item_id = ?',
      whereArgs: [workItemId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => MeasurementSession.fromMap(map)).toList();
  }

  Future<List<MeasurementSession>> getByStatus(String status) async {
    final db = await _db.database;
    final result = await db.query(
      'measurement_sessions',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => MeasurementSession.fromMap(map)).toList();
  }

  Future<List<MeasurementSession>> getByDateRange(
      DateTime start, DateTime end) async {
    final db = await _db.database;
    final result = await db.query(
      'measurement_sessions',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => MeasurementSession.fromMap(map)).toList();
  }

  Future<MeasurementSession?> getActiveSession() async {
    final db = await _db.database;
    final result = await db.query(
      'measurement_sessions',
      where: 'status IN (?, ?)',
      whereArgs: ['in_progress', 'paused'],
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return MeasurementSession.fromMap(result.first);
  }

  Future<void> insert(MeasurementSession session) async {
    final db = await _db.database;
    await db.insert('measurement_sessions', session.toMap());
  }

  Future<void> update(MeasurementSession session) async {
    final db = await _db.database;
    await db.update(
      'measurement_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete(
      'measurement_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Cycle Records
  Future<List<CycleRecord>> getCycles(String sessionId) async {
    final db = await _db.database;
    final result = await db.query(
      'cycle_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'sequence_number ASC',
    );
    return result.map((map) => CycleRecord.fromMap(map)).toList();
  }

  Future<void> insertCycle(CycleRecord cycle) async {
    final db = await _db.database;
    await db.insert('cycle_records', cycle.toMap());
  }

  Future<void> updateCycle(CycleRecord cycle) async {
    final db = await _db.database;
    await db.update(
      'cycle_records',
      cycle.toMap(),
      where: 'id = ?',
      whereArgs: [cycle.id],
    );
  }

  Future<void> deleteCycle(String id) async {
    final db = await _db.database;
    await db.delete(
      'cycle_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Session Events
  Future<List<SessionEvent>> getEvents(String sessionId) async {
    final db = await _db.database;
    final result = await db.query(
      'session_events',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'offset_ms ASC',
    );
    return result.map((map) => SessionEvent.fromMap(map)).toList();
  }

  Future<void> insertEvent(SessionEvent event) async {
    final db = await _db.database;
    await db.insert('session_events', event.toMap());
  }

  // Statistics
  Future<Map<String, dynamic>> getTodayStats() async {
    final db = await _db.database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();

    final sessionCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM measurement_sessions WHERE status = ? AND created_at >= ?',
      ['completed', startOfDay],
    );

    final totalTime = await db.rawQuery(
      'SELECT SUM(active_ms) as total FROM measurement_sessions WHERE status = ? AND created_at >= ?',
      ['completed', startOfDay],
    );

    final avgCycle = await db.rawQuery('''
      SELECT AVG(c.duration_ms) as avg_duration
      FROM cycle_records c
      INNER JOIN measurement_sessions s ON c.session_id = s.id
      WHERE s.status = ? AND s.created_at >= ? AND c.is_flagged = 0
    ''', ['completed', startOfDay]);

    return {
      'session_count': sessionCount.first['count'] as int,
      'total_time_ms': totalTime.first['total'] as int? ?? 0,
      'avg_cycle_ms': avgCycle.first['avg_duration'] as double? ?? 0.0,
    };
  }

  Future<List<MeasurementSession>> getRecent({int limit = 5}) async {
    final db = await _db.database;
    final result = await db.query(
      'measurement_sessions',
      where: 'status = ?',
      whereArgs: ['completed'],
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return result.map((map) => MeasurementSession.fromMap(map)).toList();
  }
}
