// screens/chat_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String myUid = FirebaseAuth.instance.currentUser!.uid;
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("الرسائل"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "ابحث عن شخص...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data();
          final following = List<String>.from(userData?['following'] ?? []);

          if (following.isEmpty) {
            return const Center(child: Text("مش متابع حد لسه"));
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: following)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs
                  .where((doc) {
                    final username = (doc.data()['username'] ?? '').toString().toLowerCase();
                    return username.contains(searchQuery);
                  })
                  .toList();

              if (users.isEmpty) {
                return const Center(child: Text("لا يوجد نتائج"));
              }

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getLastMessagesStream(users),
                builder: (context, lastMsgSnap) {
                  if (!lastMsgSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final usersWithLastMsg = lastMsgSnap.data!;

                  usersWithLastMsg.sort((a, b) {
                    final t1 = a['lastMessageTime'] as Timestamp?;
                    final t2 = b['lastMessageTime'] as Timestamp?;
                    if (t1 == null && t2 == null) return 0;
                    if (t1 == null) return 1;
                    if (t2 == null) return -1;
                    return t2.compareTo(t1);
                  });

                  return ListView.builder(
                    itemCount: usersWithLastMsg.length,
                    itemBuilder: (context, index) {
                      final user = usersWithLastMsg[index];
                      final userId = user['id'] as String;
                      final userName = user['username'] as String;
                      final userPhoto = user['photoUrl'] as String? ?? '';
                      final lastMessage = user['lastMessage'] as String? ?? "";

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              userPhoto.isNotEmpty ? NetworkImage(userPhoto) : null,
                          child: userPhoto.isEmpty ? const Icon(Icons.person) : null,
                        ),
                        title: Text(userName),
                        subtitle: Text(lastMessage), // بس آخر رسالة فقط
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                otherUserId: userId,
                                otherUserName: userName,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _createChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return sorted.join('_');
  }

  Stream<List<Map<String, dynamic>>> _getLastMessagesStream(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> users) async* {
    for (;;) {
      List<Map<String, dynamic>> result = [];
      for (var userDoc in users) {
        final userId = userDoc.id;
        final userData = userDoc.data();
        final chatId = _createChatId(myUid, userId);

        final chatSnap = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .snapshots()
            .first;

        final lastMessage = chatSnap.data()?['lastMessage'] as String?;
        final lastMessageTime = chatSnap.data()?['lastMessageTime'] as Timestamp?;

        result.add({
          'id': userId,
          'username': userData['username'] ?? 'User',
          'photoUrl': userData['photoUrl'] ?? '',
          'lastMessage': lastMessage ?? "",
          'lastMessageTime': lastMessageTime,
        });
      }
      yield result;
      await Future.delayed(const Duration(seconds: 1)); // تحديث كل ثانية
    }
  }
}
