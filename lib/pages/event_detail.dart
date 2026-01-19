import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:searah_backend/models/event_model.dart';
import 'package:searah_backend/viewmodel/home_viewmodel.dart';

const Color _kPrimaryColor = Color(0xFFFA8B60); // Orange Coral
class EventDetailPage extends StatelessWidget {
  final Event event;

  const EventDetailPage({super.key, required this.event});
  

  // ----------------------------------------------------------------------
  // FUNGSI POPUP DAFTAR PESERTA
  // ----------------------------------------------------------------------
  void _showParticipantsModal(
      BuildContext context, HomeViewModel vm, Event currentEvent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final List<dynamic> participants = currentEvent.participants;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indikator Drag
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Judul
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Peserta Event (${participants.length})",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 20),

                  // List Peserta
                  Expanded(
                    child: participants.isEmpty
                        ? const Center(
                            child: Text(
                              "Belum ada peserta.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: controller,
                            itemCount: participants.length,
                            itemBuilder: (context, index) {
                              final member = participants[index];
                              final String name =
                                  member['name'] ?? 'Tanpa Nama';
                              final String email = member['email'] ?? '';
                              final int memberId = member['id'];

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFFA8B60),
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(name),
                                trailing: memberId == currentEvent.creatorId
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: const Text("Host",
                                            style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 12)))
                                    : null,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------------------------
  // FUNGSI HAPUS EVENT (KONFIRMASI)
  // ----------------------------------------------------------------------
  Future<void> _confirmDelete(
      BuildContext context, HomeViewModel vm, int eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Event"),
        content: const Text(
            "Apakah Anda yakin ingin menghapus event ini? Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          TextButton(
            child: const Text("Hapus",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await vm.deleteEvent(eventId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Event berhasil dihapus")),
          );
          Navigator.pop(context); // Kembali ke halaman sebelumnya
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Gagal menghapus: $e"),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMMM yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Consumer<HomeViewModel>(
      builder: (context, vm, child) {
        // Ambil data event terbaru dari state (jika ada update)
        // Gunakan orElse null agar aman jika event sudah terhapus
        final Event currentEvent = vm.events.firstWhere(
          (e) => e.id == event.id,
          orElse: () => event,
        );
        String? getPhotoUrl() {
          if (event?.photo == null || event!.photo!.isEmpty) return null;

          // Karena sekarang Backend sudah mengirim Full URL, langsung return saja
          return event!.photo;
        }

        final String creatorName = vm.getCreatorName(currentEvent.creatorId);

        // 🔥 CEK APAKAH USER ADALAH PEMBUAT EVENT
        // Pastikan Anda menambahkan getter `int? get currentUserId => _currentUserId;` di HomeViewModel
        final bool isCreator = vm.currentUserId == currentEvent.creatorId;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Detail Event",
                style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              // 🔥 TOMBOL HAPUS (HANYA MUNCUL JIKA CREATOR)
              if (isCreator)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Hapus Event',
                  onPressed: () =>
                      _confirmDelete(context, vm, currentEvent.id!),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Gambar Event
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                const SizedBox(height: 20),

                // 2. Judul & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        currentEvent.title,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (currentEvent.isJoined)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Text(
                          "Joined",
                          style: TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Info Bar (Creator & Participants)
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Dibuat oleh",
                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(creatorName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Spacer(),

                    // TOMBOL LIHAT PESERTA
                    InkWell(
                      onTap: () =>
                          _showParticipantsModal(context, vm, currentEvent),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.group,
                                size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              "${currentEvent.participantsCount} Peserta",
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                const Divider(height: 30),

                // 4. Waktu & Lokasi
                _detailRow(Icons.calendar_today, "Tanggal",
                    dateFormat.format(currentEvent.startTime)),
                const SizedBox(height: 12),
                _detailRow(Icons.access_time, "Waktu",
                    "${timeFormat.format(currentEvent.startTime)} - ${timeFormat.format(currentEvent.endTime)} WIB"),
                const SizedBox(height: 12),
                _detailRow(Icons.location_on, "Lokasi",
                    currentEvent.locationName ?? "Lokasi ditentukan di peta"),

                const Divider(height: 30),

                // 5. Deskripsi
                const Text("Deskripsi",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  currentEvent.description ?? "Tidak ada deskripsi.",
                  style: const TextStyle(color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // 6. Tombol Aksi (Join/Leave)
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, -5))
              ],
            ),
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: vm.isUserSharingLocation
                    ? () {
                        if (currentEvent.isJoined) {
                          vm.leaveEvent(currentEvent.id!);
                        } else {
                          vm.joinEvent(currentEvent.id!);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentEvent.isJoined
                      ? Colors.redAccent
                      : const Color(0xFFFA8B60),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: vm.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        currentEvent.isJoined
                            ? "Batalkan Keikutsertaan (Leave)"
                            : "Ikuti Event Ini (Join)",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget Row Detail (Anti Overflow)
  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
