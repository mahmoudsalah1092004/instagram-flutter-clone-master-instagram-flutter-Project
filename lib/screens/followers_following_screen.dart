// screens/followers_following_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/screens/profile_screen.dart';

class FollowersFollowingScreen extends StatefulWidget {
  final String uid;
  final bool showFollowers; // true = followers, false = following

  const FollowersFollowingScreen({
  super.key,
  required this.uid,
  required this.showFollowers,
});

  @override
  State<FollowersFollowingScreen> createState() => _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen>
    with SingleTickerProviderStateMixin {
  List followers = [];
  List following = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  getUserData() async {
    var userSnap =
        await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();

    setState(() {
      followers = userSnap['followers'];
      following = userSnap['following'];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.showFollowers ? 0 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Connections"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Followers"),
              Tab(text: "Following"),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  buildUserList(followers),
                  buildUserList(following),
                ],
              ),
      ),
    );
  }

  Widget buildUserList(List userIds) {
    if (userIds.isEmpty) {
      return const Center(child: Text("No users found"));
    }

    return ListView.builder(
      itemCount: userIds.length,
      itemBuilder: (context, index) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(userIds[index])
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            var userData = snapshot.data!;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(userData['photoUrl']),
              ),
              title: Text(userData['username']),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ProfileScreen(uid: userData['uid']),
                ));
              },
            );
          },
        );
      },
    );
  }
}
