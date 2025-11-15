import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../models/friend_model.dart';
import '../models/group_model.dart';
import 'package:latlong2/latlong.dart';
// import 'package:http/http.dart' as http; // Tidak digunakan di sini
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';

class HomeViewModel extends ChangeNotifier {
  // ====== State Utama ======
  List<Friend> _friends = [];
  List<Group> _groups = [];
  bool _isLoadingGroups = false;
  String? _currentUserName;
  String? _currentUserEmail;
  List<Map<String, dynamic>> _friendLocations = [];
  List<Map<String, dynamic>> get friendLocations => _friendLocations;

  // 🆕 State Lokasi Pengguna & Stream Subscription
  LatLng _userLocation = LatLng(-6.8208, 107.1396); // Default
  StreamSubscription<Position>? _positionSubscription;
  // ⬇️ Tambahkan di sini
  Timer? _debounceSendLocation; // 🕒 untuk delay kirim lokasi ke server
  LatLng? _searchResultLocation; // 📍 pisahkan lokasi hasil pencarian

  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();

  bool _isLoading = false;
  bool _isUserSharingLocation = true;
  bool isLoadingFriends = false;

  int? _currentUserId;
  String? _authToken;

  // ====== Getter ======
  List<Friend> get friends => _friends;
  List<Group> get groups => _groups;
  bool get isLoadingGroups => _isLoadingGroups;
  bool get isLoading => _isLoading;
  bool get isUserSharingLocation => _isUserSharingLocation;
  bool get hasFriends => _friends.isNotEmpty;
  bool get hasGroups => _groups.isNotEmpty;
  String? get currentUserName => _currentUserName;
  String? get currentUserEmail => _currentUserEmail;
  String? get authToken => _authToken;
  int? get currentUserId => _currentUserId;

  LatLng get userLocation => _userLocation;
  LatLng get mapCenter => _userLocation;
// ⬇️ Tambahkan di sini
  LatLng get searchResultLocation => _searchResultLocation ?? _userLocation;

