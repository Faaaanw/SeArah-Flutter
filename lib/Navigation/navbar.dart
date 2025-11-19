// File: lib/pages/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:searah_backend/pages/dashboard_page.dart';
import 'package:searah_backend/pages/friends_page.dart';
import 'package:searah_backend/pages/notification_page.dart';
import 'package:searah_backend/pages/profile_page.dart';


const Color _kPrimaryButtonColor = Color(0xFFFA8B60);
const Color _kPeachIconColor = Color(0xFFBFA4A0);

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePageWidget(),
    NotificationsPage(),
    FriendsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _kPrimaryButtonColor,
        unselectedItemColor: _kPeachIconColor,
        backgroundColor: Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined), label: 'Notifications'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined), label: 'Friends'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
