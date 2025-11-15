import 'package:flutter/material.dart';
import '../services/api_services.dart';

class FriendViewModel extends ChangeNotifier {
  List<dynamic> friends = [];
  bool isLoading = false;

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
      return res['message'];
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> acceptFriend({
    required int friendshipId,
    required String token,
  }) async {
    try {
      await ApiService.acceptFriend(friendshipId, token);
      return "Permintaan diterima";
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<Map<String, dynamic>>?> searchUserByName(
      String name, String token) async {
    try {
      final response = await ApiService.getRequest(
        '/search-user?name=$name', // sesuaikan endpoint Laravel kamu
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

  Future<List<Map<String, dynamic>>?> loadPendingRequests(String token) async {
    try {
      final List<dynamic> data = await ApiService.getPendingRequests(token);
      // Konversi ke list map agar bisa langsung dipakai di UI
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('❌ Error loadPendingRequests: $e');
      return [];
    }
  }
}
