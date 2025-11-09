// File: lib/viewmodel/home_viewmodel.dart
import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../models/friend_model.dart';
// WAJIB DITAMBAH: Import model Group
import '../models/group_model.dart';

class HomeViewModel extends ChangeNotifier {
  // ====== State Utama ======
  List<Friend> _friends = [];
  // START: Penambahan dan Perbaikan untuk Group
  List<Group> _groups = [];
  bool _isLoadingGroups = false;
  // END: Penambahan dan Perbaikan untuk Group
  String? _currentUserName;
  String? _currentUserEmail;

  String? get currentUserName => _currentUserName;
  String? get currentUserEmail => _currentUserEmail;

  bool _isLoading = false;
  bool _isUserSharingLocation = true;
  // Menghapus _hasGroups karena bisa dicek dari _groups.isNotEmpty

  // Akan diisi setelah login
  int? _currentUserId;
  String? _authToken;

  // ====== Getter ======
  List<Friend> get friends => _friends;
  // START: Getter untuk Group
  List<Group> get groups => _groups;
  bool get isLoadingGroups => _isLoadingGroups;
  // END: Getter untuk Group

  bool get isLoading => _isLoading;
  bool get isUserSharingLocation => _isUserSharingLocation;
  bool get hasFriends => _friends.isNotEmpty;
  // Perbaikan: Cek hasGroups dari list _groups
  bool get hasGroups => _groups.isNotEmpty;
  String? get authToken => _authToken;
  int? get currentUserId => _currentUserId;
  bool isLoadingFriends = false;

  // ====== Setter (dipanggil setelah login) ======
  void setUserSession({required int userId, required String token}) {
    _currentUserId = userId;
    _authToken = token;
  }

  // Method untuk menghapus sesi saat logout
  void clearSession() {
    _currentUserId = null;
    _authToken = null;
    _friends = [];
    _groups = [];
    _isLoading = false;
    _isUserSharingLocation = true;
    isLoadingFriends = false;
    _isLoadingGroups = false;
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    if (_authToken == null) return;
    try {
      final data = await ApiService.getCurrentUser(_authToken!);
      _currentUserName = data['name'];
      _currentUserEmail = data['email'];
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal memuat profil user: $e');
    }
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
      // Muat data Grup dan Teman secara paralel
      await Future.wait([
        fetchFriends(),
        fetchGroups(), // Muat grup
      ]);

      // Lokasi teman hanya dimuat jika ada teman
      if (_friends.isNotEmpty) {
        await fetchFriendLocations();
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ... (fetchFriends tetap sama) ...
  Future<void> fetchFriends() async {
    if (_authToken == null) return;

    isLoadingFriends = true;
    notifyListeners();

    try {
      final friendData = await ApiService.getFriends(_authToken!);
      // Asumsi Friend Model kompatibel dengan data User (ID, name, email)
      _friends = friendData.map((json) => Friend.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Gagal mengambil daftar teman: $e');
      _friends = [];
    } finally {
      isLoadingFriends = false;
      notifyListeners();
    }
  }

  // ... (fetchFriendLocations tetap sama) ...
  Future<void> fetchFriendLocations() async {
    if (_authToken == null || _currentUserId == null) return;

    try {
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

  // ====== Fitur Grup Baru ======

  // 🆕 Metode untuk mengambil daftar grup
  Future<void> fetchGroups() async {
    if (_authToken == null) return;

    _isLoadingGroups = true;
    notifyListeners();

    try {
      _groups = await ApiService.getUserGroups(_authToken!);
    } catch (e) {
      debugPrint('Gagal memuat grup: $e');
      _groups = [];
    } finally {
      _isLoadingGroups = false;
      notifyListeners();
    }
  }

  // ✅ Metode untuk menambahkan grup yang baru dibuat
  // Sekarang menerima objek Group, bukan Map
  void addGroup(Group newGroup) {
    _groups.insert(0, newGroup); // Masukkan di awal list
    notifyListeners();
  }

  // Note: Menghapus method setHasGroups karena sudah digantikan oleh getter hasGroups

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
