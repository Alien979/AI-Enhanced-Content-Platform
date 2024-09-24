import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Book Writing Platform'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserProfileScreen()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Currently Reading',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildCurrentlyReadingSection(context),
              const SizedBox(height: 24),
              Text(
                'Your Books',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildYourBooksSection(context),
              const SizedBox(height: 24),
              Text(
                'Public Library',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildPublicLibrarySection(context),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/book_config');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Create New Book'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text('Public Library'),
            onTap: () {
              Navigator.pushNamed(context, '/public_library');
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('My Books'),
            onTap: () {
              Navigator.pushNamed(context, '/books');
            },
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Create New Book'),
            onTap: () {
              Navigator.pushNamed(context, '/book_config');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pushNamed(context, '/user_profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: () async {
              await _auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentlyReadingSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('books')
          .where('authorId', isEqualTo: _auth.currentUser?.uid)
          .where('status', isEqualTo: 'in_progress')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: ListTile(
              title: const Text('No book in progress'),
              subtitle: const Text('Start a new book to begin writing'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, '/book_config');
              },
            ),
          );
        }

        var bookData = snapshot.data!.docs.first.data() as Map<String, dynamic>?;
        if (bookData == null) {
          return const Card(
            child: ListTile(
              title: Text('Error loading book'),
              subtitle: Text('Please try again later'),
            ),
          );
        }

        String title = bookData['title'] as String? ?? 'Untitled';
        String coverUrl = bookData['coverUrl'] as String? ?? 'https://via.placeholder.com/50';
        int chapterCount = bookData['chapterCount'] as int? ?? 0;

        return Card(
          child: ListTile(
            leading: Image.network(
              coverUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[300],
                  child: const Icon(Icons.book, size: 25),
                );
              },
            ),
            title: Text(title),
            subtitle: Text('$chapterCount chapters'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/book_writing',
                arguments: {'bookId': snapshot.data!.docs.first.id},
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildYourBooksSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('books')
          .where('authorId', isEqualTo: _auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No books yet. Start writing!'));
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var bookData = snapshot.data!.docs[index].data() as Map<String, dynamic>?;

              if (bookData == null) {
                return const SizedBox.shrink(); // Skip this item if data is null
              }

              String title = bookData['title'] as String? ?? 'Untitled';
              String coverUrl = bookData['coverUrl'] as String? ?? 'https://via.placeholder.com/120x160';

              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/book_writing',
                    arguments: {'bookId': snapshot.data!.docs[index].id},
                  );
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.book, size: 50),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPublicLibrarySection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('books')
          .where('isPublished', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No public books available.'));
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var bookData = snapshot.data!.docs[index].data() as Map<String, dynamic>?;

              if (bookData == null) {
                return const SizedBox.shrink(); // Skip this item if data is null
              }

              String title = bookData['title'] as String? ?? 'Untitled';
              String coverUrl = bookData['coverUrl'] as String? ?? 'https://via.placeholder.com/120x160';

              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/book_reading',
                    arguments: {'bookId': snapshot.data!.docs[index].id},
                  );
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.book, size: 50),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> createBook(String title, String summary, String genre) async {
    try {
      await _firestore.collection('books').add({
        'title': title,
        'summary': summary,
        'genre': genre,
        'authorId': _auth.currentUser!.uid,
        'coverUrl': 'https://via.placeholder.com/120x160', // Default cover
        'chapterCount': 0,
        'status': 'in_progress',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating book: $e');
      rethrow;
    }
  }
}
