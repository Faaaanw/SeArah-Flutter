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
  List<Friend> _allFriends = []; // simpan semua teman
  List<Friend> _friends = []; // yang difilter, untuk UI
  List<Group> _groups = [];
  bool _isLoadingGroups = false;
  String? _currentUserName;
  String? _currentUserEmail;
  List<Map<String, dynamic>> _friendLocations = [];
  List<Map<String, dynamic>> get friendLocations => _friendLocations;
  int? _currentGroupId;
  int? get currentGroupId => _currentGroupId;
  Timer? _debounceSearch;
  Map<String, List<dynamic>> _searchCache = {};
  final Distance _distance = const Distance();
  LatLng? _searchMarker;
  LatLng? get searchMarker => _searchMarker;

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
  List<Friend> get friendsForMap => _friends
      .where((f) =>
          f.isSharingLocation && f.latitude != null && f.longitude != null)
      .toList();

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

// Saat user pilih grup
  void setCurrentGroup(int? groupId) async {
    _currentGroupId = groupId;

    if (groupId == null) {
      // All groups
      _friends = List.from(_allFriends);
      safeNotifyListeners();
    } else {
      // Ambil teman dari backend sesuai grup
      await fetchFriendsByGroup(groupId);
    }
  }

// Ambil teman dari backend per grup
  Future<void> fetchFriendsByGroup(int groupId) async {
    if (_authToken == null) return;

    _isLoading = true;
    safeNotifyListeners();

    try {
      final friendsInGroup = await ApiService.getFriendsByGroup(
          groupId: groupId, token: _authToken!);

      // Update cache _allFriends supaya pindah ke "All Groups" tetap ada
      _allFriends.removeWhere((f) => f.groupId == groupId);
      _allFriends.addAll(friendsInGroup);

      _friends = friendsInGroup;
      await fetchFriendLocations(_authToken!); // optional, ambil lokasi teman
    } catch (e) {
      debugPrint('Gagal mengambil teman per grup: $e');
      _friends = [];
    } finally {
      _isLoading = false;
      safeNotifyListeners();
    }
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
    await fetchFriendLocations(_authToken!);

// Reset lokasi user jika sharing dimatikan
    if (!_isUserSharingLocation) {
      _userLocation = LatLng(0, 0);
      safeNotifyListeners();
    }

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

  void toggleLocationSharing(bool value) {
    _isUserSharingLocation = value;

    // Jika dimatikan, hapus lokasi user di server
    if (!value) {
      _userLocation = LatLng(0, 0); // atau bisa null, sesuaikan
      _sendLocationToServer(0, 0, isSharing: false);
    } else {
      _sendLocationToServer(
        _userLocation.latitude,
        _userLocation.longitude,
        isSharing: true,
      );
    }

    safeNotifyListeners();
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
      _allFriends = friendData
          .map((json) => Friend.fromJson(json))
          .where(
              (f) => f.id != _currentUserId) // Hanya teman, bukan user sendiri
          .toList();

      // Tampilkan sesuai currentGroupId
      filterFriendsByGroup(_currentGroupId);
    } catch (e) {
      debugPrint('Gagal mengambil daftar teman: $e');
      _allFriends = [];
      _friends = [];
    } finally {
      isLoadingFriends = false;
      safeNotifyListeners();
    }
  }

  void filterFriendsByGroup(int? groupId) {
    if (groupId == null) {
      _friends = List.from(_allFriends);
    } else {
      _friends = _allFriends.where((f) => f.groupId == groupId).toList();
    }
    safeNotifyListeners();
  }

  void updateFriendLocationsOnMap() {
    if (_friendLocations.isEmpty || _friends.isEmpty) return;

    for (var friend in _friends) {
      final loc = _friendLocations.firstWhere(
        (f) => f['id'] == friend.id,
        orElse: () => {},
      );

      if (loc.isNotEmpty) {
        final isSharing = (loc['is_sharing'] ?? 1) == 1;
        friend.isSharingLocation = isSharing;

        if (isSharing) {
          friend.latitude = _safeParseDouble(loc['latitude']);
          friend.longitude = _safeParseDouble(loc['longitude']);
        } else {
          friend.latitude = null;
          friend.longitude = null;
        }
      }
    }

    // 🔹 Filter _friends agar hanya tampil yang sharing
    // Jangan hapus teman dari list _friends, cukup update lokasi & status sharing
    for (var friend in _friends) {
      final loc = _friendLocations.firstWhere(
        (f) => f['id'] == friend.id,
        orElse: () => {},
      );

      if (loc.isNotEmpty) {
        final isSharing = (loc['is_sharing'] ?? 1) == 1;
        friend.isSharingLocation = isSharing;

        if (isSharing) {
          friend.latitude = _safeParseDouble(loc['latitude']);
          friend.longitude = _safeParseDouble(loc['longitude']);
        } else {
          friend.latitude = null;
          friend.longitude = null;
        }
      }
    }

    safeNotifyListeners();
  }

  double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // ====== Fetch Friend Locations ======
  Future<void> fetchFriendLocations(String token) async {
    if (_currentUserId == null) return;
    try {
      final res = await ApiService.getFriendLocations(_currentUserId!, token);
      _friendLocations = List<Map<String, dynamic>>.from(res);
      updateFriendLocationsOnMap(); // ✅ sinkronisasi dan filter teman
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
  void filterByGroup(int groupId) {
    _friends = _friends.where((f) => f.groupId == groupId).toList();
    safeNotifyListeners();
  }

  Future<void> searchLocation(String query) async {
    if (query.isEmpty) return;

    _isLoading = true;
    safeNotifyListeners();

    try {
      // PAKAI CACHE DULU JIKA ADA
      List results;
      if (_searchCache.containsKey(query)) {
        results = _sortByDistance(_searchCache[query]!);
      } else {
        results = await ApiService.searchLocation(
          query,
          lat: _userLocation.latitude,
          lon: _userLocation.longitude,
        );
        _searchCache[query] = results;
      }

      if (results.isNotEmpty) {
        final loc = results.first; // hasil terdekat

        final lat = double.tryParse(loc['lat'] ?? '0');
        final lon = double.tryParse(loc['lon'] ?? '0');

        if (lat != null && lon != null) {
          _searchResultLocation = LatLng(lat, lon);
          mapController.move(_searchResultLocation!, 14.0);
          _searchMarker = LatLng(lat, lon);

          debugPrint("✅ Lokasi ditemukan: $lat, $lon");
        }
      } else {
        debugPrint("❌ Lokasi tidak ditemukan");
      }
    } catch (e) {
      debugPrint("Error mencari lokasi: $e");
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

    // DEBOUNCE agar tidak spam API
    _debounceSearch?.cancel();
    _debounceSearch = Timer(const Duration(milliseconds: 400), () async {
      // CEK CACHE
      if (_searchCache.containsKey(query)) {
        _searchResults = _sortByDistance(_searchCache[query]!);
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

        // SIMPAN KE CACHE
        _searchCache[query] = results;

        // SORT BERDASARKAN JARAK
        _searchResults = _sortByDistance(results);
      } catch (e) {
        debugPrint('Error fetchSearchSuggestions: $e');
        _searchResults = [];
      } finally {
        _isSearching = false;
        safeNotifyListeners();
      }
    });
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // ⬇️ Tambahkan di sini
  void clearSearch() {
    searchController.clear();
    _searchResults = [];
    _isSearching = false;

    _searchMarker = null; // 🔥 Hapus marker pencarian

    safeNotifyListeners();
  }

  void startFriendLocationUpdates() {
    Timer.periodic(const Duration(seconds: 15), (_) {
      if (_authToken != null) {
        fetchFriendLocations(_authToken!);
      }
    });
  }

  void setSearchMarker(double lat, double lon) {
    _searchMarker = LatLng(lat, lon);
    mapController.move(_searchMarker!, 15.0);
    safeNotifyListeners();
  }

  List<dynamic> _sortByDistance(List results) {
    return List.from(results)
      ..sort((a, b) {
        final latA = double.tryParse(a['lat'] ?? '0') ?? 0;
        final lonA = double.tryParse(a['lon'] ?? '0') ?? 0;
        final latB = double.tryParse(b['lat'] ?? '0') ?? 0;
        final lonB = double.tryParse(b['lon'] ?? '0') ?? 0;

        final dA = _distance.as(
            LengthUnit.Meter,
            LatLng(_userLocation.latitude, _userLocation.longitude),
            LatLng(latA, lonA));

        final dB = _distance.as(
            LengthUnit.Meter,
            LatLng(_userLocation.latitude, _userLocation.longitude),
            LatLng(latB, lonB));

        return dA.compareTo(dB); // urutkan ascending
      });
  }

  void clearSearchField() {
    searchController.clear(); // clear tulisan
    clearSearchResults(); // hapus daftar hasil
    clearSearchMarker(); // hapus marker di map
    mapController.move(userLocation, 15.0);
    safeNotifyListeners(); // update UI
  }

  void clearSearchMarker() {
    _searchMarker = null;
    safeNotifyListeners();
  }
}
