// lib/screens/publish_book_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublishBookScreen extends StatefulWidget {
  final String bookId;

  const PublishBookScreen({super.key, required this.bookId});

  @override
  _PublishBookScreenState createState() => _PublishBookScreenState();
}

class _PublishBookScreenState extends State<PublishBookScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic> _bookData = {};

  @override
  void initState() {
    super.initState();
    _loadBookData();
  }

  void _loadBookData() async {
    try {
      DocumentSnapshot bookDoc = await _firestore.collection('books').doc(widget.bookId).get();
      setState(() {
        _bookData = bookDoc.data() as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading book data: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading book data. Please try again.')),
      );
    }
  }

  void _publishBook() async {
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('books').doc(widget.bookId).update({
        'isPublished': true,
        'publishedDate': FieldValue.serverTimestamp(),
      });
      setState(() {
        _bookData['isPublished'] = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book published successfully!')),
      );
    } catch (e) {
      print('Error publishing book: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error publishing book. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish Book'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _bookData['title'] ?? 'Untitled',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text('Author: ${_bookData['authorName'] ?? 'Unknown'}'),
                  Text('Genre: ${_bookData['genre'] ?? 'Unspecified'}'),
                  Text('Chapters: ${_bookData['chapterCount'] ?? 0}'),
                  const SizedBox(height: 24),
                  Text(
                    'Book Preview',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    child: ListTile(
                      leading: Image.network(
                        _bookData['coverUrl'] ?? 'https://via.placeholder.com/50x80',
                        width: 50,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                      title: Text(_bookData['title'] ?? 'Untitled'),
                      subtitle: Text(_bookData['authorName'] ?? 'Unknown'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Publishing your book will make it visible to other users in the Public Library. '
                    'Make sure you have completed all chapters and reviewed your content before publishing.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: _bookData['isPublished'] == true
                        ? const Text(
                            'This book is already published!',
                            style: TextStyle(fontSize: 18, color: Colors.green),
                          )
                        : ElevatedButton(
                            onPressed: _publishBook,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                            child: Text('Publish Book'),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}