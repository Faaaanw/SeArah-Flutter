// File: lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:searah_backend/pages/create_group_page.dart';
import '../viewmodel/home_viewmodel.dart';
import '../models/friend_model.dart';
// Import model Event (Diasumsikan ada)
import '../models/event_model.dart';
// Import model Group
import '../models/group_model.dart';

// Definisi Konstanta Warna (Sama dengan di LoginPage)
const Color _kPrimaryButtonColor = Color(0xFFFA8B60);
const Color _kPeachIconColor = Color(0xFFBFA4A0);

class HomePageWidget extends StatelessWidget {
  const HomePageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeView();
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    // --- LOGIKA KONDISI PANEL BAWAH ---
    Widget bottomPanelContent;
    bool showBottomPanel = true;

    if (vm.isLoading) {
      bottomPanelContent = const Center(child: CircularProgressIndicator());
    } else if (!vm.hasGroups) {
      // 1. KONDISI: Belum punya grup sama sekali
      bottomPanelContent = const _CreateGroupPanel();
    } else {
      // 2. KONDISI: Punya Grup (Lanjut ke Tampilan Peta)

      // *** LOGIKA PENYUSUNAN FRIEND LIST PANEL ***
      // NOTE: Logika ini HARUS disesuaikan nanti dengan state Event dan Current Group
      bottomPanelContent = _FriendListPanel(
        friends: vm.friends,
        currentUserId: vm.currentUserId ?? 0, // FIX: ubah ke int non-null
        currentEvent: null,
      );
    }

    // Untuk saat ini, kita selalu tampilkan panel sesuai desain
    // Jika Anda ingin panel hilang saat tidak ada Event/Friend, ubah showBottomPanel.

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Layer (Layer Bawah)
          _buildMapLayer(context, vm, vm.friends),

          // 2. Search & Group Filter Bar (Layer Atas, Floating)
          _buildSearchAndFilter(context, vm),

          // 3. Status/Friend List Panel (Layer Bawah, Sticky)
          if (showBottomPanel) // Tampilkan panel jika kondisi memenuhi
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.45,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 10, spreadRadius: 5)
                  ],
                ),
                child: bottomPanelContent,
              ),
            ),

          // 4. Floating Event Card (Sesuai Screenshot)
          if (vm.hasGroups &&
              !vm.isLoading) // Tampilkan di atas panel, jika ada grup
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).size.height * 0.45 -
                  20, // Posisi di atas panel
              child: const _EventCard(
                event: null, // TODO: Isi dengan Event aktual
              ),
            ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.45 + 20,
            right: 20,
            child: _LocationSharingButton(vm: vm),
          ),
        ],
      ),
    );
  }

  // ... _buildMapLayer tetap sama ...
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
            additionalOptions: {'key': 'nkV8u6JfP6d8DPcFsYJe'},
            userAgentPackageName: 'com.searah.app',
            tileDimension: 256,
            minZoom: 2,
            maxZoom: 18,
            keepBuffer: 2,
          ),
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
                    color: Colors.blue, size: 40),
              );

              return MarkerLayer(
                key: ValueKey(friendMarkers.length + 1),
                markers: [
                  // 🔴 Marker Teman
                  ...friendMarkers,

                  // 🔵 Marker Hasil Pencarian
                  if (vm.searchMarker != null)
                    Marker(
                      point: vm.searchMarker!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.blue, // 🔵 BEDA DARI USER
                        size: 40,
                      ),
                    ),

                  // 🟢 Marker User
                  userMarker,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ... _buildSearchAndFilter diubah untuk Group Dropdown ...
  Widget _buildSearchAndFilter(BuildContext context, HomeViewModel vm) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Row(
            children: [
              // 🔸 Search bar
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8)
                    ],
                  ),
                  child: TextField(
                    controller: vm.searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Location',
                      border: InputBorder.none,
                      prefixIcon:
                          const Icon(Icons.search, color: _kPeachIconColor),

                      // 🔥 Tambahkan tombol CLEAR di sini
                      suffixIcon: vm.searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                vm.clearSearchField(); // << fungsi di ViewModel
                              },
                            )
                          : null,

                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (query) {
                      if (query.isEmpty) {
                        vm.clearSearchField(); // sekarang clear marker dan results juga
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
              const SizedBox(width: 10),
              // 🔸 Group button
              _GroupDropdownButton(vm: vm),
            ],
          ),

          // 🔸 Loading bar
          if (vm.isSearching) const LinearProgressIndicator(minHeight: 2),

          // 🔸 Daftar hasil pencarian
          if (vm.searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
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
                        color: _kPeachIconColor, size: 18),
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
}
// --- 3. Widget State Teman (Disesuaikan) ---

// 3.1. State: Panel yang Tampil saat tidak ada Event
class _FriendListPanel extends StatelessWidget {
  final List<Friend> friends;
  final Event? currentEvent;
  final int currentUserId;

