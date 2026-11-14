import '../database/app_database.dart';
import '../models/work_item.dart';

class WorkItemRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<WorkItem>> getAll() async {
    final db = await _db.database;
    final result = await db.query(
      'work_items',
      orderBy: 'created_at DESC',
    );
    return result.map((map) => WorkItem.fromMap(map)).toList();
  }

  Future<WorkItem?> getById(String id) async {
    final db = await _db.database;
    final result = await db.query(
      'work_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return WorkItem.fromMap(result.first);
  }

  Future<List<WorkItem>> getPinned() async {
    final db = await _db.database;
    final result = await db.query(
      'work_items',
      where: 'is_pinned = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return result.map((map) => WorkItem.fromMap(map)).toList();
  }

  Future<List<WorkItem>> search(String query) async {
    final db = await _db.database;
    final result = await db.query(
      'work_items',
      where: 'name LIKE ? OR code LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => WorkItem.fromMap(map)).toList();
  }

  Future<void> insert(WorkItem item) async {
    final db = await _db.database;
    await db.insert('work_items', item.toMap());
  }

  Future<void> update(WorkItem item) async {
    final db = await _db.database;
    await db.update(
      'work_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete(
      'work_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getSessionCount(String workItemId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM measurement_sessions WHERE work_item_id = ?',
      [workItemId],
    );
    return result.first['count'] as int;
  }

  Future<void> togglePin(String id) async {
    final db = await _db.database;
    final item = await getById(id);
    if (item != null) {
      await db.update(
        'work_items',
        {'is_pinned': item.isPinned ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
