import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  static const String _apiKey = 'AIzaSyDKxYk8uoSqRCv-_qQPL9xhfwOV3pC39_0';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  static Future<String> getAIAssistance({
    required List<String> previousChapters,
    required String currentChapter,
    required String prompt,
    int maxTokens = 500,
  }) async {
    try {
      // Limit the context to avoid exceeding token limits
      const int maxContextLength = 2000; // Adjust this value based on your needs
      String fullContext = '';

      // Add current chapter first
      fullContext += "Current chapter:\n$currentChapter\n\n";

      // Add previous chapters, starting from the most recent
      for (int i = previousChapters.length - 1; i >= 0; i--) {
        String chapterSummary =
            "Chapter ${i + 1} summary:\n${_summarizeText(previousChapters[i])}\n\n";
        if ((fullContext + chapterSummary).length <= maxContextLength) {
          fullContext = chapterSummary + fullContext;
        } else {
          break;
        }
      }

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'Origin': 'http://localhost:3000', // Add this line for CORS
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """Here is the context of the book:

$fullContext

Based on this context and the current state of the story, please $prompt.
Ensure your response is consistent with the existing narrative and writing style.
Do not repeat information already provided. Focus on moving the story forward or elaborating on the requested details.
"""
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": maxTokens,
            "topK": 40,
            "topP": 0.95,
            "stopSequences": []
          },
          "safetySettings": [
            {
              "category": "HARM_CATEGORY_HARASSMENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_HATE_SPEECH",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        } else {
          throw Exception('Unexpected response format from AI service');
        }
      } else {
        print('API Error: Status ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to get AI assistance: ${response.body}');
      }
    } catch (e) {
      print('Error getting AI assistance: $e');
      return 'Error: Unable to get AI assistance at this time. Please try again later. (Error details: ${e.toString()})';
    }
  }

  static String _summarizeText(String text, {int maxLength = 200}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}