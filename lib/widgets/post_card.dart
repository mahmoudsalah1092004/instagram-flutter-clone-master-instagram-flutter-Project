// widgets/post_card.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/models/user.dart' as model;
import 'package:instagram_clone_flutter/providers/user_provider.dart';
import 'package:instagram_clone_flutter/resources/firestore_methods.dart';
import 'package:instagram_clone_flutter/screens/comments_screen.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';
import 'package:instagram_clone_flutter/utils/global_variable.dart';
import 'package:instagram_clone_flutter/utils/utils.dart';
import 'package:instagram_clone_flutter/widgets/like_animation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:instagram_clone_flutter/screens/profile_screen.dart';

class PostCard extends StatefulWidget {
  final dynamic snap;
  const PostCard({
    super.key,
    required this.snap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int commentLen = 0;
  bool isLikeAnimating = false;

  @override
  void initState() {
    super.initState();
    fetchCommentLen();
  }

  fetchCommentLen() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.snap['postId'])
          .collection('comments')
          .get();
      commentLen = snap.docs.length;
    } catch (err) {
      if (mounted) {
        showSnackBar(context, err.toString());
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  deletePost(String postId) async {
    try {
      await FireStoreMethods().deletePost(postId);
    } catch (err) {
      if (mounted) {
        showSnackBar(context, err.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final model.User? user = userProvider.getUser; // ✅ بقى ممكن يكون null

    final width = MediaQuery.of(context).size.width;

    // ✅ لو الـ user لسه ما اتحملش
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: width > webScreenSize ? secondaryColor : mobileBackgroundColor,
        ),
        color: mobileBackgroundColor,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          // HEADER
          Container(
  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16).copyWith(right: 0),
  child: Row(
    children: [
      // 1. الجزء الخاص بالانتقال للبروفايل
      Expanded(
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  uid: widget.snap['uid'].toString(),
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                  widget.snap['profImage'].toString(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.snap['username'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // 2. الجزء الخاص بمسح البوست (يظهر فقط لصاحب البوست)
      if (widget.snap['uid'].toString() == user.uid)
        IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shrinkWrap: true,
                  children: [
                    'Delete',
                  ]
                      .map(
                        (e) => InkWell(
                          onTap: () async {
                            // دالة المسح الحقيقية
                            await FireStoreMethods().deletePost(widget.snap['postId']);
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            child: Text(e),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          },
          icon: const Icon(Icons.more_vert),
        ),
    ],
  ),
),
          // IMAGE
          GestureDetector(
            onDoubleTap: () {
              FireStoreMethods().likePost(
                widget.snap['postId'].toString(),
                user.uid,
                widget.snap['likes'],
              );
              setState(() => isLikeAnimating = true);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
  width: double.infinity, // تاخد عرض الشاشة بالكامل
  child: Image.network(
    widget.snap['postUrl'].toString(), // رابط الصورة
    // شيلنا الـ height وشيلنا الـ fit
    
    // كود اللودينج (عشان يظهر دايرة تحميل لحد ما الصورة تظهر)
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return const Center(
        child: CircularProgressIndicator(),
      );
    },
    
    // كود الخطأ (عشان لو الصورة باظت ميعملش شاشة حمراء)
    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
  ),
),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isLikeAnimating ? 1 : 0,
                  child: LikeAnimation(
                    isAnimating: isLikeAnimating,
                    duration: const Duration(milliseconds: 400),
                    onEnd: () => setState(() => isLikeAnimating = false),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // LIKE, COMMENT SECTION
          Row(
            children: <Widget>[
              LikeAnimation(
                isAnimating: widget.snap['likes'].contains(user.uid),
                smallLike: true,
                child: IconButton(
                  icon: widget.snap['likes'].contains(user.uid)
                      ? const Icon(Icons.favorite, color: Colors.red)
                      : const Icon(Icons.favorite_border),
                  onPressed: () => FireStoreMethods().likePost(
                    widget.snap['postId'].toString(),
                    user.uid,
                    widget.snap['likes'],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        CommentsScreen(postId: widget.snap['postId'].toString()),
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: () {}),
              const Spacer(),
              IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
            ],
          ),

          // DESCRIPTION + COMMENTS COUNT + DATE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${widget.snap['likes'].length} likes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: primaryColor),
                      children: [
                        TextSpan(
                          text: widget.snap['username'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' ${widget.snap['description']}'),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          CommentsScreen(postId: widget.snap['postId'].toString()),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'View all $commentLen comments',
                      style: const TextStyle(color: secondaryColor),
                    ),
                  ),
                ),
                Text(
                  DateFormat.yMMMd()
                      .format(widget.snap['datePublished'].toDate()),
                  style: const TextStyle(color: secondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
