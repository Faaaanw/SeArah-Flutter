import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:searah_backend/models/event_model.dart';
import '../services/api_services.dart';
import '../models/friend_model.dart';
import '../models/group_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class HomeViewModel extends ChangeNotifier {
  // ====== State Utama ======
  List<Friend> _allFriends = [];
  List<Friend> _friends = [];
  List<int> sentRequestIds = [];
  List<Group> _groups = [];
  List<Event> get events => _events;
  bool _isInitialized = false; // 🔥 Tambahkan ini
  bool get isInitialized => _isInitialized;

  List<Event> _events = [];
  LatLng? selectedEventLocation;
  Event? activeEvent;
  List<Friend> eventMembers = [];
  Event? _currentEvent;
  Event? get currentEvent => _currentEvent;
  Timer? _locationTimer;

  void setCurrentEvent(Event? event) {
    _currentEvent = event;
    safeNotifyListeners();
  }

  bool _isEventLoading = false;
  bool get isEventLoading => _isEventLoading;

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
  Timer? _debounceSendLocation;
  LatLng? _searchResultLocation;
  Timer? _friendUpdateTimer;

  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();

  bool _isLoading = false;
  bool _isUserSharingLocation = true;
  bool isLoadingFriends = false;

  int? _currentUserId;
  String? _authToken;

  // ====== Getter ======
  List<Friend> get friends => _friends;
  List<Friend> get allFriends => _allFriends;
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
  LatLng get searchResultLocation => _searchResultLocation ?? _userLocation;
  bool isRequestSent(int userId) {
    return sentRequestIds.contains(userId);
  }

  // ====== Lifecycle Safety ======
  bool _disposed = false;
  void safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;

    // 🔥 Panggil fungsi pembatalan terpusat sebelum dispose
    stopAllBackgroundUpdates();

    searchController.dispose();
    super.dispose();
  }

  void startLocationPolling() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // ... panggil ApiService.getFriendLocations(...)
    });
  }

  // 🔥 FUNGSI BARU UNTUK MENGHENTIKAN TIMER:
  void stopLocationPolling() {
    _locationTimer?.cancel();
    _locationTimer = null;
    print("✅ Polling Lokasi Teman Dihentikan.");
  }

  // ====== Setter (dipanggil setelah login) ======
  // ====== Setter (dipanggil setelah login) ======
  void setUserSession({required int userId, required String token}) {
    _currentUserId = userId;
    _authToken = token;

    // 🔥 WAJIB: Init notifikasi & Update Token begitu sesi aktif
    setupNotifications();

    startLocationUpdates();
    startFriendLocationUpdates();
  }

  void clearSession() {
    stopAllBackgroundUpdates(); // ⛔ Hentikan semua polling/stream sebelum menghapus token.

    _currentUserId = null;
    _authToken = null;
    _friends = [];
    _groups = [];
    _isLoading = false;
    _isInitialized = false;
    _isUserSharingLocation = true;
    isLoadingFriends = false;
    _isLoadingGroups = false;
    safeNotifyListeners();
  }

  // Saat user pilih grup
  Future<void> setCurrentGroup(int? groupId) async {
    _currentGroupId = groupId;

    if (groupId == null) {
      _friends = List.from(_allFriends);
      _events = [];
      safeNotifyListeners();
      return;
    }

    await fetchFriendsByGroup(groupId);
    await fetchEvents(groupId);
  }

  // Contoh di ViewModel
  Future<List<dynamic>> fetchCandidates(int groupId) async {
    // 1. Cek apakah token null. Jika ya, kembalikan list kosong agar tidak crash.
    if (_authToken == null) {
      print("⚠️ Gagal fetch candidates: Token tidak ditemukan.");
      return [];
    }

    try {
      // 2. Panggil API dengan tanda seru (!) karena kita sudah memastikan tidak null di atas
      return await ApiService.getGroupCandidates(
        token: _authToken!,
        groupId: groupId,
      );
    } catch (e) {
      print("Error fetching candidates: $e");
      return [];
    }
  }

  Future<bool> addMemberToGroup(int groupId, int userId) async {
    if (_authToken == null) return false;
    try {
      _isLoading = true;
      notifyListeners();

      // Panggil API Service yang sudah diperbaiki sebelumnya
      await ApiService.addMemberToGroup(
        token: _authToken!,
        groupId: groupId,
        memberUserId: userId,
      );

      _isLoading = false;
      notifyListeners();
      return true; // Berhasil
    } catch (e) {
      print("Error add member: $e");
      _isLoading = false;
      notifyListeners();
      return false; // Gagal
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

      _allFriends.removeWhere((f) => f.groupId == groupId);
      _allFriends.addAll(friendsInGroup);

      _friends = friendsInGroup;
      await fetchFriendLocations(_authToken!);
    } catch (e) {
      debugPrint('Gagal mengambil teman per grup: $e');
      _friends = [];
    } finally {
      _isLoading = false;
      safeNotifyListeners();
    }
  }

  // Tambahkan ini di HomeViewModel jika belum ada
  Future<void> addFriend(int friendId) async {
    if (_authToken == null || _currentUserId == null) return;
    try {
      await ApiService.addFriend(
        userId: _currentUserId!,
        friendId: friendId,
        token: _authToken!,
      );
      if (!sentRequestIds.contains(friendId)) {
        sentRequestIds.add(friendId);
        notifyListeners();
      }
      // Opsional: Refresh data atau update status local
    } catch (e) {
      debugPrint("Gagal add friend: $e");
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

  // Di dalam HomeViewModel
  Future<void> initializeHomeData() async {
    // 1. Set loading TRUE agar UI menampilkan CircularProgressIndicator, bukan EmptyPlaceholder
    _isLoading = true;
    notifyListeners(); // Update UI ke Loading State

    try {
      // 2. Ambil Data Grup dulu
      await fetchGroups();

      // 3. Logika Default: Jika ada grup, ambil "All Friends" (null)
      // Jika tidak ada grup, friends tetap kosong
      if (_groups.isNotEmpty) {
        await setCurrentGroup(
            null); // Ini akan memanggil fetchFriends() untuk semua grup
      }
    } catch (e) {
      print("Error initializing home: $e");
    } finally {
      // 4. Matikan Loading
      _isLoading = false;
      notifyListeners();
    }
  }

  // ====== Load Semua Data Awal ======
  Future<void> loadInitialData() async {
    await fetchFriendLocations(_authToken!);
    setupNotifications();

    if (!_isUserSharingLocation) {
      _userLocation = LatLng(0, 0);
      safeNotifyListeners();
    }

    if (_authToken == null || _currentUserId == null) {
      debugPrint('❌ Error: Token atau userId belum diatur.');
      return;
    }
    if (_currentGroupId != null) {
      await fetchEvents(_currentGroupId!);
    }

    _isLoading = true;
    safeNotifyListeners();

    try {
      await Future.wait([
        fetchFriends(),
        fetchGroups(),
        _getCurrentUserPositionOnce(), // 🔄 Ambil lokasi GPS di awal
      ]);

      if (_friends.isNotEmpty) {
        await fetchFriendLocations(_authToken!);
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      _isLoading = false;
      _isInitialized = true; // Tandai sudah inisialisasi
      safeNotifyListeners();
    }
  }

  Future<Position> _safeDeterminePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ... (Bagian cek permission di atas TETAP SAMA, jangan diubah) ...
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // 🔥 BAGIAN YANG DIUBAH: Tambahkan timeLimit
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5), // Menyerah setelah 5 detik
    );
  }

  Future<void> _getCurrentUserPositionOnce() async {
    try {
      // Panggil fungsi aman yang kita buat di atas
      final position = await _safeDeterminePosition();

      _userLocation = LatLng(position.latitude, position.longitude);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Cek mapController agar tidak error jika belum siap
        try {
          mapController.move(_userLocation, 13.0);
        } catch (e) {
          debugPrint("Map controller belum siap: $e");
        }
      });
      safeNotifyListeners();
    } catch (e) {
      // Tangani jika error, jangan crash
      debugPrint('⚠️ Gagal mendapatkan lokasi (sekali): $e');
    }
  }

  void startLocationUpdates() async {
    if (_currentUserId == null || _authToken == null) return;

    // 1. Cek izin dulu
    try {
      await _safeDeterminePosition();
    } catch (e) {
      debugPrint("⚠️ Tidak bisa memulai stream lokasi karena izin/service: $e");
      return;
    }

    _positionSubscription?.cancel();

    // 2. 🔥 FIX: Gunakan 'high' bukan 'bestForNavigation' untuk stabilitas Web
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).handleError((error) {
      debugPrint("⚠️ Error pada Stream Lokasi: $error");
    }).listen((dynamic position) {
      // Cek apakah data benar-benar Position
      if (position is Position) {
        _userLocation = LatLng(position.latitude, position.longitude);
        safeNotifyListeners();

        if (_isUserSharingLocation) {
          _sendLocationToServerDebounced(position.latitude, position.longitude);
        }
      } else {
        debugPrint("⚠️ Stream menerima data bukan Position: $position");
      }
    });

    debugPrint('✅ Location stream started safely (Web compatible).');
  }

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

  void _sendLocationToServerDebounced(double lat, double lon) {
    _debounceSendLocation?.cancel();
    _debounceSendLocation = Timer(const Duration(seconds: 5), () {
      _sendLocationToServer(lat, lon);
    });
  }

  void stopLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    debugPrint('Location updates stopped.');
  }

  Future<void> toggleLocationSharing(bool value) async {
    _isUserSharingLocation = value;
    if (!value) {
      // MATIKAN SHARING
      await _sendLocationToServer(
        _userLocation.latitude,
        _userLocation.longitude,
        isSharing: false,
      );
      debugPrint("🚫 Sharing dimatikan");
    } else {
      try {
        final pos = await _safeDeterminePosition();
        _userLocation = LatLng(pos.latitude, pos.longitude);

        startLocationUpdates(); // Mulai stream lagi

        await _sendLocationToServer(
          pos.latitude,
          pos.longitude,
          isSharing: true,
        );

        mapController.move(_userLocation, 15.0);
        debugPrint("📍 Sharing dihidupkan");
      } catch (e) {
        debugPrint("⚠️ Gagal mengaktifkan sharing: $e");
        // Kembalikan toggle switch ke off jika gagal
        _isUserSharingLocation = false;
      }
    }
    safeNotifyListeners();
  }

  // ====== Fetch Friends ======
  Future<void> fetchFriends() async {
    if (_authToken == null) return;

    isLoadingFriends = true;
    safeNotifyListeners();

    try {
      final friendData = await ApiService.getFriends(_authToken!);
      _allFriends = friendData
          .map((json) => Friend.fromJson(json))
          .where((f) => f.id != _currentUserId)
          .toList();

      filterFriendsByGroup(_currentGroupId);

      updateFriendLocationsOnMap();
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
    safeNotifyListeners();
  }

  double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> fetchFriendLocations(String token) async {
    if (_currentUserId == null) return;
    try {
      final res = await ApiService.getFriendLocations(_currentUserId!, token);
      _friendLocations = List<Map<String, dynamic>>.from(res);
      updateFriendLocationsOnMap();
      debugPrint(
          '✅ Lokasi teman berhasil diambil (${_friendLocations.length})');
    } catch (e) {
      debugPrint('⚠️ Gagal memuat lokasi teman: $e');
    }
  }

  Future<void> fetchGroups() async {
    if (_authToken == null) return;

    _isLoadingGroups = true;
    safeNotifyListeners();

    try {
      _groups = await ApiService.getUserGroups(_authToken!);
      if (_currentGroupId == null && _groups.isNotEmpty) {
        setCurrentGroup(_groups.first.id);
      }
    } catch (e) {
      debugPrint('Gagal memuat grup: $e');
      _groups = [];
    } finally {
      _isLoadingGroups = false;
      safeNotifyListeners();
    }
  }

  void addGroup(Group newGroup) {
    _groups.insert(0, newGroup);
    safeNotifyListeners();
  }

  void filterByGroup(int groupId) {
    _friends = _friends.where((f) => f.groupId == groupId).toList();
    safeNotifyListeners();
  }

  Future<void> searchLocation(String query) async {
    if (query.isEmpty) return;

    _isLoading = true;
    safeNotifyListeners();

    try {
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
        final loc = results.first;

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

  Future<void> fetchSearchSuggestions(String query) async {
    // 1. Jika kosong, langsung clear (Instant)
    if (query.isEmpty) {
      _debounceSearch?.cancel(); // Batalkan timer yang berjalan
      _searchResults = [];
      _isSearching = false; // Matikan loading
      notifyListeners(); // Pakai notifyListeners standar jika safeNotifyListeners ribet
      return;
    }

    // 2. Cancel timer sebelumnya jika user masih mengetik
    _debounceSearch?.cancel();

    // 3. SET TIMER LEBIH SINGKAT (300ms atau 250ms)
    _debounceSearch = Timer(const Duration(milliseconds: 300), () async {
      // Cek Cache dulu (Instant result)
      if (_searchCache.containsKey(query)) {
        _searchResults = _sortByDistance(_searchCache[query]!);
        _isSearching = false; // Pastikan loading mati
        notifyListeners();
        return;
      }

      // Mulai Loading State
      _isSearching = true;
      notifyListeners();

      try {
        final results = await ApiService.searchLocation(
          query,
          lat: _userLocation.latitude,
          lon: _userLocation.longitude,
        );

        // Simpan ke cache
        _searchCache[query] = results;

        _searchResults = _sortByDistance(results);
      } catch (e) {
        debugPrint('Error fetchSearchSuggestions: $e');
        _searchResults = [];
      } finally {
        // Matikan Loading State
        _isSearching = false;
        notifyListeners();
      }
    });
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  void clearSearch() {
    searchController.clear();
    _searchResults = [];
    _isSearching = false;
    _searchMarker = null;
    safeNotifyListeners();
  }

  Future<List<dynamic>> searchLocationDirectly(String query) async {
    if (query.isEmpty) return [];

    try {
      // Cek cache dulu jika ada
      if (_searchCache.containsKey(query)) {
        return _sortByDistance(_searchCache[query]!);
      }

      // Panggil API
      final results = await ApiService.searchLocation(
        query,
        lat: _userLocation.latitude,
        lon: _userLocation.longitude,
      );

      // Simpan ke cache
      _searchCache[query] = results;

      return _sortByDistance(results);
    } catch (e) {
      debugPrint('Error searchLocationDirectly: $e');
      return [];
    }
  }

  void startFriendLocationUpdates() {
    _friendUpdateTimer?.cancel();
    _friendUpdateTimer = Timer.periodic(const Duration(seconds: 15), (_) {
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

        return dA.compareTo(dB);
      });
  }

  void clearSearchField() {
    searchController.clear();
    clearSearchResults();
    clearSearchMarker();
    mapController.move(userLocation, 15.0);
    safeNotifyListeners();
  }

  void stopAllBackgroundUpdates() {
    stopLocationPolling(); // (Fungsi ini sudah ada di kode Anda)

    // ⛔ BATALKAN SEMUA TIMER UPDATE BERKALA
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _friendUpdateTimer?.cancel();
    _friendUpdateTimer = null;
    _debounceSendLocation?.cancel();
    _debounceSearch?.cancel();

    debugPrint("🛑 Semua background update (GPS, Teman, Timer) DIHENTIKAN.");
  }

  void clearSearchMarker() {
    _searchMarker = null;
    safeNotifyListeners();
  }

  Future<void> fetchGroupEvents(int groupId, String token) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await ApiService.getGroupEvents(groupId, token);
      _events = result;
    } catch (e) {
      print("Error fetch events: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEvents(int groupId) async {
    if (_authToken == null) {
      debugPrint("❌ fetchEvents: authToken null, tidak bisa fetch events");
      return;
    }

    _currentGroupId = groupId;
    _isEventLoading = true;
    safeNotifyListeners();

    debugPrint("🔹 fetchEvents: Memulai fetch events untuk groupId=$groupId");

    try {
      final events = await ApiService.getGroupEvents(groupId, _authToken!);

      debugPrint("🔹 fetchEvents: API returned ${events.length} event(s)");

      for (var ev in events) {
        debugPrint(
            "   Event: id=${ev.id}, title=${ev.title}, lat=${ev.locationLatitude}, lng=${ev.locationLongitude}");
      }

      _events = events;

      if (_events.isNotEmpty) {
        _currentEvent = _events.first;
        debugPrint(
            "🔹 fetchEvents: currentEvent di-set ke id=${_currentEvent?.id}, title=${_currentEvent?.title}");
      } else {
        debugPrint("🔹 fetchEvents: tidak ada event di grup ini");
      }
    } catch (e) {
      debugPrint("❌ fetchEvents: Gagal ambil event: $e");
      _events = [];
    } finally {
      _isEventLoading = false;
      safeNotifyListeners();
    }
  }

  Future<Event> createEvent({
    required int groupId,
    required String title,
    String? description,
    File? imageFile, // 🆕 Sesuaikan nama parameter agar konsisten (imageFile)
    required double latitude,
    required double longitude,
    String? locationName,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (_authToken == null) throw Exception("Token tidak ditemukan");

    try {
      _isLoading = true;
      notifyListeners();

      final event = await ApiService.createEvent(
        token: _authToken!,
        groupId: groupId,
        title: title,
        description: description,
        locationName: locationName,
        lat: latitude,
        lng: longitude,
        startTime: startTime,
        endTime: endTime,
        imageFile: imageFile, // 🚀 TERUSKAN KE SERVICE
      );

      // Refresh list event setelah berhasil tambah
      await fetchEvents(groupId);

      return event;
    } catch (e) {
      debugPrint("❌ Error createEvent di ViewModel: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Di dalam class HomeViewModel

  String getCreatorName(int creatorId) {
    if (_currentUserId != null && creatorId == _currentUserId) {
      return "Anda"; // Atau ambil dari _currentUserName
    }
    try {
      final creator = _friends.firstWhere((friend) => friend.id == creatorId);
      return creator.name ?? "Tanpa Nama";
    } catch (e) {
      // 3. Fallback jika user tidak ditemukan di list (misal user sudah left group tapi event masih ada)
      return "Mantan Anggota";
    }
  }

  Future<void> joinEvent(int eventId) async {
    if (_authToken == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final message = await ApiService.joinEvent(eventId, _authToken!);
      debugPrint("Join Event: $message");

      if (_currentGroupId != null) {
        await fetchEvents(_currentGroupId!);
      }
    } catch (e) {
      debugPrint("Gagal join event: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> leaveEvent(int eventId) async {
    if (_authToken == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final message = await ApiService.leaveEvent(eventId, _authToken!);
      debugPrint("Leave Event: $message");

      if (_currentGroupId != null) {
        await fetchEvents(_currentGroupId!);
      }
    } catch (e) {
      debugPrint("Gagal leave event: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEvent(int eventId) async {
    if (_authToken == null) {
      debugPrint("❌ deleteEvent: Token null");
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // 1. Panggil API Delete
      final message = await ApiService.deleteEvent(eventId, _authToken!);
      debugPrint("✅ Delete Event Success: $message");

      // 2. Update List Lokal (Optimistic Update)
      // Kita hapus manual dari list _events agar tidak perlu fetch ulang ke server
      _events.removeWhere((event) => event.id == eventId);

      // 3. Handle jika event yang dihapus adalah event yang sedang aktif di UI
      if (_currentEvent?.id == eventId) {
        _currentEvent = null;

        // Opsional: Jika masih ada event lain, set event pertama sebagai default
        if (_events.isNotEmpty) {
          _currentEvent = _events.first;
        }
      }
    } catch (e) {
      debugPrint("❌ Gagal menghapus event: $e");
      rethrow; // Lempar error ke UI agar bisa menampilkan SnackBar Error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔥 FUNGSI BARU: SETUP NOTIFIKASI
  Future<void> setupNotifications() async {
    if (_authToken == null) return; // Guard clause

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Minta Izin (Idempotent: aman dipanggil berkali-kali)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Izin Notifikasi Diberikan');

      // 2. Init Local Notification
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print("Notifikasi diklik: ${response.payload}");
        },
      );

      // 3. 🔥 UPDATE TOKEN KE SERVER (INTI MASALAHNYA DI SINI)
      // Kita ambil token fresh dari Firebase
      String? fcmToken = await messaging.getToken();

      if (fcmToken != null) {
        print(
            "🔥 Mengirim FCM TOKEN ke Server: ${fcmToken.substring(0, 10)}...");
        try {
          // Pastikan ApiService.updateFcmToken Anda sudah benar
          await ApiService.updateFcmToken(fcmToken, _authToken!);
          print("✅ Token FCM berhasil diperbarui di Database");
        } catch (e) {
          print("❌ Gagal update token ke server: $e");
        }
      }

      // 4. Listener Foreground (Saat aplikasi dibuka)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print(
            '📩 Pesan masuk saat aplikasi dibuka: ${message.notification?.title}');

        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'High Importance Notifications',
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
                playSound: true,
              ),
            ),
            payload: jsonEncode(message.data),
          );
        }
      });
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return "${meters.toStringAsFixed(0)}m";
    } else {
      return "${(meters / 1000).toStringAsFixed(1)}km";
    }
  }

  /// 1. Hitung Jarak User ke Teman
  String getDistanceToFriend(Friend friend) {
    // Jika teman tidak share lokasi atau koordinat null
    if (!friend.isSharingLocation ||
        friend.latitude == null ||
        friend.longitude == null) {
      return "";
    }

    // Hitung jarak menggunakan LatLng user saat ini vs LatLng teman
    final double meterDist = _distance.as(
      LengthUnit.Meter,
      _userLocation, // Lokasi User (Realtime GPS)
      LatLng(
          friend.latitude!, friend.longitude!), // Lokasi Teman (Dari Backend)
    );

    return _formatDistance(meterDist);
  }

  /// 2. Hitung Jarak User ke Event
  String getDistanceToEvent(Event event) {
    // Validasi koordinat event
    if (event.locationLatitude == 0 && event.locationLongitude == 0) {
      return "Lokasi Online/TBD";
    }

    final double meterDist = _distance.as(
      LengthUnit.Meter,
      _userLocation,
      LatLng(event.locationLatitude, event.locationLongitude),
    );

    return _formatDistance(meterDist);
  }

  /// 3. Ambil Object Friend berdasarkan ID Peserta Event
  /// Mengubah list ID (ex: [1, 5, 8]) menjadi List<Friend> lengkap dengan Foto & Nama
  List<Friend> getEventParticipantsData(Event event) {
    if (event.participants.isEmpty) return [];

    // Cari teman di list _allFriends yang ID-nya ada di event.participants
    // Kita pakai _allFriends agar bisa mendeteksi teman meski beda grup,
    // atau pakai _friends jika ingin strict satu grup.
    List<Friend> members = _allFriends
        .where((friend) => event.participants.contains(friend.id))
        .toList();

    // Tambahkan diri sendiri jika join (opsional, karena user login mungkin tidak ada di list friends)
    if (event.participants.contains(_currentUserId)) {
      // Logic jika ingin menampilkan foto diri sendiri di list peserta
      // Bisa handle manual di UI atau tambahkan object dummy Friend di sini
    }

    return members;
  }
}

extension HomeViewModelRefresh on HomeViewModel {
  /// 🔄 Smart Refresh: Tidak bikin layar putih & Urutan Data Benar
  Future<void> refreshData() async {
    if (_authToken == null || _currentUserId == null) return;
    try {
      debugPrint("🔹 Refresh dimulai: Mengambil Grup dulu...");
      await fetchGroups();

      // Pastikan ada grup yang dipilih
      final groupId =
          _currentGroupId ?? (_groups.isNotEmpty ? _groups.first.id : null);

      // Jika grup berubah/hilang, update state
      if (_currentGroupId != groupId) {
        _currentGroupId = groupId;
      }

      debugPrint("🔹 Grup OK (ID: $groupId). Mengambil data paralel...");
      await Future.wait([
        loadUserProfile(),
        fetchFriendLocations(_authToken!),

        // Hanya fetch teman & event jika ada grup
        if (groupId != null) ...[
          fetchFriendsByGroup(groupId),
          fetchEvents(groupId),
        ] else ...[
          // Jika tidak ada grup, kosongkan list dengan aman
          Future(() {
            _friends = [];
            _events = [];
          })
        ]
      ]);
      _getCurrentUserPositionOnce().then((_) {
        debugPrint("📍 GPS Refreshed (Background)");
      }).catchError((e) {
        debugPrint("⚠️ GPS Background Error: $e");
      });

      debugPrint("✅ Refresh data selesai & UI di-update");
    } catch (e) {
      debugPrint("❌ Gagal refresh data: $e");
    } finally {
      // Pastikan UI di-rebuild dengan data baru
      safeNotifyListeners();
    }
  }
}
