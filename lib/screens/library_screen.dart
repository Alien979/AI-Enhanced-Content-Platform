// lib/screens/library_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedGenre = 'All';
  List<String> _genres = ['All'];

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  void _loadGenres() async {
    try {
      var genresSnapshot = await _firestore.collection('genres').get();
      if (mounted) {
        setState(() {
          _genres = ['All', ...genresSnapshot.docs.map((doc) => doc['name'] as String)];
        });
      }
    } catch (e) {
      print('Error loading genres: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Library'),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildGenreDropdown(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                var books = snapshot.data!.docs;
                books = books.where((book) {
                  var data = book.data() as Map<String, dynamic>;
                  bool matchesSearch = data['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
                  bool matchesGenre = _selectedGenre == 'All' || data['genre'] == _selectedGenre;
                  return matchesSearch && matchesGenre;
                }).toList();

                return _buildBookGrid(books);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search books',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        value: _selectedGenre,
        isExpanded: true,
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
    );
  }

  Widget _buildBookGrid(List<QueryDocumentSnapshot> books) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        var book = books[index].data() as Map<String, dynamic>;
        return _buildBookCard(book, books[index].id);
      },
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book, String bookId) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookReaderScreen(bookId: bookId),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: book['coverImage'] != null
                  ? Image.network(
                      book['coverImage'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.book, size: 40, color: Colors.grey[600]),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.book, size: 40, color: Colors.grey[600]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book['title'] ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    book['authorName'] ?? 'Unknown author',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}