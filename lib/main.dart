// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/book_config_screen.dart';
import 'screens/book_writing_screen.dart';
import 'screens/book_library_screen.dart';
import 'screens/library_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/ai_settings_screen.dart';
import 'screens/book_statistics_screen.dart';
import 'screens/book_reader_screen.dart';
import 'screens/publish_book_screen.dart';
import 'screens/main_screen.dart';

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
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(secondary: Colors.blueAccent),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
          displayLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87),
          displayMedium: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.black87),
          displaySmall: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black87),
          headlineMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87),
          headlineSmall: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87),
          titleLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 14.0, color: Colors.black54),
          bodyMedium: TextStyle(fontSize: 12.0, color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
      ),
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => MainScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/books': (context) => BookLibraryScreen(),
        '/book_config': (context) => BookConfigScreen(),
        '/library': (context) => LibraryScreen(),
        '/user_profile': (context) => UserProfileScreen(),
        '/ai_settings': (context) => AISettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/book_writing') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => BookWritingScreen(bookId: args['bookId']),
          );
        }
        if (settings.name == '/book_statistics') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => BookStatisticsScreen(bookId: args['bookId']),
          );
        }
        if (settings.name == '/book_reader') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => BookReaderScreen(bookId: args['bookId']),
          );
        }
        if (settings.name == '/publish_book') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PublishBookScreen(bookId: args['bookId']),
          );
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return LoginScreen();
          }
          return MainScreen();
        }
        return SplashScreen();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading...', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;

  ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red),
        ),
      ),
    );
  }
}