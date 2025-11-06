// File: lib/pages/create_group_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_services.dart';
import '../viewmodel/home_viewmodel.dart';

const Color _kPrimaryButtonColor = Color(0xFFFA8B60);
const Color _kPeachIconColor = Color(0xFFBFA4A0);

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final List<int> _selectedFriends = [];
  bool _isSubmitting = false;
  @override
  void initState() {
    super.initState();

    // 🔥 Ambil daftar teman saat halaman ini dibuka
    Future.microtask(() {
      final vm = context.read<HomeViewModel>();
      vm.fetchFriends();
      Future.microtask(() async {
        final vm = context.read<HomeViewModel>();
        print("Auth token: ${vm.authToken}");
        await vm.fetchFriends();
        print("Friends loaded: ${vm.friends.length}");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Grup"),
        backgroundColor: _kPrimaryButtonColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Nama Grup",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _nameController,
                validator: (v) => v!.isEmpty ? 'Nama grup wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              const Text("Deskripsi (opsional)",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(controller: _descController),
              const SizedBox(height: 24),
              const Text("Undang Teman",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: vm.isLoadingFriends
                    ? const Center(child: CircularProgressIndicator())
                    : vm.friends.isEmpty
                        ? const Center(
                            child: Text("Belum ada teman untuk diundang"))
                        : ListView.builder(
                            itemCount: vm.friends.length,
                            itemBuilder: (context, index) {
                              final friend = vm.friends[index];
                              final selected =
                                  _selectedFriends.contains(friend.id);
                              return CheckboxListTile(
                                value: selected,
                                title: Text(friend.name),
                                subtitle: Text(friend.email),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedFriends.add(friend.id);
                                    } else {
                                      _selectedFriends.remove(friend.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.group_add_outlined),
                  label: const Text("Buat Grup dan Undang"),
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            await _createGroup(vm);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryButtonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createGroup(HomeViewModel vm) async {
    if (vm.authToken == null || vm.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token atau User ID belum tersedia.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // ✅ Sesuaikan pemanggilan API dengan format baru
      final result = await ApiService.createGroup(
        token: vm.authToken!,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        memberIds: _selectedFriends,
      );

      // Tambahkan ke ViewModel agar langsung terlihat
      vm.addGroup(result['group']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Grup berhasil dibuat!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal membuat grup: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
