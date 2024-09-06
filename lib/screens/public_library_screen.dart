// lib/screens/public_library_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_reader_screen.dart';
import 'review_screen.dart';

class PublicLibraryScreen extends StatefulWidget {
  @override
  _PublicLibraryScreenState createState() => _PublicLibraryScreenState();
}

class _PublicLibraryScreenState extends State<PublicLibraryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _searchQuery = '';
  String _selectedGenre = 'All';
  List<String> _genres = ['All'];

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  void _loadGenres() async {
    var genresSnapshot = await _firestore.collection('genres').get();
    setState(() {
      _genres = ['All', ...genresSnapshot.docs.map((doc) => doc['name'] as String)];
    });
  }

  Future<void> _importBook(String bookId) async {
    try {
      DocumentSnapshot bookDoc = await _firestore.collection('books').doc(bookId).get();
      Map<String, dynamic> bookData = bookDoc.data() as Map<String, dynamic>;
      
      await _firestore.collection('books').add({
        ...bookData,
        'authorId': _auth.currentUser!.uid,
        'originalAuthorId': bookData['authorId'],
        'isPublished': false,
        'importedFrom': bookId,
        'importedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Book imported successfully')),
      );
    } catch (e) {
      print('Error importing book: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing book')),
      );
    }
  }

  void _showReviewDialog(String bookId, String bookTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(bookId: bookId, bookTitle: bookTitle),
      ),
    );
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
        title: Text('Public Library'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search books...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          DropdownButton<String>(
            value: _selectedGenre,
            items: _genres.map((String genre) {
              return DropdownMenuItem<String>(
                value: genre,
                child: Text(genre),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedGenre = newValue!;
              });
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('books')
                  .where('isPublished', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No published books available.'));
                }

                var books = snapshot.data!.docs;
                books = books.where((book) {
                  var data = book.data() as Map<String, dynamic>;
                  bool matchesSearch = data['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
                  bool matchesGenre = _selectedGenre == 'All' || data['genre'] == _selectedGenre;
                  return matchesSearch && matchesGenre;
                }).toList();

                return ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    var book = books[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(book['title']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Author: ${book['authorName']} | Genre: ${book['genre']}'),
                          _buildRatingStars(book['averageRating'] ?? 0.0),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.book),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookReaderScreen(bookId: books[index].id),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.file_copy),
                            onPressed: () => _importBook(books[index].id),
                          ),
                          IconButton(
                            icon: Icon(Icons.rate_review),
                            onPressed: () => _showReviewDialog(books[index].id, book['title']),
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(book['title']),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: <Widget>[
                                    Text('Author: ${book['authorName']}'),
                                    Text('Genre: ${book['genre']}'),
                                    Text('Summary: ${book['summary']}'),
                                    Text('Rating: ${book['averageRating']?.toStringAsFixed(1) ?? 'Not rated'}'),
                                  ],
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('Close'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}