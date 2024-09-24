import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
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
import 'screens/onboarding_screen.dart';
import 'screens/book_writing_guide_screen.dart';
import 'providers/writing_mode_provider.dart';

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
  runApp(
    ChangeNotifierProvider(
      create: (context) => WritingModeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Book Writing Platform',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(secondary: Colors.blueAccent),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/books': (context) => const BookLibraryScreen(),
        '/book_config': (context) => const BookConfigScreen(),
        '/library': (context) => const LibraryScreen(),
        '/user_profile': (context) => const UserProfileScreen(),
        '/ai_settings': (context) => const AISettingsScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;
        switch (settings.name) {
          case '/book_writing':
            return MaterialPageRoute(
              builder: (context) => BookWritingScreen(bookId: args?['bookId']),
            );
          case '/book_statistics':
            return MaterialPageRoute(
              builder: (context) =>
                  BookStatisticsScreen(bookId: args?['bookId']),
            );
          case '/book_reader':
            return MaterialPageRoute(
              builder: (context) => BookReaderScreen(bookId: args?['bookId']),
            );
          case '/publish_book':
            return MaterialPageRoute(
              builder: (context) => PublishBookScreen(bookId: args?['bookId']),
            );
          case '/book_writing_guide':
            return MaterialPageRoute(
              builder: (context) =>
                  BookWritingGuideScreen(bookId: args?['bookId']),
            );
          default:
            return null;
        }
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final prefs = snapshot.data;
          final onboardingComplete =
              prefs?.getBool('onboarding_complete') ?? false;

          if (!onboardingComplete) {
            return const OnboardingScreen();
          }

          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                User? user = snapshot.data;
                if (user == null) {
                  return const LoginScreen();
                }
                return const MainScreen();
              }
              return const SplashScreen();
            },
          );
        }
        return const SplashScreen();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text('Loading...', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