  // ====== Lifecycle Safety ======
  bool _disposed = false;
  void safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _positionSubscription?.cancel(); // 🔄 Hentikan stream
    super.dispose();
  }

  // ====== Setter (dipanggil setelah login) ======
  void setUserSession({required int userId, required String token}) {
    _currentUserId = userId;
    _authToken = token;
    startLocationUpdates();
    startFriendLocationUpdates();
  }

  void clearSession() {
    _currentUserId = null;
    _authToken = null;
    _friends = [];
    _groups = [];
    _isLoading = false;
    _isUserSharingLocation = true;
    isLoadingFriends = false;
    _isLoadingGroups = false;
    _positionSubscription?.cancel(); // Pastikan stream berhenti saat logout
    safeNotifyListeners();
  }

  // ====== Load Profile ======
  Future<void> loadUserProfile() async {
    if (_authToken == null) return;
    try {
      final data = await ApiService.getCurrentUser(_authToken!);
      _currentUserName = data['name'];
      _currentUserEmail = data['email'];
      safeNotifyListeners();
    } catch (e) {
      debugPrint('Gagal memuat profil user: $e');
    }
  }

  // ====== Load Semua Data Awal ======
  Future<void> loadInitialData() async {
    if (_authToken == null || _currentUserId == null) {
      debugPrint('❌ Error: Token atau userId belum diatur.');
      return;
    }

    _isLoading = true;
    safeNotifyListeners();

    try {
      // Muat data grup, teman, dan lokasi pengguna saat ini secara paralel
      await Future.wait([
        fetchFriends(),
        fetchGroups(),
        _getCurrentUserPositionOnce(), // 🔄 Ambil lokasi GPS di awal, hanya sekali
      ]);

      if (_friends.isNotEmpty) {
        await fetchFriendLocations(_authToken!);
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      _isLoading = false;
      safeNotifyListeners();
    }
  }

  // ----------------------------------------------------
  // 🔄 FUNGSI LOKASI REALTIME (Diubah menjadi Stream)
  // ----------------------------------------------------

  // 🆕 Fungsi untuk mengambil posisi awal (sekali saja)
  Future<void> _getCurrentUserPositionOnce() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Layanan lokasi dinonaktifkan.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          debugPrint('Izin lokasi ditolak. Menggunakan lokasi default.');
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _userLocation = LatLng(position.latitude, position.longitude);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(_userLocation, 13.0);
      });
      safeNotifyListeners();
    } catch (e) {
      debugPrint('Gagal mendapatkan lokasi saat ini (sekali): $e');
    }
  }

  /**
   * 🔄 Memulai stream untuk pembaruan lokasi yang cepat dan akurat.
   */
  void startLocationUpdates() {
    if (_currentUserId == null || _authToken == null) return;

    _positionSubscription?.cancel();

    // Konfigurasi Akurasi dan Filter Jarak
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // Akurasi tertinggi
      distanceFilter: 10, // Update hanya jika bergerak 10 meter
    );

    // ⬇️ Ganti bagian ini
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    )
        .distinct((p1, p2) =>
            p1.latitude == p2.latitude && p1.longitude == p2.longitude)
        .listen((Position position) {
      _userLocation = LatLng(position.latitude, position.longitude);
      safeNotifyListeners();

      // Kirim posisi baru ke server jika sharing aktif
      if (_isUserSharingLocation) {
        _sendLocationToServerDebounced(position.latitude, position.longitude);
      }

      // Refresh lokasi teman (diambil setiap kali lokasi user diupdate/dikirim)
    }, onError: (error) {
      debugPrint('Error pada Location Stream: $error');
    });

    debugPrint('Location stream started (Distance Filter: 10m).');
  }

  /**
   * 🆕 Fungsi terpisah untuk mengirim ke server.
   */
  Future<void> _sendLocationToServer(double lat, double lon,
      {bool isSharing = true}) async {
    if (_currentUserId == null || _authToken == null) return;

    await ApiService.updateUserLocation(
      userId: _currentUserId!,
      token: _authToken!,
      latitude: lat,
      longitude: lon,
      isSharing: isSharing,
    );
  }

