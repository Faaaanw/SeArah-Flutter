import 'package:flutter/material.dart';
import 'package:searah_backend/main.dart';
import 'package:searah_backend/pages/home_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5), // warna background lembut
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ===== TOP BAR =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainPage())),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back, color: Colors.black),
                          SizedBox(width: 6),
                          Text("Back", style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            offset: Offset(0, 2),
                            blurRadius: 6,
                            color: Colors.black12,
                          )
                        ],
                      ),
                      child: const Icon(Icons.photo_camera_outlined,
                          color: Colors.black),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ===== AVATAR + NAME =====
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Circle Avatar
                  const CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(
                      "https://i.pravatar.cc/200?img=12",
                    ),
                  ),

                  // Badge PRO
                  Positioned(
                    bottom: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.pink,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "PRO",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 15),

              const Text(
                "Alison Danis",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "UX/UI Designer",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),

              const SizedBox(height: 30),

              // ===== WHITE CARD MENU =====
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      icon: Icons.person,
                      iconColor: Colors.pink,
                      title: "Edit profile",
                    ),
                    _menuTile(
                      icon: Icons.bar_chart,
                      iconColor: Colors.purple,
                      title: "My stats",
                    ),
                    _menuTile(
                      icon: Icons.settings,
                      iconColor: Colors.orange,
                      title: "Settings",
                    ),
                    _menuTile(
                      icon: Icons.group_add,
                      iconColor: Colors.grey,
                      title: "Invite a friend",
                    ),
                    _menuTile(
                      icon: Icons.help_outline,
                      iconColor: Colors.black54,
                      title: "Help",
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ===== REUSABLE MENU TILE =====
  Widget _menuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return Column(
      children: [
        ListTile(
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
}
