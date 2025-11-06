  // File: lib/viewmodel/home_viewmodel.dart
  import 'package:flutter/material.dart';
  import '../services/api_services.dart';
  import '../models/friend_model.dart';

  class HomeViewModel extends ChangeNotifier {
    // ====== State Utama ======
    List<Friend> _friends = [];
    bool _isLoading = false;
    bool _isUserSharingLocation = true;
    bool _hasGroups = false;

    // Akan diisi setelah login
    int? _currentUserId;
    String? _authToken;

    // ====== Getter ======
    List<Friend> get friends => _friends;
    bool get isLoading => _isLoading;
    bool get isUserSharingLocation => _isUserSharingLocation;
    bool get hasFriends => _friends.isNotEmpty;
    bool get hasGroups => _hasGroups;
    String? get authToken => _authToken;
    int? get currentUserId => _currentUserId;
    bool isLoadingFriends = false;

    // ====== Setter (dipanggil setelah login) ======
    void setUserSession({required int userId, required String token}) {
      _currentUserId = userId;
      _authToken = token;
    }

    // ====== Core Methods ======
    Future<void> loadInitialData() async {
      if (_authToken == null || _currentUserId == null) {
        debugPrint('❌ Error: Token atau userId belum diatur.');
        return;
      }

      _isLoading = true;
      notifyListeners();

      try {
        await fetchFriends();

        if (_friends.isNotEmpty) {
          _hasGroups = true;
          await fetchFriendLocations();
        } else {
          _hasGroups = false;
        }
      } catch (e) {
        debugPrint("Error loading data: $e");
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }

    Future<void> fetchFriends() async {
    if (_authToken == null) return;

    isLoadingFriends = true;
    notifyListeners();

    try {
      final friendData = await ApiService.getFriends(_authToken!);
      _friends = friendData.map((json) => Friend.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Gagal mengambil daftar teman: $e');
      _friends = [];
    } finally {
      isLoadingFriends = false;
      notifyListeners();
    }
  }


    Future<void> fetchFriendLocations() async {
      if (_authToken == null || _currentUserId == null) return;

      try {
        // ✅ getFriendLocations masih butuh userId & token
        final locationData =
            await ApiService.getFriendLocations(_currentUserId!, _authToken!);

        for (var loc in locationData) {
          final index = _friends.indexWhere((f) => f.id == loc['user_id']);
          if (index != -1 && _friends[index].isSharingLocation) {
            _friends[index].updateLocation(
              loc['latitude'],
              loc['longitude'],
            );
          }
        }

        notifyListeners();
      } catch (e) {
        debugPrint('Gagal mengambil lokasi teman: $e');
      }
    }

    // ====== Fitur Grup ======
    void addGroup(Map<String, dynamic> groupJson) {
      _hasGroups = true;
      notifyListeners();
    }

    void setHasGroups(bool value) {
      _hasGroups = value;
      notifyListeners();
    }

    // ====== Lokasi User Sendiri ======
    void toggleLocationSharing(bool value) {
      _isUserSharingLocation = value;
      // TODO: Integrasi API update status berbagi lokasi
      // ApiService.updateLocationSharing(_currentUserId!, value, _authToken!);
      notifyListeners();
    }

    // ====== Filter Grup (Placeholder) ======
    void filterByGroup(String groupId) {
      // TODO: Filter teman berdasarkan grup tertentu
      notifyListeners();
    }
  }
