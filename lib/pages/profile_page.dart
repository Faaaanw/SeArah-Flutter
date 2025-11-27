import 'package:flutter/material.dart';
import 'package:searah_backend/pages/login_page.dart';
import 'package:searah_backend/viewmodel/home_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:searah_backend/models/user_model.dart';
import 'package:searah_backend/services/api_services.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token'); // ← FIXED

    print("TOKEN = $token");

    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final result = await ApiService.getCurrentUser(token);
      print("API RESULT = $result");

      final userJson = result['user'] ?? result['data'] ?? result;

      if (userJson != null) {
        setState(() {
          user = User.fromJson(userJson);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error load user: $e");
      setState(() => isLoading = false);
    }
  }

  // Di dalam class _ProfilePageState
  Future<void> logoutUser() async {
    // 1. Dapatkan View Model
    // Gunakan listen: false karena kita tidak ingin widget ini me-rebuild saat VM berubah
    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // 2. 🛑 PANGGIL CLEAR SESSION DI HOMEVIEWMODEL 🛑
    // Ini akan menghentikan semua timer, streaming GPS, dan polling teman.
    homeViewModel.clearSession(); // 🔥 PENTING!

    // 3. Panggil API Logout (optional)
    if (token != null) {
      try {
        await ApiService.logout(token);
      } catch (e) {
        print("Logout API error (Token sudah dihapus di sisi klien): $e");
      }
    }

    // 4. Hapus semua data session lokal
    await prefs.clear();

    if (!mounted) return;

    // 5. Arahkan ke LoginPage, hapus semua history
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPageWidget()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = user?.name ?? "Guest User";
    final email = user?.email ?? "-";

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ===== AVATAR =====
              CircleAvatar(
                radius: 60,
                backgroundImage:
                    NetworkImage("https://i.pravatar.cc/200?u=$email"),
              ),

              const SizedBox(height: 15),

              // ===== NAMA =====
              Text(
                name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 4),

              // ===== EMAIL =====
              Text(
                email,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),

              const SizedBox(height: 30),

              // ===== MENU CARD =====
              _buildMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _menuTile(
            Icons.person,
            Colors.pink,
            "Edit profile",
            onTap: showEditProfilePopup,
          ),
          _menuTile(Icons.settings, Colors.orange, "Settings"),
          _menuTile(Icons.help_outline, Colors.black54, "Help"),
          _menuTileLogout(Icons.logout, Colors.red, "Logout"),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _menuTileLogout(IconData icon, Color iconColor, String title) {
    return Column(
      children: [
        ListTile(
          onTap: logoutUser, // ← langsung panggil logout
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: iconColor, // Warna merah biar berbeda
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios,
              size: 16, color: iconColor.withOpacity(0.8)),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _menuTile(IconData icon, Color iconColor, String title,
      {VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
        const Divider(height: 1),
      ],
    );
  }

  void showEditProfilePopup() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SizedBox(
          height: 170,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text("Edit Nama"),
                onTap: () {
                  Navigator.pop(context);
                  showEditNamePopup();
                },
              ),
              ListTile(
                leading: Icon(Icons.lock, color: Colors.orange),
                title: Text("Ganti Password"),
                onTap: () {
                  Navigator.pop(context);
                  showEditPasswordPopup();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showEditNamePopup() {
    final controller = TextEditingController(text: user?.name ?? "");

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("Edit Nama"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: "Nama baru"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('auth_token');

                if (token == null) return;

                try {
                  await ApiService.updateName(
                      token: token, name: controller.text);

                  setState(() {
                    user = user?.copyWith(name: controller.text);
                  });

                  Navigator.pop(context);
                } catch (e) {
                  print("Error update nama: $e");
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  void showEditPasswordPopup() {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("Ganti Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPass,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password lama"),
              ),
              TextField(
                controller: newPass,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password baru"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('auth_token');

                if (token == null) return;

                try {
                  await ApiService.changePassword(
                    token: token,
                    currentPassword: oldPass.text,
                    newPassword: newPass.text,
                  );

                  Navigator.pop(context);
                } catch (e) {
                  print("Error ganti password: $e");
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }
}
