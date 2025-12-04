// screens/post_screen.dart
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/widgets/post_card.dart';

class PostScreen extends StatelessWidget {
  final Map<String, dynamic> snap;
  const PostScreen({Key? key, required this.snap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          snap['username'],
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        children: [
          PostCard(snap: snap), // هتظهر الصورة بنسبة 4:5 زي الانستجرام
        ],
      ),
    );
  }
}


