import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pastikan package intl ada di pubspec.yaml
import 'package:provider/provider.dart';
import 'package:searah_backend/services/api_services.dart';
import 'package:searah_backend/viewmodel/home_viewmodel.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  // Warna tema (sesuaikan dengan app Anda)
  final Color _kPrimaryColor = const Color(0xFFFA8B60);

  @override
  void initState() {
    super.initState();
    // Ambil data saat halaman pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNotifications();
    });
  }

  Future<void> _fetchNotifications() async {
    final vm = context.read<HomeViewModel>();
    
    // Cek token
    if (vm.authToken == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await ApiService.getNotifications(vm.authToken!);
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetch notif: $e");
      setState(() => _isLoading = false);
    }
  }

  // Helper untuk format tanggal (Misal: "24 Nov, 14:30")
  String _formatDate(String? dateString) {
    if (dateString == null) return "";
    try {
      final DateTime date = DateTime.parse(dateString).toLocal(); // Konversi ke waktu lokal
      return DateFormat('d MMM, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background putih bersih
      appBar: AppBar(
        title: const Text(
          "Notifikasi",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // Flat design
        iconTheme: const IconThemeData(color: Colors.black), // Tombol back hitam
      ),
      body: RefreshIndicator(
        color: _kPrimaryColor,
        onRefresh: _fetchNotifications, // Tarik ke bawah untuk refresh
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _kPrimaryColor))
            : _notifications.isEmpty
                ? _buildEmptyState()
                : _buildNotificationList(),
      ),
    );
  }

  // Widget Tampilan Kosong
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Belum ada notifikasi",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Widget List Notifikasi
  Widget _buildNotificationList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        final bool isRead = (notif['is_read'] ?? 0) == 1;

        return Container(
          // Opsional: Beri background tipis jika belum dibaca
          decoration: BoxDecoration(
            color: isRead ? Colors.white : _kPrimaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: _kPrimaryColor.withOpacity(0.2),
              child: Icon(
                _getIconByType(notif['type']),
                color: _kPrimaryColor,
                size: 24,
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    notif['title'] ?? 'Info',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatDate(notif['created_at']),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                notif['body'] ?? '',
                style: TextStyle(
                  color: isRead ? Colors.grey[600] : Colors.black87,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            onTap: () {
              // TODO: Bisa tambahkan aksi, misal tandai sudah dibaca
              // atau navigasi ke halaman detail event/teman
            },
          ),
        );
      },
    );
  }

  // Helper Icon berdasarkan tipe notifikasi
  IconData _getIconByType(String? type) {
    if (type == 'friend_request') return Icons.person_add;
    if (type == 'new_event') return Icons.event;
    if (type == 'event_join') return Icons.group_add;
    return Icons.notifications; // Default icon
  }
}