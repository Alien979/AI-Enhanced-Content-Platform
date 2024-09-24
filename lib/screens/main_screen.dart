// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';
import 'book_library_screen.dart';
import 'library_screen.dart';
import 'user_profile_screen.dart';
import 'book_config_screen.dart';
import 'book_writing_guide_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const BookLibraryScreen(),
    const LibraryScreen(),
    const UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'My Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        onPressed: () {
          _showWritingOptions(context);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showWritingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Start New Book'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BookConfigScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Continue Writing'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToLastBook(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToLastBook(BuildContext context) async {
    try {
      String userId = _auth.currentUser!.uid;
      QuerySnapshot booksSnapshot = await _firestore
          .collection('books')
          .where('authorId', isEqualTo: userId)
          .orderBy('lastModified', descending: true)
          .limit(1)
          .get();

      if (booksSnapshot.docs.isNotEmpty) {
        String bookId = booksSnapshot.docs.first.id;
        Navigator.pushNamed(
          context,
          '/book_writing_guide',
          arguments: {'bookId': bookId},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No books found. Start a new book!')),
        );
      }
    } catch (e) {
      print('Error navigating to last book: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading last book. Please try again.')),
      );
    }
  }
}