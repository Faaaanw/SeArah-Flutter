import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('searah');
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
      id INTEGER PRIMARY KEY, // Hapus AUTOINCREMENT jika ID disinkronkan dari server
      creator_id INTEGER NOT NULL,
      group_id INTEGER NOT NULL, // ⬅️ DITAMBAH
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
