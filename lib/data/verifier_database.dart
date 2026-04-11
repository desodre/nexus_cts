import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nexus_cts/models/verifier_result.dart';

class VerifierDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbDir = p.join(
      Platform.environment['HOME'] ?? '.',
      '.nexus_cts',
    );
    await Directory(dbDir).create(recursive: true);
    final dbPath = p.join(dbDir, 'verifier.db');

    _db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE executions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        xml_path TEXT NOT NULL,
        device_serial TEXT,
        build_fingerprint TEXT,
        suite_plan TEXT,
        suite_version TEXT,
        start_time TEXT,
        passed INTEGER NOT NULL DEFAULT 0,
        failed INTEGER NOT NULL DEFAULT 0,
        not_executed INTEGER NOT NULL DEFAULT 0,
        modules_done INTEGER NOT NULL DEFAULT 0,
        modules_total INTEGER NOT NULL DEFAULT 0,
        imported_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE modules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        execution_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        abi TEXT NOT NULL DEFAULT '',
        done INTEGER NOT NULL DEFAULT 0,
        passed INTEGER NOT NULL DEFAULT 0,
        failed INTEGER NOT NULL DEFAULT 0,
        total_tests INTEGER NOT NULL DEFAULT 0,
        runtime_ms TEXT,
        its_scenes TEXT,
        FOREIGN KEY (execution_id) REFERENCES executions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE test_cases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        module_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        result TEXT NOT NULL DEFAULT 'not_executed',
        message TEXT,
        stacktrace TEXT,
        FOREIGN KEY (module_id) REFERENCES modules(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE modules ADD COLUMN its_scenes TEXT');
    }
  }

  // ── Executions ──

  static Future<int> insertExecution(VerifierExecution exec) async {
    final db = await instance;
    return db.insert('executions', exec.toMap());
  }

  static Future<List<VerifierExecution>> allExecutions() async {
    final db = await instance;
    final rows =
        await db.query('executions', orderBy: 'imported_at DESC');
    return rows.map(VerifierExecution.fromMap).toList();
  }

  static Future<void> deleteExecution(int id) async {
    final db = await instance;
    await db.delete('test_cases',
        where:
            'module_id IN (SELECT id FROM modules WHERE execution_id = ?)',
        whereArgs: [id]);
    await db.delete('modules', where: 'execution_id = ?', whereArgs: [id]);
    await db.delete('executions', where: 'id = ?', whereArgs: [id]);
  }

  // ── Modules ──

  static Future<int> insertModule(VerifierModule mod) async {
    final db = await instance;
    return db.insert('modules', mod.toMap());
  }

  static Future<List<VerifierModule>> modulesFor(int executionId) async {
    final db = await instance;
    final rows = await db.query('modules',
        where: 'execution_id = ?',
        whereArgs: [executionId],
        orderBy: 'name ASC');
    return rows.map(VerifierModule.fromMap).toList();
  }

  static Future<List<VerifierModule>> failedModulesFor(
      int executionId) async {
    final db = await instance;
    final rows = await db.query('modules',
        where: 'execution_id = ? AND failed > 0',
        whereArgs: [executionId],
        orderBy: 'name ASC');
    return rows.map(VerifierModule.fromMap).toList();
  }

  static Future<List<VerifierModule>> cameraItsModulesFor(
      int executionId) async {
    final db = await instance;
    final rows = await db.query('modules',
        where: 'execution_id = ? AND name LIKE ?',
        whereArgs: [executionId, '%CameraITS%'],
        orderBy: 'name ASC');
    return rows.map(VerifierModule.fromMap).toList();
  }

  // ── Test Cases ──

  static Future<void> insertTestCase(VerifierTestCase tc) async {
    final db = await instance;
    await db.insert('test_cases', tc.toMap());
  }

  static Future<void> insertTestCasesBatch(
      List<VerifierTestCase> cases) async {
    final db = await instance;
    final batch = db.batch();
    for (final tc in cases) {
      batch.insert('test_cases', tc.toMap());
    }
    await batch.commit(noResult: true);
  }

  static Future<List<VerifierTestCase>> testCasesFor(int moduleId) async {
    final db = await instance;
    final rows = await db.query('test_cases',
        where: 'module_id = ?',
        whereArgs: [moduleId],
        orderBy: 'result DESC, name ASC');
    return rows.map(VerifierTestCase.fromMap).toList();
  }

  static Future<List<VerifierTestCase>> failedTestCasesFor(
      int moduleId) async {
    final db = await instance;
    final rows = await db.query('test_cases',
        where: "module_id = ? AND result = 'fail'",
        whereArgs: [moduleId],
        orderBy: 'name ASC');
    return rows.map(VerifierTestCase.fromMap).toList();
  }

  /// Loads all test cases for an execution, grouped by module ID.
  static Future<Map<int, List<VerifierTestCase>>> allTestCasesGrouped(
      int executionId) async {
    final db = await instance;
    final rows = await db.rawQuery('''
      SELECT tc.* FROM test_cases tc
      INNER JOIN modules m ON tc.module_id = m.id
      WHERE m.execution_id = ?
      ORDER BY tc.result DESC, tc.name ASC
    ''', [executionId]);
    final map = <int, List<VerifierTestCase>>{};
    for (final row in rows) {
      final tc = VerifierTestCase.fromMap(row);
      map.putIfAbsent(tc.moduleId, () => []).add(tc);
    }
    return map;
  }
}
