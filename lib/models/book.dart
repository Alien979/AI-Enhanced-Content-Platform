import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String authorId;
  int currentChapter;
  int chapterCount;
  final DateTime lastModified;
  bool isPublished;
  String? coverUrl;
  String? summary;
  String? genre;

  Book({
    required this.id,
    required this.title,
    required this.authorId,
    this.currentChapter = 1,
    this.chapterCount = 1,
    required this.lastModified,
    this.isPublished = false,
    this.coverUrl,
    this.summary,
    this.genre,
  });

  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      authorId: data['authorId'] ?? '',
      currentChapter: data['currentChapter'] ?? 1,
      chapterCount: data['chapterCount'] ?? 1,
      lastModified: (data['lastModified'] as Timestamp).toDate(),
      isPublished: data['isPublished'] ?? false,
      coverUrl: data['coverUrl'],
      summary: data['summary'],
      genre: data['genre'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'authorId': authorId,
      'currentChapter': currentChapter,
      'chapterCount': chapterCount,
      'lastModified': Timestamp.fromDate(lastModified),
      'isPublished': isPublished,
      'coverUrl': coverUrl,
      'summary': summary,
      'genre': genre,
    };
  }

  Book copyWith({
    String? title,
    int? currentChapter,
    int? chapterCount,
    DateTime? lastModified,
    bool? isPublished,
    String? coverUrl,
    String? summary,
    String? genre,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      authorId: authorId,
      currentChapter: currentChapter ?? this.currentChapter,
      chapterCount: chapterCount ?? this.chapterCount,
      lastModified: lastModified ?? this.lastModified,
      isPublished: isPublished ?? this.isPublished,
      coverUrl: coverUrl ?? this.coverUrl,
      summary: summary ?? this.summary,
      genre: genre ?? this.genre,
    );
  }

  bool get isComplete => currentChapter == chapterCount;

  double get progress => chapterCount > 0 ? currentChapter / chapterCount : 0;

  String get statusText {
    if (isPublished) return 'Published';
    if (isComplete) return 'Completed';
    return 'In Progress';
  }

  @override
  String toString() {
    return 'Book(id: $id, title: $title, authorId: $authorId, currentChapter: $currentChapter, chapterCount: $chapterCount, lastModified: $lastModified, isPublished: $isPublished, genre: $genre)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Book &&
      other.id == id &&
      other.title == title &&
      other.authorId == authorId &&
      other.currentChapter == currentChapter &&
      other.chapterCount == chapterCount &&
      other.lastModified == lastModified &&
      other.isPublished == isPublished &&
      other.coverUrl == coverUrl &&
      other.summary == summary &&
      other.genre == genre;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      title.hashCode ^
      authorId.hashCode ^
      currentChapter.hashCode ^
      chapterCount.hashCode ^
      lastModified.hashCode ^
      isPublished.hashCode ^
      coverUrl.hashCode ^
      summary.hashCode ^
      genre.hashCode;
  }
}