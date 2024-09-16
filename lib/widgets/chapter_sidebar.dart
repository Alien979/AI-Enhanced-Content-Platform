import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChapterSidebar extends StatelessWidget {
  final String bookId;
  final int currentChapter;
  final Function(int) onChapterSelected;
  final VoidCallback onAddChapter;

  ChapterSidebar({
    required this.bookId,
    required this.currentChapter,
    required this.onChapterSelected,
    required this.onAddChapter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.grey[200],
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('books')
            .doc(bookId)
            .collection('chapters')
            .orderBy('chapterNumber')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var chapters = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chapters.length + 1,
            itemBuilder: (context, index) {
              if (index == chapters.length) {
                return ListTile(
                  title: Text('Add Chapter'),
                  leading: Icon(Icons.add),
                  onTap: onAddChapter,
                );
              }

              var chapter = chapters[index];
              var chapterNumber = chapter['chapterNumber'];

              return ListTile(
                title: Text('Chapter $chapterNumber'),
                selected: chapterNumber == currentChapter,
                onTap: () => onChapterSelected(chapterNumber),
              );
            },
          );
        },
      ),
    );
  }
}