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

  // 🔹 1. Invite user → status = pending
  Future<int> inviteUser({
    required int eventId,
    required int userId,
    String role = 'participant',
  }) async {
    final db = await AppDatabase.instance.database;

    // Cek apakah user sudah pernah diundang atau join
    final existing = await db.query(
      tableName,
      where: 'event_id = ? AND user_id = ?',
      whereArgs: [eventId, userId],
    );

    if (existing.isNotEmpty) {
      // Jika sudah ada relasi, tidak perlu insert lagi
      return -1;
    }

    final participant = EventParticipant(
      eventId: eventId,
      userId: userId,
      role: role,
      status: 'pending',
      createdAt: DateTime.now().toIso8601String(),
    );

    return await db.insert(tableName, participant.toMap());
  }

  // 🔹 2. Accept invitation (pending → joined)
  Future<int> acceptInvitation(int eventId, int userId) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      tableName,
      {'status': 'joined'},
      where: 'event_id = ? AND user_id = ? AND status = ?',
      whereArgs: [eventId, userId, 'pending'],
    );
  }

  // 🔹 3. Decline invitation (pending → declined)
  Future<int> declineInvitation(int eventId, int userId) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      tableName,
      {'status': 'declined'},
      where: 'event_id = ? AND user_id = ? AND status = ?',
      whereArgs: [eventId, userId, 'pending'],
    );
  }

  // 🔹 4. Ambil semua undangan pending untuk user tertentu
  Future<List<EventParticipant>> getPendingInvites(int userId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      tableName,
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'pending'],
    );
    return result.map((e) => EventParticipant.fromMap(e)).toList();
  }

  // 🔹 5. Ambil semua event yang user sudah join
  Future<List<EventParticipant>> getJoinedEvents(int userId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      tableName,
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'joined'],
    );
    return result.map((e) => EventParticipant.fromMap(e)).toList();
  }

  // 🔹 6. Hapus user dari event
  Future<int> removeParticipant(int eventId, int userId) async {
    final db = await AppDatabase.instance.database;
    return await db.delete(
      tableName,
      where: 'event_id = ? AND user_id = ?',
      whereArgs: [eventId, userId],
    );
  }
}
