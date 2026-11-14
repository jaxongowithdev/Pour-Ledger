import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/glaze_entity.dart';
import '../models/formula_version.dart';
import '../models/ingredient_item.dart';
import '../models/formula_component.dart';
import '../models/experiment_record.dart';
import '../models/sample_tile.dart';
import '../models/evaluation_result.dart';
import '../models/user_preferences.dart';
import '../models/kiln_session.dart';
import '../models/experiment_photo.dart';
import 'demo_data.dart';

class StorageManager {
  static final StorageManager instance = StorageManager._init();
  static Database? _database;

  StorageManager._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('CycleTime.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Glazes table
    await db.execute('''
      CREATE TABLE glazes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        favorite INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // Formula versions table
    await db.execute('''
      CREATE TABLE formula_versions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        glazeId INTEGER NOT NULL,
        version TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (glazeId) REFERENCES glazes (id) ON DELETE CASCADE
      )
    ''');

    // Ingredients table
    await db.execute('''
      CREATE TABLE ingredients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        defaultUnit TEXT DEFAULT 'g'
      )
    ''');

    // Formula components table
    await db.execute('''
      CREATE TABLE formula_components(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        versionId INTEGER NOT NULL,
        ingredientId INTEGER NOT NULL,
        weight REAL NOT NULL,
        percentage REAL NOT NULL,
        FOREIGN KEY (versionId) REFERENCES formula_versions (id) ON DELETE CASCADE,
        FOREIGN KEY (ingredientId) REFERENCES ingredients (id)
      )
    ''');

    // Experiment records table
    await db.execute('''
      CREATE TABLE experiment_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        versionId INTEGER NOT NULL,
        name TEXT NOT NULL,
        testDate TEXT NOT NULL,
        targetCone TEXT NOT NULL,
        kilnId TEXT,
        status TEXT DEFAULT 'preparing',
        notes TEXT,
        FOREIGN KEY (versionId) REFERENCES formula_versions (id) ON DELETE CASCADE
      )
    ''');

    // Sample tiles table
    await db.execute('''
      CREATE TABLE sample_tiles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        testId INTEGER NOT NULL,
        number INTEGER NOT NULL,
        clayBody TEXT,
        applicationMethod TEXT DEFAULT 'brush',
        layerCount INTEGER DEFAULT 2,
        thickness TEXT DEFAULT 'medium',
        notes TEXT,
        FOREIGN KEY (testId) REFERENCES experiment_records (id) ON DELETE CASCADE
      )
    ''');

    // Kiln sessions table
    await db.execute('''
      CREATE TABLE kiln_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        testId INTEGER NOT NULL,
        kilnId TEXT,
        targetTemperature INTEGER NOT NULL,
        peakTemperature INTEGER DEFAULT 0,
        holdMinutes INTEGER DEFAULT 10,
        atmosphere TEXT DEFAULT 'oxidation',
        startedAt TEXT,
        completedAt TEXT,
        FOREIGN KEY (testId) REFERENCES experiment_records (id) ON DELETE CASCADE
      )
    ''');

    // Evaluation results table
    await db.execute('''
      CREATE TABLE evaluation_results(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tileId INTEGER NOT NULL,
        color TEXT,
        surface TEXT,
        texture TEXT,
        gloss TEXT,
        opacity TEXT,
        coverage TEXT,
        adhesion TEXT,
        rating INTEGER DEFAULT 3,
        notes TEXT,
        isBest INTEGER DEFAULT 0,
        FOREIGN KEY (tileId) REFERENCES sample_tiles (id) ON DELETE CASCADE
      )
    ''');

    // Defect records table
    await db.execute('''
      CREATE TABLE defect_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        resultId INTEGER NOT NULL,
        defectType TEXT NOT NULL,
        FOREIGN KEY (resultId) REFERENCES evaluation_results (id) ON DELETE CASCADE
      )
    ''');

    // Experiment photos table
    await db.execute('''
      CREATE TABLE experiment_photos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        testId INTEGER NOT NULL,
        tileId INTEGER,
        stage TEXT NOT NULL,
        path TEXT NOT NULL,
        caption TEXT,
        FOREIGN KEY (testId) REFERENCES experiment_records (id) ON DELETE CASCADE,
        FOREIGN KEY (tileId) REFERENCES sample_tiles (id) ON DELETE CASCADE
      )
    ''');

    // Version changes table
    await db.execute('''
      CREATE TABLE version_changes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        versionId INTEGER NOT NULL,
        description TEXT NOT NULL,
        FOREIGN KEY (versionId) REFERENCES formula_versions (id) ON DELETE CASCADE
      )
    ''');

    // Timeline entries table
    await db.execute('''
      CREATE TABLE timeline_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        testId INTEGER NOT NULL,
        action TEXT NOT NULL,
        description TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (testId) REFERENCES experiment_records (id) ON DELETE CASCADE
      )
    ''');

    // User preferences table
    await db.execute('''
      CREATE TABLE user_preferences(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        themeMode TEXT DEFAULT 'system',
        temperatureUnit TEXT DEFAULT 'celsius',
        weightUnit TEXT DEFAULT 'g',
        language TEXT DEFAULT 'en',
        notificationsEnabled INTEGER DEFAULT 1
      )
    ''');

    // Seed demo data
    await DemoData.seed(db);
  }

  // Glazes CRUD
  Future<int> createGlaze(GlazeEntity glaze) async {
    final db = await database;
    return await db.insert('glazes', glaze.toMap());
  }

  Future<List<GlazeEntity>> getAllGlazes() async {
    final db = await database;
    final maps = await db.query('glazes', orderBy: 'createdAt DESC');
    return maps.map((map) => GlazeEntity.fromMap(map)).toList();
  }

  Future<GlazeEntity?> getGlazeById(int id) async {
    final db = await database;
    final maps = await db.query('glazes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return GlazeEntity.fromMap(maps.first);
  }

  Future<int> updateGlaze(GlazeEntity glaze) async {
    final db = await database;
    return await db.update('glazes', glaze.toMap(), where: 'id = ?', whereArgs: [glaze.id]);
  }

  Future<int> deleteGlaze(int id) async {
    final db = await database;
    return await db.delete('glazes', where: 'id = ?', whereArgs: [id]);
  }

  // Formula versions CRUD
  Future<int> createFormulaVersion(FormulaVersion version) async {
    final db = await database;
    return await db.insert('formula_versions', version.toMap());
  }

  Future<List<FormulaVersion>> getVersionsByGlazeId(int glazeId) async {
    final db = await database;
    final maps = await db.query('formula_versions', where: 'glazeId = ?', whereArgs: [glazeId], orderBy: 'createdAt DESC');
    return maps.map((map) => FormulaVersion.fromMap(map)).toList();
  }

  Future<FormulaVersion?> getFormulaVersionById(int id) async {
    final db = await database;
    final maps = await db.query('formula_versions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return FormulaVersion.fromMap(maps.first);
  }

  // Ingredients CRUD
  Future<int> createIngredient(IngredientItem ingredient) async {
    final db = await database;
    return await db.insert('ingredients', ingredient.toMap());
  }

  Future<List<IngredientItem>> getAllIngredients() async {
    final db = await database;
    final maps = await db.query('ingredients', orderBy: 'name ASC');
    return maps.map((map) => IngredientItem.fromMap(map)).toList();
  }

  // Formula components CRUD
  Future<int> createFormulaComponent(FormulaComponent component) async {
    final db = await database;
    return await db.insert('formula_components', component.toMap());
  }

  Future<List<FormulaComponent>> getComponentsByVersionId(int versionId) async {
    final db = await database;
    final maps = await db.query('formula_components', where: 'versionId = ?', whereArgs: [versionId]);
    return maps.map((map) => FormulaComponent.fromMap(map)).toList();
  }

  Future<int> updateFormulaComponent(FormulaComponent component) async {
    final db = await database;
    return await db.update('formula_components', component.toMap(), where: 'id = ?', whereArgs: [component.id]);
  }

  // Experiment records CRUD
  Future<int> createExperimentRecord(ExperimentRecord record) async {
    final db = await database;
    return await db.insert('experiment_records', record.toMap());
  }

  Future<List<ExperimentRecord>> getAllExperimentRecords() async {
    final db = await database;
    final maps = await db.query('experiment_records', orderBy: 'testDate DESC');
    return maps.map((map) => ExperimentRecord.fromMap(map)).toList();
  }

  Future<List<ExperimentRecord>> getExperimentsByVersionId(int versionId) async {
    final db = await database;
    final maps = await db.query('experiment_records', where: 'versionId = ?', whereArgs: [versionId], orderBy: 'testDate DESC');
    return maps.map((map) => ExperimentRecord.fromMap(map)).toList();
  }

  Future<ExperimentRecord?> getExperimentRecordById(int id) async {
    final db = await database;
    final maps = await db.query('experiment_records', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ExperimentRecord.fromMap(maps.first);
  }

  Future<int> updateExperimentRecord(ExperimentRecord record) async {
    final db = await database;
    return await db.update('experiment_records', record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  // Sample tiles CRUD
  Future<int> createSampleTile(SampleTile tile) async {
    final db = await database;
    return await db.insert('sample_tiles', tile.toMap());
  }

  Future<List<SampleTile>> getTilesByTestId(int testId) async {
    final db = await database;
    final maps = await db.query('sample_tiles', where: 'testId = ?', whereArgs: [testId], orderBy: 'number ASC');
    return maps.map((map) => SampleTile.fromMap(map)).toList();
  }

  // Evaluation results CRUD
  Future<int> createEvaluationResult(EvaluationResult result) async {
    final db = await database;
    return await db.insert('evaluation_results', result.toMap());
  }

  Future<EvaluationResult?> getResultByTileId(int tileId) async {
    final db = await database;
    final maps = await db.query('evaluation_results', where: 'tileId = ?', whereArgs: [tileId]);
    if (maps.isEmpty) return null;
    return EvaluationResult.fromMap(maps.first);
  }

  Future<int> updateEvaluationResult(EvaluationResult result) async {
    final db = await database;
    return await db.update('evaluation_results', result.toMap(), where: 'id = ?', whereArgs: [result.id]);
  }

  // Kiln sessions CRUD
  Future<int> createKilnSession(KilnSession session) async {
    final db = await database;
    return await db.insert('kiln_sessions', session.toMap());
  }

  Future<List<KilnSession>> getKilnSessionsByTestId(int testId) async {
    final db = await database;
    final maps = await db.query('kiln_sessions', where: 'testId = ?', whereArgs: [testId]);
    return maps.map((map) => KilnSession.fromMap(map)).toList();
  }

  Future<int> updateKilnSession(KilnSession session) async {
    final db = await database;
    return await db.update('kiln_sessions', session.toMap(), where: 'id = ?', whereArgs: [session.id]);
  }

  // Experiment photos CRUD
  Future<int> createExperimentPhoto(ExperimentPhoto photo) async {
    final db = await database;
    return await db.insert('experiment_photos', photo.toMap());
  }

  Future<List<ExperimentPhoto>> getPhotosByTestId(int testId) async {
    final db = await database;
    final maps = await db.query('experiment_photos', where: 'testId = ?', whereArgs: [testId]);
    return maps.map((map) => ExperimentPhoto.fromMap(map)).toList();
  }

  Future<int> deleteExperimentPhoto(int id) async {
    final db = await database;
    return await db.delete('experiment_photos', where: 'id = ?', whereArgs: [id]);
  }

  // User preferences CRUD
  Future<UserPreferences> getUserPreferences() async {
    final db = await database;
    final maps = await db.query('user_preferences', limit: 1);
    if (maps.isEmpty) {
      final prefs = UserPreferences();
      await db.insert('user_preferences', prefs.toMap());
      return prefs;
    }
    return UserPreferences.fromMap(maps.first);
  }

  Future<int> updateUserPreferences(UserPreferences prefs) async {
    final db = await database;
    return await db.update('user_preferences', prefs.toMap(), where: 'id = ?', whereArgs: [prefs.id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
