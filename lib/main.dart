// File: main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodel/home_viewmodel.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
// import 'pages/create_group_page.dart'; // Tidak perlu di sini jika tidak digunakan sebagai rute utama

// 👉 Tambahkan global key ini
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SeArah',
      navigatorKey: navigatorKey, // 👉 Selalu sediakan GlobalKey
      home: const LoginPageWidget(), // Tetapkan halaman awal di sini
      // ❌ Hapus routes di bawah ini jika tidak digunakan secara khusus
      // routes: {
      //   '/dashboard': (context) => const HomePageWidget(),
      //   '/create-group': (context) => const CreateGroupPage(),
      // },
    );
  }
}