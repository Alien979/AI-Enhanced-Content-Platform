// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/side_drawer.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  int _totalBooks = 0;
  int _totalChapters = 0;
  int _totalWords = 0;
  Map<String, int> _genreDistribution = {};
  List<Map<String, dynamic>> _recentBooks = [];
  int _dailyWordGoal = 0;
  int _wordsWrittenToday = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await Future.wait([
          _loadBooks(userId),
          _loadWritingGoal(userId),
          _loadTodayWords(userId),
        ]);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBooks(String userId) async {
    QuerySnapshot booksSnapshot = await _firestore
        .collection('books')
        .where('authorId', isEqualTo: userId)
        .get();

    _totalBooks = booksSnapshot.docs.length;
    _genreDistribution = {};
    _recentBooks = [];

    for (var bookDoc in booksSnapshot.docs) {
      Map<String, dynamic> bookData = bookDoc.data() as Map<String, dynamic>;
      _totalChapters += bookData['chapterCount'] as int? ?? 0;
      
      String genre = bookData['genre'] as String? ?? 'Unknown';
      _genreDistribution[genre] = (_genreDistribution[genre] ?? 0) + 1;

      QuerySnapshot chaptersSnapshot = await bookDoc.reference.collection('chapters').get();
      for (var chapterDoc in chaptersSnapshot.docs) {
        String content = (chapterDoc.data() as Map<String, dynamic>)['content'] as String? ?? '';
        _totalWords += content.split(' ').length;
      }

      if (_recentBooks.length < 5) {
        _recentBooks.add({
          'title': bookData['title'],
          'lastModified': (bookData['lastModified'] as Timestamp).toDate(),
        });
      }
    }

    _recentBooks.sort((a, b) => b['lastModified'].compareTo(a['lastModified']));
  }

  Future<void> _loadWritingGoal(String userId) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      _dailyWordGoal = userData['dailyWordGoal'] as int? ?? 0;
    }
  }

  Future<void> _loadTodayWords(String userId) async {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));

    QuerySnapshot todayWordsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyWords')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .get();

    if (todayWordsSnapshot.docs.isNotEmpty) {
      _wordsWrittenToday = todayWordsSnapshot.docs.first['wordCount'] as int? ?? 0;
    }
  }

  void _setDailyWordGoal() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    TextEditingController _controller = TextEditingController(text: _dailyWordGoal.toString());
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Daily Word Goal'),
        content: TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Daily Word Goal'),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () async {
              int? newGoal = int.tryParse(_controller.text);
              if (newGoal != null && newGoal > 0) {
                await _firestore.collection('users').doc(userId).set({
                  'dailyWordGoal': newGoal,
                }, SetOptions(merge: true));
                setState(() {
                  _dailyWordGoal = newGoal;
                });
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      drawer: SideDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Writing Statistics', style: Theme.of(context).textTheme.headline5),
                    SizedBox(height: 16),
                    _buildStatCard('Total Books', _totalBooks.toString()),
                    _buildStatCard('Total Chapters', _totalChapters.toString()),
                    _buildStatCard('Total Words', _totalWords.toString()),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Daily Word Goal', style: Theme.of(context).textTheme.headline6),
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: _setDailyWordGoal,
                        ),
                      ],
                    ),
                    LinearProgressIndicator(
                      value: _dailyWordGoal > 0 ? _wordsWrittenToday / _dailyWordGoal : 0,
                      minHeight: 10,
                    ),
                    Text('${_wordsWrittenToday} / ${_dailyWordGoal} words'),
                    SizedBox(height: 24),
                    Text('Genre Distribution', style: Theme.of(context).textTheme.headline6),
                    SizedBox(height: 8),
                    ..._genreDistribution.entries.map((entry) => 
                      _buildGenreBar(entry.key, entry.value, _totalBooks)
                    ),
                    SizedBox(height: 24),
                    Text('Recent Books', style: Theme.of(context).textTheme.headline6),
                    SizedBox(height: 8),
                    ..._recentBooks.map((book) => 
                      ListTile(
                        title: Text(book['title']),
                        subtitle: Text('Last modified: ${DateFormat('MMM d, yyyy').format(book['lastModified'])}'),
                      )
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.subtitle1),
            SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headline4),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreBar(String genre, int count, int total) {
    double percentage = count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(genre),
          ),
          Expanded(
            flex: 7,
            child: Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Text('${(percentage * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}