// ⬇️ Tambahkan di sini
  void _sendLocationToServerDebounced(double lat, double lon) {
    _debounceSendLocation?.cancel();
    _debounceSendLocation = Timer(const Duration(seconds: 5), () {
      _sendLocationToServer(lat, lon);
    });
  }

  /**
   * 🔄 Menghentikan stream pembaruan lokasi (Mengganti stopLocationUpdates lama).
   */
  void stopLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    debugPrint('Location updates stopped.');
  }

  // ❌ _updateLocationAndRefresh dihapus karena fungsinya diambil alih oleh Stream

  // ====== Lokasi User ======
  void toggleLocationSharing(bool value) {
    _isUserSharingLocation = value;
    safeNotifyListeners();

    // kirim status baru ke server
    _sendLocationToServer(
      _userLocation.latitude,
      _userLocation.longitude,
      isSharing: value,
    );
  }

  // (Fungsi-fungsi lain: fetchFriends, fetchFriendLocations, fetchGroups, addGroup, searchLocation, dll., tetap sama)
  // ...

  // ====== Fetch Friends ======
  Future<void> fetchFriends() async {
    if (_authToken == null) return;

    isLoadingFriends = true;
    safeNotifyListeners();

    try {
      final friendData = await ApiService.getFriends(_authToken!);
      _friends = friendData.map((json) => Friend.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Gagal mengambil daftar teman: $e');
      _friends = [];
    } finally {
      isLoadingFriends = false;
      safeNotifyListeners();
    }
    for (var f in _friends) {
      debugPrint(
          '➡️ ${f.name} (${f.id}) - lat: ${f.latitude}, lng: ${f.longitude}');
    }
  }

  void updateFriendLocationsOnMap() {
    if (_friendLocations.isEmpty || _friends.isEmpty) return;

    // _friendLocations = [{'id': 1, 'latitude': -6.82, 'longitude': 107.14}, ...]
    for (var friend in _friends) {
      final loc = _friendLocations.firstWhere(
        (f) => f['id'] == friend.id,
        orElse: () => {},
      );
      if (loc.isNotEmpty) {
        friend.latitude = (loc['latitude'] as num?)?.toDouble();
        friend.longitude = (loc['longitude'] as num?)?.toDouble();
      }
    }
    notifyListeners();
  }

  // ====== Fetch Friend Locations ======
  Future<void> fetchFriendLocations(String token) async {
    if (_currentUserId == null) return;
    try {
      final res = await ApiService.getFriendLocations(_currentUserId!, token);
      _friendLocations = List<Map<String, dynamic>>.from(res);
      updateFriendLocationsOnMap(); // ✅ Sinkronkan lokasi teman
      debugPrint(
          '✅ Lokasi teman berhasil diambil (${_friendLocations.length})');
    } catch (e) {
      debugPrint('⚠️ Gagal memuat lokasi teman: $e');
    }
  }

  // ... (Sisa kode fetchGroups, addGroup, filterByGroup, searchLocation, fetchSearchSuggestions, clearSearchResults)
  // ...

  // ====== Fetch Groups ======
  Future<void> fetchGroups() async {
    if (_authToken == null) return;

    _isLoadingGroups = true;
    safeNotifyListeners();

    try {
      _groups = await ApiService.getUserGroups(_authToken!);
    } catch (e) {
      debugPrint('Gagal memuat grup: $e');
      _groups = [];
    } finally {
      _isLoadingGroups = false;
      safeNotifyListeners();
    }
  }

  // ====== Tambah Grup Baru ======
  void addGroup(Group newGroup) {
    _groups.insert(0, newGroup);
    safeNotifyListeners();
  }

  // ====== Filter Grup (opsional) ======
  void filterByGroup(String groupId) {
    // TODO: filter teman berdasarkan grup tertentu
    safeNotifyListeners();
  }

  Future<void> searchLocation(String query) async {
    if (query.isEmpty) return;

    _isLoading = true;
    safeNotifyListeners();

    try {
      final results = await ApiService.searchLocation(
        query,
        lat: _userLocation.latitude,
        lon: _userLocation.longitude,
      );

      if (results.isNotEmpty) {
        final loc = results.first;
        final lat = double.tryParse(loc['lat'] ?? '0');
        final lon = double.tryParse(loc['lon'] ?? '0');
        if (lat != null && lon != null) {
          _searchResultLocation = LatLng(lat, lon);
          mapController.move(_searchResultLocation!, 14.0);

          debugPrint("✅ Lokasi ditemukan: $lat, $lon");
        } else {
          debugPrint("⚠️ Format lokasi tidak valid: $loc");
        }
      } else {
        debugPrint("❌ Lokasi tidak ditemukan");
      }
    } catch (e) {
      debugPrint("Error mencari lokasi lewat backend: $e");
    } finally {
      _isLoading = false;
      safeNotifyListeners();
    }
  }

  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  List<dynamic> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  // Fungsi baru untuk rekomendasi pencarian
  Future<void> fetchSearchSuggestions(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      safeNotifyListeners();
      return;
    }

    _isSearching = true;
    safeNotifyListeners();

    try {
      final results = await ApiService.searchLocation(
        query,
        lat: _userLocation.latitude,
        lon: _userLocation.longitude,
      );
      _searchResults = results;
    } catch (e) {
      _searchResults = [];
      debugPrint('Error fetchSearchSuggestions: $e');
    } finally {
      _isSearching = false;
      safeNotifyListeners();
    }
  }

  void clearSearchResults() {
    searchResults.clear();
    notifyListeners();
  }

  // ⬇️ Tambahkan di sini
  void clearSearch() {
    searchController.clear();
    _searchResults = [];
    _isSearching = false;
    safeNotifyListeners();
  }

  void startFriendLocationUpdates() {
    Timer.periodic(const Duration(seconds: 15), (_) {
      if (_authToken != null) {
        fetchFriendLocations(_authToken!);
      }
    });
  }
}
