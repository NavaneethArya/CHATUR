// geminiEligibilityQuestions.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class GeminiEligibilityQuestions {
  static const String apiKey = 'AIzaSyDRJ80dwt7j5wL8WSJoINZRK3enlC8hVkw';
  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  static Future<bool> generateAndStoreQuestions(
      BuildContext context, String language) async {
    final GlobalKey dialogKey = GlobalKey();
    bool dialogIsOpen = true;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            key: dialogKey,
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Generating eligibility questions...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ).then((_) => dialogIsOpen = false);

      await Future.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();

      // Fetch schemes data
      final schemes = await _fetchSchemes(language);

      if (schemes.isEmpty) {
        if (dialogIsOpen && context.mounted) Navigator.of(context).pop();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No schemes found to generate questions')),
          );
        }
        return false;
      }

      // Extract ONLY eligibility criteria (not entire schemes)
      List<String> allEligibility = [];
      for (var scheme in schemes) {
        if (scheme['Eligibility'] is List) {
          allEligibility.addAll(List<String>.from(scheme['Eligibility']));
        }
      }

      allEligibility =
          allEligibility.where((e) => e.trim().isNotEmpty).toSet().toList();

      if (allEligibility.isEmpty) {
        if (dialogIsOpen && context.mounted) Navigator.of(context).pop();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No eligibility criteria found in schemes')),
          );
        }
        return false;
      }

      // Chunk eligibility criteria to prevent token limits
      final chunkSize = 50; // Process 50 eligibility criteria at a time
      List<Map<String, String>> allQuestions = [];

      for (int i = 0; i < allEligibility.length; i += chunkSize) {
        final chunk = allEligibility.skip(i).take(chunkSize).toList();
        final chunkQuestions = await _generateQuestionsWithGemini(chunk);
        allQuestions.addAll(chunkQuestions);

        // Stop if we have enough questions
        if (allQuestions.length >= 30) break;
      }

      if (allQuestions.isEmpty) {
        if (dialogIsOpen && context.mounted) Navigator.of(context).pop();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to generate questions. Check logs.')),
          );
        }
        return false;
      }

      // Remove duplicates and limit to 30 questions
      final uniqueQuestions = _removeDuplicateQuestions(allQuestions);
      final finalQuestions = uniqueQuestions.take(30).toList();

      // Store all 30 questions
      await prefs.setString(
          'eligibility_questions', jsonEncode(finalQuestions));
      await prefs.setInt('questions_generated_timestamp',
          DateTime.now().millisecondsSinceEpoch);

      if (dialogIsOpen && context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${finalQuestions.length} eligibility questions generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return true;
    } catch (e) {
      if (dialogIsOpen && context.mounted) Navigator.of(context).pop();
      print('Fatal Error in generateAndStoreQuestions: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchSchemes(
      String language) async {
    try {
      final languageCode = language == 'English'
          ? 'en'
          : language == 'Kannada'
              ? 'kn'
              : 'hi';
      final url = 'https://navarasa-chathur-api.hf.space/$languageCode/schemes';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('karnataka')) {
          return List<Map<String, dynamic>>.from(data['karnataka']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      } else {
        print('Error fetching schemes: Status code ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('Error fetching schemes: $e');
      return [];
    }
  }

  // Safe JSON extractor - salvages valid JSON even if response is malformed
  static String _extractJson(String input) {
    final start = input.indexOf('[');
    final end = input.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      return input.substring(start, end + 1);
    }
    return '[]'; // fallback to empty array
  }

  static Future<List<Map<String, String>>> _generateQuestionsWithGemini(
      List<String> eligibilityCriteria) async {
    try {
      // STRICT JSON PROMPT - Forces Gemini to output only valid JSON
      final prompt = '''
You are a JSON generator. Your ONLY task is to generate valid JSON.

Analyze the following eligibility criteria and generate exactly 30 unique yes/no questions.

Eligibility Criteria:
${eligibilityCriteria.join('\n')}

CRITICAL RULES:
1. Return ONLY a valid JSON array - NO text, NO markdown, NO explanations
2. Each question must be 2-3 lines maximum and sound natural
3. Questions must cover: age, income, occupation, caste, residence, education, family status
4. All questions must be answerable with YES or NO only
5. Do NOT repeat or create similar questions

REQUIRED FORMAT (EXACTLY):
[
  {"question": "Are you above 18 years of age?", "answer": "yes"},
  {"question": "Do you belong to SC/ST community?", "answer": "yes"}
]

If you cannot generate questions, return an empty array: []

Do NOT include:
- Any text outside the JSON array
- Markdown code blocks (```json or ```)
- Comments or explanations
- Line breaks within question strings

Generate ONLY pure, valid JSON now:
''';

      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2, // Lower temperature for more consistent output
          'maxOutputTokens': 4096,
        }
      });

      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Safety check for API response structure
        if (data['candidates'] == null ||
            data['candidates'].isEmpty ||
            data['candidates'][0] == null ||
            data['candidates'][0]['content'] == null ||
            data['candidates'][0]['content']['parts'] == null ||
            data['candidates'][0]['content']['parts'].isEmpty) {
          print(
              'API response failed safety check (Likely blocked or incomplete): ${response.body}');
          return [];
        }

        final generatedText =
            data['candidates'][0]['content']['parts'][0]['text'];

        print('Raw Gemini Response: $generatedText');

        // Extract JSON using safe extractor
        String jsonText = _extractJson(generatedText.trim());

        // Additional cleanup - remove markdown wrappers if present
        jsonText = jsonText
            .replaceAll(RegExp(r'^\s*```json\s*'), '')
            .replaceAll(RegExp(r'\s*```\s*$'), '')
            .trim();

        print('Extracted JSON: $jsonText');

        // Try parsing the extracted JSON
        try {
          final questionsJson = jsonDecode(jsonText);

          if (questionsJson is! List) {
            print('Parsed content is not a JSON array.');
            return [];
          }

          List<Map<String, String>> questions = [];

          for (var item in questionsJson) {
            if (item is Map &&
                item.containsKey('question') &&
                item.containsKey('answer')) {
              // Clean up question text
              String questionText = item['question'].toString().trim();

              // Skip if question is empty or too short
              if (questionText.length < 10) continue;

              questions.add({
                'question': questionText,
                'answer': item['answer'].toString().toLowerCase(),
              });
            }
          }

          print('Successfully parsed ${questions.length} questions');

          // Limit to 30 questions
          if (questions.length > 30) {
            questions = questions.sublist(0, 30);
          }

          return questions;
        } catch (e) {
          print('Error parsing extracted JSON: $e');
          print('Failed JSON content (extracted): $jsonText');

          // Try one more fallback - attempt to fix common JSON issues
          try {
            // Replace single quotes with double quotes
            jsonText = jsonText.replaceAll("'", '"');
            final questionsJson = jsonDecode(jsonText);

            if (questionsJson is List) {
              List<Map<String, String>> questions = [];
              for (var item in questionsJson) {
                if (item is Map &&
                    item.containsKey('question') &&
                    item.containsKey('answer')) {
                  questions.add({
                    'question': item['question'].toString().trim(),
                    'answer': item['answer'].toString().toLowerCase(),
                  });
                }
              }
              return questions;
            }
          } catch (e2) {
            print('Fallback parsing also failed: $e2');
          }

          return [];
        }
      } else {
        print('Gemini API error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error generating questions with Gemini: $e');
      return [];
    }
  }

  // Remove duplicate questions based on similarity
  static List<Map<String, String>> _removeDuplicateQuestions(
      List<Map<String, String>> questions) {
    final seen = <String>{};
    final unique = <Map<String, String>>[];

    for (var q in questions) {
      // Normalize question for comparison (lowercase, remove extra spaces)
      final normalized =
          q['question']!.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

      if (!seen.contains(normalized)) {
        seen.add(normalized);
        unique.add(q);
      }
    }

    return unique;
  }

  // Get 20 RANDOM questions from the stored 30 questions
  static Future<List<Map<String, String>>> getStoredQuestions({
    bool randomize = true,
    int count = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final questionsJson = prefs.getString('eligibility_questions');

      if (questionsJson != null) {
        final List<dynamic> decoded = jsonDecode(questionsJson);
        final allQuestions =
            decoded.map((item) => Map<String, String>.from(item)).toList();

        if (randomize && allQuestions.length > count) {
          // Shuffle and return only 'count' questions (default 20)
          allQuestions.shuffle(Random());
          return allQuestions.take(count).toList();
        }

        return allQuestions;
      }
      return [];
    } catch (e) {
      print('Error retrieving stored questions: $e');
      return [];
    }
  }

  static Future<void> clearStoredQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('eligibility_questions');
    await prefs.remove('questions_generated_timestamp');
  }

  static Future<bool> hasStoredQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('eligibility_questions');
  }

  // Get total count of stored questions
  static Future<int> getStoredQuestionsCount() async {
    final questions = await getStoredQuestions(randomize: false);
    return questions.length;
  }
}
