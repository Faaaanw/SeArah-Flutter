import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/event_model.dart';

class EventTable {
  static const tableName='events';

  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
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
  }

  final dbHelper = AppDatabase.instance;

  Future<int> insertEvent(Event event) async {
    final db = await dbHelper.database;
    return await db.insert('events', event.toMap());
  }

  Future<List<Event>> getAllEvents() async {
    final db = await dbHelper.database;
    final result = await db.query('events', orderBy: 'start_time DESC');
    return result.map((e) => Event.fromMap(e)).toList();
  }

  Future<int> updateEvent(Event event) async {
    final db = await dbHelper.database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await dbHelper.database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }
}
