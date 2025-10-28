import 'package:searah_backend/models/user_locations_model.dart';
import 'package:sqflite/sqflite.dart';
import '../app_database.dart';


class UserLocationTable {
  static const tableName = 'user_locations';

  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> upsertLocation(UserLocation location) async {
    final db = await AppDatabase.instance.database;

    // Cek apakah user sudah punya lokasi
    final existing = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [location.userId],
    );

    if (existing.isNotEmpty) {
      // Update existing record
      return await db.update(
        tableName,
        {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'user_id = ?',
        whereArgs: [location.userId],
      );
    } else {
      // Insert new record
      return await db.insert(tableName, location.toMap());
    }
  }

  Future<UserLocation?> getByUserId(int userId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isNotEmpty) {
      return UserLocation.fromMap(result.first);
    }
    return null;
  }

  Future<List<UserLocation>> getAll() async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(tableName);
    return result.map((e) => UserLocation.fromMap(e)).toList();
  }
}
