import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String authorId;
  final int? currentChapter;
  final DateTime lastModified;
  bool isPublished;

  Book({
    required this.id,
    required this.title,
    required this.authorId,
    this.currentChapter,
    required this.lastModified,
    this.isPublished = false,
  });

  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      authorId: data['authorId'] ?? '',
      currentChapter: data['currentChapter'],
      lastModified: (data['lastModified'] as Timestamp).toDate(),
      isPublished: data['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'authorId': authorId,
      'currentChapter': currentChapter,
      'lastModified': Timestamp.fromDate(lastModified),
      'isPublished': isPublished,
    };
  }
}