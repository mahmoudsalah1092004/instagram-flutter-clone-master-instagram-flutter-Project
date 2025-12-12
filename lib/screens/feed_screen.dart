// screens/feed_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';
import 'package:instagram_clone_flutter/widgets/post_card.dart';
import 'package:instagram_clone_flutter/screens/chat_list_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: mobileBackgroundColor,
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
            ),
      body: Stack(
        children: [
          // ===== البوستات =====
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .orderBy('datePublished', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No posts yet',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                );
              }

              final posts = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80), // عشان الزرار ميغطيش البوستات
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final snap = posts[index].data();
                  return Center(
                    child: Container(
                      width: screenWidth > 600 ? 550 : double.infinity,
                      child: PostCard(snap: snap),
                    ),
                  );
                },
              );
            },
          ),

          // ===== زرار الشات صغير تحت اليمين =====
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatListScreen()),
                );
              },
              child: const Text(
                "Chat",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
