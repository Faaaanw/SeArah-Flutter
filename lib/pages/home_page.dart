import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:searah_backend/pages/create_event_page.dart';
import 'package:searah_backend/pages/create_group_page.dart';
import 'package:searah_backend/pages/event_detail.dart';
import 'package:searah_backend/pages/friends_page.dart';
import '../viewmodel/home_viewmodel.dart';
import '../models/friend_model.dart';
import '../models/event_model.dart';
import 'package:shimmer/shimmer.dart';

// --- Konstanta Warna (Disesuaikan dengan Target Desain) ---
const Color _kPrimaryColor = Color(0xFFFA8B60); // Orange Coral
const Color _kBgCreamColor = Color(0xFFFFF6E5); // Krem Background Card Teman
const Color _kTextColor = Color(0xFF5D4037); // Coklat Tua untuk Teks

class HomePageWidget extends StatelessWidget {
  const HomePageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeView();
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<HomeViewModel>();
      await vm.initializeHomeData();
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext(int maxIndex) {
    if (_currentIndex < maxIndex - 1) {
      _currentIndex++;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final now = DateTime.now();

    // 1. Urutkan event yang valid
    final sortedEvents = List<Event>.from(vm.events)
        .where((e) => e.endTime != null && e.endTime!.isAfter(now))
        .toList()
      ..sort((a, b) => b.startTime!.compareTo(a.startTime!));

    // 2. Cek status loading global
    bool isGlobalLoading = vm.isLoading || vm.isEventLoading || _isFirstLoad;

    // 3. Panel Putih tetap muncul jika user punya grup ATAU sedang loading
    // Ini menjaga agar panel tidak hilang saat refresh/init
    bool showBottomPanel = vm.hasGroups || isGlobalLoading;

    // 4. Event Card Logic
    bool showEventCard =
        showBottomPanel && sortedEvents.isNotEmpty && !isGlobalLoading;

    // --- LOGIC PENENTUAN ISI PANEL (MODIFIED) ---
    Widget bottomPanelContent;

    if (isGlobalLoading) {
      // 🔥 PERUBAHAN UTAMA:
      // Saat loading, JANGAN pakai CircularProgressIndicator.
      // Tetap panggil _FriendListPanel dengan isLoading: true agar Shimmer muncul.
      bottomPanelContent = _FriendListPanel(
        friends: vm.friends, // List boleh kosong, shimmer akan menutupinya
        currentUserId: vm.currentUserId ?? 0,
        currentUserLocation: vm.userLocation,
        isLoading: true, // <--- Memicu Shimmer Effect
      );
    } else if (!vm.hasGroups) {
      // Jika loading selesai & tidak punya grup
      bottomPanelContent = const _CreateGroupPanel();
    } else if (vm.friends.isEmpty) {
      // Punya grup tapi teman kosong
      bottomPanelContent = const _EmptyFriendListPlaceholder();
    } else {
      // Normal: Tampilkan list teman
      bottomPanelContent = _FriendListPanel(
        friends: vm.friends,
        currentUserId: vm.currentUserId ?? 0,
        currentUserLocation: vm.userLocation,
        isLoading: false,
      );
    }
    // ---------------------------------------------

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Map Layer
          _buildMapLayer(context, vm, vm.friends, sortedEvents),

          // 2. Search & Filter
          _buildSearchAndFilter(context, vm),

          // 3. Bottom Panel (Background Putih Melengkung)
          if (showBottomPanel)
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  // Tinggi panel (bisa disesuaikan logic-nya jika event ada/tidak)
                  height: MediaQuery.of(context).size.height * 0.40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15,
                          offset: Offset(0, -5))
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    // Menampilkan Shimmer atau Konten Asli
                    child: bottomPanelContent,
                  ),
                ),
              ),
            ),

          // 4. Event Card (Hanya muncul jika TIDAK loading dan ADA event)
          if (showEventCard) ...[
            Positioned(
              left: 0,
              right: 0,
              bottom: (MediaQuery.of(context).size.height * 0.40) - 50,
              child: SizedBox(
                height: 130,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: sortedEvents.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                    vm.setCurrentEvent(sortedEvents[index]);
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _EventCard(
                        userLocation: vm.userLocation,
                        event: sortedEvents[index],
                      ),
                    );
                  },
                  physics: const ClampingScrollPhysics(),
                ),
              ),
            ),

            // Tombol Navigasi Kiri
            Positioned(
              left: 10,
              bottom: (MediaQuery.of(context).size.height * 0.40) - 10,
              child: IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: Colors.white, size: 30),
                onPressed: _goToPrevious,
              ),
            ),

            // Tombol Navigasi Kanan
            Positioned(
              right: 10,
              bottom: (MediaQuery.of(context).size.height * 0.40) - 10,
              child: IconButton(
                icon: const Icon(Icons.chevron_right,
                    color: Colors.white, size: 30),
                onPressed: () => _goToNext(sortedEvents.length),
              ),
            ),
          ],

          // 5. Location Button
          Positioned(
            bottom: 20,
            right: 20,
            child: _LocationSharingButton(vm: vm),
          ),
        ],
      ),
    );
  }
}

