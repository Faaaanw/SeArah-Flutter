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

// --- Konstanta Warna (Disesuaikan dengan Target Desain) ---
const Color _kPrimaryColor = Color(0xFFFA8B60); // Orange Coral
const Color _kBgCreamColor = Color(0xFFFFF6E5); // Krem Background Card Teman
const Color _kTextColor = Color(0xFF5D4037); // Coklat Tua untuk Teks
const Color _kGreyText = Color(0xFFA1887F); // Abu-abu kecoklatan

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
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
    // Urutkan event
    final sortedEvents = List<Event>.from(vm.events)
        .where((e) =>
            e.endTime != null && e.endTime!.isAfter(now)) // 🔥 FILTER DISINI
        .toList()
      ..sort((a, b) => b.startTime!.compareTo(a.startTime!));

    // Bottom panel logic
    // Bottom panel logic
    Widget bottomPanelContent;

// 🔥 PERBAIKAN LOGIC UTAMA BOTTOM PANEL
    if (vm.isLoading || vm.isEventLoading) {
      bottomPanelContent = const Center(child: CircularProgressIndicator());
    } else if (!vm.hasGroups) {
      // 1. Belum ada Grup: Tampilkan panel untuk buat grup
      bottomPanelContent = const _CreateGroupPanel();
    } else if (vm.friends.isEmpty) {
      bottomPanelContent =
          const _EmptyFriendListPlaceholder(); // <--- BARIS KRITIS
    } else {
      // 3. Grup ada dan Teman ada: Tampilkan daftar teman di panel
      bottomPanelContent = _FriendListPanel(
        friends: vm.friends,
        currentUserId: vm.currentUserId ?? 0,
        currentUserLocation: vm.userLocation,
      );
    }
