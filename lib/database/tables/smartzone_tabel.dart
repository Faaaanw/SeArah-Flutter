  import 'package:sqflite/sqflite.dart';
  import 'package:searah_backend/database/app_database.dart';
  import 'dart:math';

  import '/models/smartzone_model.dart';

  class SmartZoneTable {
    static const tableName = 'smart_zones';

    Future<void> createTable(Database db) async {
      await db.execute('''
        CREATE TABLE $tableName (
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

    /// ✅ CREATE
    Future<int> insertZone(SmartZone zone) async {
      final db = await AppDatabase.instance.database;
      return await db.insert(tableName, zone.toMap());
    }

    /// 🔍 READ (ambil semua zona user)
    Future<List<SmartZone>> getZonesByUser(int userId) async {
      final db = await AppDatabase.instance.database;
      final result =
          await db.query(tableName, where: 'user_id = ?', whereArgs: [userId]);
      return result.map((e) => SmartZone.fromMap(e)).toList();
    }

    /// 🔄 UPDATE
    Future<int> updateZone(SmartZone zone) async {
      final db = await AppDatabase.instance.database;
      return await db.update(
        tableName,
        zone.toMap(),
        where: 'id = ?',
        whereArgs: [zone.id],
      );
    }

    /// ❌ DELETE
    Future<int> deleteZone(int id) async {
      final db = await AppDatabase.instance.database;
      return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
    }

    /// 📍 CEK user dalam radius zona
    bool checkUserInZone(double userLat, double userLng, SmartZone zone) {
      double distance = _calculateDistance(
        userLat,
        userLng,
        zone.centerLatitude,
        zone.centerLongitude,
      );
      return distance <= zone.radiusM;
    }

    /// 🔢 Haversine Formula (jarak dua koordinat dalam meter)
    double _calculateDistance(
        double lat1, double lon1, double lat2, double lon2) {
      const R = 6371000; // radius bumi (meter)
      double dLat = _degToRad(lat2 - lat1);
      double dLon = _degToRad(lon2 - lon1);

      double a = sin(dLat / 2) * sin(dLat / 2) +
          cos(_degToRad(lat1)) *
              cos(_degToRad(lat2)) *
              sin(dLon / 2) *
              sin(dLon / 2);
      double c = 2 * atan2(sqrt(a), sqrt(1 - a));
      return R * c;
    }

    double _degToRad(double deg) => deg * pi / 180.0;
  }