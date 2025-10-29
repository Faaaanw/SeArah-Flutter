import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Import tabel modular
// import 'tables/user_tabel.dart';
import 'tables/friendship_tabel.dart';
import 'tables/user_locations_tabel.dart';
import 'tables/event_tabel.dart';
import 'tables/event_participant_tabel.dart';
import 'tables/smartzone_tabel.dart';

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
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // await UserTable().createTable(db);
    await FriendshipTable().createTable(db);
    await UserLocationTable().createTable(db);
    await EventTable().createTable(db);
    await EventParticipantTable().createTable(db);
    await SmartZoneTable().createTable(db);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
