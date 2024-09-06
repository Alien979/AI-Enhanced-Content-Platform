// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/book_config_screen.dart';
import 'screens/book_writing_screen.dart';
import 'screens/book_library_screen.dart';
import 'screens/public_library_screen.dart';
import 'screens/user_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyACSYlGC95BHsPkmEPontpj3xlAkMpNenA",
      authDomain: "monday-d7ae4.firebaseapp.com",
      projectId: "monday-d7ae4",
      storageBucket: "monday-d7ae4.appspot.com",
      messagingSenderId: "1086251428669",
      appId: "1:1086251428669:web:e425170d1f156b8c0a7354",
      measurementId: "G-1T94EZ9GMY",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Book Writing Platform',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data;
            if (user == null) {
              return LoginScreen();
            }
            return HomeScreen();
          }
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/books': (context) => BookLibraryScreen(),
        '/book_config': (context) => BookConfigScreen(),
        '/library': (context) => BookLibraryScreen(),
        '/public_library': (context) => PublicLibraryScreen(),
        '/user_profile': (context) => UserProfileScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/book_writing') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return BookWritingScreen(bookId: args['bookId']);
            },
          );
        }
        return null;
      },
    );
  }
}
