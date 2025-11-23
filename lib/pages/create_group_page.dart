import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_services.dart';
import '../viewmodel/home_viewmodel.dart';
import '../models/group_model.dart';

const Color _kPrimaryButtonColor = Color(0xFFFA8B60);

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Set untuk menyimpan ID teman agar tidak duplikat dan pencarian lebih cepat
  final Set<int> _selectedFriends = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Fetch data terbaru saat halaman dibuka
    Future.microtask(() {
      context.read<HomeViewModel>().fetchFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    // 🔥 PENTING: Gunakan allFriends, bukan friends
    // friends = list yang terfilter berdasarkan grup yang aktif
    // allFriends = list total semua teman
    final friendList = vm.allFriends;

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

              const SizedBox(height: 8), // Sedikit jarak

              Expanded(
                child: vm.isLoadingFriends
                    ? const Center(child: CircularProgressIndicator())
                    : friendList.isEmpty // 🔥 Cek friendList (allFriends)
                        ? const Center(
                            child: Text("Anda belum memiliki teman."))
                        : ListView.builder(
                            itemCount: friendList.length,
                            itemBuilder: (context, index) {
                              final friend = friendList[index];
                              final selected =
                                  _selectedFriends.contains(friend.id);

                              return CheckboxListTile(
                                value: selected,
                                title: Text(friend.name),
                                subtitle: Text(friend.email),
                                activeColor: _kPrimaryButtonColor,
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
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.group_add_outlined),
                  label: const Text("Buat Grup",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            await _createGroup(vm);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryButtonColor,
                    foregroundColor: Colors.white, // Agar text & icon putih
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
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        memberIds: _selectedFriends.toList(), // Konversi Set ke List
      );

      vm.addGroup(newGroup);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Grup berhasil dibuat!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      String errorMessage = e.toString().contains('Exception:')
          ? e.toString().substring(e.toString().indexOf(':') + 1).trim()
          : 'Terjadi kesalahan: $e';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $errorMessage')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
