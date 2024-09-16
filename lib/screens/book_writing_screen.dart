import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/chapter_sidebar.dart';
import '../models/book.dart';
import '../providers/writing_mode_provider.dart';
import 'book_statistics_screen.dart';

class BookWritingScreen extends StatefulWidget {
  final String bookId;

  BookWritingScreen({required this.bookId});

  @override
  _BookWritingScreenState createState() => _BookWritingScreenState();
}

class _BookWritingScreenState extends State<BookWritingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TextEditingController _contentController;
  late TextEditingController _aiPromptController;
  Book? _book;
  int _currentChapter = 1;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAILoading = false;
  List<String> _previousChapters = [];
  String _aiGeneratedContent = '';

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _aiPromptController = TextEditingController();
    _loadBookData();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  Future<void> _loadBookData() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot bookDoc = await _firestore.collection('books').doc(widget.bookId).get();
      _book = Book.fromFirestore(bookDoc);
      _currentChapter = _book?.currentChapter ?? 1;
      await _loadChapters();
    } catch (e) {
      _showErrorSnackBar('Error loading book data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChapters() async {
    try {
      QuerySnapshot chaptersSnapshot = await _firestore
          .collection('books')
          .doc(widget.bookId)
          .collection('chapters')
          .orderBy('chapterNumber')
          .get();

      _previousChapters = [];
      for (var doc in chaptersSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['chapterNumber'] != _currentChapter) {
          _previousChapters.add(data['content'] ?? '');
        } else {
          _contentController.text = data['content'] ?? '';
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error loading chapters: $e');
    }
  }

  Future<void> _saveChapter() async {
    setState(() => _isSaving = true);
    try {
      await _firestore
          .collection('books')
          .doc(widget.bookId)
          .collection('chapters')
          .doc(_currentChapter.toString())
          .set({
        'content': _contentController.text,
        'chapterNumber': _currentChapter,
        'lastModified': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore.collection('books').doc(widget.bookId).update({
        'lastModified': FieldValue.serverTimestamp(),
        'currentChapter': _currentChapter,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chapter saved successfully')),
      );
    } catch (e) {
      _showErrorSnackBar('Error saving chapter: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _getAIAssistance() async {
    String prompt = _aiPromptController.text;
    if (prompt.isEmpty) {
      _showErrorSnackBar('Please enter a prompt for AI assistance');
      return;
    }

    setState(() => _isAILoading = true);
    try {
      String aiSuggestion = await AIService.getAIAssistance(
        previousChapters: _previousChapters,
        currentChapter: _contentController.text,
        prompt: prompt,
      );

      setState(() => _aiGeneratedContent = aiSuggestion);
    } catch (e) {
      _showErrorSnackBar('Error getting AI assistance: $e');
    } finally {
      setState(() => _isAILoading = false);
    }
  }

  void _insertAIContent() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final newText = text.replaceRange(selection.start, selection.end, _aiGeneratedContent);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + _aiGeneratedContent.length),
    );
    setState(() => _aiGeneratedContent = '');
  }

  Future<void> _togglePublishStatus() async {
  try {
    bool currentStatus = _book?.isPublished ?? false;
    await _firestore.collection('books').doc(widget.bookId).update({
      'isPublished': !currentStatus,
    });
    setState(() {
      if (_book != null) {
        _book!.isPublished = !currentStatus;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(currentStatus ? 'Book unpublished' : 'Book published')),
    );
  } catch (e) {
    _showErrorSnackBar('Error updating publish status: $e');
  }
}

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final writingMode = context.watch<WritingModeProvider>();

    return Scaffold(
      appBar: CustomAppBar(
        title: _book?.title ?? 'Writing',
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isSaving ? null : _saveChapter,
          ),
          IconButton(
            icon: Icon(_book?.isPublished == true ? Icons.public : Icons.public_off),
            onPressed: _togglePublishStatus,
          ),
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookStatisticsScreen(bookId: widget.bookId),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Row(
              children: [
                ChapterSidebar(
                  bookId: widget.bookId,
                  currentChapter: _currentChapter,
                  onChapterSelected: (chapter) {
                    _saveChapter().then((_) {
                      setState(() => _currentChapter = chapter);
                      _loadChapters();
                    });
                  },
                  onAddChapter: () {
                    // Implement add chapter functionality
                  },
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          color: writingMode.isDistractionFree ? Colors.black : Colors.white,
                          child: TextField(
                            controller: _contentController,
                            maxLines: null,
                            expands: true,
                            style: TextStyle(
                              color: writingMode.isDistractionFree ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ),
                      if (_aiGeneratedContent.isNotEmpty)
                        Container(
                          color: Colors.grey[200],
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('AI Generated Content:', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text(_aiGeneratedContent),
                              SizedBox(height: 8),
                              ElevatedButton(
                                child: Text('Insert AI Content'),
                                onPressed: _insertAIContent,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey[200],
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('AI Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        TextField(
                          controller: _aiPromptController,
                          decoration: InputDecoration(
                            hintText: 'Enter your prompt here...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          child: _isAILoading
                              ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                              : Text('Get AI Assistance'),
                          onPressed: _isAILoading ? null : _getAIAssistance,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: !writingMode.isDistractionFree
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Word count: ${_contentController.text.split(RegExp(r'\s+')).length}'),
                    Text('Chapter $_currentChapter'),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}