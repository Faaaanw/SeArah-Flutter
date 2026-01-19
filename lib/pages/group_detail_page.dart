import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:searah_backend/viewmodel/home_viewmodel.dart';
// Sesuaikan import model Anda

// --- Theme Constants ---
const Color _kPrimaryOrange = Color(0xFFFF6F4D);
const Color _kTextDark = Color(0xFF2D2D2D);

class GroupDetailPage extends StatefulWidget {
  final int groupId;
  final String groupName;

  const GroupDetailPage(
      {super.key, required this.groupId, required this.groupName});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  bool _isLoading = true;
  List<dynamic> _members = [];
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  Future<void> _fetchGroupDetails() async {
    final viewModel = Provider.of<HomeViewModel>(context, listen: false);
    try {
      // Mengambil detail member + status creator
      // Pastikan viewmodel.fetchFriendsByGroup mengisi data _members & status creator
      await viewModel.fetchFriendsByGroup(widget.groupId);

      if (mounted) {
        setState(() {
          _members = viewModel.friends;
          // TODO: Ganti logic ini dengan data real dari API (misal group.creatorId)
          _isCreator = true; 
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _kPrimaryOrange))
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGroupInfoCard(),
                        const SizedBox(height: 32),
                        _buildMembersHeader(context, viewModel),
                        const SizedBox(height: 16),
                        _buildMembersList(),
                        const SizedBox(height: 40),
                        _buildActionButtons(context, viewModel),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // --- Widget Builders ---

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text("Info Grup",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        if (_isCreator)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: "Hapus Grup",
            onPressed: () => _confirmDeleteGroup(
                context, Provider.of<HomeViewModel>(context, listen: false)),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade100, height: 1),
      ),
    );
  }

  Widget _buildGroupInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0EB), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFF0EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
              ],
            ),
            child: const Icon(Icons.groups_rounded,
                size: 42, color: _kPrimaryOrange),
          ),
          const SizedBox(height: 16),
          Text(
            widget.groupName,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: _kTextDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(_isCreator ? "Admin: Kamu" : "Anggota",
                    style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersHeader(BuildContext context, HomeViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.people_outline, color: _kPrimaryOrange),
            const SizedBox(width: 8),
            Text(
              "Anggota (${_members.length})",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: _kTextDark),
            ),
          ],
        ),
        if (_isCreator)
          TextButton.icon(
            onPressed: () => _showAddMemberDialog(context, vm),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFFF0EB),
              foregroundColor: _kPrimaryOrange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: const Text("Undang",
                style: TextStyle(fontWeight: FontWeight.bold)),
          )
      ],
    );
  }

  Widget _buildMembersList() {
    if (_members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("Belum ada anggota lain.",
              style: TextStyle(color: Colors.grey.shade500)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final member = _members[index];
        final isSharing = member.isSharingLocation;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.03),
                  blurRadius: 5,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: NetworkImage(
                    "https://ui-avatars.com/api/?name=${member.name}&background=random"),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name ?? "User",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: _kTextDark)),
                    const SizedBox(height: 2),
                   
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSharing
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSharing ? Icons.location_on : Icons.location_off_outlined,
                  color: isSharing ? Colors.green : Colors.grey,
                  size: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, HomeViewModel vm) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLeaveGroup(context, vm),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red.shade200),
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.exit_to_app_rounded),
        label: const Text("Keluar dari Grup",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- Logic & Dialogs ---

  // 🔥 UPDATE: Menggunakan Dialog Selection List (Bukan Input Email Manual)
  void _showAddMemberDialog(BuildContext context, HomeViewModel vm) async {
    // Tampilkan dialog custom yang mengambil data candidates
    final bool? result = await showDialog(
      context: context,
      builder: (context) => _MemberSelectionDialog(
        groupId: widget.groupId,
        viewModel: vm,
      ),
    );

    // Jika result true (berhasil add), refresh halaman
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Anggota berhasil ditambahkan"),
          backgroundColor: Colors.green,
        ),
      );
      _fetchGroupDetails(); // Refresh list anggota
    }
  }

  void _confirmLeaveGroup(BuildContext context, HomeViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Keluar Grup?"),
        content: const Text(
            "Anda tidak akan bisa melihat lokasi teman di grup ini lagi."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Implementasi API Leave Group (Sesuaikan jika method ada)
              // await vm.leaveGroup(widget.groupId);
              Navigator.pop(context); // Kembali ke Dashboard
              vm.fetchGroups();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Berhasil keluar grup")));
            },
            child: const Text("Keluar",
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, HomeViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus Grup?"),
        content: const Text(
            "Grup ini akan dihapus permanen. Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Implementasi API Delete Group
              // await vm.deleteGroup(widget.groupId);
              Navigator.pop(context);
              vm.fetchGroups();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Grup dihapus")));
            },
            child: const Text("Hapus",
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

// =========================================================
// 🔥 WIDGET BARU: Dialog Pilih Teman (Candidates)
// =========================================================
class _MemberSelectionDialog extends StatefulWidget {
  final int groupId;
  final HomeViewModel viewModel;

  const _MemberSelectionDialog(
      {required this.groupId, required this.viewModel});

  @override
  State<_MemberSelectionDialog> createState() => _MemberSelectionDialogState();
}

class _MemberSelectionDialogState extends State<_MemberSelectionDialog> {
  bool _isLoading = true;
  List<dynamic> _candidates = [];

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
  }

  Future<void> _fetchCandidates() async {
    // Memanggil fungsi fetchCandidates di ViewModel
    final results = await widget.viewModel.fetchCandidates(widget.groupId);
    if (mounted) {
      setState(() {
        _candidates = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _addMember(int userId) async {
    setState(() => _isLoading = true);
    
    // Panggil fungsi add member di ViewModel
    final success = await widget.viewModel.addMemberToGroup(widget.groupId, userId);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true); // Tutup dialog & kirim sinyal sukses
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Gagal menambahkan anggota")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Undang Teman"),
      content: SizedBox(
        width: double.maxFinite,
        height: 300, // Batasi tinggi agar scrollable
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _candidates.isEmpty
                ? const Center(
                    child: Text(
                      "Semua teman sudah ada di grup \natau Anda belum memiliki teman.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _candidates.length,
                    itemBuilder: (context, index) {
                      final user = _candidates[index];
                      // Pastikan parsing data JSON sesuai (nama key dari Laravel)
                      final name = user['name'] ?? 'No Name';
                      final email = user['email'] ?? '-';
                      final userId = user['id'];

                      return ListTile(
                        leading: CircleAvatar(
                           backgroundColor: Colors.grey.shade200,
                           backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=$name&background=random"),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      
                        trailing: const Icon(Icons.add_circle_outline, color: _kPrimaryOrange),
                        onTap: () => _addMember(userId),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Tutup", style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}