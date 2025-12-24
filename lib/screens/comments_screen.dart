// screens/comments_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/resources/firestore_methods.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';
import 'package:intl/intl.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String username = '';
  String profilePic = '';
  String? replyingToCommentId;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

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

  void postComment() async {
    if (_commentController.text.isNotEmpty) {
      if (replyingToCommentId != null) {
        // إرسال رد
        await FireStoreMethods().postReply(
          widget.postId,
          replyingToCommentId!,
          _commentController.text,
          FirebaseAuth.instance.currentUser!.uid,
          username,
          profilePic,
        );
        replyingToCommentId = null; // إعادة تعيين بعد الرد
      } else {
        // إرسال كومنت عادي
        await FireStoreMethods().postComment(
          widget.postId,
          _commentController.text,
          FirebaseAuth.instance.currentUser!.uid,
          username,
          profilePic,
        );
      }

      _commentController.clear();

      // Scroll to bottom
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  List<TextSpan> _buildTextSpans(String text) {
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return [TextSpan(text: text, style: const TextStyle(color: Colors.white))];
    }

    List<TextSpan> spans = [];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: const TextStyle(color: Colors.white),
        ));
      }
      final usernameMention = match.group(1);
      spans.add(TextSpan(
        text: '@$usernameMention',
        style: const TextStyle(color: Colors.blue),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Clicked on @$usernameMention')),
            );
          },
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: const TextStyle(color: Colors.white),
      ));
    }

    return spans;
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
                    var commentDoc = snapshot.data!.docs[index];
                    var comment = commentDoc.data();
                    var commentId = commentDoc.id;

                    List likes = comment['likes'] ?? [];
                    Timestamp? timestamp = comment['datePublished'] as Timestamp?;
                    String formattedDate = timestamp != null
                        ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
                        : '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                        children: _buildTextSpans(comment['text'] ?? ''),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                                        ),
                                        const SizedBox(width: 10),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              replyingToCommentId = commentId;
                                              _commentController.text =
                                                  '@${comment['name']} ';
                                              _commentController.selection = TextSelection.fromPosition(
                                                TextPosition(offset: _commentController.text.length),
                                              );
                                            });
                                          },
                                          child: const Text(
                                            'Reply',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.favorite,
                                  color: likes.contains(FirebaseAuth.instance.currentUser!.uid)
                                      ? Colors.red
                                      : Colors.grey,
                                  size: 18,
                                ),
                                onPressed: () {
                                  FireStoreMethods().likeComment(
                                    widget.postId,
                                    commentId,
                                    FirebaseAuth.instance.currentUser!.uid,
                                    likes,
                                  );
                                },
                              ),
                              if (comment['uid'] == FirebaseAuth.instance.currentUser!.uid)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Comment'),
                                        content:
                                            const Text('Are you sure you want to delete this comment?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(),
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
                                              if (!ctx.mounted) return;
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
                          // الردود
                          StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('posts')
                                .doc(widget.postId)
                                .collection('comments')
                                .doc(commentId)
                                .collection('replies')
                                .orderBy('datePublished', descending: false)
                                .snapshots(),
                            builder: (context,
                                AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> replySnapshot) {
                              if (!replySnapshot.hasData || replySnapshot.data!.docs.isEmpty) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(left: 40, top: 4),
                                child: Column(
                                  children: replySnapshot.data!.docs.map((replyDoc) {
                                    var reply = replyDoc.data();
                                    List replyLikes = reply['likes'] ?? [];
                                    Timestamp? replyTime = reply['datePublished'] as Timestamp?;
                                    String replyDate = replyTime != null
                                        ? DateFormat('MMM d, yyyy').format(replyTime.toDate())
                                        : '';
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundImage: NetworkImage(reply['profilePic'] ?? ''),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              RichText(
                                                text: TextSpan(
                                                  children: _buildTextSpans(reply['text'] ?? ''),
                                                ),
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                replyDate,
                                                style: const TextStyle(color: Colors.white54, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.favorite,
                                            color: replyLikes.contains(FirebaseAuth.instance.currentUser!.uid)
                                                ? Colors.red
                                                : Colors.grey,
                                            size: 16,
                                          ),
                                          onPressed: () {
                                            FireStoreMethods().likeComment(
                                              widget.postId,
                                              commentId,
                                              FirebaseAuth.instance.currentUser!.uid,
                                              replyLikes,
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  }).toList(),
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
                      decoration: InputDecoration(
                        hintText: replyingToCommentId != null ? 'Replying...' : 'Add a comment...',
                        hintStyle: const TextStyle(color: Colors.white54),
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
