// services/posts_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class PostsService {
  static Future<String> uploadImage(File imageFile) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('posts/${DateTime.now().millisecondsSinceEpoch}.jpg');

    await storageRef.putFile(imageFile);
    final imageUrl = await storageRef.getDownloadURL();
    return imageUrl;
  }

  static Future<void> addPost(File imageFile, String caption, String uid) async {
    final imageUrl = await uploadImage(imageFile);

    await FirebaseFirestore.instance.collection('posts').add({
      'imageUrl': imageUrl,
      'caption': caption,
      'uid': uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

  }
}
