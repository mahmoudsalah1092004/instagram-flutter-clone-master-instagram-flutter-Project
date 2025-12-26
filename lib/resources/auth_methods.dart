// lib/resources/auth_methods.dart
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram_clone_flutter/models/user.dart' as model;
import 'package:instagram_clone_flutter/resources/storage_methods.dart';

class AuthMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ... (keep existing methods: getUserDetails, signUpUser, loginUser, signOut) ...

  // get user details (with check if doc exists)
  Future<model.User?> getUserDetails() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    DocumentSnapshot documentSnapshot =
        await _firestore.collection('users').doc(currentUser.uid).get();

    if (!documentSnapshot.exists) {
      return null;
    }

    return model.User.fromSnap(documentSnapshot);
  }

  // Signing Up User
  Future<String> signUpUser({
    required String email,
    required String password,
    required String username,
    required String bio,
    required Uint8List file,
  }) async {
    String res = "Some error Occurred";
    try {
      if (email.isNotEmpty &&
          password.isNotEmpty &&
          username.isNotEmpty &&
          bio.isNotEmpty) {
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        String photoUrl = await StorageMethods()
            .uploadImageToStorage('profilePics', file, false);

        model.User user = model.User(
          username: username,
          uid: cred.user!.uid,
          photoUrl: photoUrl,
          email: email,
          bio: bio,
          followers: [],
          following: [],
        );

        await _firestore.collection("users").doc(cred.user!.uid).set(user.toJson());

        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  // Logging in user
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error Occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  // Sign out user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // START: Add updateUserData method
  Future<String> updateUserData({
    required String uid,
    required String username,
    required String bio,
    Uint8List? file, // Make file optional
  }) async {
    String res = "Some error Occurred";
    try {
      String? photoUrl;

      // If a new file is provided, upload it and get the URL
      if (file != null) {
        photoUrl = await StorageMethods()
            .uploadImageToStorage('profilePics', file, false);
      }

      // Create a map of data to update
      Map<String, dynamic> userData = {
        'username': username,
        'bio': bio,
      };

      // If a new photoUrl was generated, add it to the map
      if (photoUrl != null) {
        userData['photoUrl'] = photoUrl;
      }

      // Update the user document in Firestore
      await _firestore.collection('users').doc(uid).update(userData);

      // Note: You might also want to update the username/profImage
      // in all existing posts and comments by this user.
      // This is a more complex operation, often done using Cloud Functions
      // for consistency, but for this feature, we'll just update the user's profile.

      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }
  // 🆕 END: Add updateUserData method
}