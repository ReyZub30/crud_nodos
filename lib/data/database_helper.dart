import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/nodo.dart';

/// Versión del esquema de la base de datos.
///   1 = esquema original (sin ubicación).
///   2 = agrega la columna `ubicacion_nodo`.
///
/// DEMOSTRACIÓN DE LA MIGRACIÓN:
///   1. Ejecuta la app con kDbVersion = 1 y agrega registros.
///   2. Cambia a kDbVersion = 2, guarda y presiona R (hot restart).
///   3. Se ejecuta onUpgrade: aparece la columna y los registros siguen ahí.
const int kDbVersion = 2;

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String dbName = 'nodos.db';
  static const String table = 'nodos';

  Database? _db;
  List<String> _columns = const [];
  String _path = '';
  String _log = '';

  Future<Database> get database async => _db ??= await _open();

  /// Columnas reales de la tabla (leídas con PRAGMA table_info).
  List<String> get columns => _columns;
  bool get hasUbicacion => _columns.contains('ubicacion_nodo');
  String get path => _path;

  /// Qué pasó al abrir la BD (creación, migración o sin cambios).
  String get log => _log;

  Future<Database> _open() async {
    _path = p.join(await getDatabasesPath(), dbName);
    _log = 'La base de datos ya estaba en v$kDbVersion; no hubo cambios de esquema.';
    final db = await openDatabase(
      _path,
      version: kDbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade,
    );
    _columns = await _readColumns(db);
    return db;
  }

  // ---------------------------------------------------------------------------
  // Esquema y migraciones
  // ---------------------------------------------------------------------------

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        tipo TEXT NOT NULL,
        valor REAL NOT NULL,
        fecha_registro TEXT NOT NULL
      )
    ''');
    // Una instalación nueva en v2 recibe el mismo esquema que una migrada.
    if (version >= 2) await _migrateToV2(db);
    _log = 'Base de datos creada desde cero en la versión v$version.';
  }

  /// Controlador de migración. sqflite lo ejecuta dentro de una transacción:
  /// si algo falla, se revierte todo y no se pierden datos.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final before = await _count(db);
    if (oldVersion < 2) await _migrateToV2(db);
    // Futuras migraciones: if (oldVersion < 3) await _migrateToV3(db);
    final after = await _count(db);
    _log = 'Migración v$oldVersion → v$newVersion completada: se agregó la columna '
        'ubicacion_nodo. Registros antes: $before, después: $after.';
  }

  /// v1 → v2: agrega la columna sin borrar la tabla (nada de DROP TABLE).
  /// Los registros existentes reciben el valor por defecto 'Sin asignar'.
  static Future<void> _migrateToV2(DatabaseExecutor db) async {
    final cols = await _readColumns(db);
    if (cols.contains('ubicacion_nodo')) return; // ya migrada
    await db.execute(
      "ALTER TABLE $table ADD COLUMN ubicacion_nodo TEXT NOT NULL DEFAULT 'Sin asignar'",
    );
  }

  /// Si se regresa a v1 se conserva la columna (SQLite no la borra fácilmente)
  /// para no perder información.
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    _log = 'Se pidió bajar de v$oldVersion a v$newVersion; se conservó el esquema para no perder datos.';
  }

  static Future<List<String>> _readColumns(DatabaseExecutor db) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.map((r) => r['name'] as String).toList();
  }

  static Future<int> _count(DatabaseExecutor db) async =>
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $table')) ?? 0;

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// CREATE
  Future<int> insert(Nodo nodo) async {
    final db = await database;
    return db.insert(table, nodo.toMap(includeId: false, includeUbicacion: hasUbicacion));
  }

  /// READ
  Future<List<Nodo>> getAll() async {
    final db = await database;
    final rows = await db.query(table, orderBy: 'id DESC');
    return rows.map(Nodo.fromMap).toList();
  }

  /// UPDATE
  Future<int> update(Nodo nodo) async {
    final db = await database;
    return db.update(
      table,
      nodo.toMap(includeId: false, includeUbicacion: hasUbicacion),
      where: 'id = ?',
      whereArgs: [nodo.id],
    );
  }

  /// DELETE
  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAll() async {
    final db = await database;
    return db.delete(table);
  }

  Future<int> count() async => _count(await database);

  // ---------------------------------------------------------------------------
  // Inserción masiva: transacción ACID + batch
  // ---------------------------------------------------------------------------

  /// Inserta muchos registros en UNA sola transacción usando batch.
  /// - Atomicidad: o se insertan todos o ninguno.
  /// - batch agrupa las operaciones y las envía juntas al motor nativo,
  ///   por eso es muy rápido y no congela la interfaz.
  /// Devuelve el tiempo que tardó la operación.
  Future<Duration> insertMany(List<Nodo> nodos, {bool keepIds = false}) async {
    final db = await database;
    final stopwatch = Stopwatch()..start();
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final nodo in nodos) {
        batch.insert(
          table,
          nodo.toMap(includeId: keepIds, includeUbicacion: hasUbicacion),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
    stopwatch.stop();
    return stopwatch.elapsed;
  }
}
