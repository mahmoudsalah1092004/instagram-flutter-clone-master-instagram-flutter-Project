// screens/feed_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';
import 'package:instagram_clone_flutter/widgets/post_card.dart';
import 'package:instagram_clone_flutter/screens/chat_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:instagram_clone_flutter/models/user.dart' as model;
import 'package:instagram_clone_flutter/providers/user_provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool isRandom = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final model.User? user = Provider.of<UserProvider>(context).getUser;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      backgroundColor: mobileBackgroundColor,

      // ---------- AppBar ----------
      appBar: screenWidth > 600
          ? null
          : AppBar(
              backgroundColor: mobileBackgroundColor,
              title: const Text(
                'Instagram',
                style: TextStyle(
                  fontFamily: 'Billabong',
                  fontSize: 32,
                ),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      isRandom = true;
                    });
                  },
                ),
              ],
            ),

      // ---------- Feed ----------
      body: StreamBuilder(
        stream: isRandom
            ? FirebaseFirestore.instance.collection('posts').snapshots()
            : FirebaseFirestore.instance
                .collection('posts')
                .orderBy('datePublished', descending: true)
                .snapshots(),
        builder: (context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🟢 عرض بوستات المتابعين + بوستاتي
          final filteredPosts = snapshot.data!.docs.where((post) {
            return user.following.contains(post['uid']) ||
                user.uid == post['uid'];
          }).toList();

          // 🔀 ترتيب عشوائي بعد الريفريش
          if (isRandom) {
            filteredPosts.shuffle();
          }

          // لو مفيش بوستات
          if (filteredPosts.isEmpty) {
            return const Center(
              child: Text(
                "Follow people to see their posts! 👥",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredPosts.length,
            itemBuilder: (context, index) {
              return Center(
                child: SizedBox(
                  width: screenWidth > 600 ? 550 : double.infinity,
                  child: PostCard(
                    snap: filteredPosts[index].data(),
                  ),
                ),
              );
            },
          );
        },
      ),

      // ---------- Messages Button ----------
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        child: const Icon(Icons.messenger_outline),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChatListScreen(),
            ),
          );
        },
      ),
    );
  }
}
