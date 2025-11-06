// File: lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../viewmodel/home_viewmodel.dart';
import '../models/friend_model.dart';


// Definisi Konstanta Warna (Sama dengan di LoginPage)
const Color _kPrimaryButtonColor = Color(0xFFFA8B60);
const Color _kPeachIconColor = Color(0xFFBFA4A0);

class HomePageWidget extends StatelessWidget {
  const HomePageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel()..loadInitialData(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Layer (Layer Bawah)
          _buildMapLayer(context, vm.friends),

          // 2. Search & Group Filter Bar (Layer Atas, Floating)
          _buildSearchAndFilter(context, vm),

          // 3. Status/Friend List Panel (Layer Bawah, Sticky)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45, // Sekitar 45%
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
              child: vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vm.hasFriends
                      ? _FriendListPanel(friends: vm.friends) // Ada Teman
                      : const _ConnectNowPanel(), // Belum Ada Teman
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // --- Component Builders ---

  Widget _buildMapLayer(BuildContext context, List<Friend> friends) {
    // Lokasi default (misalnya, di tengah Cianjur)
    final initialCenter = LatLng(-6.8208, 107.1396); 
    
    // Filter dan buat markers untuk teman yang berbagi lokasi
    final markers = friends
        .where((f) => f.latitude != null && f.longitude != null)
        .map((f) => Marker(
              point: LatLng(f.latitude!, f.longitude!),
              width: 60,
              height: 60,
              child: _FriendMapMarker(friend: f),
            ))
        .toList();

    // Tambahkan marker User Sendiri
    markers.add(
      Marker(
        point: initialCenter, // Ganti dengan lokasi user sendiri
        width: 60,
        height: 60,
        child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
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
        // Polyline atau Circle (untuk SmartZones) bisa ditambahkan di sini
      ],
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, HomeViewModel vm) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Column(
        children: [
          // Search Bar
          Container(
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
          
          const SizedBox(height: 10),

          // Pengaturan Berbagi Lokasi & Group (TODO: Ganti dengan Group Dropdown)
          _LocationSharingToggle(vm: vm),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _kPrimaryButtonColor,
      unselectedItemColor: _kPeachIconColor,
      backgroundColor: Colors.white,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined), label: 'Map'),
        BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined), label: 'Notifications'),
        BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined), label: 'Events'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      onTap: (index) {
        // Navigasi ke halaman lain
      },
    );
  }
}


// --- 3. Widget State Teman ---

// 3.1. State: Belum ada teman
class _ConnectNowPanel extends StatelessWidget {
  const _ConnectNowPanel();

  @override
  Widget build(BuildContext context) {
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
                // TODO: Navigasi ke halaman Add Friend
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Go to Add Friend Page')),
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

// 3.2. State: Sudah ada teman
class _FriendListPanel extends StatelessWidget {
  final List<Friend> friends;
  const _FriendListPanel({required this.friends});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODO: Ganti dengan Event Card seperti di gambar kanan Anda
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: _kPrimaryButtonColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Text('Event Card Placeholder', 
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ),
        
        const Padding(
          padding: EdgeInsets.only(left: 20.0, top: 8.0, bottom: 8.0),
          child: Text(
            'Your Friends',
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
      subtitle: Text(
          isOffline ? 'Location Disabled' : 'Online'),
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

// 3.4 Toggle Berbagi Lokasi
class _LocationSharingToggle extends StatelessWidget {
  final HomeViewModel vm;
  const _LocationSharingToggle({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // TODO: Group Filter Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8)
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.group, color: _kPeachIconColor, size: 20),
              const SizedBox(width: 8),
              // Placeholder Dropdown
              DropdownButton<String>(
                value: 'All Friends', // Ganti dengan Group yang dipilih
                items: const [
                  DropdownMenuItem(value: 'All Friends', child: Text('All Friends')),
                  DropdownMenuItem(value: 'Family', child: Text('Family')),
                  DropdownMenuItem(value: 'Work', child: Text('Work')),
                ],
                onChanged: (String? newValue) {
                  // vm.filterByGroup(newValue!);
                },
                underline: Container(), // Hapus garis bawah
              ),
            ],
          ),
        ),

        // Toggle Status Berbagi Lokasi User
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8)
            ],
          ),
          child: Row(
            children: [
              Text(vm.isUserSharingLocation ? 'Sharing' : 'Hidden', 
                   style: TextStyle(fontSize: 14, color: vm.isUserSharingLocation ? Colors.green : Colors.red)),
              Switch(
                value: vm.isUserSharingLocation,
                onChanged: vm.toggleLocationSharing,
                activeColor: _kPrimaryButtonColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}