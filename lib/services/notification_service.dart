import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> sendBloodRequestNotification({
    required String receiverId,
    required String senderId,
    required String message,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': receiverId, // who should receive the notification
      'senderId': senderId, // who sent the message
      'message': message,
      'timestamp': Timestamp.now(),
    });
  }
}

