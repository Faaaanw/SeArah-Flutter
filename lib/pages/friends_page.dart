import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodel/friend_viewmodel.dart';
import 'package:quickalert/quickalert.dart';

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

  // --- Palette Warna Modern ---
  static const Color primaryColor = Color(0xFFFA8B60); // Coral
  static const Color secondaryColor = Color(0xFF4DB6AC); // Soft Teal
  static const Color backgroundColor = Color(0xFFF9FAFB); // Very Light Grey
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF2D3142);
  static const Color textLight = Color(0xFF9CA3AF);

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
    FocusScope.of(context).unfocus();

    setState(() {
      isSearching = true;
      searchResults = [];
    });

    final viewModel = context.read<FriendViewModel>();
    final results = await viewModel.searchUserByName(name, token!);

    setState(() {
      searchResults = results ?? [];
      isSearching = false;
    });

    if (results == null || results.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: textDark,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Text('Pengguna tidak ditemukan.',
                style: TextStyle(fontFamily: fontName)),
          ),
        );
      }
    }
  }

  // --- WIDGETS ---

  Widget _buildCustomHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button

          const Text(
            'Friend Zone',
            style: TextStyle(
              fontFamily: fontName,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textDark,
              letterSpacing: 0.5,
            ),
          ),

          // Refresh Button
          _buildCircleButton(
            icon: Icons.refresh_rounded,
            onTap: _initData,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: textDark, size: 20),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 55,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicatorPadding: const EdgeInsets.all(6),
        indicator: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: textLight,
        labelStyle: const TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: "Teman"),
          Tab(text: "Cari"),
          Tab(text: "Request"),
        ],
      ),
    );
  }

  Widget _buildFriendListItem(Map<String, dynamic> item,
      {required bool isPending, required bool isSearch}) {
    final viewModel = context.watch<FriendViewModel>();

    final name = item['name'] ?? item['from_name'] ?? 'Tanpa Nama';
  

    // Pastikan ID diambil dengan aman
    final int targetUserId = isPending
        ? (item['from_id'] ?? item['user_id'] ?? 0)
        : (item['id'] ?? 0);

    final int? itemId = item['id'];

    bool isDisabled = false;
    bool showActionButton = false;
    String actionLabel = "";
    IconData actionIcon = Icons.check;
    Color buttonColor = primaryColor;
    VoidCallback? onActionTap;

    // --- LOGIKA UTAMA (UPDATED) ---
    if (isPending) {
      // ... (Logika Permintaan Masuk TETAP SAMA) ...
      showActionButton = true;
      actionLabel = "Terima";
      actionIcon = Icons.check_circle_outline;
      buttonColor = secondaryColor;
      onActionTap = () async {
        if (token == null || itemId == null) return;
        await _handleAcceptFriend(viewModel, itemId!);
      };
    } else if (isSearch && targetUserId != userId) {
      showActionButton = true;

      // Ambil status langsung dari hasil search (dari backend)
      // null jika tidak ada hubungan
      String? serverStatus = item['friendship_status'];
      bool amISender = item['is_sender'] == true;

      // Cek A: Apakah sudah berteman? (Baik dari Local ViewModel atau Server Status)
      if (viewModel.isAlreadyFriend(targetUserId) ||
          serverStatus == 'accepted') {
        actionLabel = "Berteman";
        actionIcon = Icons.people_alt;
        buttonColor = Colors.grey.shade400;
        isDisabled = true;
      }
      // 🔥 Cek B (DIPERBAIKI): Apakah statusnya Pending & Kita yang kirim?
      // Kita cek dari 2 sumber:
      // 1. Local (viewModel.isRequestSent) -> biar responsif pas baru klik add
      // 2. Server (serverStatus == 'pending' && amISender) -> biar persisten pas search ulang
      else if (viewModel.isRequestSent(targetUserId) ||
          (serverStatus == 'pending' && amISender)) {
        actionLabel = "Menunggu";
        actionIcon = Icons.hourglass_top_rounded;
        buttonColor = const Color(0xFFFFB74D); // Orange
        isDisabled = true;
      }
      // Cek C: Apakah dia yang add kita? (Incoming Request dari Search Result)
      else if (serverStatus == 'pending' && !amISender) {
        // Kalau status pending tapi BUKAN kita pengirimnya, berarti dia yg add
        // Kita kasih tombol Terima
        // Note: Kita butuh friendship ID untuk terima, untungnya API search biasanya return User ID.
        // Untuk amannya, tombol ini bisa kita arahkan user cek tab "Request" atau panggil API accept by UserID (kalau ada).

        // Opsi simpel: Tampilkan status "Permintaan Masuk"
        actionLabel = "Cek Request";
        actionIcon = Icons.mark_email_unread_outlined;
        buttonColor = secondaryColor;
        onActionTap = () {
          // Pindah ke tab request (index 2)
          DefaultTabController.of(context).animateTo(2);
        };
      }
      // Cek D: Incoming Request (Logika lama via Local ViewModel)
      else {
        int? incomingFriendshipId =
            viewModel.getIncomingRequestFriendshipId(targetUserId);

        if (incomingFriendshipId != null) {
          actionLabel = "Terima";
          actionIcon = Icons.check_circle;
          buttonColor = secondaryColor;
          onActionTap = () async {
            if (token == null) return;
            await _handleAcceptFriend(viewModel, incomingFriendshipId);
          };
        } else {
          // Kasus Tambah Teman Baru (Add)
          actionLabel = "Tambah";
          actionIcon = Icons.person_add_outlined;
          buttonColor = primaryColor;
          onActionTap = () async {
            if (token == null || userId == null) return;
            await _handleAddFriend(viewModel, targetUserId);
          };
        }
      }
    }

    // --- RENDER UI (SAMA SEPERTI SEBELUMNYA) ---
    return Container(
      // ... (Code container UI sama persis, tidak perlu diubah)
      // Copy-paste sisa return Container dari kode sebelumnya di sini
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0E0E0).withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDisabled ? Colors.grey : buttonColor)
                        .withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      (isDisabled ? Colors.grey : buttonColor).withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontFamily: fontName,
                      fontWeight: FontWeight.bold,
                      color: isDisabled ? Colors.grey : buttonColor,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Text Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: fontName,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

              // Action Button
              if (showActionButton)
                InkWell(
                  onTap: isDisabled ? null : onActionTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? Colors.grey
                              .withOpacity(0.1) // Background abu jika disabled
                          : buttonColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: isDisabled
                          ? Border.all(color: Colors.grey.shade300)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          actionIcon,
                          size: 18,
                          color: isDisabled ? Colors.grey : buttonColor,
                        ),
                        if (actionLabel.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            actionLabel,
                            style: TextStyle(
                              fontFamily: fontName,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDisabled ? Colors.grey : buttonColor,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAcceptFriend(FriendViewModel vm, int friendshipId) async {
    final msg =
        await vm.acceptFriend(friendshipId: friendshipId, token: token!);
    if (mounted) _showSuccessAlert(msg ?? "Permintaan diterima");
    // Refresh UI search result agar tombol berubah jadi "Berteman"
    setState(() {});
  }

  Future<void> _handleAddFriend(FriendViewModel vm, int targetId) async {
    final msg =
        await vm.addFriend(userId: userId!, friendId: targetId, token: token!);
    if (mounted) _showSuccessAlert(msg ?? "Permintaan dikirim");
    // Clear search atau update UI sesuai kebutuhan
    setState(() {
      friendIdController.clear();
      searchResults = [];
    });
  }

  void _showSuccessAlert(String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: 'Sukses',
      text: message,
      confirmBtnColor: primaryColor,
    );
  }

  // --- TAB CONTENTS ---

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: primaryColor.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontFamily: fontName,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(FriendViewModel viewModel) {
    if (viewModel.friends.isEmpty) {
      return _buildEmptyState(
          "Sepi banget...",
          "Kamu belum punya teman.\nAyo cari teman barumu sekarang!",
          Icons.group_off_rounded);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: viewModel.friends.length,
      itemBuilder: (context, index) {
        return _buildFriendListItem(viewModel.friends[index],
            isPending: false, isSearch: false);
      },
    );
  }

  Widget _buildAddFriendTab() {
    return Column(
      children: [
        // Modern Search Bar
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: friendIdController,
              style: const TextStyle(fontFamily: fontName, color: textDark),
              decoration: InputDecoration(
                hintText: "Ketik nama teman...",
                hintStyle:
                    const TextStyle(fontFamily: fontName, color: textLight),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: primaryColor),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () =>
                        _searchByName(context, friendIdController.text.trim()),
                  ),
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onSubmitted: (value) => _searchByName(context, value.trim()),
            ),
          ),
        ),

        // Search Results
        Expanded(
          child: isSearching
              ? const Center(
                  child: CircularProgressIndicator(color: primaryColor))
              : searchResults.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        // Prevent overflow on small screens
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (friendIdController.text.isNotEmpty)
                              _buildEmptyState(
                                  "Tidak Ditemukan",
                                  "Coba cari dengan nama lain.",
                                  Icons.search_off_rounded)
                            else
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                child: Image.network(
                                  'https://cdn-icons-png.flaticon.com/512/7486/7486747.png', // Illustrasi simple
                                  height: 150,
                                  color: Colors.grey.shade200,
                                  colorBlendMode: BlendMode.srcATop,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        return _buildFriendListItem(searchResults[index],
                            isPending: false, isSearch: true);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    if (pendingRequests.isEmpty) {
      return _buildEmptyState(
          "Tidak ada permintaan",
          "Belum ada yang ingin berteman\ndenganmu saat ini.",
          Icons.mark_email_read_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: pendingRequests.length,
      itemBuilder: (context, index) {
        return _buildFriendListItem(pendingRequests[index],
            isPending: true, isSearch: false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendViewModel>(
      builder: (context, viewModel, _) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: backgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  _buildCustomHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildFriendsTab(viewModel),
                        _buildAddFriendTab(),
                        _buildRequestsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
