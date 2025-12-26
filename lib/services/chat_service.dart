// services/chat_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Returns a stable chatId for two uids (sorted)
  String getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Future<String> _currentUid() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not signed in');
    return user.uid;
  }

  /// Send text message and update chat doc
  Future<void> sendTextMessage({
    required String chatId,
    required String text,
  }) async {
    final senderId = await _currentUid();
    final chatDoc = _firestore.collection('chats').doc(chatId);
    final msgRef = chatDoc.collection('messages').doc();

    final msgData = <String, dynamic>{
      'senderId': senderId,
      'text': text,
      'imageUrl': '',
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [senderId],
    };

    final batch = _firestore.batch();
    batch.set(msgRef, msgData);
    batch.set(chatDoc, {
      'members': chatId.split('_'),
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Send image message: upload to Storage then save message
  Future<void> sendImageMessage({
    required String chatId,
    required File imageFile,
  }) async {
    final senderId = await _currentUid();
    final id = const Uuid().v4();
    final ref = _storage.ref().child('chat_images/$chatId/$id.jpg');
    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();

    final chatDoc = _firestore.collection('chats').doc(chatId);
    final msgRef = chatDoc.collection('messages').doc();

    final msgData = <String, dynamic>{
      'senderId': senderId,
      'text': '',
      'imageUrl': url,
      'type': 'image',
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [senderId],
    };

    final batch = _firestore.batch();
    batch.set(msgRef, msgData);
    batch.set(chatDoc, {
      'members': chatId.split('_'),
      'lastMessage': '[Image]',
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Stream last messages (default limit)
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String chatId, {int limit = 50}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }
}
