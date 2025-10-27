import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('searah.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Buat database dan tabel
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Buat tabel events
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        creator_id INTEGER,
        title TEXT,
        description TEXT,
        location_name TEXT,
        location_latitude REAL,
        location_longitude REAL,
        start_time TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Buat tabel event_participants
    await db.execute('''
      CREATE TABLE event_participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER,
        user_id INTEGER,
        rsvp_status TEXT,
        is_organizer INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Buat tabel smart_zones
    await db.execute('''
      CREATE TABLE smart_zones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT,
        center_latitude REAL,
        center_longitude REAL,
        radius_m INTEGER,
        associated_event_id INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
