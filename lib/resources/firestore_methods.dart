// resources/firestore_methods.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:instagram_clone_flutter/models/post.dart';
import 'package:instagram_clone_flutter/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

class FireStoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ رفع بوست جديد
  Future<String> uploadPost(
    String description,
    Uint8List file,
    String uid,
    String username,
    String profImage,
  ) async {
    String res = "Some error occurred";
    try {
      String photoUrl =
          await StorageMethods().uploadImageToStorage('posts', file, true);
      String postId = const Uuid().v1();

      Post post = Post(
        description: description,
        uid: uid,
        username: username,
        likes: [],
        postId: postId,
        datePublished: DateTime.now(),
        postUrl: photoUrl,
        profImage: profImage,
      );

      await _firestore.collection('posts').doc(postId).set(post.toJson());
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // ✅ لايك / أنلايك بوست + Notification
  Future<String> likePost(String postId, String uid, List likes, String postOwnerId) async {
    String res = "Some error occurred";
    try {
      // جلب بيانات المستخدم المرسل للاشعار
      DocumentSnapshot userSnap =
          await _firestore.collection('users').doc(uid).get();
      String username = (userSnap.data() as dynamic)['username'] ?? 'User';
      String photoUrl = (userSnap.data() as dynamic)['photoUrl'] ?? '';

      if (likes.contains(uid)) {
        // إزالة اللايك
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        // إضافة لايك
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid]),
        });

        // إضافة Notification للمالك
        if (postOwnerId != uid) {
          await _firestore
              .collection('users')
              .doc(postOwnerId)
              .collection('notifications')
              .add({
            'type': 'like',
            'fromUid': uid,
            'fromUsername': username,
            'fromPhoto': photoUrl,
            'postId': postId,
            'date': Timestamp.now(),
            'seen': false,
          });
        }
      }
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // ✅ كتابة تعليق جديد + Notification
  Future<String> postComment(
    String postId,
    String text,
    String uid,
    String name,
    String profilePic,
    String postOwnerId,
  ) async {
    String res = "Some error occurred";
    try {
      // جلب بيانات المستخدم المرسل للاشعار
      DocumentSnapshot userSnap =
          await _firestore.collection('users').doc(uid).get();
      String username = (userSnap.data() as dynamic)['username'] ?? 'User';
      String photoUrl = (userSnap.data() as dynamic)['photoUrl'] ?? '';

      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();

        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set({
          'profilePic': profilePic,
          'name': name,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': DateTime.now(),
        });

        // إضافة Notification للمالك
        if (postOwnerId != uid) {
          await _firestore
              .collection('users')
              .doc(postOwnerId)
              .collection('notifications')
              .add({
            'type': 'comment',
            'fromUid': uid,
            'fromUsername': username,
            'fromPhoto': photoUrl,
            'postId': postId,
            'date': Timestamp.now(),
            'seen': false,
          });
        }

        res = 'success';
      } else {
        res = "Please enter text";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // ✅ حذف بوست
  Future<String> deletePost(String postId) async {
    String res = "Some error occurred";
    try {
      await _firestore.collection('posts').doc(postId).delete();
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // ✅ متابعة / إلغاء متابعة مستخدم (Follow / Unfollow) + Notification
  Future<void> followUser(String uid, String followId) async {
    try {
      DocumentSnapshot userSnap =
          await _firestore.collection('users').doc(uid).get();

      List following = (userSnap.data()! as dynamic)['following'];

      // جلب بيانات المستخدم المرسل للاشعار
      DocumentSnapshot fromSnap =
          await _firestore.collection('users').doc(uid).get();
      String username = (fromSnap.data() as dynamic)['username'] ?? 'User';
      String photoUrl = (fromSnap.data() as dynamic)['photoUrl'] ?? '';

      if (following.contains(followId)) {
        // الغاء المتابعة
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid]),
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId]),
        });
      } else {
        // متابعة
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayUnion([uid]),
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayUnion([followId]),
        });

        // إضافة Notification للمتابع
        if (followId != uid) {
          await _firestore
              .collection('users')
              .doc(followId)
              .collection('notifications')
              .add({
            'type': 'follow',
            'fromUid': uid,
            'fromUsername': username,
            'fromPhoto': photoUrl,
            'postId': null,
            'date': Timestamp.now(),
            'seen': false,
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ followUser error: ${e.toString()}');
    }
  }
}
