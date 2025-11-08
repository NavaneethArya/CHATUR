// geminiAPI.dart - FIXED VERSION
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // NOTE: Replace with a secure method for API key management in a production environment
  static const String apiKey = 'AIzaSyDRJ80dwt7j5wL8WSJoINZRK3enlC8hVkw';
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';

  // Generate questions based on eligibility and documents
  static Future<List<Map<String, dynamic>>> generateEligibilityQuestions(
      List<String> eligibility, List<String> documentsRequired) async {
    try {
      final prompt = '''
You are a government scheme eligibility officer. Generate questions to verify eligibility for THIS SPECIFIC SCHEME.

SCHEME ELIGIBILITY CRITERIA:
${eligibility.map((e) => '• $e').join('\n')}

REQUIRED DOCUMENTS:
${documentsRequired.map((d) => '• $d').join('\n')}

INSTRUCTIONS:
1. Generate 10-15 questions total - ALL must be YES/NO type only
2. Create ONE question per eligibility criterion (NO DUPLICATES)
3. Questions must be 2-3 lines, clear and easy to understand
4. Group similar documents into 2-4 combined questions
5. NO numeric, amount, income values, or measurement questions
6. All questions must ask "Do you..." or "Are you..." format

QUESTION RULES:

For ALL criteria (including age, income, land, experience):
- ALL questions **must be of type "yesno"** 
- Example: For "Age must be above 18," ask "Are you currently above the age of 18 years?"
- Example: For "Income below 200000," ask "Is your total annual household income below the required threshold?"
- Example: For "5 years experience," ask "Do you have at least 5 years of professional experience in this field?"
- Make questions conversational and clear
- NO questions asking for specific numbers, amounts, or measurements

For DOCUMENTS:
- Combine similar docs: "Do you have any government-issued ID proof such as Aadhaar Card, PAN Card, or Voter ID?"
- Combine education docs: "Do you have the required educational certificates (10th/12th marksheets, degree certificates)?"
- Combine income/caste: "Do you have valid Income Certificate and Caste Certificate issued by competent authority?"

CRITICAL:
- NO duplicate questions
- NO numeric input questions
- Each eligibility point = ONE yes/no question only
- Questions should be professional yet easy to understand
- Return 10-15 questions (not less)
- ALL questions must have "type": "yesno"

OUTPUT FORMAT (JSON only, no markdown):
{
  "questions": [
    {
      "id": 1,
      "question": "Clear 2-3 line yes/no question?",
      "type": "yesno",
      "relatedCriteria": "Exact eligibility criterion",
      "isDocumentQuestion": false
    }
  ]
}

Mark document questions with "isDocumentQuestion": true
Return ONLY valid JSON.
''';

      final response = await http.post(
        Uri.parse('$baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 3500,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText =
            data['candidates'][0]['content']['parts'][0]['text'];

        String cleanedText = generatedText.trim();
        // Remove markdown wrappers
        if (cleanedText.startsWith('```json')) {
          cleanedText = cleanedText.substring(7);
        } else if (cleanedText.startsWith('```')) {
          cleanedText = cleanedText.substring(3);
        }
        if (cleanedText.endsWith('```')) {
          cleanedText = cleanedText.substring(0, cleanedText.length - 3);
        }
        cleanedText = cleanedText.trim();

        final questionsData = jsonDecode(cleanedText);
        List<Map<String, dynamic>> questions =
            List<Map<String, dynamic>>.from(questionsData['questions']);

        // Remove duplicates based on question text
        Set<String> seenQuestions = {};
        questions = questions.where((q) {
          String normalizedQuestion =
              q['question'].toString().toLowerCase().trim();
          if (seenQuestions.contains(normalizedQuestion)) {
            return false;
          }
          seenQuestions.add(normalizedQuestion);
          return true;
        }).toList();

        // Re-assign IDs and enforce 'yesno' type
        for (int i = 0; i < questions.length; i++) {
          questions[i]['id'] = i + 1;
          questions[i]['type'] = 'yesno'; // Enforce only yesno type
        }

        return questions;
      } else {
        throw Exception('Failed to generate questions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating questions: $e');
      return _getFallbackQuestions(eligibility, documentsRequired);
    }
  }

  // FIXED: Evaluate eligibility based on user answers
  static Future<Map<String, dynamic>> evaluateEligibility(
    List<String> eligibility,
    List<String> documentsRequired,
    List<Map<String, dynamic>> questions,
    Map<int, dynamic> answers,
  ) async {
    int eligibilityNoCount = 0;
    int documentNoCount = 0;
    int totalEligibilityQuestions = 0;
    int totalDocumentQuestions = 0;
    List<String> failedCriteria = [];
    List<String> missingDocuments = [];

    // Analyze answers
    for (var entry in answers.entries) {
      final questionIndex = entry.key;
      final answer = entry.value;

      // Safety check for index
      if (questionIndex >= questions.length) continue;

      final question = questions[questionIndex];
      final isDocQuestion = question['isDocumentQuestion'] == true;

      if (isDocQuestion) {
        totalDocumentQuestions++;
        if (answer is bool && !answer) {
          documentNoCount++;
          missingDocuments.add(question['relatedCriteria']);
        }
      } else {
        totalEligibilityQuestions++;
        if (answer is bool && !answer) {
          eligibilityNoCount++;
          failedCriteria.add(question['relatedCriteria']);
        }
      }
    }

    // --- CORRECTED ELIGIBILITY LOGIC ---
    String finalStatus;
    String finalConfidence;
    String finalMessage;
    List<String> finalRecommendations = [];

    // Rule 1: All "Yes" in eligibility AND 0-1 "No" in documents -> ELIGIBLE
    if (eligibilityNoCount == 0 && documentNoCount <= 1) {
      finalStatus = 'eligible';
      finalConfidence = 'high';

      if (documentNoCount == 0) {
        finalMessage =
            'Excellent! You meet all eligibility requirements and have all required documents. Your application is ready for submission.';
        finalRecommendations = [
          'Proceed to submit your application immediately.',
          'Keep all original documents ready for verification.',
          'Track your application status regularly through the official portal.'
        ];
      } else {
        finalMessage =
            'Great! You meet all core eligibility requirements. While one document is missing, you are still eligible. Please submit the missing document as soon as possible.';
        finalRecommendations = [
          'Submit your application now to secure your place.',
          'Provide the missing document (${missingDocuments.map((d) => d.replaceFirst('Required Documents: ', '').replaceFirst('Required Document: ', '')).join(', ')}) within 7 days.',
          'Keep photocopies of all submitted documents for your records.'
        ];
      }
    }
    // Rule 2: All "Yes" in eligibility AND 2+ "No" in documents -> MAYBE ELIGIBLE
    else if (eligibilityNoCount == 0 && documentNoCount > 1) {
      finalStatus = 'maybe_eligible';
      finalConfidence = 'medium';
      finalMessage =
          'You meet all core eligibility criteria, which is excellent! However, multiple required documents are missing (${documentNoCount} documents). You must provide these documents to complete your eligibility.';
      finalRecommendations = [
        'Immediately gather the following missing documents: ${missingDocuments.map((d) => d.replaceFirst('Required Documents: ', '').replaceFirst('Required Document: ', '')).join(', ')}.',
        'Visit the nearest government office or CSC center for assistance in obtaining these documents.',
        'Once all documents are arranged, resubmit your application.',
        'Keep track of document validity periods and renewal dates.'
      ];
    }
    // Rule 3: 1+ "No" in eligibility AND any "No" in documents -> NOT ELIGIBLE
    else if (eligibilityNoCount > 0 && documentNoCount > 0) {
      finalStatus = 'not_eligible';
      finalConfidence = 'high';
      finalMessage =
          'Unfortunately, you do not meet the essential eligibility criteria for this scheme. Additionally, some required documents are missing. Both eligibility requirements and proper documentation are mandatory.';
      finalRecommendations = [
        'Review the unmet criteria: ${failedCriteria.join(', ')}.',
        'Explore other government schemes that may better match your current situation.',
        'Contact the scheme office at the toll-free helpline for guidance on alternative schemes.',
        'Consider reapplying in the future if your circumstances change.'
      ];
    }
    // Rule 4: 1+ "No" in eligibility AND all "Yes" in documents -> NOT ELIGIBLE
    else if (eligibilityNoCount > 0 && documentNoCount == 0) {
      finalStatus = 'not_eligible';
      finalConfidence = 'high';
      finalMessage =
          'While you have all the required documents, you do not meet one or more essential eligibility criteria for this scheme. Meeting eligibility requirements is mandatory for scheme benefits.';
      finalRecommendations = [
        'Carefully review the failed criteria: ${failedCriteria.join(', ')}.',
        'Check if you can fulfill these criteria in the near future and reapply.',
        'Explore similar schemes with different eligibility requirements.',
        'Visit your nearest Jan Seva Kendra for personalized guidance.',
        'Keep your documents safe for future applications.'
      ];
    }
    // Fallback (should not occur with proper logic)
    else {
      finalStatus = 'not_eligible';
      finalConfidence = 'low';
      finalMessage =
          'Unable to determine eligibility status. Please contact the scheme office for manual verification.';
      finalRecommendations = [
        'Contact the scheme helpline for assistance.',
        'Visit the nearest government office with all your documents.',
        'Request a manual eligibility verification.'
      ];
    }

    return {
      'status': finalStatus,
      'eligible': finalStatus == 'eligible',
      'maybeEligible': finalStatus == 'maybe_eligible',
      'confidence': finalConfidence,
      'message': finalMessage,
      'failedCriteria': failedCriteria,
      'missingDocuments': missingDocuments,
      'recommendations': finalRecommendations,
      'statistics': {
        'eligibilityNoCount': eligibilityNoCount,
        'documentNoCount': documentNoCount,
        'totalEligibilityQuestions': totalEligibilityQuestions,
        'totalDocumentQuestions': totalDocumentQuestions,
      }
    };
  }

  // Fallback Questions - All Yes/No only, No numeric questions
  static List<Map<String, dynamic>> _getFallbackQuestions(
      List<String> eligibility, List<String> documentsRequired) {
    List<Map<String, dynamic>> questions = [];
    Set<String> addedQuestions = {};
    int id = 1;

    // Generate questions from eligibility criteria - All Yes/No type
    for (var criteria in eligibility) {
      if (criteria.trim().isEmpty) continue;

      String question = _convertToYesNoQuestion(criteria);

      if (!addedQuestions.contains(question.toLowerCase())) {
        questions.add({
          'id': id++,
          'question': question,
          'type': 'yesno',
          'relatedCriteria': criteria,
          'isDocumentQuestion': false,
        });
        addedQuestions.add(question.toLowerCase());
      }
    }

    // Group documents intelligently
    if (documentsRequired.isNotEmpty) {
      List<String> idDocs = [];
      List<String> eduDocs = [];
      List<String> incomeCasteDocs = [];
      List<String> otherDocs = [];

      for (var doc in documentsRequired) {
        String lower = doc.toLowerCase();
        if (lower.contains('aadhaar') ||
            lower.contains('pan') ||
            lower.contains('voter') ||
            lower.contains('id') ||
            lower.contains('card')) {
          idDocs.add(doc);
        } else if (lower.contains('10th') ||
            lower.contains('12th') ||
            lower.contains('degree') ||
            lower.contains('certificate') ||
            lower.contains('marksheet')) {
          eduDocs.add(doc);
        } else if (lower.contains('income') ||
            lower.contains('caste') ||
            lower.contains('domicile')) {
          incomeCasteDocs.add(doc);
        } else {
          otherDocs.add(doc);
        }
      }

      if (idDocs.isNotEmpty) {
        questions.add({
          'id': id++,
          'question':
              'Do you have any government-issued ID proof?\n(Such as Aadhaar Card, PAN Card, or Voter ID)',
          'type': 'yesno',
          'relatedCriteria': 'Required Documents: ID Proof',
          'isDocumentQuestion': true,
        });
      }

      if (eduDocs.isNotEmpty) {
        questions.add({
          'id': id++,
          'question':
              'Do you have the required educational certificates?\n(Such as 10th/12th marksheets or degree certificates)',
          'type': 'yesno',
          'relatedCriteria': 'Required Documents: Educational Certificates',
          'isDocumentQuestion': true,
        });
      }

      if (incomeCasteDocs.isNotEmpty) {
        questions.add({
          'id': id++,
          'question':
              'Do you have valid Income/Caste/Domicile certificates?\n(Issued by competent government authority)',
          'type': 'yesno',
          'relatedCriteria': 'Required Documents: Income/Caste Certificates',
          'isDocumentQuestion': true,
        });
      }

      for (var doc in otherDocs.take(2)) {
        questions.add({
          'id': id++,
          'question': 'Do you have the following document?\n$doc',
          'type': 'yesno',
          'relatedCriteria': 'Required Document: $doc',
          'isDocumentQuestion': true,
        });
      }
    }

    return questions;
  }

  // Helper method to convert eligibility criteria to yes/no questions
  static String _convertToYesNoQuestion(String criteria) {
    String lower = criteria.toLowerCase().trim();

    // Age related
    if (lower.contains('age') || lower.contains('years old')) {
      if (lower.contains('above') ||
          lower.contains('minimum') ||
          lower.contains('at least')) {
        return 'Do you meet the minimum age requirement as per this scheme?';
      } else if (lower.contains('below') || lower.contains('maximum')) {
        return 'Are you below the maximum age limit specified for this scheme?';
      }
      return 'Do you meet the age requirement for this scheme?';
    }

    // Income related
    if (lower.contains('income') || lower.contains('salary')) {
      if (lower.contains('below') || lower.contains('less than')) {
        return 'Is your total annual household income below the required threshold?';
      } else if (lower.contains('above') || lower.contains('minimum')) {
        return 'Does your annual household income meet the minimum requirement?';
      }
      return 'Do you meet the income criteria for this scheme?';
    }

    // Experience related
    if (lower.contains('experience') || lower.contains('year')) {
      return 'Do you have the required professional experience as specified in the criteria?';
    }

    // Land/Property related
    if (lower.contains('land') ||
        lower.contains('property') ||
        lower.contains('agriculture')) {
      return 'Do you own the required land or agricultural property as per scheme requirements?';
    }

    // Education related
    if (lower.contains('education') ||
        lower.contains('qualification') ||
        lower.contains('pass')) {
      return 'Do you have the required educational qualification for this scheme?';
    }

    // Caste related
    if (lower.contains('caste') ||
        lower.contains('sc') ||
        lower.contains('st') ||
        lower.contains('obc')) {
      return 'Do you belong to the eligible caste category for this scheme?';
    }

    // Gender related
    if (lower.contains('gender') ||
        lower.contains('female') ||
        lower.contains('male') ||
        lower.contains('woman') ||
        lower.contains('women')) {
      return 'Do you meet the gender eligibility requirement for this scheme?';
    }

    // Marital status
    if (lower.contains('marital') ||
        lower.contains('married') ||
        lower.contains('single') ||
        lower.contains('widow')) {
      return 'Do you meet the marital status requirement for this scheme?';
    }

    // Residency/Domicile
    if (lower.contains('resident') ||
        lower.contains('domicile') ||
        lower.contains('state') ||
        lower.contains('city')) {
      return 'Are you a resident of the eligible state/area as per scheme guidelines?';
    }

    // Employment status
    if (lower.contains('employed') ||
        lower.contains('unemployed') ||
        lower.contains('job')) {
      return 'Do you meet the employment status requirement for this scheme?';
    }

    // Business/Self-employed
    if (lower.contains('business') ||
        lower.contains('self-employed') ||
        lower.contains('entrepreneur')) {
      return 'Do you meet the business/self-employment criteria for this scheme?';
    }

    // Poverty line
    if (lower.contains('poverty') ||
        lower.contains('bpl') ||
        lower.contains('apl')) {
      return 'Do you fall within the eligible poverty line category as per scheme requirements?';
    }

    // Disability
    if (lower.contains('disability') ||
        lower.contains('disabled') ||
        lower.contains('handicapped')) {
      return 'Do you have a valid disability certificate as per scheme requirements?';
    }

    // Farmer related
    if (lower.contains('farmer') || lower.contains('agricultural')) {
      return 'Are you a registered farmer with valid agricultural land records?';
    }

    // BPL Card
    if (lower.contains('bpl card') || lower.contains('ration card')) {
      return 'Do you possess a valid BPL/Ration Card issued by competent authority?';
    }

    // Bank Account
    if (lower.contains('bank account') || lower.contains('savings account')) {
      return 'Do you have an active bank account in your name?';
    }

    // Default conversion
    return 'Do you meet the following requirement: $criteria?';
  }
}
