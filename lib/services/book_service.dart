import 'package:cloud_firestore/cloud_firestore.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getUserBookStats(String userId) async {
    QuerySnapshot booksSnapshot = await _firestore
        .collection('books')
        .where('authorId', isEqualTo: userId)
        .get();

    int booksWritten = booksSnapshot.docs.length;
    int totalWordsWritten = 0;
    for (var doc in booksSnapshot.docs) {
      totalWordsWritten += ((doc.data() as Map<String, dynamic>)['wordCount'] as num?)?.toInt() ?? 0;
    }

    QuerySnapshot readBooksSnapshot = await _firestore
        .collection('readBooks')
        .where('userId', isEqualTo: userId)
        .get();

    int booksRead = readBooksSnapshot.docs.length;

    return {
      'booksWritten': booksWritten,
      'totalWordsWritten': totalWordsWritten,
      'booksRead': booksRead,
    };
  }

  Future<List<Map<String, dynamic>>> getRecentActivity(String userId) async {
    QuerySnapshot activitySnapshot = await _firestore
        .collection('userActivity')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();

    return activitySnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return {
        'description': data['description'],
        'timestamp': data['timestamp'],
      };
    }).toList();
  }

  Future<void> createBook(String userId, String title, String summary, String genre) async {
    await _firestore.collection('books').add({
      'authorId': userId,
      'title': title,
      'summary': summary,
      'genre': genre,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'wordCount': 0,
      'isPublished': false,
    });
  }

  Future<void> updateBook(String bookId, Map<String, dynamic> updates) async {
    await _firestore.collection('books').doc(bookId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteBook(String bookId) async {
    await _firestore.collection('books').doc(bookId).delete();
  }

  Future<void> publishBook(String bookId) async {
    await _firestore.collection('books').doc(bookId).update({
      'isPublished': true,
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addChapter(String bookId, String chapterTitle, String content) async {
    await _firestore.collection('books').doc(bookId).collection('chapters').add({
      'title': chapterTitle,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update word count
    int wordCount = content.split(' ').length;
    await _firestore.collection('books').doc(bookId).update({
      'wordCount': FieldValue.increment(wordCount),
    });
  }

  Stream<QuerySnapshot> getUserBooks(String userId) {
    return _firestore
        .collection('books')
        .where('authorId', isEqualTo: userId)
        .snapshots();
  }

  Stream<QuerySnapshot> getPublishedBooks() {
    return _firestore
        .collection('books')
        .where('isPublished', isEqualTo: true)
        .snapshots();
  }
}