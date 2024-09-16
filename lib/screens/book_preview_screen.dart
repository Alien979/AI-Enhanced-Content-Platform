// lib/screens/book_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookPreviewScreen extends StatefulWidget {
  final String bookId;

  const BookPreviewScreen({super.key, required this.bookId});

  @override
  _BookPreviewScreenState createState() => _BookPreviewScreenState();
}

class _BookPreviewScreenState extends State<BookPreviewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String _bookTitle = '';
  final List<String> _chapters = [];

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
      });

      await _loadChapters(bookData['chapterCount'] ?? 0);
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading book data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChapters(int chapterCount) async {
    _chapters.clear();
    for (int i = 1; i <= chapterCount; i++) {
      DocumentSnapshot chapterDoc = await _firestore
          .collection('books')
          .doc(widget.bookId)
          .collection('chapters')
          .doc(i.toString())
          .get();

      if (chapterDoc.exists) {
        Map<String, dynamic> data = chapterDoc.data() as Map<String, dynamic>;
        _chapters.add(data['content'] as String);
      } else {
        _chapters.add('');  // Empty string for non-existent chapters
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Loading...' : 'Preview: $_bookTitle'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _chapters.length,
              itemBuilder: (context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Chapter ${index + 1}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_chapters[index]),
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
    );
  }
}