import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:searah_backend/viewmodel/home_viewmodel.dart';
import '../models/friend_model.dart';
import '../models/event_model.dart';
import 'package:latlong2/latlong.dart';

// --- Theme Constants (Sesuai Screenshot) ---
const Color _primaryOrange = Color(0xFFFF6F4D); // Warna tombol/header
const Color _lightOrangeBg = Color(0xFFFFF0EB); // Background area tertentu
const Color _textDark = Color(0xFF2D2D2D);
const Color _textGrey = Color(0xFF888888);
const double _defaultPadding = 20.0;
const double _cardRadius = 24.0;

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        // Setup Data
        final upcomingEvent =
            viewModel.events.isNotEmpty ? viewModel.events.first : null;

        // Handle Loading
        if (viewModel.isLoading) {
          return const Scaffold(
            body:
                Center(child: CircularProgressIndicator(color: _primaryOrange)),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white, // Dasar putih bersih
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: _defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // 1. HEADER: Search Bar Style (Seperti di Screenshot Map)
                  _buildSearchHeader(),

                  const SizedBox(height: 24),

                  // 2. HIGHLIGHT EVENT (Gaya Homepage3 - Orange Card)
                  _buildSectionTitle("Recent Event"),
                  const SizedBox(height: 24),
                  if (upcomingEvent != null)
                    _buildEventHighlightCard(context, upcomingEvent, viewModel)
                  else
                    _buildEmptyEventCard(),

                  const SizedBox(height: 24),

                  // 3. STATUS LOKASI (Aksi Cepat)
                  _buildLocationToggle(viewModel),

                  const SizedBox(height: 24),

                  // 4. DAFTAR TEMAN (Gaya Homepage2 - Your Friend's)
                  _buildSectionTitle("Your Friend's"),
                  const SizedBox(height: 12),
                  _buildFriendsList(viewModel),

                  const SizedBox(height: 24),

                  // 5. GRID MENU (Menu Tambahan)
                  _buildSectionTitle("Menu Cepat"),
                  const SizedBox(height: 12),
                  _buildQuickMenuGrid(context, viewModel),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET BUILDERS ---

  // 1. Header Pencarian (Meniru Search Bar di atas Peta)
  Widget _buildSearchHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.search, color: _primaryOrange, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Search Location",
              style: TextStyle(
                color: _textGrey.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _primaryOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_alt, color: Colors.white, size: 20),
          )
        ],
      ),
    );
  }

  // 2. Event Card (Orange Background seperti Homepage3)
  Widget _buildEventHighlightCard(
      BuildContext context, Event event, HomeViewModel viewModel) {
    bool isJoined = event.participants.contains(viewModel.currentUserId);
    String distanceText = viewModel.getDistanceToEvent(event);
    List<Friend> participants = viewModel.getEventParticipantsData(event);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryOrange, // Background Oranye
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: _primaryOrange.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        image: const DecorationImage(
          // Pola background tipis agar tidak polos (opsional)
          image: NetworkImage(
              "https://www.transparenttextures.com/patterns/cubes.png"),
          opacity: 0.1,
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.near_me, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    // 🔥 TAMPILKAN JARAK REAL
                    Text(distanceText,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 8),

          // Tanggal & Waktu
          Row(
            children: [
              if (participants.isNotEmpty)
                SizedBox(
                  height: 30,
                  width: (participants.length * 20.0 + 20)
                      .clamp(0, 120), // Lebar dinamis
                  child: Stack(
                    // ... di dalam Stack
                    // Ganti seluruh bagian "Stack" children di dalam _buildEventHighlightCard dengan ini:

                    children:
                        List.generate(participants.take(4).length, (index) {
                      final member = participants[index];
                      return Positioned(
                        left: index * 18.0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey.shade200,
                            // 🔥 PERBAIKAN: Langsung panggil fungsi helper, jangan cek photoUrl
                            backgroundImage:
                                NetworkImage(_getAvatarUrl(member.name)),
                            onBackgroundImageError: (_, __) {},
                          ),
                        ),
                      );
                    }),
// ...
                  ),
                )
              else
                const Text("Belum ada peserta",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),

              const Spacer(),

              // Tombol Gabung
              ElevatedButton(
                onPressed: () {
                  isJoined
                      ? viewModel.leaveEvent(event.id!)
                      : viewModel.joinEvent(event.id!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFFF6F4D),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(isJoined ? "Batal" : "Gabung"),
              )
            ],
          )
        ],
      ),
    );
  }

  // Widget jika tidak ada event
  Widget _buildEmptyEventCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _lightOrangeBg,
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_busy, size: 40, color: _primaryOrange),
          const SizedBox(height: 10),
          const Text("Belum ada acara",
              style: TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
          const Text("Buat jadwal kumpul dengan temanmu!",
              style: TextStyle(color: _textGrey, fontSize: 12)),
        ],
      ),
    );
  }

  // 3. Status Lokasi (Toggle Switch simple)
  Widget _buildLocationToggle(HomeViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: viewModel.isUserSharingLocation
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(Icons.my_location,
                    color: viewModel.isUserSharingLocation
                        ? Colors.green
                        : Colors.red,
                    size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Berbagi Lokasi",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: _textDark)),
                  Text(
                    viewModel.isUserSharingLocation ? "Aktif" : "Nonaktif",
                    style: TextStyle(
                        fontSize: 12,
                        color: viewModel.isUserSharingLocation
                            ? Colors.green
                            : Colors.red),
                  )
                ],
              ),
            ],
          ),
          Switch(
            value: viewModel.isUserSharingLocation,
            onChanged: viewModel.toggleLocationSharing,
            activeColor: _primaryOrange,
            activeTrackColor: _primaryOrange.withOpacity(0.2),
          )
        ],
      ),
    );
  }

  // 4. Friend List (Gaya Homepage2 & 3)
  Widget _buildFriendsList(HomeViewModel viewModel) {
    // 1. Ambil ID User saat ini
    final currentUserId = viewModel.currentUserId;

    // 2. 🔥 FILTER DAN TAKE (Pastikan User sendiri TIDAK termasuk)
    // Filter ini dilakukan sekali di awal, sebelum memetakan widget.
    final filteredFriends = viewModel.friends
        .where((f) => f.id != currentUserId) // Hapus user yang sedang login
        .take(10) // Ambil maksimal 10
        .toList();

    if (filteredFriends.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("Belum ada teman di grup ini.",
            style: TextStyle(color: _textGrey)),
      ));
    }

    return Column(
      children: filteredFriends.map((friend) {
        // 🔥 HITUNG JARAK DINAMIS
        String distance = viewModel.getDistanceToFriend(friend);
        bool isSharing = friend.isSharingLocation;

        // Panggil fungsi helper avatar (asumsi _getAvatarUrl sudah ada di class)
        final avatarUrl = _getAvatarUrl(friend.name);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0EB), // _lightOrangeBg
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 22,
                  // 🔥 Menggunakan NetworkImage dari UI Avatar Generator
                  backgroundImage: NetworkImage(avatarUrl),
                  onBackgroundImageError: (_, __) {},
                  child:
                      null, // Child dikosongkan karena sudah ada backgroundImage
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name ?? "Tanpa Nama",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D2D2D)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(isSharing ? Icons.location_on : Icons.location_off,
                            size: 12,
                            color: isSharing ? Colors.green : Colors.grey),
                        const SizedBox(width: 4),
                        Text(isSharing ? "Sedang aktif" : "Lokasi dimatikan",
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    isSharing ? Colors.black54 : Colors.grey)),
                      ],
                    )
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.battery_std,
                      size: 14, color: Color(0xFFFF6F4D)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.directions_walk,
                          size: 14, color: Color(0xFFFF6F4D)),
                      const SizedBox(width: 2),
                      Text(distance,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF888888))),
                    ],
                  )
                ],
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  // 5. Grid Menu Cepat
  Widget _buildQuickMenuGrid(BuildContext context, HomeViewModel viewModel) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildMenuButton(context, Icons.group_add_outlined, "Buat Grup", () {}),
        _buildMenuButton(context, Icons.map_outlined, "Lihat Peta", () {}),
        _buildMenuButton(
            context, Icons.notifications_none, "Notifikasi", () {}),
        _buildMenuButton(context, Icons.settings_outlined, "Pengaturan", () {}),
      ],
    );
  }

  Widget _buildMenuButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2))
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _primaryOrange, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: _textDark)),
          ],
        ),
      ),
    );
  }

  // Helper Judul Bagian
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _primaryOrange,
      ),
    );
  }

  // --- Helper untuk Generate URL Avatar ---
  String _getAvatarUrl(String? name) {
    String safeName = name != null && name.isNotEmpty ? name : "User";
    // Encode nama biar aman (misal spasi jadi %20)
    // background=random: warna acak
    // color=fff: teks warna putih
    return "https://ui-avatars.com/api/?name=${Uri.encodeComponent(safeName)}&background=random&color=fff&size=128";
  }
}