// Akhir dari PERBAIKAN LOGIC UTAMA BOTTOM PANEL

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Map Layer
          _buildMapLayer(context, vm, vm.friends),

          // 2. Search & Filter
          _buildSearchAndFilter(context, vm),

          // 3. Bottom Panel (Background Putih Melengkung)
          if (vm.hasGroups && !vm.isLoading && !vm.isEventLoading)
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                // Gunakan AnimatedContainer agar transisi naik/turunnya halus
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,

                // LOGIC 1: TINGGI PANEL
                // Jika ada event: 0.4 (40% layar) - Lebih pendek
                // Jika TIDAK ada event: 0.55 (55% layar) - Lebih tinggi/naik ke atas
                height: MediaQuery.of(context).size.height *
                    (vm.events.isNotEmpty ? 0.40 : 0.40),

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
                  padding:
                      EdgeInsets.only(top: vm.events.isNotEmpty ? 20.0 : 20.0),
                  child: bottomPanelContent,
                ),
              ),
            ),

          if (vm.hasGroups && sortedEvents.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: (MediaQuery.of(context).size.height * 0.40) - 50,
              child: SizedBox(
                height: 130,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: sortedEvents.length, // Pakai sortedEvents
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                    vm.setCurrentEvent(sortedEvents[index]);
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _EventCard(
                        userLocation: vm.userLocation,
                        event: sortedEvents[index], // Pakai sortedEvents
                      ),
                    );
                  },
                  physics: const ClampingScrollPhysics(),
                ),
              ),
            ),

          // Tombol Navigasi Kiri Kanan
          // 🔥 FIX 2: Ganti 'vm.events.isNotEmpty' jadi 'sortedEvents.isNotEmpty'
          if (vm.hasGroups && sortedEvents.isNotEmpty) ...[
            // TOMBOL KIRI
            Positioned(
              left: 10,
              bottom: (MediaQuery.of(context).size.height * 0.40) - 10,
              child: IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: Colors.white, size: 30),
                onPressed: _goToPrevious,
              ),
            ),

            // TOMBOL KANAN
            Positioned(
              right: 10,
              bottom: (MediaQuery.of(context).size.height * 0.40) - 10,
              child: IconButton(
                icon: const Icon(Icons.chevron_right,
                    color: Colors.white, size: 30),
                // 🔥 FIX 3: Jangan pakai vm.events.length, nanti error index out of range!
                // Pakai sortedEvents.length
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

// ... _buildMapLayer (Logic Tetap Sama) ...
Widget _buildMapLayer(
  BuildContext context,
  HomeViewModel vm,
  List<Friend> friends,
) {
  final userLoc = vm.userLocation;

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
            final friendMarkers = vm.friendsForMap
                .where((f) => f.id != vm.currentUserId)
                .map(
                  (f) => Marker(
                    point: LatLng(f.latitude!, f.longitude!),
                    width: 60,
                    height: 60,
                    child: _FriendMapMarker(friend: f),
                  ),
                )
                .toList();

            final userMarker = Marker(
              point: vm.userLocation,
              width: 60,
              height: 60,
              child: const Icon(Icons.person_pin_circle,
                  color: _kPrimaryColor, size: 50),
            );

            // 🔵 Marker lokasi search (tetap tampil)
            final searchMarkerWidget = vm.searchMarker == null
                ? <Marker>[]
                : [
                    Marker(
                      point: vm.searchMarker!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.location_on,
                        color:
                            _kPrimaryColor, // Pertahankan warna ikon yang sudah ada
                        size: 45,
                      ),
                    )
                  ];

            final addEventPopup = (vm.searchMarker == null ||
                    vm.currentGroupId == null)
                ? <Marker>[]
                : [
                    Marker(
                      // Posisikan di atas ikon lokasi (sedikit ke kiri atas)
                      point: LatLng(
                        vm.searchMarker!.latitude,
                        vm.searchMarker!.longitude,
                      ),
                      width: 150,
                      height: 60, // Tambah tinggi untuk padding

                      child: Transform.translate(
                        offset: const Offset(0, -50), // Naikkan posisi pop-up
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateEventPage(
                                  latitude: vm.searchMarker!.latitude,
                                  longitude: vm.searchMarker!.longitude,
                                  locationName: vm.searchController.text,
                                  groupId: vm.currentGroupId!,
                                ),
                              ),
                            );
                          },
                          // Tampilan Pop-up yang diperbagus
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color:
                                  _kPrimaryColor, // Ganti warna latar belakang ke warna utama
                              borderRadius:
                                  BorderRadius.circular(15), // Lebih membulat
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_location_alt,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 5),
                                const Text(
                                  "Add Event Here",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ];

            return MarkerLayer(
              markers: [
                ...friendMarkers,
                ...searchMarkerWidget, // Ikon lokasi pencarian
                ...addEventPopup, // Pop-up di atas ikon lokasi
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
Widget _buildSearchAndFilter(BuildContext context, HomeViewModel vm) {
  return Positioned(
    top: 60, // Turunkan sedikit agar tidak kena notch/status bar
    left: 24,
    right: 24,
    child: Column(
      children: [
        Row(
          children: [
            // 🔸 Search bar
            Expanded(
              child: Container(
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
            ),
            const SizedBox(width: 12),
            // 🔸 Group button
            _GroupDropdownButton(vm: vm),
          ],
        ),

        // 🔸 Loading bar
        if (vm.isSearching)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: const LinearProgressIndicator(
                minHeight: 2, color: _kPrimaryColor),
          ),

        // 🔸 Daftar hasil pencarian
        if (vm.searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 5)
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: vm.searchResults.length,
              itemBuilder: (context, index) {
                final loc = vm.searchResults[index];
                final name = loc['display_name'] ?? 'Unknown';
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on,
                      color: _kPrimaryColor, size: 18),
                  title: Text(name, style: const TextStyle(fontSize: 13)),
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
  );
}

// --- 3. Widget Panel Teman (Desain Baru) ---

// ... (Kode Import di atas tetap sama)

class _FriendListPanel extends StatelessWidget {
  final List<Friend> friends;
  final int currentUserId;
  final LatLng currentUserLocation;

  const _FriendListPanel({
    super.key,
    required this.friends,
    required this.currentUserId,
    required this.currentUserLocation,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = friends.where((f) => f.id != currentUserId).toList();

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
        const SizedBox(height: 10), // Tambahkan sedikit jarak

        // 🔥 BAGIAN YANG DIUBAH MULAI DARI SINI
        Expanded(
          child: RefreshIndicator(
            color: _kPrimaryColor, // Warna loading spinner
            backgroundColor: Colors.white,
            onRefresh: () async {
              // Panggil fungsi refresh dari ViewModel
              await context.read<HomeViewModel>().refreshData();
            },
            child: ListView.builder(
              // Penting: Agar bisa ditarik walau item sedikit
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
        // 🔥 AKHIR BAGIAN YANG DIUBAH
      ],
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
  // Warna primary
  static const Color _kPrimaryColor = Color(0xFFFA8B60);

  const _EventCard({super.key, this.event, required this.userLocation});

  @override
  Widget build(BuildContext context) {
    if (event == null) return const SizedBox.shrink();

    final Distance distanceCalc = const Distance();
    final eventLatLng =
        LatLng(event!.locationLatitude, event!.locationLongitude);
    final double km = distanceCalc(userLocation, eventLatLng) / 1000;

    // Helper format waktu & tanggal
    String formatTime(DateTime? dt) => dt == null
        ? "--:--"
        : "${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}";
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
        // Tidak perlu height fix disini, ikut parent
        // 🔥 PADDING OPTIMAL: Tidak terlalu besar agar muat banyak teks
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                // Gambar Kecil
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80, // Lebar gambar proporsional
                    height: 80,
                    color: Colors.white,
                    child: Image.asset('assets/images/event_placeholder.png',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.image, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),

                // Info Text
                Expanded(
                  child: Column(
                    // 🔥 ALIGNMENT: Rata Kiri & Tengah Vertikal
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 40.0), // Space untuk badge jarak
                        child: Text(event?.title ?? 'Event',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(height: 6),
                      _iconText(
                          Icons.calendar_today, formatDate(event?.startTime)),
                      const SizedBox(height: 2),
                      _iconText(Icons.access_time,
                          "${formatTime(event?.startTime)} - ${formatTime(event?.endTime)}"),
                      const SizedBox(height: 2),
                      _iconText(
                          Icons.location_on, event?.locationName ?? "Location"),
                    ],
                  ),
                ),
              ],
            ),

            // Badge Jarak (Pojok Kanan Atas)
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

            // Indikator Joined (Pojok Kanan Bawah)
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
              // Tombol View Kecil jika belum join
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
    return Row(children: [
      Icon(icon, color: Colors.white70, size: 12),
      const SizedBox(width: 4),
      Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis))
    ]);
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

                  // Tampilkan Email (karena lokasi nama tempat tidak ada di model)
                  Text(
                    friend.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: _kGreyText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Tampilkan Status Text
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
                      const Text(
                        "98%", // Dummy
                        style: TextStyle(
                            color: _kGreyText,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
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

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.list, color: _kPrimaryColor),
                title: const Text('All Groups'),
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
                      return ListTile(
                        leading: const Icon(Icons.group, color: _kPrimaryColor),
                        title: Text(group.name),
                        onTap: () async {
                          // Tutup modal dulu
                          Navigator.pop(context);
                          // Baru set grup (agar UI di belakang modal terlihat update)
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
                  Navigator.pop(context); // 1. Tutup Modal

                  // 2. Pindah ke Halaman Create Group
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateGroupPage()),
                  ).then((_) {
                    // 🔥 3. FIX: LOGIC SAAT KEMBALI (ON BACK)
                    // Saat user kembali dari CreateGroupPage, data 'friends' mungkin rusak
                    // karena tertimpa data global. Kita harus kembalikan ke konteks grup saat ini.

                    if (vm.currentGroupId != null) {
                      // Jika user sedang membuka grup spesifik, ambil ulang data grup itu
                      vm.fetchFriendsByGroup(vm.currentGroupId!);
                    } else {
                      // Jika user sedang di mode 'All Groups', ambil ulang data global + lokasi
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
  const _FriendMapMarker({required this.friend});

  // Tentukan lebar maksimum yang wajar untuk marker nama
  static const double _maxNameWidth = 80.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: _kPrimaryColor,
            child: Text(
              friend.name[0],
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 2),
        // 🔥 MODIFIKASI DIMULAI DI SINI
        Container(
          // 1. Batasi lebar Container
          constraints: const BoxConstraints(maxWidth: _maxNameWidth),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
          child: Text(
            friend.name,
            textAlign: TextAlign.center, // Pastikan teks di tengah
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            // 2. Tambahkan properti overflow
            overflow: TextOverflow.ellipsis,
            // 3. Batasi baris agar rapi
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
