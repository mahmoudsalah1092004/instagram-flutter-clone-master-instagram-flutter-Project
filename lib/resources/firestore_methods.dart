// resources/firestore_methods.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:instagram_clone_flutter/models/post.dart';
import 'package:instagram_clone_flutter/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';

class FireStoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -------------------------------------------
  // 📸 رفع بوست جديد
  // -------------------------------------------
  Future<String> uploadPost(
    String description,
    Uint8List file,
    String uid,
    String username,
    String profImage,
  ) async {
    String res = "Some error occurred";
    try {
      String photoUrl = await StorageMethods().uploadImageToStorage('posts', file, true);
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

      await _firestore.collection('posts').doc(postId).set({
        ...post.toJson(),
        'createdAtMillis': DateTime.now().millisecondsSinceEpoch,
      });

      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // -------------------------------------------
  // ❤️ لايك / أنلايك بوست
  // -------------------------------------------
  Future<String> likePost(String postId, String uid, List likes) async {
    String res = "Some error occurred";
    try {
      if (likes.contains(uid)) {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // -------------------------------------------
  // 💬 إضافة كومنت + دعم mentions
  // -------------------------------------------
  Future<String> postComment(
    String postId,
    String text,
    String uid,
    String name,
    String profilePic,
  ) async {
    String res = "Some error occurred";
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();
        List<String> mentions = _extractMentions(text);

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
          'likes': [],
          'mentions': mentions, // ⬅️ إضافة mentions
          'datePublished': FieldValue.serverTimestamp(),
        });
        res = 'success';
      } else {
        res = "Please enter text";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // -------------------------------------------
  // 💬 إضافة رد (Reply) + دعم mentions
  // -------------------------------------------
  Future<void> postReply(
    String postId,
    String commentId,
    String text,
    String uid,
    String name,
    String profilePic,
  ) async {
    try {
      String replyId = const Uuid().v1();
      List<String> mentions = _extractMentions(text);

      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .doc(replyId)
          .set({
        'replyId': replyId,
        'text': text,
        'uid': uid,
        'name': name,
        'profilePic': profilePic,
        'likes': [],
        'mentions': mentions, // ⬅️ إضافة mentions
        'datePublished': FieldValue.serverTimestamp(),
      });
    } catch (err) {
      if (kDebugMode) print('❌ postReply error: ${err.toString()}');
    }
  }

  // -------------------------------------------
  // ❤️ لايك / أنلايك كومنت أو رد
  // -------------------------------------------
  Future<void> likeComment(
      String postId, String commentId, String uid, List likes,
      {String? replyId}) async {
    try {
      DocumentReference ref;
      if (replyId != null) {
        ref = _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .collection('replies')
            .doc(replyId);
      } else {
        ref = _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId);
      }

      if (likes.contains(uid)) {
        await ref.update({'likes': FieldValue.arrayRemove([uid])});
      } else {
        await ref.update({'likes': FieldValue.arrayUnion([uid])});
      }
    } catch (err) {
      if (kDebugMode) print('❌ likeComment error: ${err.toString()}');
    }
  }

  // -------------------------------------------
  // استخراج الـ mentions من النص
  // -------------------------------------------
  List<String> _extractMentions(String text) {
    final regex = RegExp(r'\@(\w+)');
    final matches = regex.allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }

  // -------------------------------------------
  // 🗑️ حذف بوست
  // -------------------------------------------
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

  // -------------------------------------------
  // 👥 متابعة / إلغاء متابعة
  // -------------------------------------------
  Future<void> followUser(String uid, String followId) async {
    try {
      DocumentSnapshot userSnap = await _firestore.collection('users').doc(uid).get();
      List following = (userSnap.data()! as dynamic)['following'];

      if (following.contains(followId)) {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid]),
        });
        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId]),
        });
      } else {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayUnion([uid]),
        });
        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayUnion([followId]),
        });
      }
    } catch (e) {
      if (kDebugMode) print('❌ followUser error: ${e.toString()}');
    }
  }
}
