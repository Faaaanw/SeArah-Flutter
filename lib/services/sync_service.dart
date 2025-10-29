import 'package:searah_backend/models/user_locations_model.dart';
import 'package:searah_backend/services/api_services.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

class SyncService {
  static Future<void> syncData(int userId, String token) async {
    final db = await AppDatabase.instance.database;

    // Sinkronisasi friendships
    final friendsJson = await ApiService.getFriends(userId, token);
    await db.delete('friendships');
    for (var f in friendsJson) {
      await db.insert('friendships', {
        'id': f['id'],
        'user_id': userId,
        'friend_id': f['id'],
        'status': 'accepted',
        'share_type': f['share_type'] ?? 'none',
      });
    }

    // Sinkronisasi lokasi teman
    final locationsJson = await ApiService.getFriendLocations(userId, token);
    await db.delete('user_locations');
    for (var l in locationsJson) {
      final loc = UserLocation.fromJson(l);
      await db.insert('user_locations', {
        'user_id': loc.userId,
        'latitude': loc.latitude,
        'longitude': loc.longitude,
      });
    }
  }
}