  const _FriendListPanel({
    required this.friends,
    required this.currentUserId,
    this.currentEvent,
  });

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const _ConnectNowPanel();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: currentEvent != null ? 80 : 20),
        const Padding(
          padding: EdgeInsets.only(left: 20.0, top: 8.0, bottom: 8.0),
          child: Text(
            'Your Friend\'s',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (_) {
              final filtered =
                  friends.where((f) => f.id != currentUserId).toList();

              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final friend = filtered[index];
                  return _FriendListItem(friend: friend);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// 3.1.1 State: Belum ada teman (Connect Now - tetap sama)
class _ConnectNowPanel extends StatelessWidget {
  const _ConnectNowPanel();

  @override
  Widget build(BuildContext context) {
    // ... (kode _ConnectNowPanel yang sama) ...
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "You're not connected with your friend yet",
            style: TextStyle(color: Colors.black54, fontSize: 16),
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
                backgroundColor: _kPrimaryButtonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Text('Connect Now',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

// 3.1.2 State: Belum ada grup (Create Group - diubah sedikit)
class _CreateGroupPanel extends StatelessWidget {
  const _CreateGroupPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_add_outlined,
              color: _kPeachIconColor, size: 60),
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
                backgroundColor: _kPrimaryButtonColor,
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

// --- 4. Widget Baru: Event Card dan Group Dropdown ---

// 4.1 Event Card (Sesuai Gambar)
class _EventCard extends StatelessWidget {
  final Event? event; // Akan diisi data Event dari ViewModel
  const _EventCard({this.event});

  @override
  Widget build(BuildContext context) {
    // Jika event null, tampilkan placeholder/hidden card
    if (event == null) return const SizedBox.shrink(); // Hide if no event

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimaryButtonColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Event (Placeholder)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white, // Placeholder color
              image: const DecorationImage(
                image: AssetImage(
                    'assets/images/event_placeholder.png'), // Ganti dengan path gambar Anda
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Detail Event
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event?.title ?? 'Family Gathering', // Judul Event
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '20 Oct 2025', // event?.startTime
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '18.00 - 20.00', // Format waktu
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      event?.locationName ?? 'SMKN 1 Cianjur',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Jarak dan Partisipan (Placeholder)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('1.5Km ⬆️',
                    style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
              const SizedBox(height: 10),
              // Avatar partisipan kecil (Sesuai gambar)
              const Row(
                children: [
                  CircleAvatar(radius: 8, backgroundColor: Colors.yellow),
                  CircleAvatar(radius: 8, backgroundColor: Colors.green),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationSharingButton extends StatelessWidget {
  final HomeViewModel vm;
  const _LocationSharingButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "btn-share-location",
      backgroundColor:
          vm.isUserSharingLocation ? Colors.green : Colors.grey.shade400,
      onPressed: () {
        // toggle on/off
        vm.toggleLocationSharing(!vm.isUserSharingLocation);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.isUserSharingLocation
                ? '📍 Location sharing activated'
                : '🚫 Location sharing stopped'),
            duration: const Duration(seconds: 2),
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

// 4.2 Group Dropdown Button (Mengganti Search Bar di kanan)
class _GroupDropdownButton extends StatelessWidget {
  final HomeViewModel vm;
  const _GroupDropdownButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: IconButton(
        icon: const Icon(Icons.group, color: _kPeachIconColor, size: 22),
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
              // ... drag handle & title ...
              ListTile(
                leading: const Icon(Icons.list, color: _kPeachIconColor),
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
                        leading:
                            const Icon(Icons.group, color: _kPeachIconColor),
                        title: Text(group.name),
                        onTap: () {
                          Navigator.pop(context);
                          vm.setCurrentGroup(group.id);
                        },
                      );
                    },
                  ),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_circle_outline,
                    color: _kPrimaryButtonColor),
                title: const Text('Create New Group',
                    style: TextStyle(color: _kPrimaryButtonColor)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateGroupPage()));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ... _LocationSharingToggle (diubah untuk menghapus Group Dropdown lama) ...
// 3.2.1 Item Daftar Teman
class _FriendListItem extends StatelessWidget {
  final Friend friend;
  const _FriendListItem({required this.friend});

  @override
  Widget build(BuildContext context) {
    // Status visual: jika tidak berbagi lokasi
    final bool isOffline = friend.latitude == null;

    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade200,
        child: Text(friend.name[0]),
      ),
      title: Text(friend.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(isOffline ? 'Location Disabled' : 'Online'),
      trailing: isOffline
          ? const Icon(Icons.visibility_off, color: Colors.redAccent)
          : const Icon(Icons.location_on, color: Colors.green),
      onTap: () {
        // TODO: Fokuskan Map ke lokasi teman ini
      },
    );
  }
}

// 3.3 Marker Peta
class _FriendMapMarker extends StatelessWidget {
  final Friend friend;
  const _FriendMapMarker({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: _kPrimaryButtonColor,
          child: Text(
            friend.name[0],
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kPrimaryButtonColor, width: 2),
          ),
          child: Text(friend.name, style: const TextStyle(fontSize: 10)),
        )
      ],
    );
  }
}
