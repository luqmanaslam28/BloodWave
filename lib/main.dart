// ignore_for_file: deprecated_member_use, avoid_print

import 'package:bloodwave/Screens/WelcomeScreen.dart';
import 'package:bloodwave/Screens/role_selection_screen.dart';
import 'package:bloodwave/admin/admin_panel_screen.dart';
import 'package:bloodwave/auth/login_screen.dart';
import 'package:bloodwave/hospital/hospital_welcome.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:device_preview/device_preview.dart';
import 'firebase_options.dart';
// import 'auth/signup_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background handler for Firebase Messaging
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ✅ Add this check here too
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  _showLocalNotification(message);
}

/// Show local notification
void _showLocalNotification(RemoteMessage message) {
  final notification = message.notification;
  if (notification == null) return;

  const androidDetails = AndroidNotificationDetails(
    'bloodwave_channel',
    'BloodWave Notifications',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const platformDetails = NotificationDetails(android: androidDetails);

  flutterLocalNotificationsPlugin.show(
    0,
    notification.title,
    notification.body,
    platformDetails,
  );
}

/// Check user flow (admin / hospital / donor / signup)
Future<Map<String, dynamic>> _checkUserFlow(User? firebaseUser) async {
  if (firebaseUser == null) {
    return {"screen": "login"};
  }

  // ✅ Admin check
  if (firebaseUser.email?.toLowerCase() == "admin@gmail.com") {
    return {"screen": "admin"};
  }

  // ✅ Check if role exists
  final roleDoc = await FirebaseFirestore.instance
      .collection('user_roles')
      .doc(firebaseUser.uid)
      .get();

  final name = firebaseUser.displayName ?? firebaseUser.email ?? "";

  if (!roleDoc.exists || roleDoc['accountType'] == null) {
    return {"screen": "role", "name": name};
  }

  final accountType = roleDoc['accountType'];

  if (accountType == "person") {
    return {"screen": "welcome", "name": name};
  } else if (accountType == "hospital" || accountType == "bloodbank") {
    return {"screen": "hospital", "name": name};
  }

  return {"screen": "login"};
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase initialized successfully");
    } else {
      print("Firebase already initialized, skipping...");
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      print("Firebase already initialized (caught duplicate-app error)");
    } else {
      print("Firebase initialization error: $e");
      rethrow;
    }
  }

  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const initializationSettingsAndroid = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );
  const initSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(const BloodWaveApp());
}

class BloodWaveApp extends StatelessWidget {
  const BloodWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloodWave',
      debugShowCheckedModeBanner: false,
      // locale: DevicePreview.locale(context),
      // builder: DevicePreview.appBuilder,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Color.fromARGB(255, 0, 0, 0),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
          titleLarge: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF5F5F5),
          border: OutlineInputBorder(),
          labelStyle: TextStyle(color: Colors.black),
          hintStyle: TextStyle(color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = authSnapshot.data;
          return FutureBuilder<Map<String, dynamic>>(
            future: _checkUserFlow(user),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.hasError) {
                return const Scaffold(
                  body: Center(child: Text("Error loading user role")),
                );
              }

              final data = roleSnapshot.data ?? {};

              switch (data["screen"]) {
                case "login":
                  return const LoginScreen();
                case "role":
                  return WillPopScope(
                    onWillPop: () async => false,
                    child: RoleSelectionScreen(
                      name: data["name"] ?? "",
                      onRoleSelected: () {},
                    ),
                  );
                case "admin":
                  return const AdminPanelScreen();
                case "welcome":
                  return WelcomeScreen(name: data["name"] ?? "");
                case "hospital":
                  return HospitalSplashScreen(name: data["name"] ?? "");
                default:
                  return const LoginScreen();
              }
            },
          );
        },
      ),
    );
  }
}
