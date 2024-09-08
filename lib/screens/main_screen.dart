// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';
import 'book_library_screen.dart';
import 'library_screen.dart';
import 'user_profile_screen.dart';
import 'book_config_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0;
  final List<Widget> _screens = [
    DashboardScreen(),
    BookLibraryScreen(),
    LibraryScreen(),
    UserProfileScreen(),
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
        items: [
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
        child: Icon(Icons.edit),
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
                leading: Icon(Icons.add),
                title: Text('Start New Book'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BookConfigScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Continue Writing'),
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

  void _navigateToLastBook(BuildContext context) {
    // TODO: Implement logic to get the last book the user was working on
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to last book... (To be implemented)')),
    );
  }
}