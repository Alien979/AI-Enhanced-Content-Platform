// lib/screens/library_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_writing_screen.dart';
import 'book_reader_screen.dart';
import 'book_config_screen.dart';

class LibraryScreen extends StatefulWidget {
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _personalBooks = [];
  List<Map<String, dynamic>> _filteredPersonalBooks = [];
  List<Map<String, dynamic>> _publicBooks = [];
  List<Map<String, dynamic>> _filteredPublicBooks = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBooks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      String userId = _auth.currentUser!.uid;
      
      // Load personal books
      QuerySnapshot personalBooksSnapshot = await _firestore
          .collection('books')
          .where('authorId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      _personalBooks = personalBooksSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Load public books
      QuerySnapshot publicBooksSnapshot = await _firestore
          .collection('books')
          .where('isPublished', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .limit(50)
          .get();

      _publicBooks = publicBooksSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      _filteredPersonalBooks = List.from(_personalBooks);
      _filteredPublicBooks = List.from(_publicBooks);
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading books: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load books. Please try again.');
    }
  }

  void _filterBooks(String query) {
    setState(() {
      _filteredPersonalBooks = _personalBooks.where((book) =>
          book['title'].toLowerCase().contains(query.toLowerCase())).toList();
      _filteredPublicBooks = _publicBooks.where((book) =>
          book['title'].toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Library'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'My Books'),
            Tab(text: 'Public Books'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadBooks,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search books',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _filterBooks,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookGrid(_filteredPersonalBooks, isPersonal: true),
                _buildBookGrid(_filteredPublicBooks, isPersonal: false),
              ],
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

  Widget _buildBookGrid(List<Map<String, dynamic>> books, {required bool isPersonal}) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : books.isEmpty
            ? Center(child: Text('No books found'))
            : GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  var book = books[index];
                  return _buildBookCard(book, isPersonal: isPersonal);
                },
              );
  }

  Widget _buildBookCard(Map<String, dynamic> book, {required bool isPersonal}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => isPersonal ? _showBookOptions(book) : _navigateToBookReader(book['id']),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.network(
                book['coverUrl'] ?? 'https://via.placeholder.com/150x200',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book['title'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${book['chapterCount']} chapters',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isPersonal ? (book['isPublished'] ? 'Published' : 'Draft') : 'By ${book['authorName']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPersonal ? (book['isPublished'] ? Colors.green : Colors.orange) : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookOptions(Map<String, dynamic> book) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookWritingScreen(bookId: book['id']),
                    ),
                  ).then((_) => _loadBooks());
                },
              ),
              ListTile(
                leading: Icon(Icons.book),
                title: Text('Read'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToBookReader(book['id']);
                },
              ),
              if (!book['isPublished'])
                ListTile(
                  leading: Icon(Icons.publish),
                  title: Text('Publish'),
                  onTap: () {
                    Navigator.pop(context);
                    _publishBook(book['id']);
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteBook(book['id']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToBookReader(String bookId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookReaderScreen(bookId: bookId),
      ),
    );
  }

  void _publishBook(String bookId) async {
    try {
      await _firestore.collection('books').doc(bookId).update({
        'isPublished': true,
        'publishedAt': FieldValue.serverTimestamp(),
      });
      _loadBooks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Book published successfully')),
      );
    } catch (e) {
      print('Error publishing book: $e');
      _showErrorSnackBar('Failed to publish book. Please try again.');
    }
  }

  void _deleteBook(String bookId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this book?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await _firestore.collection('books').doc(bookId).delete();
        _loadBooks();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Book deleted successfully')),
        );
      } catch (e) {
        print('Error deleting book: $e');
        _showErrorSnackBar('Failed to delete book. Please try again.');
      }
    }
  }
}