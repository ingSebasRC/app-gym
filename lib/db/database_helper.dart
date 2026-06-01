import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../pantallas/principal.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gym.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ejercicios ADD COLUMN detalles TEXT');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ejercicios (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        peso REAL NOT NULL,
        repeticiones INTEGER NOT NULL,
        series INTEGER NOT NULL,
        dia INTEGER NOT NULL,
        detalles TEXT
      )
    ''');

    // Seed data
    await _seedData(db);
  }

  Future _seedData(Database db) async {
    final seedExercises = [
      Ejercicio(
        id: '1',
        nombre: 'Press de Banca',
        peso: 80.0,
        repeticiones: 10,
        series: 4,
        dia: 0, // Lunes
      ),
      Ejercicio(
        id: '2',
        nombre: 'Sentadillas',
        peso: 100.0,
        repeticiones: 8,
        series: 4,
        dia: 1, // Martes
      ),
      Ejercicio(
        id: '3',
        nombre: 'Peso Muerto',
        peso: 120.0,
        repeticiones: 5,
        series: 3,
        dia: 2, // Miércoles
      ),
    ];

    for (var ejercicio in seedExercises) {
      await db.insert('ejercicios', ejercicio.toMap());
    }
  }

  Future<int> insert(Ejercicio ejercicio) async {
    final db = await instance.database;
    return await db.insert('ejercicios', ejercicio.toMap());
  }

  Future<List<Ejercicio>> readAllByDia(int dia) async {
    final db = await instance.database;
    final result = await db.query(
      'ejercicios',
      where: 'dia = ?',
      whereArgs: [dia],
    );

    return result.map((json) => Ejercicio.fromMap(json)).toList();
  }

  Future<List<Ejercicio>> readHistoryByNombre(String nombre) async {
    final db = await instance.database;
    final result = await db.query(
      'ejercicios',
      where: 'nombre = ?',
      whereArgs: [nombre],
      orderBy: 'id DESC',
    );
    return result.map((json) => Ejercicio.fromMap(json)).toList();
  }

  Future<int> delete(String id) async {
    final db = await instance.database;
    return await db.delete(
      'ejercicios',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> update(Ejercicio ejercicio) async {
    final db = await instance.database;
    return await db.update(
      'ejercicios',
      ejercicio.toMap(),
      where: 'id = ?',
      whereArgs: [ejercicio.id],
    );
  }
}