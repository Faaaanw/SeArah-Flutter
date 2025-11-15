import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:searah_backend/Navigation/navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'viewmodel/home_viewmodel.dart';
import 'viewmodel/friend_viewmodel.dart'; // ✅ Tambahkan import ini
import 'pages/login_page.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final userId = prefs.getInt('user_id');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => FriendViewModel()), // ✅ Tambahkan ini
      ],
      child: MyApp(
        isLoggedIn: token != null && userId != null,
        token: token,
        userId: userId,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final String? token;
  final int? userId;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    this.token,
    this.userId,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<HomeViewModel>();
      if (widget.isLoggedIn && widget.token != null && widget.userId != null) {
        vm.setUserSession(userId: widget.userId!, token: widget.token!);
        await vm.loadUserProfile();
        await vm.loadInitialData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SeArah',
      navigatorKey: navigatorKey,
      home: widget.isLoggedIn ? const Navbar() : const LoginPageWidget(),
    );
  }
}
