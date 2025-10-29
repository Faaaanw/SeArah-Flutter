import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/event_participant_model.dart';

class EventParticipantTable {
  static const tableName = 'event_participants';

  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        role TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertParticipant(EventParticipant participant) async {
    final db = await AppDatabase.instance.database;
    return await db.insert(tableName, participant.toMap());
  }

  Future<List<EventParticipant>> getParticipantsByEvent(int eventId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      tableName,
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
    return result.map((e) => EventParticipant.fromMap(e)).toList();
  }

  Future<bool> isUserJoined(int eventId, int userId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      tableName,
      where: 'event_id = ? AND user_id = ? AND status = ?',
      whereArgs: [eventId, userId, 'joined'],
    );
    return result.isNotEmpty;
  }

  Future<int> updateStatus(int eventId, int userId, String status) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      tableName,
      {'status': status},
      where: 'event_id = ? AND user_id = ?',
      whereArgs: [eventId, userId],
    );
  }

  Future<int> removeParticipant(int eventId, int userId) async {
    final db = await AppDatabase.instance.database;
    return await db.delete(
      tableName,
      where: 'event_id = ? AND user_id = ?',
      whereArgs: [eventId, userId],
    );
  }
}
