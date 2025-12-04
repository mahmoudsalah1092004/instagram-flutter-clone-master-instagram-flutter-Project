// resources/notification_methods.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addNotification({
    required String type, // like, comment, follow
    required String senderUid,
    required String receiverUid,
    required String username,
    required String userPhoto,
    String? postImage,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': type,
        'senderUid': senderUid,
        'receiverUid': receiverUid,
        'username': username,
        'userPhoto': userPhoto,
        'postImage': postImage,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print('Error adding notification: $e');
    }
  }
}
