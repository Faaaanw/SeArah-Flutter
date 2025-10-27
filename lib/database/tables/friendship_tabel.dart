import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/friendship_model.dart';

class FriendshipTable {
  static const tableName = 'friendships';

  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        friend_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        share_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insert(Friendship friendship) async {
    final db = await AppDatabase.instance.database;
    return await db.insert(tableName, friendship.toMap());
  }

  Future<List<Friendship>> getAll() async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(tableName);
    return result.map((e) => Friendship.fromMap(e)).toList();
  }

  Future<int> updateStatus(int id, String status) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      tableName,
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateShareType(int id, String shareType) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      tableName,
      {'share_type': shareType, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
