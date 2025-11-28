import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_services.dart';
import '../viewmodel/home_viewmodel.dart';
import '../models/group_model.dart';

// --- Theme Constants ---
const Color _kPrimaryOrange = Color(0xFFFF6F4D);
const Color _kLightOrangeBg = Color(0xFFFFF0EB);
const Color _kTextDark = Color(0xFF2D2D2D);

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Set untuk menyimpan ID teman yang dipilih
  final Set<int> _selectedFriends = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Ambil data teman saat halaman dibuka
    Future.microtask(() {
      context.read<HomeViewModel>().fetchFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final friendList = vm.allFriends;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Buat Grup Baru", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Icon Visual
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: _kLightOrangeBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.group_add_rounded, size: 48, color: _kPrimaryOrange),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Input Nama Grup
                    _buildLabel("Nama Grup"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => v!.isEmpty ? 'Nama grup wajib diisi' : null,
                      decoration: _inputDecoration("Contoh: Keluarga Cemara", Icons.title),
                    ),
                    
                    const SizedBox(height: 20),

                    // Input Deskripsi
                    _buildLabel("Deskripsi (Opsional)"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: _inputDecoration("Deskripsi singkat tentang grup ini...", Icons.description_outlined),
                    ),

                    const SizedBox(height: 30),

                    // Header List Teman
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel("Undang Teman"),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kPrimaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20)
                          ),
                          child: Text(
                            "${_selectedFriends.length} Dipilih",
                            style: const TextStyle(color: _kPrimaryOrange, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    // List Teman Selection
                    vm.isLoadingFriends
                        ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _kPrimaryOrange)))
                        : friendList.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: friendList.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final friend = friendList[index];
                                  final isSelected = _selectedFriends.contains(friend.id);

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedFriends.remove(friend.id);
                                        } else {
                                          _selectedFriends.add(friend.id!);
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? _kLightOrangeBg : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? _kPrimaryOrange : Colors.grey.shade200,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.white,
                                            backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=${friend.name}&background=random"),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(friend.name ?? "User", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                                Text(friend.email ?? "-", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(Icons.check_circle, color: _kPrimaryOrange)
                                          else
                                            Icon(Icons.circle_outlined, color: Colors.grey.shade400)
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                     // Padding bawah agar tidak tertutup tombol
                     const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          
          // Tombol Submit di Bawah
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          await _createGroup(vm);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Buat Grup Sekarang", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kTextDark));
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimaryOrange, width: 1.5)),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.person_off_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text("Belum ada teman", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- Logic ---

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createGroup(HomeViewModel vm) async {
    if (vm.authToken == null) return;

    setState(() => _isSubmitting = true);

    try {
      final Group newGroup = await ApiService.createGroup(
        token: vm.authToken!,
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        memberIds: _selectedFriends.toList(),
      );

      vm.addGroup(newGroup);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Grup berhasil dibuat!'), backgroundColor: Colors.green)
        );
        Navigator.pop(context); // Kembali ke dashboard
      }
    } catch (e) {
      String errorMessage = e.toString().contains('Exception:')
          ? e.toString().substring(e.toString().indexOf(':') + 1).trim()
          : 'Terjadi kesalahan: $e';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $errorMessage'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}