// screens/search_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/screens/profile_screen.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    String query = searchController.text.toLowerCase(); 

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: TextFormField(
          controller: searchController,
          decoration: const InputDecoration(labelText: 'Search for a user...'),
          onChanged: (_) {
            setState(() {}); 
          },
        ),
      ),
      body: query.isEmpty
          ? const Center(
              child: Text(
                'Start by typing your username to view the results',
                style: TextStyle(color: Colors.white),
              ),
            )
          : FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('username', isGreaterThanOrEqualTo: query)
                  .where('username', isLessThanOrEqualTo: '$query\uf8ff')
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final users = (snapshot.data! as dynamic).docs;
                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'No user found with this username',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(uid: user['uid']),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(user['photoUrl']),
                          radius: 16,
                        ),
                        title: Text(user['username']),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
