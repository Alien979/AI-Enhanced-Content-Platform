import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_book_writing_platform/services/ai_service.dart';

class QuoteService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _quoteCollectionName = 'quotes';

  static Future<String> getOrGenerateQuote() async {
    try {
      // Check if there's a recent quote (less than 1 hour old)
      var quoteSnapshot = await _firestore
          .collection(_quoteCollectionName)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (quoteSnapshot.docs.isNotEmpty) {
        var latestQuote = quoteSnapshot.docs.first;
        var timestamp = latestQuote['timestamp'] as Timestamp;
        if (timestamp.toDate().isAfter(DateTime.now().subtract(const Duration(hours: 1)))) {
          // Return the existing quote if it's less than 1 hour old
          return latestQuote['text'];
        }
      }

      // Generate a new quote if there's no recent quote
      String newQuote = await AIService.getAIAssistance(
        previousChapters: [],
        currentChapter: '',
        prompt: 'Generate an inspiring quote about writing or creativity. The quote should be concise and no longer than 2 sentences.',
        maxTokens: 50,
      );

      // Store the new quote
      await _firestore.collection(_quoteCollectionName).add({
        'text': newQuote,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return newQuote;
    } catch (e) {
      print('Error getting or generating quote: $e');
      return 'The best way to predict the future is to create it.';
    }
  }
}