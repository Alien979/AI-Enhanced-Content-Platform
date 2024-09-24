import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'book_writing_guide_screen.dart';

class BookConfigScreen extends StatefulWidget {
  final String? bookId;

  const BookConfigScreen({super.key, this.bookId});

  @override
  _BookConfigScreenState createState() => _BookConfigScreenState();
}

class _BookConfigScreenState extends State<BookConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;

  String _title = '';
  String _summary = '';
  String _genre = 'Fiction';
  String _targetAudience = 'General';
  String _language = 'English';
  List<String> _tags = [];
  Uint8List? _imageBytes;
  String? _imageUrl;

  final List<String> _genres = ['Fiction', 'Non-fiction', 'Science Fiction', 'Fantasy', 'Mystery', 'Thriller', 'Romance', 'Horror', 'Biography', 'Self-help'];
  final List<String> _audiences = ['General', 'Children', 'Young Adult', 'Adult'];
  final List<String> _languages = ['English', 'Spanish', 'French', 'German', 'Chinese', 'Japanese', 'Other'];

  bool _isLoading = false;
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.bookId != null) {
      _loadBookData();
    }
  }

  void _loadBookData() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot bookDoc = await _firestore.collection('books').doc(widget.bookId).get();
      Map<String, dynamic> bookData = bookDoc.data() as Map<String, dynamic>;
      
      setState(() {
        _title = bookData['title'] ?? '';
        _summary = bookData['summary'] ?? '';
        _genre = bookData['genre'] ?? 'Fiction';
        _targetAudience = bookData['targetAudience'] ?? 'General';
        _language = bookData['language'] ?? 'English';
        _tags = List<String>.from(bookData['tags'] ?? []);
        _imageUrl = bookData['coverImage'];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading book data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading book data. Please try again.')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null) return _imageUrl;

    try {
      final ref = _storage.ref().child('book_covers').child('${DateTime.now().toIso8601String()}.jpg');
      await ref.putData(_imageBytes!);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading image. Please try again.')),
      );
      return null;
    }
  }

  void _addTag() {
    if (_tagController.text.isNotEmpty && !_tags.contains(_tagController.text)) {
      setState(() {
        _tags.add(_tagController.text);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      
      try {
        _imageUrl = await _uploadImage();

        Map<String, dynamic> bookData = {
          'title': _title,
          'summary': _summary,
          'genre': _genre,
          'targetAudience': _targetAudience,
          'language': _language,
          'tags': _tags,
          'coverImage': _imageUrl,
          'authorId': _auth.currentUser!.uid,
          'lastModified': FieldValue.serverTimestamp(),
        };

        if (widget.bookId == null) {
          bookData['createdAt'] = FieldValue.serverTimestamp();
          bookData['isPublished'] = false;
          DocumentReference docRef = await _firestore.collection('books').add(bookData);
          
          // Create the first chapter
          await _firestore.collection('books').doc(docRef.id).collection('chapters').doc('1').set({
            'content': '',
            'chapterNumber': 1,
            'lastModified': FieldValue.serverTimestamp(),
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BookWritingGuideScreen(bookId: docRef.id),
            ),
          );
        } else {
          await _firestore.collection('books').doc(widget.bookId).update(bookData);
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book saved successfully!')),
        );
      } catch (e) {
        print('Error saving book: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving book. Please try again.')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookId == null ? 'Create New Book' : 'Edit Book'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 150,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _imageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                                )
                              : _imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(_imageUrl!, fit: BoxFit.cover),
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate, size: 50),
                                        Text('Add Cover Image', textAlign: TextAlign.center),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _title,
                      decoration: const InputDecoration(
                        labelText: 'Book Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                      onSaved: (value) => _title = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _summary,
                      decoration: const InputDecoration(
                        labelText: 'Book Summary',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) => value!.isEmpty ? 'Please enter a summary' : null,
                      onSaved: (value) => _summary = value!,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      decoration: const InputDecoration(
                        labelText: 'Genre',
                        border: OutlineInputBorder(),
                      ),
                      value: _genre,
                      items: _genres.map((genre) {
                        return DropdownMenuItem(value: genre, child: Text(genre));
                      }).toList(),
                      onChanged: (value) => setState(() => _genre = value.toString()),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      decoration: const InputDecoration(
                        labelText: 'Target Audience',
                        border: OutlineInputBorder(),
                      ),
                      value: _targetAudience,
                      items: _audiences.map((audience) {
                        return DropdownMenuItem(value: audience, child: Text(audience));
                      }).toList(),
                      onChanged: (value) => setState(() => _targetAudience = value.toString()),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      decoration: const InputDecoration(
                        labelText: 'Language',
                        border: OutlineInputBorder(),
                      ),
                      value: _language,
                      items: _languages.map((language) {
                        return DropdownMenuItem(value: language, child: Text(language));
                      }).toList(),
                      onChanged: (value) => setState(() => _language = value.toString()),
                    ),
                    const SizedBox(height: 16),
                    const Text('Tags:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: _tags.map((tag) => Chip(
                        label: Text(tag),
                        onDeleted: () => _removeTag(tag),
                      )).toList(),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            decoration: const InputDecoration(
                              hintText: 'Add a tag',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addTag,
                          child: const Text('Add Tag'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: Text(widget.bookId == null ? 'Create Book' : 'Update Book'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}