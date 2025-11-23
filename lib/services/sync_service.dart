import 'package:searah_backend/models/user_locations_model.dart';
import 'package:searah_backend/services/api_services.dart';
import '../database/app_database.dart';

class SyncService {
  static Future<void> syncData(int userId, String token) async {
    final db = await AppDatabase.instance.database;

    // ================================
    // 👥 Sinkronisasi daftar teman
    // Sekarang getFriends() tidak perlu userId
    // ================================
    final friendsJson = await ApiService.getFriends(token);
    await db.delete('friendships');

    for (var f in friendsJson) {
      await db.insert('friendships', {
        'user_id': userId, // id pengguna saat ini
        'friend_id': f['id'], // id teman dari response API
        'status': 'accepted',
        'share_type': f['share_type'] ?? 'none',
      });
    }

    // ================================
    // 📍 Sinkronisasi lokasi teman
    // getFriendLocations masih pakai userId (sesuai route /location/friends/{user_id})
    // ================================
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

    print('✅ Sinkronisasi data teman & lokasi selesai.');
  }
}
