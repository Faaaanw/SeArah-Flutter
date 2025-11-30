import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:latlong2/latlong.dart';

// Import Halaman Detail Group
import 'package:searah_backend/pages/group_detail_page.dart';
import 'package:searah_backend/pages/notification_page.dart';

// Import ViewModel & Models
import 'package:searah_backend/viewmodel/home_viewmodel.dart';
import '../models/friend_model.dart';
import '../models/event_model.dart';

// --- Theme Constants ---
const Color _primaryOrange = Color(0xFFFF6F4D);
const Color _lightOrangeBg = Color(0xFFFFF0EB);
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

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            // ✅ FITUR 1: REFRESH INDICATOR
            child: RefreshIndicator(
              color: _primaryOrange,
              backgroundColor: Colors.white,
              onRefresh: () async {
                // 1. Tangkap ID grup yang sedang aktif
                final savedGroupId = viewModel.currentGroupId;

                // 2. Refresh data dari server
                await viewModel.loadInitialData();

                // 3. Apply ulang filter grup agar teman yang muncul sesuai grup
                // Beri sedikit delay agar transisi UI lebih halus (opsional)
                if (savedGroupId != null) {
                  await viewModel.setCurrentGroup(savedGroupId);
                }
              },
              child: SingleChildScrollView(
                // ✅ FITUR 2: PHYSICS AGAR BISA SCROLL MESKI KONTEN SEDIKIT
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: _defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // 1. HEADER: Search Bar + Group Selector
                    _buildSearchHeader(context, viewModel),

                    // Indikator Loading Tipis (Non-blocking)
                    if (viewModel.isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: LinearProgressIndicator(
                          color: _primaryOrange,
                          backgroundColor: _primaryOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // 2. HIGHLIGHT EVENT
                    _buildSectionTitle("Recent Event"),
                    const SizedBox(height: 24),

                    // Logic Tampilan Event
                    if (viewModel.isLoading && upcomingEvent == null)
                      _buildLoadingCard()
                    else if (upcomingEvent != null)
                      _buildEventHighlightCard(
                          context, upcomingEvent, viewModel)
                    else
                      _buildEmptyEventCard(),

                    const SizedBox(height: 24),

                    // 3. STATUS LOKASI
                    _buildLocationToggle(viewModel),

                    const SizedBox(height: 24),

                    // 4. DAFTAR TEMAN
                    _buildSectionTitle("Your Friend's"),
                    const SizedBox(height: 12),
                    _buildFriendsList(viewModel),

                    const SizedBox(height: 24),

                    // 5. GRID MENU
                    _buildSectionTitle("Menu Cepat"),
                    const SizedBox(height: 12),
                    _buildQuickMenuGrid(context, viewModel),

                    // Spacer bawah agar scroll nyaman
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSearchHeader(BuildContext context, HomeViewModel viewModel) {
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              viewModel.currentGroupId != null && viewModel.groups.isNotEmpty
                  ? "Grup: ${viewModel.groups.firstWhere((g) => g.id == viewModel.currentGroupId, orElse: () => viewModel.groups.first).name}"
                  : "Search Location",
              style: TextStyle(
                color: _textGrey.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () => _showGroupModal(context, viewModel),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: _primaryOrange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group, color: Colors.white, size: 20),
            ),
          )
        ],
      ),
    );
  }

  // ✅ FITUR 3: MODAL DENGAN NAVIGASI KE DETAIL GROUP DIKEMBALIKAN
  void _showGroupModal(BuildContext context, HomeViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (_) {
        final groups = vm.groups;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Pilih Grup",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textDark)),
              const SizedBox(height: 10),

              // Opsi Semua Teman
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: _lightOrangeBg,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.public, color: _primaryOrange),
                ),
                title: const Text('Semua Teman',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: vm.currentGroupId == null
                    ? const Icon(Icons.check, color: _primaryOrange)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  vm.setCurrentGroup(null);
                },
              ),

              const Divider(),

              if (groups.isEmpty)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: Text('Belum ada grup.',
                            style: TextStyle(color: _textGrey))))
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final isSelected = vm.currentGroupId == group.id;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: isSelected
                                  ? _primaryOrange.withOpacity(0.1)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.group,
                              color: isSelected ? _primaryOrange : Colors.grey),
                        ),
                        title: Text(group.name,
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    isSelected ? _primaryOrange : _textDark)),

                        // ✅ BAGIAN INI DIKEMBALIKAN: Tombol Info Navigasi
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Icon(Icons.check, color: _primaryOrange),

                            // Tombol Info (i) untuk ke Detail Page
                            IconButton(
                              icon: Icon(Icons.info_outline,
                                  color: Colors.grey.shade400),
                              onPressed: () {
                                // 1. Tutup Modal
                                Navigator.pop(context);

                                // 2. Navigasi ke Halaman Detail
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupDetailPage(
                                      groupId: group.id!,
                                      groupName: group.name,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        // Klik body ListTile untuk memilih grup
                        onTap: () async {
                          Navigator.pop(context);
                          await vm.setCurrentGroup(group.id);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      height: 150,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: _primaryOrange),
      ),
    );
  }

  Widget _buildEventHighlightCard(
      BuildContext context, Event event, HomeViewModel viewModel) {
    bool isJoined = event.participants.contains(viewModel.currentUserId);
    String distanceText = viewModel.getDistanceToEvent(event);
    List<Friend> participants = viewModel.getEventParticipantsData(event);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryOrange,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
              color: _primaryOrange.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
        image: const DecorationImage(
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
                  child: Text(event.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.near_me, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(distanceText,
                      style: const TextStyle(color: Colors.white, fontSize: 12))
                ]),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (participants.isNotEmpty)
                SizedBox(
                    height: 30,
                    width: (participants.length * 20.0 + 20).clamp(0, 120),
                    child: Stack(
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
                                  backgroundImage: NetworkImage(
                                      _getAvatarUrl(member.name)))));
                    })))
              else
                const Text("Belum ada peserta",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
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
                        borderRadius: BorderRadius.circular(20))),
                child: Text(isJoined ? "Batal" : "Gabung"),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyEventCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: _lightOrangeBg,
          borderRadius: BorderRadius.circular(_cardRadius)),
      child: Column(children: [
        const Icon(Icons.event_busy, size: 40, color: _primaryOrange),
        const SizedBox(height: 10),
        const Text("Belum ada acara",
            style: TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
        const Text("Buat jadwal kumpul dengan temanmu!",
            style: TextStyle(color: _textGrey, fontSize: 12))
      ]),
    );
  }

  Widget _buildLocationToggle(HomeViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
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
                  size: 20)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Berbagi Lokasi",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
            Text(viewModel.isUserSharingLocation ? "Aktif" : "Nonaktif",
                style: TextStyle(
                    fontSize: 12,
                    color: viewModel.isUserSharingLocation
                        ? Colors.green
                        : Colors.red))
          ]),
        ]),
        Switch(
            value: viewModel.isUserSharingLocation,
            onChanged: viewModel.toggleLocationSharing,
            activeColor: _primaryOrange,
            activeTrackColor: _primaryOrange.withOpacity(0.2))
      ]),
    );
  }

  Widget _buildFriendsList(HomeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: _primaryOrange)));
    }

    final currentUserId = viewModel.currentUserId;
    final filteredFriends =
        viewModel.friends.where((f) => f.id != currentUserId).take(10).toList();

    if (filteredFriends.isEmpty) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("Tidak ada teman yang aktif.",
                style: TextStyle(color: _textGrey)),
            if (viewModel.currentGroupId != null)
              TextButton(
                  onPressed: () => viewModel.setCurrentGroup(null),
                  child: const Text("Lihat Semua Teman",
                      style: TextStyle(color: _primaryOrange)))
          ],
        ),
      ));
    }

    return Column(
      children: filteredFriends.map((friend) {
        String distance = viewModel.getDistanceToFriend(friend);
        bool isSharing = friend.isSharingLocation;
        final avatarUrl = _getAvatarUrl(friend.name);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF0EB),
              borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                    radius: 22, backgroundImage: NetworkImage(avatarUrl))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(friend.name ?? "Tanpa Nama",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D2D2D))),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(isSharing ? Icons.location_on : Icons.location_off,
                        size: 12,
                        color: isSharing ? Colors.green : Colors.grey),
                    const SizedBox(width: 4),
                    Text(isSharing ? "Sedang aktif" : "Lokasi dimatikan",
                        style: TextStyle(
                            fontSize: 12,
                            color: isSharing ? Colors.black54 : Colors.grey))
                  ])
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Icon(Icons.battery_std, size: 14, color: Color(0xFFFF6F4D)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.directions_walk,
                    size: 14, color: Color(0xFFFF6F4D)),
                const SizedBox(width: 2),
                Text(distance,
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF888888)))
              ])
            ])
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildQuickMenuGrid(BuildContext context, HomeViewModel viewModel) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildMenuButton(context, Icons.group_add_outlined, "Buat Grup", () {
          _showGroupModal(context, viewModel);
        }),
       _buildMenuButton(
        context, 
        Icons.notifications_none, 
        "Notifikasi", 
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationPage(),
            ),
          );
        }
      ),
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
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: _primaryOrange, size: 28),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: _textDark))
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: _primaryOrange));
  }

  String _getAvatarUrl(String? name) {
    String safeName = name != null && name.isNotEmpty ? name : "User";
    return "https://ui-avatars.com/api/?name=${Uri.encodeComponent(safeName)}&background=random&color=fff&size=128";
  }
}
