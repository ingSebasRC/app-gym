import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ejercicio.dart';

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
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ejercicios ADD COLUMN detalles TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE ejercicios ADD COLUMN fecha TEXT');
      await db.execute('''
        CREATE TABLE rutinas (
          id TEXT PRIMARY KEY,
          nombre TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE ejercicios_rutina (
          id TEXT PRIMARY KEY,
          rutina_id TEXT NOT NULL,
          nombre_ejercicio TEXT NOT NULL,
          FOREIGN KEY (rutina_id) REFERENCES rutinas (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE ejercicios_maestros_custom (
          nombre TEXT PRIMARY KEY,
          grupo_muscular TEXT NOT NULL
        )
      ''');
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
        detalles TEXT,
        fecha TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE rutinas (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ejercicios_rutina (
        id TEXT PRIMARY KEY,
        rutina_id TEXT NOT NULL,
        nombre_ejercicio TEXT NOT NULL,
        FOREIGN KEY (rutina_id) REFERENCES rutinas (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ejercicios_maestros_custom (
        nombre TEXT PRIMARY KEY,
        grupo_muscular TEXT NOT NULL
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
        fecha: DateTime.now(),
      ),
      Ejercicio(
        id: '2',
        nombre: 'Sentadillas',
        peso: 100.0,
        repeticiones: 8,
        series: 4,
        dia: 1, // Martes
        fecha: DateTime.now(),
      ),
      Ejercicio(
        id: '3',
        nombre: 'Peso Muerto',
        peso: 120.0,
        repeticiones: 5,
        series: 3,
        dia: 2, // Miércoles
        fecha: DateTime.now(),
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

  Future<List<Ejercicio>> readAllByFecha(DateTime fecha) async {
    final db = await instance.database;
    final startOfDay = DateTime(fecha.year, fecha.month, fecha.day).toIso8601String();
    final endOfDay = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59).toIso8601String();
    
    final result = await db.query(
      'ejercicios',
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
    );
    return result.map((json) => Ejercicio.fromMap(json)).toList();
  }

  // Rutinas
  Future<int> insertRutina(String nombre, List<String> nombresEjercicios) async {
    final db = await instance.database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert('rutinas', {'id': id, 'nombre': nombre});
    for (var nombreEj in nombresEjercicios) {
      await db.insert('ejercicios_rutina', {
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'rutina_id': id,
        'nombre_ejercicio': nombreEj,
      });
    }
    return 1;
  }

  Future<List<Map<String, dynamic>>> readAllRutinas() async {
    final db = await instance.database;
    return await db.query('rutinas');
  }

  Future<List<String>> readEjerciciosByRutina(String rutinaId) async {
    final db = await instance.database;
    final result = await db.query(
      'ejercicios_rutina',
      where: 'rutina_id = ?',
      whereArgs: [rutinaId],
    );
    return result.map((e) => e['nombre_ejercicio'] as String).toList();
  }

  Future<int> deleteRutina(String id) async {
    final db = await instance.database;
    return await db.delete('rutinas', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateRutina(String id, List<String> nuevosEjercicios) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // Eliminar ejercicios actuales
      await txn.delete('ejercicios_rutina', where: 'rutina_id = ?', whereArgs: [id]);
      // Insertar los nuevos
      for (var nombre in nuevosEjercicios) {
        await txn.insert('ejercicios_rutina', {
          'id': '${DateTime.now().millisecondsSinceEpoch}_$nombre',
          'rutina_id': id,
          'nombre_ejercicio': nombre,
        });
        await Future.delayed(const Duration(milliseconds: 1));
      }
    });
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

  // Ejercicios Maestros Custom
  Future<int> insertEjercicioMaestroCustom(String nombre, String grupoMuscular) async {
    final db = await instance.database;
    return await db.insert(
      'ejercicios_maestros_custom',
      {'nombre': nombre, 'grupo_muscular': grupoMuscular},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> readAllEjerciciosMaestrosCustom() async {
    final db = await instance.database;
    return await db.query('ejercicios_maestros_custom');
  }
}
