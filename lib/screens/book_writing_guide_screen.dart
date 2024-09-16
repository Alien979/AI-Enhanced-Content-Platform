import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_writing_screen.dart';

class BookWritingGuideScreen extends StatefulWidget {
  final String bookId;

  const BookWritingGuideScreen({super.key, required this.bookId});

  @override
  _BookWritingGuideScreenState createState() => _BookWritingGuideScreenState();
}

class _BookWritingGuideScreenState extends State<BookWritingGuideScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<DocumentSnapshot> _bookStream;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _bookStream = _firestore.collection('books').doc(widget.bookId).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Writing Guide'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _bookStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Book not found'));
          }

          Map<String, dynamic> bookData = snapshot.data!.data() as Map<String, dynamic>;
          int totalChapters = bookData['chapterCount'] ?? 1;
          int completedChapters = bookData['completedChapters'] ?? 0;

          return Column(
            children: [
              LinearProgressIndicator(
                value: completedChapters / totalChapters,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Progress: $completedChapters / $totalChapters chapters',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Stepper(
                  currentStep: _currentStep,
                  onStepTapped: (step) => setState(() => _currentStep = step),
                  onStepContinue: () {
                    if (_currentStep < 4) {
                      setState(() => _currentStep++);
                    } else {
                      _navigateToWritingScreen();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep--);
                    }
                  },
                  steps: [
                    _buildStep(
                      title: 'Plan Your Chapter',
                      content: 'Outline the main events and key points for this chapter.',
                    ),
                    _buildStep(
                      title: 'Set the Scene',
                      content: 'Describe the setting and introduce the characters involved.',
                    ),
                    _buildStep(
                      title: 'Develop the Plot',
                      content: 'Write the main events of the chapter, focusing on character actions and dialogue.',
                    ),
                    _buildStep(
                      title: 'Add Details',
                      content: 'Enhance your writing with descriptions, emotions, and sensory details.',
                    ),
                    _buildStep(
                      title: 'Review and Edit',
                      content: 'Read through your chapter, making necessary edits and improvements.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Step _buildStep({required String title, required String content}) {
    return Step(
      title: Text(title),
      content: Text(content),
      isActive: _currentStep >= _steps.indexOf(title),
    );
  }

  void _navigateToWritingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookWritingScreen(bookId: widget.bookId),
      ),
    );
  }

  List<String> get _steps => [
    'Plan Your Chapter',
    'Set the Scene',
    'Develop the Plot',
    'Add Details',
    'Review and Edit',
  ];
}