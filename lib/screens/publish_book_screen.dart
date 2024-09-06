// lib/screens/publish_book_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublishBookScreen extends StatefulWidget {
  final String bookId;

  PublishBookScreen({required this.bookId});

  @override
  _PublishBookScreenState createState() => _PublishBookScreenState();
}

class _PublishBookScreenState extends State<PublishBookScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String _bookTitle = '';
  int _chapterCount = 0;
  bool _isPublished = false;

  @override
  void initState() {
    super.initState();
    _loadBookData();
  }

  void _loadBookData() async {
    try {
      DocumentSnapshot bookDoc = await _firestore.collection('books').doc(widget.bookId).get();
      Map<String, dynamic> bookData = bookDoc.data() as Map<String, dynamic>;
      
      setState(() {
        _bookTitle = bookData['title'];
        _chapterCount = bookData['chapterCount'] ?? 0;
        _isPublished = bookData['isPublished'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading book data: $e');
      setState(() => _isLoading = false);
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
        _isPublished = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Book published successfully!')),
      );
    } catch (e) {
      print('Error publishing book: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error publishing book. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Publish Book'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _bookTitle,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text('Number of Chapters: $_chapterCount'),
                  SizedBox(height: 32),
                  _isPublished
                      ? Text(
                          'This book is already published!',
                          style: TextStyle(fontSize: 18, color: Colors.green),
                        )
                      : ElevatedButton(
                          onPressed: _publishBook,
                          child: Text('Publish Book'),
                        ),
                  SizedBox(height: 16),
                  Text(
                    'Publishing your book will make it visible to other users. '
                    'Make sure you have completed all chapters and reviewed your content before publishing.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
    );
  }
}