Widget _buildMapLayer(
  BuildContext context,
  HomeViewModel vm,
  List<Friend> friends,
  List<Event> activeEvents, // <--- 1. TAMBAHKAN PARAMETER INI
) {
  return RepaintBoundary(
    child: FlutterMap(
      mapController: vm.mapController,
      options: MapOptions(
        initialCenter: vm.mapCenter,
        initialZoom: 13.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // ... (TileLayer tetap sama, copy paste saja bagian TileLayer kamu) ...
        TileLayer(
          urlTemplate:
              'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.jpg?key=nkV8u6JfP6d8DPcFsYJe',
          additionalOptions: const {'key': 'nkV8u6JfP6d8DPcFsYJe'},
          userAgentPackageName: 'com.searah.app',
          tileDimension: 256,
          minZoom: 2,
          maxZoom: 18,
          keepBuffer: 2,
        ),

        /// MARKER LAYER
        Consumer<HomeViewModel>(
          builder: (context, vm, _) {
            // ... (Marker Teman & User & Search tetap sama) ...
            final friendMarkers = vm.friendsForMap
                .where((f) => f.id != vm.currentUserId)
                .map((f) => Marker(
                      point: LatLng(f.latitude!, f.longitude!),
                      width: 120,
                      height: 110,
                      child: _FriendMapMarker(
                          friend: f, currentEvent: vm.currentEvent),
                    ))
                .toList();

            final userMarker = Marker(
              point: vm.userLocation,
              width: 60,
              height: 60,
              child: const Icon(Icons.person_pin_circle,
                  color: _kPrimaryColor, size: 50),
            );

            final searchMarkerWidget = vm.searchMarker == null
                ? <Marker>[]
                : [
                    Marker(
                      point: vm.searchMarker!,
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.location_on,
                          color: _kPrimaryColor, size: 45),
                    )
                  ];

            // 🔥 PERBAIKAN LOGIC EVENT MARKER 🔥
            final List<Marker> selectedEventMarkerList = [];

            // A. Ambil calon event dari VM
            Event? targetEvent = vm.currentEvent;
            final now = DateTime.now();

            // B. VALIDASI KETAT:
            // Cek 1: Apakah event hangus?
            // Cek 2: Apakah event ada di dalam list activeEvents (yg sudah difilter UI)?
            bool isEventInvalid = targetEvent != null &&
                ((targetEvent.endTime != null &&
                        targetEvent.endTime!.isBefore(now)) ||
                    !activeEvents.any((e) => e.id == targetEvent!.id));

            // C. AUTO SYNC / FALLBACK:
            // Jika vm.currentEvent kosong ATAU tidak valid (hangus),
            // maka PAKSA map untuk menampilkan event PERTAMA dari list yang valid.
            if (targetEvent == null || isEventInvalid) {
              if (activeEvents.isNotEmpty) {
                targetEvent =
                    activeEvents.first; // Ambil event paling baru/valid
              } else {
                targetEvent = null;
              }
            }

            // D. Render Marker jika targetEvent valid
            if (targetEvent != null) {
              selectedEventMarkerList.add(
                Marker(
                  point: LatLng(targetEvent.locationLatitude,
                      targetEvent.locationLongitude),
                  width: 80,
                  height: 80,
                  child: Column(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.blue, size: 50),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                  blurRadius: 4,
                                  color: Colors.black26,
                                  offset: Offset(0, 2))
                            ]),
                        child: Text(
                          targetEvent.title.length > 10
                              ? "${targetEvent.title.substring(0, 8)}..."
                              : targetEvent.title,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                ),
              );
            }

            return MarkerLayer(
              markers: [
                ...friendMarkers,
                ...searchMarkerWidget,
                ...selectedEventMarkerList, // Marker yang sudah divalidasi
                if (vm.isUserSharingLocation) userMarker,
              ],
            );
          },
        ),
      ],
    ),
  );
}
// ... _buildSearchAndFilter (UI dipercantik sedikit) ...
// ... (kode lain tetap sama)

