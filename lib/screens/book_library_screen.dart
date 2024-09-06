// lib/screens/book_library_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_writing_screen.dart';
import 'book_reader_screen.dart';
import 'book_config_screen.dart';
import '../widgets/side_drawer.dart';

class BookLibraryScreen extends StatefulWidget {
  @override
  _BookLibraryScreenState createState() => _BookLibraryScreenState();
}

class _BookLibraryScreenState extends State<BookLibraryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<DocumentSnapshot> _allBooks = [];
  List<DocumentSnapshot> _filteredBooks = [];
  String _searchQuery = '';
  String _selectedGenre = 'All';
  String _selectedTag = 'All';
  List<String> _genres = ['All'];
  List<String> _tags = ['All'];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        QuerySnapshot booksSnapshot = await _firestore
            .collection('books')
            .where('authorId', isEqualTo: userId)
            .orderBy('lastModified', descending: true)
            .get();

        setState(() {
          _allBooks = booksSnapshot.docs;
          _filteredBooks = _allBooks;
          _genres = ['All', ..._extractGenres(_allBooks)];
          _tags = ['All', ..._extractTags(_allBooks)];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading books: $e');
      setState(() => _isLoading = false);
    }
  }

  List<String> _extractGenres(List<DocumentSnapshot> books) {
    Set<String> genres = {};
    for (var book in books) {
      String genre = (book.data() as Map<String, dynamic>)['genre'] ?? 'Unknown';
      genres.add(genre);
    }
    return genres.toList()..sort();
  }

  List<String> _extractTags(List<DocumentSnapshot> books) {
    Set<String> tags = {};
    for (var book in books) {
      List<String> bookTags = List<String>.from((book.data() as Map<String, dynamic>)['tags'] ?? []);
      tags.addAll(bookTags);
    }
    return tags.toList()..sort();
  }

  void _filterBooks() {
    setState(() {
      _filteredBooks = _allBooks.where((book) {
        Map<String, dynamic> data = book.data() as Map<String, dynamic>;
        bool matchesSearch = data['title'].toLowerCase().contains(_searchQuery.toLowerCase());
        bool matchesGenre = _selectedGenre == 'All' || data['genre'] == _selectedGenre;
        bool matchesTag = _selectedTag == 'All' || (data['tags'] as List<dynamic>).contains(_selectedTag);
        return matchesSearch && matchesGenre && matchesTag;
      }).toList();
    });
  }

  void _deleteBook(String bookId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this book?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await _firestore.collection('books').doc(bookId).delete();
        _loadBooks();  // Reload the book list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Book deleted successfully')),
        );
      } catch (e) {
        print('Error deleting book: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting book: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Library'),
      ),
      drawer: SideDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search books',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _filterBooks();
                      });
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedGenre,
                          hint: Text('Select Genre'),
                          items: _genres.map((String genre) {
                            return DropdownMenuItem<String>(
                              value: genre,
                              child: Text(genre),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedGenre = newValue!;
                              _filterBooks();
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedTag,
                          hint: Text('Select Tag'),
                          items: _tags.map((String tag) {
                            return DropdownMenuItem<String>(
                              value: tag,
                              child: Text(tag),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedTag = newValue!;
                              _filterBooks();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: _filteredBooks.isEmpty
                      ? Center(child: Text('No books found.'))
                      : ListView.builder(
                          itemCount: _filteredBooks.length,
                          itemBuilder: (context, index) {
                            var book = _filteredBooks[index].data() as Map<String, dynamic>;
                            return Card(
                              elevation: 4,
                              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                leading: book['coverImage'] != null
                                    ? Image.network(
                                        book['coverImage'],
                                        width: 50,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Icon(Icons.book, size: 50),
                                      )
                                    : Icon(Icons.book, size: 50),
                                title: Text(book['title'] ?? 'Untitled', style: TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Genre: ${book['genre'] ?? 'Not specified'}'),
                                    Text('Chapters: ${book['chapterCount'] ?? 0}'),
                                    Text('Status: ${book['isPublished'] == true ? 'Published' : 'Draft'}'),
                                    Wrap(
                                      spacing: 4,
                                      children: (book['tags'] as List<dynamic>? ?? []).map((tag) => Chip(
                                        label: Text(tag, style: TextStyle(fontSize: 10)),
                                        padding: EdgeInsets.all(2),
                                      )).toList(),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BookConfigScreen(bookId: _filteredBooks[index].id),
                                          ),
                                        ).then((_) => _loadBooks());
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.book),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BookWritingScreen(bookId: _filteredBooks[index].id),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () => _deleteBook(_filteredBooks[index].id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookConfigScreen()),
          ).then((_) => _loadBooks());
        },
      ),
    );
  }
}