import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodel/friend_viewmodel.dart'; // Pastikan path ini benar

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  String? token;
  int? userId;
  final friendIdController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> pendingRequests = [];
  bool isSearching = false;
  // showPending: false for Daftar Teman, true for Permintaan Masuk
  bool showPending = false;

  // Warna tema
  static const Color primaryColor = Color(0xFFFA8B60); // Orange-Red/Coral
  static const Color secondaryColor =
      Colors.teal; // Teal/Green for actions/requests
  static const Color backgroundColor = Color(0xFFF7F7F7); // Light background
  static const Color cardColor = Colors.white;

  // Nama font Poppins
  static const String fontName = 'Poppins';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    friendIdController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
    userId = prefs.getInt('user_id');

    if (token != null && mounted) {
      final vm = Provider.of<FriendViewModel>(context, listen: false);
      await vm.loadFriends(token!);
      pendingRequests = await vm.loadPendingRequests(token!) ?? [];
      setState(() {});
    }
  }

  Future<void> _searchByName(BuildContext context, String name) async {
    if (name.isEmpty || token == null) return;
    FocusScope.of(context).unfocus(); // Close keyboard

    setState(() {
      isSearching = true;
      searchResults = []; // Clear previous search results
    });

    final viewModel = context.read<FriendViewModel>();
    final results = await viewModel.searchUserByName(name, token!);

    setState(() {
      searchResults = results ?? [];
      isSearching = false;
    });

    if (results == null || results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pengguna tidak ditemukan.',
                style: TextStyle(fontFamily: fontName))),
      );
    }
  }

  Widget _buildCustomHeader(BuildContext context, FriendViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(
          top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Back (gunakan ikon panah dari referensi foto 1)
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 5,
                    offset: const Offset(0, 2)),
              ],
            ),
            
          ),

          const Text(
            'Your Friends',
            style: TextStyle(
              fontFamily: fontName, // Poppins
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color:primaryColor,
            ),
          ),

          // Tombol Refresh
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 5,
                    offset: const Offset(0, 2)),
              ],
            ),
           
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildSegmentButton(
                title: "Daftar Teman",
                isSelected: !showPending,
                onPressed: () => setState(() {
                  showPending = false;
                  searchResults =
                      []; // Clear search results when switching back
                }),
                activeColor: primaryColor,
              ),
            ),
            Expanded(
              child: _buildSegmentButton(
                title: "Permintaan Masuk",
                isSelected: showPending,
                onPressed: () => setState(() => showPending = true),
                activeColor: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onPressed,
    required Color activeColor,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: fontName, // Poppins
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // Widget untuk menampilkan list item teman atau permintaan dengan visual yang ditingkatkan
  Widget _buildFriendListItem(Map<String, dynamic> item,
      {required bool isPending}) {
    final viewModel = context.read<FriendViewModel>();
    final name = item['name'] ?? item['from_name'] ?? 'Tanpa Nama';
    final email = item['email'] ?? item['from_email'] ?? '-';
    final id = item['id'];

    // Gradasi warna untuk card, berdasarkan mode
    final Color cardStartColor = isPending
        ? secondaryColor.withOpacity(0.1)
        : primaryColor.withOpacity(0.1);
    final Color cardEndColor = isPending
        ? secondaryColor.withOpacity(0.0)
        : primaryColor.withOpacity(0.0);

    // Warna aksen untuk avatar dan tombol
    final Color accentColor = isPending ? secondaryColor : primaryColor;

    // Cek apakah ini hasil pencarian yang belum berteman (untuk tombol Tambah)
    final bool isSearchResultAndNotFriend =
        searchResults.contains(item) && item['id'] != userId;

    // Cek apakah ini tombol yang harus ditampilkan
    final bool showActionButton = isPending || isSearchResultAndNotFriend;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          gradient: LinearGradient(
            colors: [cardStartColor, cardEndColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withOpacity(0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: accentColor,
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(
                fontFamily: fontName, // Poppins
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87),
          ),
          subtitle: Text(
            email,
            style: TextStyle(
                fontFamily: fontName,
                color: Colors.grey.shade600,
                fontSize: 12),
          ),
          trailing: showActionButton
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(90, 40),
                  ),
                  onPressed: () async {
                    if (token == null || id == null) return;

                    String? message;
                    if (isPending) {
                      // Terima Permintaan
                      message = await viewModel.acceptFriend(
                        friendshipId: id,
                        token: token!,
                      );
                      _initData(); // Reload data after accepting
                    } else if (isSearchResultAndNotFriend) {
                      // Tambah Teman (dari hasil pencarian)
                      if (userId == null) return;
                      message = await viewModel.addFriend(
                        userId: userId!,
                        friendId: id,
                        token: token!,
                      );
                      // Clear search results after sending request
                      setState(() {
                        searchResults = [];
                        friendIdController.clear();
                      });
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              message ??
                                  (isPending
                                      ? 'Permintaan diterima.'
                                      : 'Permintaan dikirim.'),
                              style: const TextStyle(
                                  fontFamily: fontName))), // Poppins
                    );
                  },
                  child: Text(isPending ? "Terima" : "Tambah",
                      style: const TextStyle(
                          fontFamily: fontName, // Poppins
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Custom Header (Non-AppBar)
                _buildCustomHeader(context, viewModel),

                // 2. Segmented Control (Daftar Teman / Permintaan Masuk)
                _buildSegmentedControl(),

                // 3. Search Section (Hanya tampil saat Daftar Teman aktif)
                if (!showPending)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: friendIdController,
                            style: const TextStyle(
                                fontFamily: fontName), // Poppins
                            decoration: InputDecoration(
                              hintText: "Cari ID atau Nama Teman",
                              hintStyle: TextStyle(
                                  fontFamily: fontName, // Poppins
                                  color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: primaryColor, width: 2),
                              ),
                              filled: true,
                              fillColor: cardColor,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (value) =>
                                _searchByName(context, value.trim()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Search Button
                        Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: () => _searchByName(
                              context,
                              friendIdController.text.trim(),
                            ),
                            tooltip: 'Cari',
                          ),
                        ),
                      ],
                    ),
                  ),

                if (isSearching)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                        child: CircularProgressIndicator(color: primaryColor)),
                  ),

                // 4. List View Section
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (isSearching)
                        return const SizedBox
                            .shrink(); // Hide list while searching

                      if (showPending) {
                        // ======= PERMINTAAN MASUK =======
                        if (pendingRequests.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                "🎉 Tidak ada permintaan masuk. Semua aman! 🛡️",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontFamily: fontName,
                                    color: Colors.grey), // Poppins
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: pendingRequests.length,
                          itemBuilder: (context, index) {
                            return _buildFriendListItem(pendingRequests[index],
                                isPending: true);
                          },
                        );
                      } else {
                        // ======= DAFTAR TEMAN / HASIL PENCARIAN =======
                        final isSearchActive = searchResults.isNotEmpty;
                        final listToDisplay =
                            isSearchActive ? searchResults : viewModel.friends;

                        if (listToDisplay.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                isSearchActive
                                    ? "zzz No result for '${friendIdController.text}'."
                                    : "You dont have any friends yet. Start adding some!",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: fontName,
                                    color: Colors.grey), // Poppins
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: listToDisplay.length,
                          itemBuilder: (context, index) {
                            return _buildFriendListItem(listToDisplay[index],
                                isPending: false);
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
