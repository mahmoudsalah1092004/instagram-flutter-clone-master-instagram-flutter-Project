// main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/providers/user_provider.dart';
import 'package:instagram_clone_flutter/responsive/mobile_screen_layout.dart';
import 'package:instagram_clone_flutter/responsive/responsive_layout.dart';
import 'package:instagram_clone_flutter/responsive/web_screen_layout.dart';
import 'package:instagram_clone_flutter/screens/login_screen.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint("🚀 App starting...");

  try {
    // initialise app based on platform- web or mobile
    if (kIsWeb) {
      debugPrint("🌐 Initializing Firebase for Web...");
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCZ-xrXqD5D19Snauto-Fx_nLD7PLrBXGM",
          appId: "1:585119731880:web:eca6e4b3c42a755cee329d",
          messagingSenderId: "585119731880",
          projectId: "instagram-clone-4cea4",
          storageBucket: 'instagram-clone-4cea4.appspot.com',
        ),
      );
    } else {
      debugPrint("📱 Initializing Firebase for Android...");
      await Firebase.initializeApp();
    }

    debugPrint("✅ Firebase initialized successfully!");
  } catch (e) {
    debugPrint("❌ Firebase initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Instagram Clone',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: mobileBackgroundColor,
        ),
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            debugPrint("🔥 Snapshot state: ${snapshot.connectionState}");
            debugPrint("🔥 Has data: ${snapshot.hasData}");
            debugPrint("🔥 Has error: ${snapshot.hasError}");

            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData) {
                debugPrint("✅ User is logged in!");
                return const ResponsiveLayout(
                  mobileScreenLayout: MobileScreenLayout(),
                  webScreenLayout: WebScreenLayout(),
                );
              } else if (snapshot.hasError) {
                debugPrint("❌ Error: ${snapshot.error}");
                return Center(child: Text('${snapshot.error}'));
              } else {
                debugPrint("👤 No user logged in, going to LoginScreen");
              }
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              debugPrint("⏳ Waiting for connection...");
              return const Center(child: CircularProgressIndicator());
            }

            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
