// screens/notifications_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/screens/profile_screen.dart';
import 'package:instagram_clone_flutter/screens/comments_screen.dart';
import 'package:instagram_clone_flutter/resources/firestore_methods.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .collection('notifications')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'لا يوجد إشعارات',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final data = notif.data() as Map<String, dynamic>;

              final String type = data['type'] ?? '';
              final String fromUid = data['fromUid'] ?? '';
              final String fromUsername = data['fromUsername'] ?? 'User';
              final String fromPhoto = data['fromPhoto'] ?? '';
              final String? postId = data['postId'];
              final bool seen = data['seen'] ?? false;

              return ListTile(
                tileColor: seen ? Colors.black : Colors.grey[900],
                leading: CircleAvatar(
                  backgroundImage: fromPhoto.isNotEmpty ? NetworkImage(fromPhoto) : null,
                  child: fromPhoto.isEmpty ? const Icon(Icons.person) : null,
                ),
                title: Text(
                  '$fromUsername ${_getMessageText(type)}',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _formatDate(data['date'] as Timestamp?),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: type == 'follow'
                    ? FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUid)
                            .get(),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData) return const SizedBox.shrink();
                          List following =
                              (userSnap.data!.data() as dynamic)['following'] ?? [];
                          bool isFollowing = following.contains(fromUid);

                          return TextButton(
                            onPressed: () async {
                              await FireStoreMethods().followUser(currentUid, fromUid);
                            },
                            child: Text(
                              isFollowing ? 'متابع' : 'متابعة',
                              style: const TextStyle(color: Colors.blueAccent),
                            ),
                          );
                        },
                      )
                    : null,
                onTap: () {
                  // فتح الصفحة المناسبة
                  if (type == 'follow') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(uid: fromUid),
                      ),
                    );
                  } else if ((type == 'like' || type == 'comment') && postId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommentsScreen(postId: postId),
                      ),
                    );
                  }
                  // تحديث الـ seen بعد الضغط
                  notif.reference.update({'seen': true});
                },
              );
            },
          );
        },
      ),
    );
  }

  String _getMessageText(String type) {
    switch (type) {
      case 'like':
        return 'أعجب بمنشورك';
      case 'comment':
        return 'علق على منشورك';
      case 'follow':
        return 'تابعك';
      default:
        return '';
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime dt = timestamp.toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
