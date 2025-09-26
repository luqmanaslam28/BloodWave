import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> saveDeviceToken(String uid) async {
  // Request notification permissions
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // Permission granted
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
      print("✅ FCM token saved: $token");
    }
  } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
    print("❌ Permission denied for notifications.");
  } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
    print("❗ Notification permission not determined.");
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print("ℹ️ Provisional permission granted.");
  } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
    print("❌ Permission denied or blocked permanently.");
  }
}


/// Send a push notification to the target device using their FCM token
Future<void> sendPushNotification({
  required String fcmToken,
  required String title,
  required String body,
}) async {
  const String serverKey = 'YOUR_SERVER_KEY_HERE'; // 🔒 Replace this with your Firebase Cloud Messaging Server key

  try {
    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode({
        'to': fcmToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      }),
    );

    if (response.statusCode == 200) {
      print('✅ Push notification sent');
    } else {
      print('❌ Failed to send notification: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error sending push notification: $e');
  }
}
