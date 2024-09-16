import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_reader_screen.dart';
import 'review_screen.dart';

class PublicLibraryScreen extends StatefulWidget {
  const PublicLibraryScreen({super.key});

  @override
  _PublicLibraryScreenState createState() => _PublicLibraryScreenState();
}

class _PublicLibraryScreenState extends State<PublicLibraryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _searchQuery = '';
  String _selectedGenre = 'All';
  List<String> _genres = ['All'];

  final Color primaryColor = const Color(0xFF6200EE);
  final Color secondaryColor = const Color(0xFF03DAC6);
  final Color backgroundColor = const Color(0xFFF5F5F5);
  final Color textColor = const Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  void _loadGenres() async {
    try {
      var genresSnapshot = await _firestore.collection('genres').get();
      setState(() {
        _genres = ['All', ...genresSnapshot.docs.map((doc) => doc['name'] as String)];
      });
    } catch (e) {
      print('Error loading genres: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Public Library', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildGenreDropdown(),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('books')
                  .where('isPublished', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No published books available.', style: TextStyle(color: textColor)));
                }

                var books = snapshot.data!.docs;

                books = books.where((book) {
                  var data = book.data() as Map<String, dynamic>;
                  bool matchesSearch = data['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
                  bool matchesGenre = _selectedGenre == 'All' || data['genre'] == _selectedGenre;
                  return matchesSearch && matchesGenre;
                }).toList();

                return _buildBookList(books);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search books...',
          prefixIcon: Icon(Icons.search, color: primaryColor),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildGenreDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Select Genre',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        value: _selectedGenre,
        items: _genres.map((String genre) {
          return DropdownMenuItem<String>(
            value: genre,
            child: Text(genre),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedGenre = newValue ?? 'All';
          });
        },
      ),
    );
  }

  Widget _buildBookList(List<QueryDocumentSnapshot> books) {
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        var book = books[index].data() as Map<String, dynamic>;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: book['coverUrl'] != null
                ? Image.network(book['coverUrl'], width: 60, height: 90, fit: BoxFit.cover)
                : Icon(Icons.book, size: 60, color: primaryColor),
            title: Text(book['title'] ?? 'Untitled', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Author: ${book['authorName'] ?? 'Unknown'} | Genre: ${book['genre'] ?? 'Not specified'}',
                    style: TextStyle(color: textColor.withOpacity(0.7))),
                _buildRatingStars(book['averageRating'] ?? 0.0),
              ],
            ),
            trailing: _buildBookActions(books[index].id, book),
            onTap: () => _showBookDetails(book),
          ),
        );
      },
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

  Widget _buildBookActions(String bookId, Map<String, dynamic> book) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.book, color: primaryColor),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookReaderScreen(bookId: bookId),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.file_copy, color: primaryColor),
          onPressed: () => _importBook(bookId),
        ),
        IconButton(
          icon: Icon(Icons.rate_review, color: primaryColor),
          onPressed: () => _showReviewDialog(bookId, book['title']),
        ),
      ],
    );
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
        SnackBar(content: const Text('Book imported successfully'), backgroundColor: secondaryColor),
      );
    } catch (e) {
      print('Error importing book: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error importing book'), backgroundColor: Colors.red),
      );
    }
  }

  void _showBookDetails(Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(book['title'] ?? 'Untitled'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Author: ${book['authorName'] ?? 'Unknown'}'),
                Text('Genre: ${book['genre'] ?? 'Not specified'}'),
                Text('Summary: ${book['summary'] ?? 'No summary available'}'),
                Text('Rating: ${book['averageRating']?.toStringAsFixed(1) ?? 'Not rated'}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showReviewDialog(String bookId, String bookTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(bookId: bookId, bookTitle: bookTitle),
      ),
    );
  }
}
