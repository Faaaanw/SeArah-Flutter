import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Imports sesuai struktur project Anda
import 'package:searah_backend/Navigation/navbar.dart';
import 'package:searah_backend/pages/login_page.dart';
import 'package:searah_backend/viewmodel/home_viewmodel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    
    // Setup Animasi Fade In
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // Jalankan logika pengecekan sesi
    _checkSessionAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkSessionAndNavigate() async {
    // 1. Beri jeda minimal agar logo sempat terlihat (estetika)
    //    Kita jalankan timer bersamaan dengan proses loading data
    final minDuration = Future.delayed(const Duration(seconds: 3));

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getInt('user_id');

      // 2. Cek apakah user login
      if (token != null && userId != null) {
        if (!mounted) return;

        // 3. Load Data menggunakan ViewModel
        final homeVm = context.read<HomeViewModel>();
        
        // Set user session
        homeVm.setUserSession(userId: userId, token: token);
        
        // Tunggu proses load data penting selesai
        await Future.wait([
          homeVm.loadUserProfile(),
          homeVm.loadInitialData(),
          minDuration, // Tunggu timer juga
        ]);

        if (!mounted) return;
        
        // 4. Navigasi ke Navbar (Home)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Navbar()),
        );
      } else {
        // Jika tidak ada token, tunggu timer selesai lalu ke Login
        await minDuration;
        
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPageWidget()),
        );
      }
    } catch (e) {
      // Error handling sederhana, jika gagal load data, lempar ke login
      await minDuration;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPageWidget()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Sesuaikan dengan warna background logo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo dengan animasi FadeTransition
            FadeTransition(
              opacity: _opacity,
              child: Image.asset(
                'assets/images/Searah_logo.png', // Pastikan path sesuai
                width: 200, // Sesuaikan ukuran
                height: 200,
              ),
            ),
            const SizedBox(height: 20),
            // Indikator loading kecil di bawah logo
            
          ],
        ),
      ),
    );
  }
}