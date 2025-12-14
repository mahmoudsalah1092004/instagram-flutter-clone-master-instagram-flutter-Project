// providers/user_provider.dart
import 'package:flutter/widgets.dart';
import 'package:instagram_clone_flutter/models/user.dart';
import 'package:instagram_clone_flutter/resources/auth_methods.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final AuthMethods _authMethods = AuthMethods();

  User? get getUser => _user;

  Future<void> refreshUser() async {
    final user = await _authMethods.getUserDetails();
    if (user != null) {
      _user = user;
      notifyListeners();
    } else {
      // لو مفيش user في Firestore
      debugPrint("⚠️ No user data found in Firestore for this account.");
    }
  }
}
