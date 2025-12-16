// screens/comments_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/resources/firestore_methods.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';
import 'package:intl/intl.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String username = '';
  String profilePic = '';
  String postOwnerId = ''; // 👈 معرف صاحب البوست

  @override
  void initState() {
    super.initState();
    _getUserData();
    _getPostOwnerId();
  }

  // جلب بيانات المستخدم الحالي
  void _getUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (userDoc.exists) {
      setState(() {
        username = (userDoc.data() as Map<String, dynamic>)['username'] ?? 'User';
        profilePic = (userDoc.data() as Map<String, dynamic>)['photoUrl'] ?? '';
      });
    }
  }

  // جلب UID صاحب البوست
  void _getPostOwnerId() async {
    DocumentSnapshot postDoc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .get();

    if (postDoc.exists) {
      setState(() {
        postOwnerId = (postDoc.data() as Map<String, dynamic>)['uid'] ?? '';
      });
    }
  }

  // نشر تعليق
  void postComment() async {
    if (_commentController.text.isNotEmpty && postOwnerId.isNotEmpty) {
      await FireStoreMethods().postComment(
        widget.postId,
        _commentController.text,
        FirebaseAuth.instance.currentUser!.uid,
        username,
        profilePic,
        postOwnerId,
      );
      _commentController.clear();

      // Scroll to bottom بعد إضافة التعليق
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .collection('comments')
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            int commentCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return Text('Comments ($commentCount)', style: const TextStyle(color: Colors.white));
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('datePublished', descending: false)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No comments yet', style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var comment = snapshot.data!.docs[index].data();
                    var commentId = snapshot.data!.docs[index].id;
                    Timestamp timestamp = comment['datePublished'] as Timestamp;
                    String formattedDate = DateFormat('MMM d, yyyy').format(timestamp.toDate());

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(comment['profilePic'] ?? ''),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: comment['name'] ?? 'User',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const TextSpan(text: "  "),
                                      TextSpan(
                                        text: comment['text'] ?? '',
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (comment['uid'] == FirebaseAuth.instance.currentUser!.uid)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Comment'),
                                    content: const Text('Are you sure you want to delete this comment?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await FirebaseFirestore.instance
                                              .collection('posts')
                                              .doc(widget.postId)
                                              .collection('comments')
                                              .doc(commentId)
                                              .delete();
                                          Navigator.of(ctx).pop();
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(color: Colors.white24),
          SafeArea(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(profilePic),
                  radius: 18,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: postComment,
                  child: const Text('Post', style: TextStyle(color: Colors.blueAccent)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
