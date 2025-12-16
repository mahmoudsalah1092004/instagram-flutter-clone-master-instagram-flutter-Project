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
    String query = searchController.text.toLowerCase(); // لجعل البحث غير حساس لحروف كبيرة/صغيرة

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: TextFormField(
          controller: searchController,
          decoration: const InputDecoration(labelText: 'ابحث عن مستخدم...'),
          onChanged: (_) {
            setState(() {}); // إعادة بناء الشاشة مع كل حرف
          },
        ),
      ),
      body: query.isEmpty
          ? const Center(
              child: Text(
                'ابدأ بكتابة اسم المستخدم لعرض النتائج',
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
                      'لا يوجد مستخدم بهذا الاسم',
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
