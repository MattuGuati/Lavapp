import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tickets.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE tickets(id TEXT PRIMARY KEY, nombre TEXT, celular TEXT, estado TEXT, cantidad INTEGER)',
        );
      },
    );
  }

  Future<void> insertTicket(Map<String, dynamic> ticket) async {
    final db = await database;
    await db.insert('tickets', ticket, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllTickets() async {
    final db = await database;
    return db.query('tickets');
  }

  Future<void> deleteTicket(String id) async {
    final db = await database;
    await db.delete('tickets', where: 'id = ?', whereArgs: [id]);
  }
}
