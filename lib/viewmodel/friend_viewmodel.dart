import 'package:flutter/material.dart';
import '../services/api_services.dart';

class FriendViewModel extends ChangeNotifier {
  List<dynamic> friends = [];
  List<Map<String, dynamic>> pendingRequests =
      []; // Ubah tipe jadi lebih spesifik
  bool isLoading = false;

  // --- Load Data ---

  Future<void> loadFriends(String token) async {
    isLoading = true;
    notifyListeners();

    try {
      friends = await ApiService.getFriends(token);
    } catch (e) {
      debugPrint("❌ Gagal ambil teman: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>?> loadPendingRequests(String token) async {
    try {
      final List<dynamic> data = await ApiService.getPendingRequests(token);
      pendingRequests = List<Map<String, dynamic>>.from(data);
      notifyListeners(); // Notify agar UI bisa update status saat search
      return pendingRequests;
    } catch (e) {
      debugPrint('❌ Error loadPendingRequests: $e');
      return [];
    }
  }

  // --- Search & Status Helpers (BARU) ---

  Future<List<Map<String, dynamic>>?> searchUserByName(
      String name, String token) async {
    try {
      final response = await ApiService.getRequest(
        '/search-user?name=$name',
        token,
      );

      if (response['success'] == true && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error searchUserByName: $e');
      return [];
    }
  }

  // Cek apakah User ID ini sudah ada di daftar teman
  bool isAlreadyFriend(int userId) {
    return friends.any((f) => f['id'] == userId);
  }

  // Cek apakah User ID ini ada di daftar permintaan masuk (Pending)
  // Mengembalikan ID Friendship (untuk action accept) jika ada, null jika tidak
  int? getIncomingRequestFriendshipId(int userId) {
    try {
      // Asumsi: pendingRequests memiliki field 'from_id' atau 'user_id' yang merujuk ke pengirim
      // dan 'id' adalah friendship_id
      final request = pendingRequests.firstWhere(
        (r) => (r['from_id'] ?? r['user_id']) == userId,
        orElse: () => {},
      );

      if (request.isNotEmpty) {
        return request['id']; // Kembalikan friendship ID
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // --- Actions ---

  Future<String?> addFriend({
    required int userId,
    required int friendId,
    required String token,
  }) async {
    try {
      final res = await ApiService.addFriend(
        userId: userId,
        friendId: friendId,
        token: token,
      );
      return res['message'] ?? 'Berhasil menambah teman';
    } catch (e) {
      return _cleanError(e);
    }
  }

  Future<String?> acceptFriend({
    required int friendshipId,
    required String token,
  }) async {
    try {
      await ApiService.acceptFriend(friendshipId, token);
      // Refresh data lokal setelah accept
      await loadFriends(token);
      await loadPendingRequests(token);
      return "Permintaan diterima";
    } catch (e) {
      return _cleanError(e);
    }
  }

  String _cleanError(Object e) {
    String errorMsg = e.toString();
    if (errorMsg.startsWith("Exception: ")) {
      errorMsg = errorMsg.replaceFirst("Exception: ", "");
    }
    return errorMsg;
  }
}
