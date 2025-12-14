// lib/screens/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/resources/auth_methods.dart';
import 'package:instagram_clone_flutter/resources/firestore_methods.dart';
// 🆕 START: Import EditProfileScreen
import 'package:instagram_clone_flutter/screens/edit_profile_screen.dart';
// 🆕 END: Import EditProfileScreen
import 'package:instagram_clone_flutter/screens/login_screen.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';
import 'package:instagram_clone_flutter/widgets/follow_button.dart';
// 🆕 START: Import User model
import 'package:instagram_clone_flutter/models/user.dart' as model;
// 🆕 END: Import User model

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isFollowing = false;
  bool isLoading = false;
  // 🆕 START: Add userData variable
  model.User? userData; // Make it nullable initially
  // 🆕 END: Add userData variable

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🆕 START: Use User model
        userData = model.User.fromSnap(snapshot.data!);
        int followers = userData!.followers.length;
        int following = userData!.following.length;
        isFollowing = userData!.followers.contains(currentUserId);
        // 🆕 END: Use User model

        return Scaffold(
          appBar: AppBar(
            backgroundColor: mobileBackgroundColor,
            title: Text(userData!.username), // 🆕 Use model
            centerTitle: false,
          ),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey,
                          backgroundImage: NetworkImage(
                            userData!.photoUrl, // 🆕 Use model
                          ),
                          radius: 40,
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('posts')
                                    .where('uid', isEqualTo: widget.uid)
                                    .snapshots(),
                                builder: (context, postSnapshot) {
                                  if (!postSnapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }

                                  int postLen = postSnapshot.data!.docs.length;

                                  return Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      buildStatColumn(postLen, "Posts"),
                                      buildStatColumn(followers, "Followers"),
                                      buildStatColumn(following, "Following"),
                                    ],
                                  );
                                },
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  currentUserId == widget.uid
                                      // 🆕 START: Change to "Edit Profile" button
                                      ? FollowButton(
                                          text: 'Edit Profile',
                                          backgroundColor:
                                              mobileBackgroundColor,
                                          textColor: Colors.white,
                                          borderColor: Colors.grey,
                                          function: () {
                                            // Navigate to edit profile screen
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditProfileScreen(
                                                  user: userData!,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      // 🆕 END: Change to "Edit Profile" button
                                      : isFollowing
                                          ? FollowButton(
                                              text: 'Unfollow',
                                              backgroundColor: Colors.white,
                                              textColor: Colors.black,
                                              borderColor: Colors.grey,
                                              function: () async {
                                                await FireStoreMethods()
                                                    .followUser(
                                                  currentUserId,
                                                  userData!.uid, // 🆕 Use model
                                                );
                                                // No need for setState, StreamBuilder will handle it
                                              },
                                            )
                                          : FollowButton(
                                              text: 'Follow',
                                              backgroundColor: Colors.blue,
                                              textColor: Colors.white,
                                              borderColor: Colors.blue,
                                              function: () async {
                                                await FireStoreMethods()
                                                    .followUser(
                                                  currentUserId,
                                                  userData!.uid, // 🆕 Use model
                                                );
                                                // No need for setState, StreamBuilder will handle it
                                              },
                                            ),
                                ],
                              ),
                              // 🆕 START: Add Sign Out button separately
                              if (currentUserId == widget.uid)
                                FollowButton(
                                  text: 'Sign Out',
                                  backgroundColor: mobileBackgroundColor,
                                  textColor: Colors.white,
                                  borderColor: Colors.grey,
                                  function: () async {
                                    await AuthMethods().signOut();
                                    if (context.mounted) {
                                      Navigator.of(context)
                                          .pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  },
                                ),
                              // 🆕 END: Add Sign Out button separately
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(top: 15),
                      child: Text(
                        userData!.username, // 🆕 Use model
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(userData!.bio), // 🆕 Use model
                    ),
                  ],
                ),
              ),
              const Divider(),
              // ✅ عرض بوستات المستخدم في GridView
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('uid', isEqualTo: widget.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final posts = snapshot.data!.docs;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: posts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 1.5,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      DocumentSnapshot snap = posts[index];
                      return SizedBox(
                        child: Image(
                          image: NetworkImage(snap['postUrl']),
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Column buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          num.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}