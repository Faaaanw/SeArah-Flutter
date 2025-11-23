import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:searah_backend/models/event_model.dart';
import '../services/api_services.dart';
import '../models/friend_model.dart';
import '../models/group_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';

class HomeViewModel extends ChangeNotifier {
  // ====== State Utama ======
  List<Friend> _allFriends = [];
  List<Friend> _friends = [];
  List<Group> _groups = [];
  List<Event> get events => _events;

  List<Event> _events = [];
  LatLng? selectedEventLocation;
  Event? activeEvent;
  List<Friend> eventMembers = [];
  Event? _currentEvent;
  Event? get currentEvent => _currentEvent;

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

  // ====== Lifecycle Safety ======
  bool _disposed = false;
  void safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _positionSubscription?.cancel();
    _friendUpdateTimer?.cancel();
    _debounceSendLocation?.cancel();
    _debounceSearch?.cancel();
    searchController.dispose();
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
    _positionSubscription?.cancel();
    _friendUpdateTimer?.cancel();
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
      safeNotifyListeners();
    }
  }

  // ----------------------------------------------------
  // 🔄 FUNGSI LOKASI REALTIME (🔥 UPDATED FIX ERROR)
  // ----------------------------------------------------

  /// 🔥 FIX: Helper function untuk mengecek izin & service SECARA AMAN
  /// Ini mencegah error "Object is not subtype of Position" di Web
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

  /// 🔥 FIX: Menggunakan _safeDeterminePosition
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
      // Opsional: Set lokasi default jika gagal total
      // _userLocation = LatLng(-6.8208, 107.1396);
    }
  }

  /**
   * 🔄 Memulai stream untuk pembaruan lokasi.
   */
  /**
   * 🔄 Memulai stream untuk pembaruan lokasi.
   * 🔥 FIX: Menggunakan pendekatan defensive programming untuk Web
   */
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
    })
        // .distinct() // ⚠️ FIX: Distinct dimatikan dulu untuk mencegah error perbandingan tipe data object

        // 3. 🔥 FIX: Terima sebagai 'dynamic' dulu, jangan langsung 'Position'
        .listen((dynamic position) {
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

  void toggleLocationSharing(bool value) async {
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
      // HIDUPKAN SHARING
      // 🔥 FIX: Gunakan safe determine position di sini juga
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

  // ... (Sisa kode ke bawah SAMA PERSIS, tidak ada perubahan)
  // fetchFriends, fetchFriendLocations, searchLocation, dll...

  // ====== Fetch Friends ======
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

      // 🔥 TAMBAHKAN BARIS INI:
      // Tempelkan kembali data lokasi yang tersimpan di cache ke object teman yang baru
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
    if (query.isEmpty) {
      _searchResults = [];
      safeNotifyListeners();
      return;
    }

    _debounceSearch?.cancel();
    _debounceSearch = Timer(const Duration(milliseconds: 400), () async {
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

        _searchCache[query] = results;
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

  void clearSearch() {
    searchController.clear();
    _searchResults = [];
    _isSearching = false;
    _searchMarker = null;
    safeNotifyListeners();
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
    required double latitude,
    required double longitude,
    String? locationName,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (_authToken == null) throw Exception("Token tidak ditemukan");

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
    );

    await fetchEvents(groupId);

    return event;
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
}

extension HomeViewModelRefresh on HomeViewModel {
  /// 🔄 Smart Refresh: Tidak bikin layar putih & Urutan Data Benar
  Future<void> refreshData() async {
    if (_authToken == null || _currentUserId == null) return;

    // ❌ JANGAN set _isLoading = true di sini!
    // Biarkan UI lama tetap tampil. Indikator loading cukup dari RefreshIndicator/Tombol.

    // Kita pakai flag lokal atau state khusus jika perlu, tapi untuk refresh,
    // biarkan user melihat data lama sampai data baru "pop" muncul.

    try {
      debugPrint("🔹 Refresh dimulai: Mengambil Grup dulu...");

      // 1. LANGKAH KRITIS: Ambil Grup DULUAN (Serial)
      // Kita harus pastikan grup terupdate sebelum minta data teman/event
      await fetchGroups();

      // Pastikan ada grup yang dipilih
      final groupId =
          _currentGroupId ?? (_groups.isNotEmpty ? _groups.first.id : null);

      // Jika grup berubah/hilang, update state
      if (_currentGroupId != groupId) {
        _currentGroupId = groupId;
      }

      debugPrint("🔹 Grup OK (ID: $groupId). Mengambil data paralel...");

      // 2. LANGKAH PARALEL: Ambil sisa data SEKALIGUS
      // Profil, Lokasi Teman, dan (Teman + Event berdasarkan Grup ID tadi)
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

      // 3. GPS (Fire and Forget)
      // Jalankan GPS di background saja, jangan tunggu dia selesai untuk menyelesaikan refresh
      // Ini bikin refresh terasa "instan"
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
