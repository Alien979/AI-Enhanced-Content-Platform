// lib/screens/book_writing_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ai_service.dart';
import 'book_preview_screen.dart';
import 'publish_book_screen.dart';
import 'ai_settings_screen.dart';
import 'book_statistics_screen.dart';
import 'book_reader_screen.dart';

class BookWritingScreen extends StatefulWidget {
  final String bookId;

  BookWritingScreen({required this.bookId});

  @override
  _BookWritingScreenState createState() => _BookWritingScreenState();
}

class _BookWritingScreenState extends State<BookWritingScreen> with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late TextEditingController _contentController;
  TextEditingController _promptController = TextEditingController();
  int _currentChapter = 1;
  int _totalChapters = 1;
  bool _isLoading = true;
  bool _isSaving = false;
  String _bookTitle = '';
  bool _isAILoading = false;
  int _initialWordCount = 0;
  String _aiGeneratedContent = '';
  List<String> _previousChapters = [];
  bool _isPublished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _contentController = TextEditingController();
    _loadBookData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _contentController.dispose();
    _promptController.dispose();
    _updateDailyWordCount();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveChapter();
      _updateDailyWordCount();
    }
  }

  Future<void> _loadBookData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot bookDoc = await _firestore.collection('books').doc(widget.bookId).get();
      Map<String, dynamic> bookData = bookDoc.data() as Map<String, dynamic>;
      
      if (mounted) {
        setState(() {
          _bookTitle = bookData['title'];
          _totalChapters = bookData['chapterCount'] ?? 1;
          _isPublished = bookData['isPublished'] ?? false;
          _isLoading = false;
        });
      }

      await _loadChapterContent();
    } catch (e) {
      print('Error loading book data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadChapterContent() async {
    if (!mounted) return;
    try {
      DocumentSnapshot chapterDoc = await _firestore
          .collection('books')
          .doc(widget.bookId)
          .collection('chapters')
          .doc(_currentChapter.toString())
          .get();

      if (chapterDoc.exists) {
        Map<String, dynamic> chapterData = chapterDoc.data() as Map<String, dynamic>;
        _contentController.text = chapterData['content'] ?? '';
      } else {
        _contentController.text = '';
      }

      _previousChapters = await _loadPreviousChapters();

      _initialWordCount = _contentController.text.split(RegExp(r'\s+')).length;
      if (mounted) setState(() {});
    } catch (e) {
      print('Error loading chapter content: $e');
    }
  }

  Future<List<String>> _loadPreviousChapters() async {
    List<String> chapters = [];
    for (int i = 1; i < _currentChapter; i++) {
      DocumentSnapshot prevChapterDoc = await _firestore
          .collection('books')
          .doc(widget.bookId)
          .collection('chapters')
          .doc(i.toString())
          .get();
      if (prevChapterDoc.exists) {
        chapters.add(prevChapterDoc['content']);
      }
    }
    return chapters;
  }

  Future<void> _saveChapter() async {
    if (!mounted) return;
    
    setState(() => _isSaving = true);
    
    try {
      await _firestore
          .collection('books')
          .doc(widget.bookId)
          .collection('chapters')
          .doc(_currentChapter.toString())
          .set({
        'content': _contentController.text,
        'lastModified': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore.collection('books').doc(widget.bookId).update({
        'chapterCount': _totalChapters,
        'lastModified': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chapter saved successfully')),
        );
      }
    } catch (e) {
      print('Error saving chapter: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving chapter: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateDailyWordCount() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    int currentWordCount = _contentController.text.split(RegExp(r'\s+')).length;
    int wordsWritten = currentWordCount - _initialWordCount;

    if (wordsWritten > 0) {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      DocumentReference dailyWordCountRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyWords')
          .doc(today.toIso8601String());

      await dailyWordCountRef.set({
        'date': today,
        'wordCount': FieldValue.increment(wordsWritten),
      }, SetOptions(merge: true));

      _initialWordCount = currentWordCount;
    }
  }

  Future<void> _getAIAssistance() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a prompt for AI assistance')),
      );
      return;
    }

    setState(() => _isAILoading = true);
    try {
      String aiSuggestion = await AIService.getAIAssistance(
        previousChapters: _previousChapters,
        currentChapter: _contentController.text,
        prompt: _promptController.text,
      );
      
      setState(() {
        _aiGeneratedContent = aiSuggestion;
        _isAILoading = false;
      });
    } catch (e) {
      print('Error getting AI assistance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting AI assistance: $e')),
      );
      setState(() => _isAILoading = false);
    }
  }

  void _insertAIContent() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      _aiGeneratedContent,
    );
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + _aiGeneratedContent.length),
    );
    setState(() {
      _aiGeneratedContent = '';
    });
  }

  void _navigateChapter(int direction) {
    _saveChapter();
    setState(() {
      _currentChapter += direction;
      if (_currentChapter > _totalChapters) {
        _totalChapters = _currentChapter;
      }
    });
    _loadChapterContent();
  }

  void _togglePublishStatus() async {
    try {
      await _firestore.collection('books').doc(widget.bookId).update({
        'isPublished': !_isPublished,
      });
      setState(() {
        _isPublished = !_isPublished;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isPublished ? 'Book published' : 'Book unpublished')),
      );
    } catch (e) {
      print('Error toggling publish status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating publish status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Loading...' : 'Writing: $_bookTitle'),
        actions: _buildAppBarActions(),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildBodyContent(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.save),
        onPressed: _isSaving ? null : _saveChapter,
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: Icon(_isPublished ? Icons.public_off : Icons.public),
        onPressed: _togglePublishStatus,
      ),
      IconButton(
        icon: Icon(Icons.settings),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AISettingsScreen()),
        ),
      ),
      IconButton(
        icon: Icon(Icons.bar_chart),
        onPressed: _isSaving ? null : () {
          _saveChapter();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookStatisticsScreen(bookId: widget.bookId),
            ),
          );
        },
      ),
      IconButton(
        icon: Icon(Icons.book),
        onPressed: _isSaving ? null : () {
          _saveChapter();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookReaderScreen(bookId: widget.bookId),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildBodyContent() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildWritingArea(),
        ),
        VerticalDivider(width: 1, thickness: 1),
        Expanded(
          flex: MediaQuery.of(context).size.width > 1200 ? 1 : 2,
          child: _buildAIAssistantArea(),
        ),
      ],
    );
  }

  Widget _buildWritingArea() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _contentController,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: 'Start writing your chapter here...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        _buildChapterNavigation(),
      ],
    );
  }

  Widget _buildChapterNavigation() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _currentChapter > 1 ? () => _navigateChapter(-1) : null,
          ),
          Text('Chapter $_currentChapter of $_totalChapters', 
               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () => _navigateChapter(1),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAssistantArea() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text('AI Assistant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          TextField(
            controller: _promptController,
            decoration: InputDecoration(
              hintText: 'Enter your prompt here...',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isAILoading ? null : _getAIAssistance,
            child: _isAILoading
                ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                : Text('Get AI Assistance'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: Text(_aiGeneratedContent),
              ),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _aiGeneratedContent.isNotEmpty ? _insertAIContent : null,
            child: Text('Insert AI Content'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}