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
        currentEvent: null, // TODO: Isi dengan Event dari VM
      );
    }
    
    // Untuk saat ini, kita selalu tampilkan panel sesuai desain
    // Jika Anda ingin panel hilang saat tidak ada Event/Friend, ubah showBottomPanel.

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Layer (Layer Bawah)
          _buildMapLayer(context, vm.friends),

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
          if (vm.hasGroups && !vm.isLoading) // Tampilkan di atas panel, jika ada grup
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).size.height * 0.45 - 20, // Posisi di atas panel
              child: const _EventCard(
                event: null, // TODO: Isi dengan Event aktual
              ),
            ),
        ],
      ),
      
    );
  }

  // ... _buildMapLayer tetap sama ...
  Widget _buildMapLayer(BuildContext context, List<Friend> friends) {
    // ... (kode _buildMapLayer yang sama) ...
    final initialCenter = LatLng(-6.8208, 107.1396);
    final markers = friends
        .where((f) => f.latitude != null && f.longitude != null)
        .map((f) => Marker(
              point: LatLng(f.latitude!, f.longitude!),
              width: 60,
              height: 60,
              child: _FriendMapMarker(friend: f),
            ))
        .toList();
    markers.add(
      Marker(
        point: initialCenter, // Ganti dengan lokasi user sendiri
        width: 60,
        height: 60,
        child:
            const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
      ),
    );
    return FlutterMap(
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(markers: markers),
      ],
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
              // Search Bar
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
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Location',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: _kPeachIconColor),
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Group Dropdown & Filter Icon (Sesuai Gambar)
              _GroupDropdownButton(vm: vm),
            ],
          ),
          const SizedBox(height: 10),
          // Toggle Status Berbagi Lokasi User
          Align(
            alignment: Alignment.centerRight,
            child: _LocationSharingToggle(vm: vm),
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
  final Event? currentEvent; // Event yang aktif (digunakan untuk Placeholder)
  
  const _FriendListPanel({required this.friends, this.currentEvent});

  @override
  Widget build(BuildContext context) {
    // START: Hapus Placeholder Event Card di sini, digantikan oleh _EventCard di Stack
    
    if (!friends.isNotEmpty) {
      // Belum Ada Teman (Tampilkan Connect Now)
      return const _ConnectNowPanel();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Padding untuk menaikkan list di bawah Event Card
        SizedBox(height: currentEvent != null ? 80 : 20), 
        
        const Padding(
          padding: EdgeInsets.only(left: 20.0, top: 8.0, bottom: 8.0),
          child: Text(
            'Your Friend\'s', // Sesuai screenshot
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return _FriendListItem(friend: friend);
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
          const Icon(Icons.group_add_outlined, color: _kPeachIconColor, size: 60),
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
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10)
        ],
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
                image: AssetImage('assets/images/event_placeholder.png'), // Ganti dengan path gambar Anda
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
                    const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '20 Oct 2025', // event?.startTime
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '18.00 - 20.00', // Format waktu
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      event?.locationName ?? 'SMKN 1 Cianjur',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                child: const Text('1.5Km ⬆️', style: TextStyle(color: Colors.white, fontSize: 10)),
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

// 4.2 Group Dropdown Button (Mengganti Search Bar di kanan)
class _GroupDropdownButton extends StatelessWidget {
  final HomeViewModel vm;
  const _GroupDropdownButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    // Tampilkan tombol ini hanya jika ada Grup
    if (!vm.hasGroups) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: const Icon(Icons.person, color: _kPeachIconColor, size: 28), // Ikon default
      );
    }
    
    // Logic Group Dropdown
    // TODO: Definisikan _currentGroup di HomeViewModel dan gunakan di sini
    final String? currentGroupId = null; // Ganti dengan vm.currentGroup?.id.toString()
    final List<Group> groups = vm.groups;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentGroupId, // Tetapkan nilai null/ID grup aktif
          icon: const Icon(Icons.people, color: _kPeachIconColor),
          hint: const Text('Pilih Grup', style: TextStyle(color: Colors.black87)),
          items: [
            // List Grup Aktif
            ...groups.map((Group group) {
              return DropdownMenuItem<String>(
                value: group.id.toString(),
                child: Text(group.name, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            
            // Pemisah
            const DropdownMenuItem<String>(
              value: 'divider',
              enabled: false,
              child: Divider(color: Colors.black12),
            ),

            // Opsi Create New Group
            DropdownMenuItem<String>(
              value: 'create_new',
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, size: 18, color: _kPrimaryButtonColor),
                  const SizedBox(width: 6),
                  Text('Create New Group', style: TextStyle(color: _kPrimaryButtonColor)),
                ],
              ),
            ),
          ],
          onChanged: (String? newValue) {
            if (newValue == 'create_new') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupPage()),
              );
            } else if (newValue != null && newValue != 'divider') {
              // TODO: Ganti Grup Aktif di ViewModel dan panggil sinkronisasi
              // vm.setCurrentGroup(int.parse(newValue));
            }
          },
        ),
      ),
    );
  }
}

// ... _LocationSharingToggle (diubah untuk menghapus Group Dropdown lama) ...
class _LocationSharingToggle extends StatelessWidget {
  final HomeViewModel vm;
  const _LocationSharingToggle({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Penting agar tidak melebar
        children: [
          Text(
            vm.isUserSharingLocation ? 'Sharing' : 'Hidden',
            style: TextStyle(
              fontSize: 14,
              color: vm.isUserSharingLocation ? Colors.green : Colors.red,
            ),
          ),
          Switch(
            value: vm.isUserSharingLocation,
            onChanged: vm.toggleLocationSharing,
            activeColor: _kPrimaryButtonColor,
          ),
        ],
      ),
    );
  }
}

// ... Widget lainnya (_FriendListItem, _FriendMapMarker) tetap sama ...

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

