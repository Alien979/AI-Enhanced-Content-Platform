// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'public_library_screen.dart';
import 'user_profile_screen.dart';
import 'book_library_screen.dart';
import 'book_config_screen.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Book Writing Platform'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfileScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.library_books),
              title: Text('Public Library'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PublicLibraryScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.book),
              title: Text('My Books'),
              onTap: () {
                Navigator.pushNamed(context, '/books');
              },
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Create New Book'),
              onTap: () {
                Navigator.pushNamed(context, '/book_config');
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('My Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () async {
                await _auth.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to AI Book Writing Platform',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Start writing your next bestseller!',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              child: Text('My Books'),
              onPressed: () {
                Navigator.of(context).pushNamed('/books');
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Create New Book'),
              onPressed: () {
                Navigator.of(context).pushNamed('/book_config');
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Public Library'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PublicLibraryScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}