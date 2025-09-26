// import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background message handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _showLocalNotification(message);
}

/// Initialize notifications (call from main)
Future<void> initializeNotifications() async {
  // iOS & Android 13+ permissions
  await FirebaseMessaging.instance.requestPermission();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _showLocalNotification(message);
  });

  // App opened from background message
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // You can navigate to specific screens here if needed
    debugPrint('🔔 Notification tapped: ${message.notification?.title}');
  });

  // Background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

/// Show notification
void _showLocalNotification(RemoteMessage message) {
  final notification = message.notification;
  if (notification == null) return;

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'bloodwave_channel',
    'BloodWave Notifications',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  flutterLocalNotificationsPlugin.show(
    0,
    notification.title,
    notification.body,
    platformDetails,
  );
}
