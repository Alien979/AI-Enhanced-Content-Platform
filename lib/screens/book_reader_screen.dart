// lib/screens/book_reader_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookReaderScreen extends StatefulWidget {
  final String bookId;

  BookReaderScreen({required this.bookId});

  @override
  _BookReaderScreenState createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String _bookTitle = '';
  List<String> _chapters = [];
  int _currentChapterIndex = 0;
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadBookData();
  }

  void _loadBookData() async {
    try {
      DocumentSnapshot bookDoc = await _firestore.collection('books').doc(widget.bookId).get();
      Map<String, dynamic> bookData = bookDoc.data() as Map<String, dynamic>;
      
      QuerySnapshot chaptersSnapshot = await _firestore
          .collection('books')
          .doc(widget.bookId)
          .collection('chapters')
          .orderBy(FieldPath.documentId)
          .get();

      List<String> chapters = chaptersSnapshot.docs
          .map((doc) => doc['content'] as String)
          .toList();

      setState(() {
        _bookTitle = bookData['title'];
        _chapters = chapters;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading book data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _nextChapter() {
    if (_currentChapterIndex < _chapters.length - 1) {
      setState(() {
        _currentChapterIndex++;
      });
    }
  }

  void _previousChapter() {
    if (_currentChapterIndex > 0) {
      setState(() {
        _currentChapterIndex--;
      });
    }
  }

  void _changeFontSize(double size) {
    setState(() {
      _fontSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Loading...' : _bookTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.text_fields),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Adjust Font Size'),
                    content: Slider(
                      value: _fontSize,
                      min: 12.0,
                      max: 24.0,
                      divisions: 6,
                      label: _fontSize.round().toString(),
                      onChanged: (double value) {
                        _changeFontSize(value);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      _chapters[_currentChapterIndex],
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _currentChapterIndex > 0 ? _previousChapter : null,
                        child: Text('Previous Chapter'),
                      ),
                      Text('Chapter ${_currentChapterIndex + 1}'),
                      ElevatedButton(
                        onPressed: _currentChapterIndex < _chapters.length - 1 ? _nextChapter : null,
                        child: Text('Next Chapter'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}