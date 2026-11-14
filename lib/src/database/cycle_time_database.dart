import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pour_ledger.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Work Items table
    await db.execute('''
      CREATE TABLE work_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT,
        category TEXT,
        description TEXT,
        target_cycle_ms INTEGER,
        product_unit TEXT NOT NULL DEFAULT 'product',
        color_value INTEGER,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Measurement Sessions table
    await db.execute('''
      CREATE TABLE measurement_sessions (
        id TEXT PRIMARY KEY,
        work_item_id TEXT,
        work_item_name_snapshot TEXT NOT NULL,
        lot_code TEXT,
        status TEXT NOT NULL,
        timing_mode TEXT NOT NULL,
        started_at TEXT,
        ended_at TEXT,
        elapsed_ms INTEGER NOT NULL DEFAULT 0,
        active_ms INTEGER NOT NULL DEFAULT 0,
        paused_ms INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (work_item_id) REFERENCES work_items (id) ON DELETE SET NULL
      )
    ''');

    // Cycle Records table
    await db.execute('''
      CREATE TABLE cycle_records (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        sequence_number INTEGER NOT NULL,
        duration_ms INTEGER NOT NULL,
        started_offset_ms INTEGER,
        ended_offset_ms INTEGER,
        is_flagged INTEGER NOT NULL DEFAULT 0,
        flag_reason TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES measurement_sessions (id) ON DELETE CASCADE
      )
    ''');

    // Session Events table
    await db.execute('''
      CREATE TABLE session_events (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        offset_ms INTEGER NOT NULL,
        label TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES measurement_sessions (id) ON DELETE CASCADE
      )
    ''');

    // App Settings table
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        theme_mode TEXT NOT NULL DEFAULT 'system',
        time_unit TEXT NOT NULL DEFAULT 'seconds',
        decimal_places INTEGER NOT NULL DEFAULT 1,
        enable_vibration INTEGER NOT NULL DEFAULT 1,
        pause_handling TEXT NOT NULL DEFAULT 'exclude'
      )
    ''');

    // Insert default settings
    await db.insert('app_settings', {
      'id': 1,
      'theme_mode': 'system',
      'time_unit': 'seconds',
      'decimal_places': 1,
      'enable_vibration': 1,
      'pause_handling': 'exclude',
    });

    // Create indexes for better query performance
    await db.execute(
        'CREATE INDEX idx_sessions_work_item ON measurement_sessions(work_item_id)');
    await db.execute(
        'CREATE INDEX idx_sessions_status ON measurement_sessions(status)');
    await db.execute(
        'CREATE INDEX idx_sessions_created_at ON measurement_sessions(created_at)');
    await db.execute(
        'CREATE INDEX idx_cycles_session ON cycle_records(session_id)');
    await db.execute(
        'CREATE INDEX idx_events_session ON session_events(session_id)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle future database migrations
    if (oldVersion < 2) {
      // Example migration for version 2
      // await db.execute('ALTER TABLE ...');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pour_ledger.db');
    await deleteDatabase(path);
    _database = null;
  }
}
