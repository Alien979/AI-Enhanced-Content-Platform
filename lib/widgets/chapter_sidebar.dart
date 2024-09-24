import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChapterSidebar extends StatelessWidget {
  final String bookId;
  final int currentChapter;
  final Function(int) onChapterSelected;
  final VoidCallback onAddChapter;
  final bool isVisible;
  final VoidCallback onClose;

  const ChapterSidebar({
    super.key,
    required this.bookId,
    required this.currentChapter,
    required this.onChapterSelected,
    required this.onAddChapter,
    required this.isVisible,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isVisible ? 200 : 0,
      child: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text('Chapters'),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('books')
                    .doc(bookId)
                    .collection('chapters')
                    .orderBy('chapterNumber')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var chapters = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: chapters.length + 1,
                    itemBuilder: (context, index) {
                      if (index < chapters.length) {
                        var chapter = chapters[index];
                        var chapterNumber = chapter['chapterNumber'];

                        return ListTile(
                          title: Text('Chapter $chapterNumber'),
                          selected: chapterNumber == currentChapter,
                          onTap: () {
                            onChapterSelected(chapterNumber);
                            if (MediaQuery.of(context).size.width < 600) {
                              onClose();
                            }
                          },
                        );
                      } else {
                        return ListTile(
                          title: const Text('Add Chapter'),
                          leading: const Icon(Icons.add),
                          onTap: onAddChapter,
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}