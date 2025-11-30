import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:searah_backend/viewmodel/home_viewmodel.dart';
import 'package:searah_backend/viewmodel/friend_viewmodel.dart';
import 'package:searah_backend/pages/splash_screen.dart';

// 🔥 1. GLOBAL NAVIGATOR KEY
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🔥 2. SETUP LOCAL NOTIFICATIONS PLUGIN (Global)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 🔥 3. BACKGROUND HANDLER
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🌙 Background Message received: ${message.messageId}');
}

// 🔥 4. DEFINISI CHANNEL ANDROID
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // ID harus sama dengan Backend & Manifest
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.max,
  playSound: true,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set Background Handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // -----------------------------------------------------------------------
  // 🔥 TAMBAHAN PENTING: Inisialisasi Local Notifications
  // Tanpa ini, notifikasi foreground tidak akan bisa muncul (error icon missing)
  // -----------------------------------------------------------------------
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // Pastikan icon ada

  // Untuk iOS (jika nanti butuh)
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print("🔔 Notifikasi diklik: ${response.payload}");
      // Logika navigasi saat notif diklik bisa ditaruh sini
    },
  );

  // Buat Channel di Android System
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Opsi iOS Foreground
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // -----------------------------------------------------------------------
  // 🔥 TAMBAHAN PENTING: Foreground Listener (Saat Aplikasi Dibuka)
  // -----------------------------------------------------------------------
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('☀️ Foreground Message received: ${message.notification?.title}');
    
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Jika notifikasi ada isinya, kita PAKSA tampilkan pakai Local Notification
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher', // Icon wajib ada
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        payload: jsonEncode(message.data), // Simpan data untuk diklik
      );
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => FriendViewModel()),
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
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}