Widget _buildSearchAndFilter(BuildContext context, HomeViewModel vm) {
  return Positioned(
    top: 60, // Sesuaikan jika perlu
    left: 24,
    right: 24,
    // ❌ HAPUS COLUMN PEMBUNGKUS UTAMA DISINI
    // Ganti langsung dengan Row agar sisi Kiri dan Kanan terpisah secara vertikal
    child: Row(
      crossAxisAlignment:
          CrossAxisAlignment.start, // 🔥 PENTING: Agar start dari atas
      children: [
        // ---------------------------------------------
        // 👈 SISI KIRI (Search Bar + Loading + Hasil)
        // ---------------------------------------------
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Agar tidak memakan semua tinggi
            children: [
              // 1. Search Bar Container
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ],
                ),
                child: TextField(
                  controller: vm.searchController,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'Search Location',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search, color: _kPrimaryColor),
                    suffixIcon: vm.searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.grey, size: 20),
                            onPressed: () {
                              vm.clearSearchField();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onChanged: (query) {
                    if (query.isEmpty) {
                      vm.clearSearchField();
                      return;
                    }
                    if (query.length > 2) {
                      vm.fetchSearchSuggestions(query);
                    } else {
                      vm.clearSearchResults();
                    }
                  },
                  onSubmitted: (query) {
                    FocusScope.of(context).unfocus();
                    if (query.isEmpty) {
                      vm.clearSearchField();
                      return;
                    }
                    vm.searchLocation(query);
                    vm.clearSearchResults();
                  },
                ),
              ),

              // 2. Loading Bar (Dipindah kesini)
              if (vm.isSearching)
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 12, right: 12),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: _kPrimaryColor,
                    backgroundColor: Colors.black12,
                  ),
                ),

              // 3. Hasil Pencarian (Dipindah kesini)
              if (vm.searchResults.isNotEmpty && !vm.isSearching)
                Container(
                  margin: const EdgeInsets.only(
                      top: 4), // Jarak tipis dari search bar
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 5)
                    ],
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: vm.searchResults.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final loc = vm.searchResults[index];
                      final name = loc['display_name'] ?? 'Unknown';
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on,
                            color: _kPrimaryColor, size: 18),
                        title: Text(name,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          final lat = double.tryParse(loc['lat'] ?? '0') ?? 0;
                          final lon = double.tryParse(loc['lon'] ?? '0') ?? 0;
                          vm.setSearchMarker(lat, lon);
                          vm.searchController.text = name;
                          vm.clearSearchResults();
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // ---------------------------------------------
        // 👉 SISI KANAN (Group & Create Event)
        // ---------------------------------------------
        // Kolom ini sekarang berdiri sendiri di sebelah kanan
        // dan tidak akan mendorong hasil pencarian ke bawah.
        Column(
          children: [
            // 1. Group Dropdown
            _GroupDropdownButton(vm: vm),

            const SizedBox(height: 12),

            // 2. Tombol Create Event
            if (vm.hasGroups)
              GestureDetector(
                onTap: () {
                  if (vm.currentGroupId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Pilih grup terlebih dahulu")),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateEventPage(
                        groupId: vm.currentGroupId!,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kPrimaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.add_location_alt_outlined,
                          color: Colors.white, size: 20),
                      SizedBox(height: 2),
                      Text(
                        "Create",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Event",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

// ... (kode lain tetap sama)
// --- 3. Widget Panel Teman (Desain Baru) ---

// ... (Kode Import di atas tetap sama)

class _FriendListPanel extends StatelessWidget {
  final List<Friend> friends;
  final int currentUserId;
  final LatLng currentUserLocation;
  final bool isLoading; // 🔥 1. Tambah parameter ini

  const _FriendListPanel({
    super.key,
    required this.friends,
    required this.currentUserId,
    required this.currentUserLocation,
    this.isLoading = false, // Default false
  });

  @override
  Widget build(BuildContext context) {
    // Filter logic tetap sama
    final filtered =
        friends.where((f) => f.id != currentUserId && f.isFriend).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Your Friend\'s',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _kPrimaryColor,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 🔥 2. Logika Switching antara Shimmer dan Data Asli
        Expanded(
          child: isLoading
              ? _buildShimmerList() // Tampilkan Shimmer jika loading
              : filtered.isEmpty
                  ? const Center(
                      child: Text(
                          "No active friends nearby")) // Handle empty state jika perlu
                  : RefreshIndicator(
                      color: _kPrimaryColor,
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        await context.read<HomeViewModel>().refreshData();
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final friend = filtered[index];
                          return _FriendListItem(
                            friend: friend,
                            currentUserLocation: currentUserLocation,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // 🔥 3. Widget Shimmer Kustom
  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        physics:
            const NeverScrollableScrollPhysics(), // Disable scroll saat loading
        itemCount: 5, // Tampilkan 5 dummy item
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              // Dummy Avatar
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
              ),
              const SizedBox(width: 16),
              // Dummy Text Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateGroupPanel extends StatelessWidget {
  const _CreateGroupPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_add_outlined, color: _kPrimaryColor, size: 60),
          const SizedBox(height: 16),
          const Text(
            "Anda belum bergabung dalam grup mana pun.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black87, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "Mulai berbagi lokasi dengan membuat grup baru.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            width: 200,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroupPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Text('Create Group',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFriendListPlaceholder extends StatelessWidget {
  const _EmptyFriendListPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 BAGIAN YANG DIUBAH: Bungkus dengan RefreshIndicator & ScrollView
    return RefreshIndicator(
      color: _kPrimaryColor,
      onRefresh: () async {
        await context.read<HomeViewModel>().refreshData();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight, // Agar bisa ditarik penuh
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_alt_outlined,
                        color: _kPrimaryColor, size: 50),
                    const SizedBox(height: 16),
                    const Text(
                      "Grup Anda belum memiliki teman.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black87, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Tambahkan teman ke grup ini untuk mulai berbagi lokasi.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FriendsPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: const Text('Add Friends',
                            style:
                                TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- 4. Event Card & Friend List Item (Desain Baru) ---

// 4.1 Event Card Modern (Oranye Penuh)
class _EventCard extends StatelessWidget {
  final Event? event;
  final LatLng userLocation;
  static const Color _kPrimaryColor = Color(0xFFFA8B60);

  const _EventCard({super.key, this.event, required this.userLocation});

  @override
  Widget build(BuildContext context) {
    if (event == null) return const SizedBox.shrink();

    final Distance distanceCalc = const Distance();
    final eventLatLng =
        LatLng(event!.locationLatitude, event!.locationLongitude);
    final double km = distanceCalc(userLocation, eventLatLng) / 1000;

    // Helper format waktu
    String formatTime(DateTime? dt) => dt == null
        ? "--:--"
        : "${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}";

    // Helper format tanggal
    String formatDate(DateTime? dt) {
      if (dt == null) return "--";
      final months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
    }

    // 🔧 LOGIC URL GAMBAR YANG AMAN
    String? getPhotoUrl() {
      if (event?.photo == null || event!.photo!.isEmpty) return null;

      // Karena sekarang Backend sudah mengirim Full URL, langsung return saja
      return event!.photo;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(event: event!),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12), // Mengurangi padding agar lebih luas
        decoration: BoxDecoration(
            color: _kPrimaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: _kPrimaryColor.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
            gradient: const LinearGradient(
                colors: [Color(0xFFFA8B60), Color(0xFFF37140)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: Stack(
          children: [
            Row(
              children: [
                // --- 1. GAMBAR (Updated) ---
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.white, // Background putih saat loading
                    child: getPhotoUrl() != null
                        ? Image.network(
                            getPhotoUrl()!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: _kPrimaryColor)),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback jika gagal load network
                              return Image.asset(
                                'assets/images/event_placeholder.jpg',
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/event_placeholder.jpg',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // --- 2. TEXT INFO ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Padding(
                        padding:
                            const EdgeInsets.only(right: 40.0), // Space badge
                        child: Text(
                          event?.title ?? 'Event',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Info Rows
                      _iconText(
                          Icons.calendar_today, formatDate(event?.startTime)),
                      const SizedBox(height: 2),
                      _iconText(Icons.access_time,
                          "${formatTime(event?.startTime)} - ${formatTime(event?.endTime)}"),
                      const SizedBox(height: 2),
                      // Tambah padding kanan agar tidak tertutup badge 'Joined'
                      Padding(
                        padding: const EdgeInsets.only(right: 50.0),
                        child: _iconText(Icons.location_on,
                            event?.locationName ?? "Location"),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Badge Jarak (Kanan Atas)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Text("${km.toStringAsFixed(1)}Km",
                    style: const TextStyle(
                        color: _kPrimaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),

            // Indikator Joined / Arrow (Kanan Bawah)
            if (event!.isJoined)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ]),
                  child: const Row(
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text("Joined",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 12),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        )
      ],
    );
  }
}

// 3.2.1 Item Daftar Teman (Desain "Card" Modern)
class _FriendListItem extends StatelessWidget {
  final Friend friend;
  final LatLng currentUserLocation; // Tambahkan parameter ini

  const _FriendListItem({
    required this.friend,
    required this.currentUserLocation,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Cek Status Online/Offline berdasarkan data Model
    // Syarat Online: isSharingLocation true DAN koordinat tidak null
    final bool isOnline = friend.isSharingLocation &&
        friend.latitude != null &&
        friend.longitude != null;

    // 2. Hitung Jarak Real (Hanya jika Online)
    String distanceText = "-";
    if (isOnline) {
      final Distance distance = const Distance();
      final double km = distance.as(
        LengthUnit.Kilometer,
        currentUserLocation,
        LatLng(friend.latitude!, friend.longitude!),
      );

      // Format: Jika jarak < 1 km, tampilkan 0.x km, jika jauh tampilkan bulat
      distanceText = km < 1
          ? "${km.toStringAsFixed(2)} km" // Contoh: 0.25 km
          : "${km.toStringAsFixed(1)} km"; // Contoh: 12.5 km
    }

    // 3. Tentukan Warna Status (Visual Difference)
    final Color statusColor = isOnline ? Colors.green : Colors.grey;
    final String statusText = isOnline ? "Online" : "Offline";

    return Opacity(
      // Jika offline, buat item sedikit transparan (Visual Difference 1)
      opacity: isOnline ? 1.0 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kBgCreamColor,
          borderRadius: BorderRadius.circular(24),
          border: isOnline
              ? null
              : Border.all(
                  color: Colors.grey.shade300), // Border abu jika offline
        ),
        child: Row(
          children: [
            // --- AVATAR ---
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade300,
                    // Di sini nanti bisa pakai NetworkImage jika ada URL foto di model
                    backgroundImage: const AssetImage(
                        'assets/images/avatar_placeholder.png'),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ),
                // Indikator Titik Status (Visual Difference 2)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 14,
                    width: 14,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // --- INFO NAMA & STATUS ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      // Jika offline, warna teks nama jadi abu-abu
                      color: isOnline ? _kTextColor : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isOnline ? Icons.wifi : Icons.wifi_off,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- INFO JARAK & BATERAI (KANAN) ---
            // Hanya tampilkan kolom ini jika Online
            if (isOnline)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Battery Row (Tetap Dummy sesuai request)
                  Row(
                    children: [
                      const Icon(Icons.battery_full,
                          size: 16, color: _kPrimaryColor),
                      const SizedBox(width: 4),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Distance Row (REAL DATA)
                  Row(
                    children: [
                      const Icon(Icons.near_me, // Ganti icon jadi panah arah
                          size: 16,
                          color: _kPrimaryColor),
                      const SizedBox(width: 4),
                      Text(
                        distanceText, // Hasil hitungan KM
                        style: const TextStyle(
                            color: _kPrimaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LocationSharingButton extends StatelessWidget {
  final HomeViewModel vm;
  const _LocationSharingButton({required this.vm});

  // Warna tema (Diasumsikan _kPrimaryColor didefinisikan di tempat lain)
  static const Color _kPrimaryColor = Color(0xFFFA8B60);
  static const String fontName = 'Poppins'; // Agar konsisten

  @override
  Widget build(BuildContext context) {
    // Note: Karena Anda menggunakan Consumer/Selector di level atas,
    // state vm.isUserSharingLocation akan diperbarui saat toggle dipanggil.

    return FloatingActionButton(
      heroTag: "btn-share-location",
      backgroundColor:
          vm.isUserSharingLocation ? _kPrimaryColor : Colors.grey.shade400,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () {
        // Simpan status sebelum toggle dipanggil
        final bool willBeSharing = !vm.isUserSharingLocation;

        // Panggil fungsi toggleLocationSharing versi lama (tanpa context)
        // Note: Asumsi fungsi ini hanya mengubah status dan mengirim data ke server
        vm.toggleLocationSharing(willBeSharing);

        // Notifikasi visual (Snackbar) ditampilkan di sini, di lapisan UI.
        // Kita menggunakan nilai yang akan datang (willBeSharing) untuk menentukan pesan dan warna.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              willBeSharing
                  ? 'Berbagi lokasi diaktifkan.'
                  : 'Berbagi lokasi dihentikan.',
              style: const TextStyle(fontFamily: fontName),
            ),
            backgroundColor: willBeSharing ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Icon(
        vm.isUserSharingLocation ? Icons.location_on : Icons.location_off,
        color: Colors.white,
      ),
    );
  }
}

// Group Dropdown Button (Tetap sama logic, hanya styling sedikit)
class _GroupDropdownButton extends StatelessWidget {
  final HomeViewModel vm;
  const _GroupDropdownButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.group, color: _kPrimaryColor, size: 24),
        onPressed: () => _showGroupModal(context),
      ),
    );
  }

  void _showGroupModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (_) {
        final groups = vm.groups;
        final hasGroups = vm.hasGroups;

        // 🔥 Logic: Cek apakah "All Groups" dipilih (null)
        final bool isAllGroupsSelected = vm.currentGroupId == null;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- OPSI ALL GROUPS ---
              ListTile(
                leading: Icon(
                  Icons.list,
                  // Ubah warna jika dipilih
                  color: isAllGroupsSelected ? _kPrimaryColor : Colors.grey,
                ),
                title: Text(
                  'All Groups',
                  style: TextStyle(
                    // Ubah warna & tebal teks jika dipilih
                    color:
                        isAllGroupsSelected ? _kPrimaryColor : Colors.black87,
                    fontWeight: isAllGroupsSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                // Tambah Centang di kanan jika dipilih
                trailing: isAllGroupsSelected
                    ? const Icon(Icons.check, color: _kPrimaryColor)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  vm.setCurrentGroup(null);
                },
              ),

              if (!hasGroups)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Belum ada grup. Buat grup baru untuk mulai berbagi lokasi!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];

                      // 🔥 Logic: Cek apakah grup ini dipilih
                      final bool isSelected = vm.currentGroupId == group.id;

                      return ListTile(
                        leading: Icon(Icons.group,
                            color: isSelected ? _kPrimaryColor : Colors.grey),
                        title: Text(
                          group.name,
                          style: TextStyle(
                            color: isSelected ? _kPrimaryColor : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        // Tambah Centang di kanan jika dipilih
                        trailing: isSelected
                            ? const Icon(Icons.check, color: _kPrimaryColor)
                            : null,
                        onTap: () async {
                          Navigator.pop(context);
                          await vm.setCurrentGroup(group.id);
                        },
                      );
                    },
                  ),
                ),
              const Divider(),
              ListTile(
                leading:
                    const Icon(Icons.add_circle_outline, color: _kPrimaryColor),
                title: const Text('Create New Group',
                    style: TextStyle(color: _kPrimaryColor)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateGroupPage()),
                  ).then((_) {
                    if (vm.currentGroupId != null) {
                      vm.fetchFriendsByGroup(vm.currentGroupId!);
                    } else {
                      vm.fetchFriends();
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// 3.3 Marker Peta (Sedikit dirapikan)
class _FriendMapMarker extends StatelessWidget {
  final Friend friend;
  final Event? currentEvent;

  const _FriendMapMarker({
    required this.friend,
    this.currentEvent,
  });

  static const double _maxNameWidth = 80.0;

  // --- LOGIC HITUNG JARAK ---
  String? _calculateDistanceInfo() {
    // 1. Cek Null Safety
    // Karena di Model Event locationLatitude adalah 'double' (bukan double?),
    // kita cukup cek apakah currentEvent-nya null.
    if (currentEvent == null ||
        friend.latitude == null ||
        friend.longitude == null) {
      return null;
    }

    // 2. Cek apakah teman ini adalah peserta event?
    // Gunakan 'participants' sesuai model
    bool isParticipant =
        currentEvent!.participants.any((p) => p['id'] == friend.id);

    if (!isParticipant) return null;

    // 3. Hitung Jarak
    final Distance distance = const Distance();

    // 🔥 PERBAIKAN DISINI:
    // Ganti .latitude -> .locationLatitude
    // Ganti .longitude -> .locationLongitude
    final double km = distance.as(
      LengthUnit.Kilometer,
      LatLng(friend.latitude!, friend.longitude!),
      LatLng(currentEvent!.locationLatitude, currentEvent!.locationLongitude),
    );

    // 4. Hitung Waktu (Asumsi 30km/jam)
    final int minutes = ((km / 30) * 60).round();

    if (km < 1) {
      final double meters = distance.as(
          LengthUnit.Meter,
          LatLng(friend.latitude!, friend.longitude!),
          LatLng(currentEvent!.locationLatitude,
              currentEvent!.locationLongitude)); // 🔥 Perbaikan disini juga
      return "${meters.round()}m • ${minutes}m";
    }

    return "${km.toStringAsFixed(1)}km • ${minutes}m";
  }

  @override
  Widget build(BuildContext context) {
    // Jalankan logika perhitungan
    final String? statusInfo = _calculateDistanceInfo();
    final bool showStatus = statusInfo != null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 🔥 Info Badge (Hanya muncul jika join event)
        // Di dalam _FriendMapMarker -> build -> Container Badge
// ...
        if (showStatus)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            // Tambahkan constraints agar badge tidak melebihi lebar marker (120 - padding)
            constraints: const BoxConstraints(maxWidth: 100),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_car, color: Colors.white, size: 10),
                const SizedBox(width: 4),
                // Gunakan Flexible agar text bisa ellipsis jika kepanjangan
                Flexible(
                  child: Text(
                    statusInfo!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow
                        .ellipsis, // 🔥 Potong teks jika terlalu panjang
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
// ...

        // --- MARKER ASLI (Avatar) ---
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: showStatus
                ? Border.all(color: const Color(0xFF2E7D32), width: 2)
                : null,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFFA8B60), // Primary Color
            child: Text(
              friend.name.isNotEmpty ? friend.name[0].toUpperCase() : "?",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 2),

        // --- NAMA TEMAN ---
        Container(
          constraints: const BoxConstraints(maxWidth: _maxNameWidth),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
          child: Text(
            friend.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        )
      ],
    );
  }
}

class _AddEventMarkerIcon extends StatelessWidget {
  const _AddEventMarkerIcon();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end, // Untuk menyejajarkan balon
      children: [
        // Balon Dialog (Speech Bubble)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 1.5), // Garis hitam
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(1, 1),
              ),
            ],
          ),
          child: const Text(
            "add event here",
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Segitiga kecil untuk 'balon' (opsional, untuk kesederhanaan kita skip/ganti dengan styling)
        // Jika ingin *persis* seperti gambar, perlu CustomPaint yang lebih kompleks, tapi ini lebih sederhana.

        // Pin Lokasi Oranye (Marker)
        const Icon(
          Icons.location_on, // Mengganti pin dengan ikon yang lebih mirip
          color: _kPrimaryColor, // Warna Oranye
          size: 45,
        ),
        // Memberikan ruang agar ikon pin muncul lebih ke bawah,
        // sehingga "Add Event Here" ada di atasnya
        const SizedBox(height: 10),
      ],
    );
  }
}
