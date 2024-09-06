// lib/screens/book_config_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class BookConfigScreen extends StatefulWidget {
  final String? bookId;

  BookConfigScreen({this.bookId});

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
  int _chapterCount = 1;
  String _targetAudience = 'General';
  String _language = 'English';
  List<String> _tags = [];
  Uint8List? _imageBytes;
  String? _imageUrl;

  List<String> _genres = ['Fiction', 'Non-fiction', 'Science Fiction', 'Fantasy', 'Mystery', 'Thriller', 'Romance', 'Horror', 'Biography', 'Self-help'];
  List<String> _audiences = ['General', 'Children', 'Young Adult', 'Adult'];
  List<String> _languages = ['English', 'Spanish', 'French', 'German', 'Chinese', 'Japanese', 'Other'];

  bool _isLoading = false;
  TextEditingController _tagController = TextEditingController();

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
        _chapterCount = bookData['chapterCount'] ?? 1;
        _targetAudience = bookData['targetAudience'] ?? 'General';
        _language = bookData['language'] ?? 'English';
        _tags = List<String>.from(bookData['tags'] ?? []);
        _imageUrl = bookData['coverImage'];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading book data: $e');
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
          'chapterCount': _chapterCount,
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
          Navigator.pushReplacementNamed(context, '/book_writing', arguments: {'bookId': docRef.id});
        } else {
          await _firestore.collection('books').doc(widget.bookId).update(bookData);
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error saving book: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving book: $e')),
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
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
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
                            ),
                            child: _imageBytes != null
                                ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                                : _imageUrl != null
                                    ? Image.network(_imageUrl!, fit: BoxFit.cover)
                                    : Icon(Icons.add_photo_alternate, size: 50),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        initialValue: _title,
                        decoration: InputDecoration(labelText: 'Book Title'),
                        validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                        onSaved: (value) => _title = value!,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        initialValue: _summary,
                        decoration: InputDecoration(labelText: 'Book Summary'),
                        maxLines: 3,
                        validator: (value) => value!.isEmpty ? 'Please enter a summary' : null,
                        onSaved: (value) => _summary = value!,
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField(
                        decoration: InputDecoration(labelText: 'Genre'),
                        value: _genre,
                        items: _genres.map((genre) {
                          return DropdownMenuItem(value: genre, child: Text(genre));
                        }).toList(),
                        onChanged: (value) => setState(() => _genre = value.toString()),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        initialValue: _chapterCount.toString(),
                        decoration: InputDecoration(labelText: 'Number of Chapters'),
                        keyboardType: TextInputType.number,
                        validator: (value) => int.tryParse(value!) == null ? 'Please enter a valid number' : null,
                        onSaved: (value) => _chapterCount = int.parse(value!),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField(
                        decoration: InputDecoration(labelText: 'Target Audience'),
                        value: _targetAudience,
                        items: _audiences.map((audience) {
                          return DropdownMenuItem(value: audience, child: Text(audience));
                        }).toList(),
                        onChanged: (value) => setState(() => _targetAudience = value.toString()),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField(
                        decoration: InputDecoration(labelText: 'Language'),
                        value: _language,
                        items: _languages.map((language) {
                          return DropdownMenuItem(value: language, child: Text(language));
                        }).toList(),
                        onChanged: (value) => setState(() => _language = value.toString()),
                      ),
                      SizedBox(height: 16),
                      Text('Tags:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                              decoration: InputDecoration(
                                hintText: 'Add a tag',
                              ),
                              onSubmitted: (_) => _addTag(),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: _addTag,
                          ),
                        ],
                      ),
                      SizedBox(height: 32),
                      Center(
                        child: ElevatedButton(
                          child: Text(widget.bookId == null ? 'Create Book' : 'Update Book'),
                          onPressed: _submitForm,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}