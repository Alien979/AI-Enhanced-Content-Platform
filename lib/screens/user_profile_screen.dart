// lib/screens/user_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_reader_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String? userId;

  UserProfileScreen({this.userId});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late String _userId;
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _userBooks = [];
  List<Map<String, dynamic>> _userReviews = [];
  bool _isLoading = true;
  bool _isEditing = false;
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId ?? _auth.currentUser!.uid;
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      // Load user data
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_userId).get();
      _userData = userDoc.data() as Map<String, dynamic>;
      _displayNameController.text = _userData['displayName'] ?? '';
      _bioController.text = _userData['bio'] ?? '';

      // Load user's books
      QuerySnapshot booksSnapshot = await _firestore.collection('books')
          .where('authorId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();
      _userBooks = booksSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // Load user's reviews
      QuerySnapshot reviewsSnapshot = await _firestore.collectionGroup('reviews')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();
      _userReviews = reviewsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    try {
      await _firestore.collection('users').doc(_userId).update({
        'displayName': _displayNameController.text,
        'bio': _bioController.text,
      });
      setState(() {
        _userData['displayName'] = _displayNameController.text;
        _userData['bio'] = _bioController.text;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile')));
    }
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Loading...' : 'Profile: ${_userData['displayName'] ?? 'User'}'),
        actions: [
          if (_userId == _auth.currentUser!.uid)
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _userData['photoURL'] != null
                            ? NetworkImage(_userData['photoURL'])
                            : null,
                        child: _userData['photoURL'] == null
                            ? Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_isEditing) ...[
                      TextField(
                        controller: _displayNameController,
                        decoration: InputDecoration(labelText: 'Display Name'),
                      ),
                      TextField(
                        controller: _bioController,
                        decoration: InputDecoration(labelText: 'Bio'),
                        maxLines: 3,
                      ),
                    ] else ...[
                      Text(_userData['displayName'] ?? 'User', style: Theme.of(context).textTheme.headlineMedium),
                      SizedBox(height: 8),
                      Text(_userData['bio'] ?? 'No bio available', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                    SizedBox(height: 24),
                    Text('Books Published', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 8),
                    _userBooks.isEmpty
                        ? Text('No books published yet.')
                        : Column(
                            children: _userBooks.map((book) => ListTile(
                              title: Text(book['title']),
                              subtitle: Text('Genre: ${book['genre']}'),
                              trailing: _buildRatingStars(book['averageRating'] ?? 0.0),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookReaderScreen(bookId: book['id']),
                                  ),
                                );
                              },
                            )).toList(),
                          ),
                    SizedBox(height: 24),
                    Text('Reviews Written', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 8),
                    _userReviews.isEmpty
                        ? Text('No reviews written yet.')
                        : Column(
                            children: _userReviews.map((review) => ListTile(
                              title: Text(review['bookTitle'] ?? 'Unknown Book'),
                              subtitle: Text(review['review']),
                              trailing: _buildRatingStars(review['rating'].toDouble()),
                            )).toList(),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}