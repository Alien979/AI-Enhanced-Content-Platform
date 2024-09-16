// lib/screens/review_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;

  const ReviewScreen({super.key, required this.bookId, required this.bookTitle});

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    try {
      await _firestore.collection('books').doc(widget.bookId).collection('reviews').add({
        'userId': _auth.currentUser!.uid,
        'userName': _auth.currentUser!.displayName ?? 'Anonymous',
        'rating': _rating,
        'review': _reviewController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update the book's average rating
      DocumentSnapshot bookDoc = await _firestore.collection('books').doc(widget.bookId).get();
      Map<String, dynamic> bookData = bookDoc.data() as Map<String, dynamic>;
      int totalRatings = (bookData['totalRatings'] ?? 0) + 1;
      double newAverageRating = ((bookData['averageRating'] ?? 0.0) * (totalRatings - 1) + _rating) / totalRatings;

      await _firestore.collection('books').doc(widget.bookId).update({
        'averageRating': newAverageRating,
        'totalRatings': totalRatings,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting review')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review: ${widget.bookTitle}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rate this book:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            const Text('Write your review:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts about this book...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitReview,
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}