// resources/notification_methods.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addNotification({
    required String type, // like, comment, follow
    required String senderUid,
    required String receiverUid,
    required String username,
    required String userPhoto,
    String? postId,
    String? postImage,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(receiverUid)
          .collection('notifications')
          .add({
        'type': type,
        'fromUid': senderUid,
        'fromUsername': username,
        'fromPhoto': userPhoto,
        'postId': postId,
        'postImage': postImage,
        'date': Timestamp.now(),
        'seen': false,
      });
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }
}
