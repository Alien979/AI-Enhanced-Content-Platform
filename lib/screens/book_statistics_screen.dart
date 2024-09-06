// lib/screens/book_statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookStatisticsScreen extends StatefulWidget {
  final String bookId;

  BookStatisticsScreen({required this.bookId});

  @override
  _BookStatisticsScreenState createState() => _BookStatisticsScreenState();
}

class _BookStatisticsScreenState extends State<BookStatisticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic> _bookStats = {};

  @override
  void initState() {
    super.initState();
    _loadBookStatistics();
  }

  void _loadBookStatistics() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot bookDoc = await _firestore.collection('books').doc(widget.bookId).get();
      Map<String, dynamic> bookData = bookDoc.data() as Map<String, dynamic>;

      QuerySnapshot chaptersSnapshot = await _firestore
          .collection('books')
          .doc(widget.bookId)
          .collection('chapters')
          .get();

      int totalWords = 0;
      int totalCharacters = 0;
      for (var doc in chaptersSnapshot.docs) {
        String content = (doc.data() as Map<String, dynamic>)['content'] as String? ?? '';
        totalWords += content.split(' ').length;
        totalCharacters += content.length;
      }

      setState(() {
        _bookStats = {
          'title': bookData['title'] ?? 'Untitled',
          'chapterCount': bookData['chapterCount'] ?? 0,
          'totalWords': totalWords,
          'totalCharacters': totalCharacters,
          'averageWordsPerChapter': totalWords / (bookData['chapterCount'] ?? 1),
          'createdAt': bookData['createdAt'] as Timestamp? ?? Timestamp.now(),
          'lastModified': bookData['lastModified'] as Timestamp? ?? Timestamp.now(),
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading book statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Statistics'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_bookStats['title'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  _buildStatItem('Total Chapters', _bookStats['chapterCount'].toString()),
                  _buildStatItem('Total Words', _bookStats['totalWords'].toString()),
                  _buildStatItem('Total Characters', _bookStats['totalCharacters'].toString()),
                  _buildStatItem('Average Words per Chapter', _bookStats['averageWordsPerChapter'].toStringAsFixed(2)),
                  _buildStatItem('Created On', DateFormat('MMM d, yyyy').format(_bookStats['createdAt'].toDate())),
                  _buildStatItem('Last Modified', DateFormat('MMM d, yyyy').format(_bookStats['lastModified'].toDate())),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}