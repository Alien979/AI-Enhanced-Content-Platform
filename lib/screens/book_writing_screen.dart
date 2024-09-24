import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/ai_service.dart';
import '../widgets/chapter_sidebar.dart';
import '../models/book.dart';
import '../providers/writing_mode_provider.dart';
import 'book_statistics_screen.dart';
import 'publish_book_screen.dart';

class BookWritingScreen extends StatefulWidget {
  final String bookId;

  const BookWritingScreen({super.key, required this.bookId});

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
  bool _isSidebarVisible = true;
  bool _isAIVisible = false;
  Timer? _saveTimer;

  // AI Settings
  double _aiTemperature = 0.7;
  int _aiMaxTokens = 150;
  String _writingStyle = 'Neutral';
  final List<String> _writingStyles = [
    'Neutral',
    'Formal',
    'Casual',
    'Poetic',
    'Technical'
  ];

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _aiPromptController = TextEditingController();
    _loadBookData();
    _setupAutoSave();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _aiPromptController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  void _setupAutoSave() {
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isSaving && _contentController.text.isNotEmpty) {
        _saveChapter();
      }
    });
  }

  Future<void> _loadBookData() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot bookDoc =
          await _firestore.collection('books').doc(widget.bookId).get();
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
      bool hasChapterOne = false;
      for (var doc in chaptersSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        int chapterNumber = data['chapterNumber'] ?? 0;
        if (chapterNumber == 1) hasChapterOne = true;
        if (chapterNumber == _currentChapter) {
          _contentController.text = data['content'] ?? '';
        } else {
          _previousChapters.add(data['content'] ?? '');
        }
      }

      if (!hasChapterOne) {
        await _firestore
            .collection('books')
            .doc(widget.bookId)
            .collection('chapters')
            .doc('1')
            .set({
          'content': '',
          'chapterNumber': 1,
          'lastModified': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading chapters: $e');
    }
  }

  Future<void> _saveChapter() async {
    if (_isSaving) return;
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
        const SnackBar(
          content: Text('Chapter saved successfully'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
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
        maxTokens: _aiMaxTokens, // If you want to keep using this parameter
      );

      setState(() => _aiGeneratedContent = aiSuggestion);
    } catch (e) {
      print('Error in _getAIAssistance: $e');
      _showErrorSnackBar('Error getting AI assistance: ${e.toString()}');
    } finally {
      setState(() => _isAILoading = false);
    }
  }

  void _insertAIContent() {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.isValid &&
        selection.start >= 0 &&
        selection.end <= text.length) {
      final newText = text.replaceRange(
          selection.start, selection.end, _aiGeneratedContent);
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: selection.start + _aiGeneratedContent.length),
      );
    } else {
      // If no valid selection, append the AI content to the end
      final newText = '$text\n$_aiGeneratedContent';
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
    setState(() => _aiGeneratedContent = '');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _changeChapter(int newChapter) async {
    await _saveChapter();
    setState(() {
      _currentChapter = newChapter;
      _contentController.text = '';
    });
    await _loadChapters();
  }

  Future<void> _addNewChapter() async {
    if (_book == null) return;
    int newChapterNumber = (_book!.chapterCount ?? 0) + 1;
    await _firestore
        .collection('books')
        .doc(widget.bookId)
        .collection('chapters')
        .doc(newChapterNumber.toString())
        .set({
      'content': '',
      'chapterNumber': newChapterNumber,
      'lastModified': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('books').doc(widget.bookId).update({
      'chapterCount': newChapterNumber,
    });

    setState(() {
      _book!.chapterCount = newChapterNumber;
      _currentChapter = newChapterNumber;
    });

    await _loadChapters();
  }

  void _showAISettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('AI Assistant Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Creativity (Temperature): ${_aiTemperature.toStringAsFixed(2)}'),
                  Slider(
                    value: _aiTemperature,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (value) {
                      setState(() => _aiTemperature = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Max Tokens: $_aiMaxTokens'),
                  Slider(
                    value: _aiMaxTokens.toDouble(),
                    min: 50,
                    max: 500,
                    divisions: 45,
                    onChanged: (value) {
                      setState(() => _aiMaxTokens = value.round());
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Writing Style'),
                    value: _writingStyle,
                    items: _writingStyles.map((style) {
                      return DropdownMenuItem(value: style, child: Text(style));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _writingStyle = value!);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    this.setState(() {}); // Update the main screen
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final writingMode = context.watch<WritingModeProvider>();
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(_book?.title ?? 'Writing',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _isSaving ? null : _saveChapter,
            tooltip: 'Save Chapter',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BookStatisticsScreen(bookId: widget.bookId),
              ),
            ),
            tooltip: 'View Statistics',
          ),
          IconButton(
            icon: const Icon(Icons.publish, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PublishBookScreen(bookId: widget.bookId),
                ),
              );
            },
            tooltip: 'Publish Book',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showAISettingsDialog,
            tooltip: 'AI Settings',
          ),
          if (isSmallScreen)
            IconButton(
              icon: Icon(_isSidebarVisible ? Icons.menu_open : Icons.menu,
                  color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSidebarVisible = !_isSidebarVisible;
                });
              },
              tooltip: 'Toggle Sidebar',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                if (!isSmallScreen || _isSidebarVisible)
                  ChapterSidebar(
                    bookId: widget.bookId,
                    currentChapter: _currentChapter,
                    onChapterSelected: _changeChapter,
                    onAddChapter: _addNewChapter,
                    isVisible: _isSidebarVisible,
                    onClose: () => setState(() => _isSidebarVisible = false),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: writingMode.isDistractionFree
                                ? Colors.black
                                : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _contentController,
                            maxLines: null,
                            expands: true,
                            style: TextStyle(
                              color: writingMode.isDistractionFree
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 18,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              hintText: 'Start writing your chapter here...',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      if (isSmallScreen && _isAIVisible) _buildAIAssistant(),
                    ],
                  ),
                ),
                if (!isSmallScreen) _buildAIAssistant(),
              ],
            ),
      floatingActionButton: isSmallScreen
          ? FloatingActionButton(
              onPressed: () => setState(() => _isAIVisible = !_isAIVisible),
              child: Icon(_isAIVisible ? Icons.close : Icons.psychology),
            )
          : null,
    );
  }

  Widget _buildAIAssistant() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Assistant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _aiPromptController,
            decoration: const InputDecoration(
              hintText: 'Enter your prompt for AI assistance...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _getAIAssistance,
                child: Text(
                    _isAILoading ? 'Getting AI Help...' : 'Get AI Assistance'),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _showAISettingsDialog,
                tooltip: 'AI Settings',
              ),
            ],
          ),
          if (_aiGeneratedContent.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('AI Generated Content:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_aiGeneratedContent),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _insertAIContent,
              child: const Text('Insert AI Content'),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Current Settings:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Temperature: ${_aiTemperature.toStringAsFixed(2)}'),
          Text('Max Tokens: $_aiMaxTokens'),
          Text('Writing Style: $_writingStyle'),
        ],
      ),
    );
  }
}
