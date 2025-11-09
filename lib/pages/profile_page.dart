import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:searah_backend/services/api_services.dart';
import 'package:searah_backend/pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _name;
  String? _email;
  String? _token;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// 🔹 Ambil data user dari SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('user_name') ?? 'Pengguna';
      _email = prefs.getString('user_email') ?? 'email@contoh.com';
      _token = prefs.getString('auth_token');
    });
  }

  /// 🔹 Logout user dari server dan hapus session lokal
  Future<void> _logout() async {
    setState(() => _isLoading = true);

    try {
      if (_token != null) {
        await ApiService.logout(_token!);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPageWidget()),
          (_) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal logout: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🔹 Dialog ganti password
  Future<void> _showChangePasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ganti Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password Lama",
              ),
            ),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password Baru",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Batal"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA8B60),
            ),
            onPressed: () async {
              if (_token == null) return;

              try {
                await ApiService.changePassword(
                  token: _token!,
                  currentPassword: currentController.text,
                  newPassword: newController.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password berhasil diganti")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal: $e')),
                );
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFA8B60),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Color(0xFFFA8B60),
                    child: Icon(Icons.person, color: Colors.white, size: 50),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _name ?? '-',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _email ?? '-',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Ganti Password'),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout'),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
    );
  }
}
