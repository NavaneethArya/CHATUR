// schemeEligibilityINdividual.dart - WITH MULTILINGUAL SUPPORT
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'schemeAPI.dart';
import 'geminiAPI.dart';

class SchemeEligibilityPage extends StatefulWidget {
  final Scheme scheme;
  final bool isDarkMode;
  final double textSizeMultiplier;
  final List<Map<String, dynamic>>? aiGeneratedQuestions;
  final String selectedLanguage;

  const SchemeEligibilityPage({
    Key? key,
    required this.scheme,
    required this.isDarkMode,
    required this.textSizeMultiplier,
    this.aiGeneratedQuestions,
    this.selectedLanguage = 'English',
  }) : super(key: key);

  @override
  _SchemeEligibilityPageState createState() => _SchemeEligibilityPageState();
}

class _SchemeEligibilityPageState extends State<SchemeEligibilityPage> {
  List<Map<String, dynamic>> _questions = [];
  Map<int, dynamic> _answers = {};
  Map<int, Map<String, String>> _translatedQuestions = {};
  int _currentQuestionIndex = 0;
  bool _isCheckingComplete = false;
  bool _isEvaluating = false;
  bool? _isEligible;
  String _resultType = '';
  String _eligibilityMessage = '';
  String _confidence = '';
  List<String> _failedCriteria = [];
  List<String> _missingDocuments = [];
  List<String> _recommendations = [];
  TextEditingController _numberController = TextEditingController();

  // Multilingual support
  String _selectedLanguage = 'English';
  FlutterTts flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _isTranslating = false;
  int _translationProgress = 0;

  static const String geminiApiKey = 'AIzaSyDRJ80dwt7j5wL8WSJoINZRK3enlC8hVkw';
  static const String geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  static const int TRANSLATION_DELAY_MS = 2000;
  static const int MAX_RETRIES = 3;
  static const int RETRY_DELAY_MS = 3000;

  // UI Translations
  final Map<String, Map<String, String>> _uiTranslations = {
    'English': {
      'title': 'AI Eligibility Assessment',
      'aiPowered': 'AI-Powered Assessment',
      'questionOf': 'Question',
      'of': 'of',
      'evaluating': 'AI is evaluating your eligibility...',
      'analyzing': 'Analyzing your responses against scheme criteria',
      'noQuestions': 'No questions available',
      'yes': 'Yes',
      'no': 'No',
      'next': 'Next',
      'previous': 'Previous Question',
      'enter': 'Enter',
      'congratulations': 'Congratulations!',
      'youAreEligible': 'YOU ARE FULLY ELIGIBLE',
      'notEligible': 'Not Eligible',
      'forThisScheme': 'FOR THIS SCHEME',
      'almostThere': 'Almost There!',
      'potentiallyEligible': 'POTENTIALLY ELIGIBLE',
      'nextSteps': 'Next Steps',
      'unmetCriteria': 'Unmet Criteria',
      'missingDocuments': 'Missing Documents',
      'suggestions': 'Suggestions',
      'recommendations': 'Recommendations',
      'checkAgain': 'Check Again',
      'goBack': 'Go Back',
      'selectLanguage': 'Select Language',
      'listen': 'Listen to Question',
      'stop': 'Stop',
      'translating': 'Translating...',
      'translatingProgress': 'Translating question',
      'languageChanged': 'Language changed to',
    },
    'Kannada': {
      'title': 'AI ಅರ್ಹತೆ ಮೌಲ್ಯಮಾಪನ',
      'aiPowered': 'AI-ಚಾಲಿತ ಮೌಲ್ಯಮಾಪನ',
      'questionOf': 'ಪ್ರಶ್ನೆ',
      'of': 'ರಲ್ಲಿ',
      'evaluating': 'AI ನಿಮ್ಮ ಅರ್ಹತೆಯನ್ನು ಮೌಲ್ಯಮಾಪನ ಮಾಡುತ್ತಿದೆ...',
      'analyzing':
          'ಯೋಜನೆ ಮಾನದಂಡಗಳ ವಿರುದ್ಧ ನಿಮ್ಮ ಪ್ರತಿಕ್ರಿಯೆಗಳನ್ನು ವಿಶ್ಲೇಷಿಸಲಾಗುತ್ತಿದೆ',
      'noQuestions': 'ಯಾವುದೇ ಪ್ರಶ್ನೆಗಳು ಲಭ್ಯವಿಲ್ಲ',
      'yes': 'ಹೌದು',
      'no': 'ಇಲ್ಲ',
      'next': 'ಮುಂದೆ',
      'previous': 'ಹಿಂದಿನ ಪ್ರಶ್ನೆ',
      'enter': 'ನಮೂದಿಸಿ',
      'congratulations': 'ಅಭಿನಂದನೆಗಳು!',
      'youAreEligible': 'ನೀವು ಸಂಪೂರ್ಣವಾಗಿ ಅರ್ಹರಾಗಿದ್ದೀರಿ',
      'notEligible': 'ಅರ್ಹರಲ್ಲ',
      'forThisScheme': 'ಈ ಯೋಜನೆಗೆ',
      'almostThere': 'ಬಹುತೇಕ ಅಲ್ಲಿದೆ!',
      'potentiallyEligible': 'ಸಂಭಾವ್ಯವಾಗಿ ಅರ್ಹ',
      'nextSteps': 'ಮುಂದಿನ ಹಂತಗಳು',
      'unmetCriteria': 'ಪೂರೈಸದ ಮಾನದಂಡಗಳು',
      'missingDocuments': 'ಕಾಣೆಯಾದ ದಾಖಲೆಗಳು',
      'suggestions': 'ಸಲಹೆಗಳು',
      'recommendations': 'ಶಿಫಾರಸುಗಳು',
      'checkAgain': 'ಮತ್ತೆ ಪರಿಶೀಲಿಸಿ',
      'goBack': 'ಹಿಂತಿರುಗಿ',
      'selectLanguage': 'ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ',
      'listen': 'ಪ್ರಶ್ನೆಯನ್ನು ಕೇಳಿ',
      'stop': 'ನಿಲ್ಲಿಸಿ',
      'translating': 'ಅನುವಾದ ಮಾಡಲಾಗುತ್ತಿದೆ...',
      'translatingProgress': 'ಪ್ರಶ್ನೆ ಅನುವಾದ',
      'languageChanged': 'ಭಾಷೆ ಬದಲಾಯಿಸಲಾಗಿದೆ',
    },
    'Hindi': {
      'title': 'AI पात्रता मूल्यांकन',
      'aiPowered': 'AI-संचालित मूल्यांकन',
      'questionOf': 'प्रश्न',
      'of': 'में से',
      'evaluating': 'AI आपकी पात्रता का मूल्यांकन कर रहा है...',
      'analyzing':
          'योजना मानदंडों के विरुद्ध आपकी प्रतिक्रियाओं का विश्लेषण किया जा रहा है',
      'noQuestions': 'कोई प्रश्न उपलब्ध नहीं',
      'yes': 'हाँ',
      'no': 'नहीं',
      'next': 'अगला',
      'previous': 'पिछला प्रश्न',
      'enter': 'दर्ज करें',
      'congratulations': 'बधाई हो!',
      'youAreEligible': 'आप पूर्णतः पात्र हैं',
      'notEligible': 'पात्र नहीं',
      'forThisScheme': 'इस योजना के लिए',
      'almostThere': 'लगभग पहुंच गए!',
      'potentiallyEligible': 'संभावित रूप से पात्र',
      'nextSteps': 'अगले कदम',
      'unmetCriteria': 'अपूर्ण मानदंड',
      'missingDocuments': 'गायब दस्तावेज़',
      'suggestions': 'सुझाव',
      'recommendations': 'सिफारिशें',
      'checkAgain': 'फिर से जांचें',
      'goBack': 'वापस जाएं',
      'selectLanguage': 'भाषा चुनें',
      'listen': 'प्रश्न सुनें',
      'stop': 'रुकें',
      'translating': 'अनुवाद हो रहा है...',
      'translatingProgress': 'प्रश्न अनुवाद',
      'languageChanged': 'भाषा बदल दी गई',
    },
  };

  String _t(String key) {
    return _uiTranslations[_selectedLanguage]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
    _initTts();

    if (widget.aiGeneratedQuestions != null &&
        widget.aiGeneratedQuestions!.isNotEmpty) {
      _questions = widget.aiGeneratedQuestions!;
      _validateQuestionsAreUnique();

      if (_selectedLanguage != 'English') {
        _translateAllQuestions();
      }
    }
  }

  Future<void> _initTts() async {
    try {
      await flutterTts.setVolume(1.0);
      await flutterTts.setSpeechRate(0.4);
      await flutterTts.setPitch(1.0);

      flutterTts.setStartHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = true;
          });
        }
      });

      flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      flutterTts.setErrorHandler((msg) {
        print('TTS Error: $msg');
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      flutterTts.setCancelHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });
    } catch (e) {
      print('TTS Init Error: $e');
    }
  }

  void _validateQuestionsAreUnique() {
    Set<String> seenQuestions = {};
    List<Map<String, dynamic>> uniqueQuestions = [];

    for (var q in _questions) {
      final questionText = q['question']?.toString().toLowerCase() ?? '';
      if (!seenQuestions.contains(questionText)) {
        seenQuestions.add(questionText);
        uniqueQuestions.add(q);
      }
    }

    _questions = uniqueQuestions;
  }

  @override
  void dispose() {
    _numberController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  // Translation methods
  String _extractJsonSafely(String input) {
    input = input.replaceAll(RegExp(r'```json\s*'), '');
    input = input.replaceAll(RegExp(r'```\s*'), '');
    input = input.trim();

    int start = input.indexOf('{');
    int end = input.lastIndexOf('}');

    if (start != -1 && end != -1 && end > start) {
      String extracted = input.substring(start, end + 1);
      if (_isValidJsonStructure(extracted)) {
        return extracted;
      }
    }

    start = input.indexOf('[');
    end = input.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      String extracted = input.substring(start, end + 1);
      if (_isValidJsonStructure(extracted)) {
        return extracted;
      }
    }

    return '{"translated": ""}';
  }

  bool _isValidJsonStructure(String json) {
    int quoteCount = '"'.allMatches(json).length;
    int openBraces = '{'.allMatches(json).length;
    int closeBraces = '}'.allMatches(json).length;

    return quoteCount % 2 == 0 && openBraces == closeBraces;
  }

  Future<String> _translateQuestionWithRetry(
      String question, String targetLanguage, int questionIndex) async {
    for (int attempt = 1; attempt <= MAX_RETRIES; attempt++) {
      try {
        print(
            'Translating Q$questionIndex to $targetLanguage (Attempt $attempt/$MAX_RETRIES)');

        String scriptName = targetLanguage == 'Kannada' ? 'ಕನ್ನಡ' : 'हिंदी';
        String scriptInstruction = targetLanguage == 'Kannada'
            ? 'Use ONLY Kannada script (ಕನ್ನಡ ಲಿಪಿ), not Roman letters.'
            : 'Use ONLY Devanagari script (देवनागरी लिपि), not Roman letters.';

        final prompt =
            '''You are a translation API that returns ONLY valid JSON.

Translate this English question to $targetLanguage language.

CRITICAL REQUIREMENTS:
1. Write translation ONLY in native $scriptName script. $scriptInstruction
2. Return ONLY a JSON object in this EXACT format: {"translated": "your translation here"}
3. DO NOT include any other text, explanation, markdown, or formatting
4. DO NOT truncate the translation - complete the full sentence
5. If you cannot translate, return: {"translated": "$question"}

English question: "$question"

JSON response (ONLY):''';

        final requestBody = jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 2048,
            'topP': 0.8,
            'topK': 10,
          },
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_NONE'
            }
          ]
        });

        final response = await http
            .post(
              Uri.parse('$geminiApiUrl?key=$geminiApiKey'),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: requestBody,
            )
            .timeout(Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data['candidates'] != null && data['candidates'].isNotEmpty) {
            String rawText =
                data['candidates'][0]['content']['parts'][0]['text'];
            String cleanedJson = _extractJsonSafely(rawText);

            try {
              final jsonData = jsonDecode(cleanedJson);
              if (jsonData is Map && jsonData.containsKey('translated')) {
                String translatedText =
                    jsonData['translated'].toString().trim();

                translatedText = translatedText.replaceAll(
                    RegExp(
                        r'^(Translation:|$targetLanguage translation:|In $scriptName:)\s*',
                        caseSensitive: false),
                    '');
                translatedText =
                    translatedText.replaceAll(RegExp(r'\n+'), ' ').trim();

                bool hasNativeScript = false;
                if (targetLanguage == 'Kannada') {
                  hasNativeScript =
                      RegExp(r'[\u0C80-\u0CFF]').hasMatch(translatedText);
                } else if (targetLanguage == 'Hindi') {
                  hasNativeScript =
                      RegExp(r'[\u0900-\u097F]').hasMatch(translatedText);
                }

                if (hasNativeScript && translatedText.isNotEmpty) {
                  print(
                      '✓ Q$questionIndex translated successfully: $translatedText');
                  return translatedText;
                } else {
                  print('⚠ Q$questionIndex missing native script, retrying...');
                  if (attempt < MAX_RETRIES) {
                    await Future.delayed(
                        Duration(milliseconds: RETRY_DELAY_MS));
                    continue;
                  }
                }
              }
            } catch (e) {
              print('✗ Q$questionIndex JSON parse error: $e');
              if (attempt < MAX_RETRIES) {
                await Future.delayed(Duration(milliseconds: RETRY_DELAY_MS));
                continue;
              }
            }
          }
        } else if (response.statusCode == 429) {
          print('⚠ Rate limit hit at Q$questionIndex, waiting longer...');
          await Future.delayed(Duration(milliseconds: RETRY_DELAY_MS * 2));
          continue;
        } else {
          print('✗ API Error at Q$questionIndex: ${response.statusCode}');
          if (attempt < MAX_RETRIES) {
            await Future.delayed(Duration(milliseconds: RETRY_DELAY_MS));
            continue;
          }
        }
      } catch (e) {
        print('✗ Translation error Q$questionIndex (Attempt $attempt): $e');
        if (attempt < MAX_RETRIES) {
          await Future.delayed(Duration(milliseconds: RETRY_DELAY_MS));
          continue;
        }
      }
    }

    print(
        '✗ Q$questionIndex translation failed after $MAX_RETRIES attempts, using English');
    return question;
  }

  Future<void> _translateAllQuestions() async {
    if (_selectedLanguage == 'English') return;

    setState(() {
      _isTranslating = true;
      _translationProgress = 0;
    });

    List<int> failedIndices = [];

    for (int i = 0; i < _questions.length; i++) {
      if (_translatedQuestions[i]?[_selectedLanguage] == null) {
        final originalQuestion = _questions[i]['question']?.toString() ?? '';

        setState(() {
          _translationProgress = i + 1;
        });

        final translated = await _translateQuestionWithRetry(
            originalQuestion, _selectedLanguage, i + 1);

        if (mounted) {
          setState(() {
            if (_translatedQuestions[i] == null) {
              _translatedQuestions[i] = {};
            }
            _translatedQuestions[i]![_selectedLanguage] = translated;

            if (translated == originalQuestion) {
              failedIndices.add(i);
            }
          });
        }

        await Future.delayed(Duration(milliseconds: TRANSLATION_DELAY_MS));
      }
    }

    // Retry failed translations
    if (failedIndices.isNotEmpty && mounted) {
      for (int i in failedIndices) {
        final originalQuestion = _questions[i]['question']?.toString() ?? '';

        final translated = await _translateQuestionWithRetry(
            originalQuestion, _selectedLanguage, i + 1);

        if (mounted && translated != originalQuestion) {
          setState(() {
            _translatedQuestions[i]![_selectedLanguage] = translated;
          });
        }

        await Future.delayed(Duration(milliseconds: TRANSLATION_DELAY_MS));
      }
    }

    setState(() {
      _isTranslating = false;
      _translationProgress = 0;
    });
  }

  Future<void> _changeLanguage(String targetLanguage) async {
    if (_selectedLanguage == targetLanguage) return;

    await flutterTts.stop();

    setState(() {
      _selectedLanguage = targetLanguage;
      _isTranslating = true;
      _translationProgress = 0;
    });

    if (targetLanguage != 'English') {
      await _translateAllQuestions();
    }

    setState(() {
      _isTranslating = false;
      _translationProgress = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_t('languageChanged')} $targetLanguage'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF667eea),
        ),
      );
    }
  }

  String _getCurrentQuestionText() {
    if (_currentQuestionIndex >= _questions.length) return '';

    if (_selectedLanguage == 'English') {
      return _questions[_currentQuestionIndex]['question']?.toString() ?? '';
    }
    return _translatedQuestions[_currentQuestionIndex]?[_selectedLanguage] ??
        _questions[_currentQuestionIndex]['question']?.toString() ??
        '';
  }

  Future<void> _speakQuestion() async {
    try {
      if (_isSpeaking) {
        await flutterTts.stop();
        return;
      }

      final questionText = _getCurrentQuestionText();

      String ttsLanguage = 'en-US';
      if (_selectedLanguage == 'Kannada') {
        ttsLanguage = 'kn-IN';
      } else if (_selectedLanguage == 'Hindi') {
        ttsLanguage = 'hi-IN';
      }

      await flutterTts.setLanguage(ttsLanguage);
      await flutterTts.speak(questionText);
    } catch (e) {
      print('TTS Speak Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Text-to-speech not available for this language'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showLanguageMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode ? Color(0xFF1A1F3A) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                _t('selectLanguage'),
                style: TextStyle(
                  fontSize: 20 * widget.textSizeMultiplier,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 20),
              _buildLanguageOption('English', '🇬🇧', 'English'),
              _buildLanguageOption('Kannada', '🇮🇳', 'ಕನ್ನಡ'),
              _buildLanguageOption('Hindi', '🇮🇳', 'हिंदी'),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String language, String flag, String nativeText) {
    final isSelected = _selectedLanguage == language;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _changeLanguage(language);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                )
              : null,
          color: isSelected
              ? null
              : (widget.isDarkMode ? Colors.white10 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: TextStyle(fontSize: 28)),
            SizedBox(width: 16),
            Text(
              nativeText,
              style: TextStyle(
                fontSize: 18 * widget.textSizeMultiplier,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (widget.isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
            Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  void _handleAnswer(dynamic answer) {
    setState(() {
      _answers[_currentQuestionIndex] = answer;

      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        _numberController.clear();
      } else {
        _evaluateWithAI();
      }
    });

    flutterTts.stop();
  }

  Future<void> _evaluateWithAI() async {
    setState(() {
      _isEvaluating = true;
    });

    try {
      final evaluation = await GeminiService.evaluateEligibility(
        widget.scheme.eligibility,
        widget.scheme.documentsRequired,
        _questions,
        _answers,
      );

      setState(() {
        _isCheckingComplete = true;
        _isEligible = evaluation['eligible'] ?? false;
        _resultType = evaluation['status'] ?? 'not_eligible';
        _confidence = evaluation['confidence'] ?? 'low';
        _eligibilityMessage = evaluation['message'] ?? 'Evaluation completed.';
        _failedCriteria = List<String>.from(evaluation['failedCriteria'] ?? []);
        _missingDocuments =
            List<String>.from(evaluation['missingDocuments'] ?? []);
        _recommendations =
            List<String>.from(evaluation['recommendations'] ?? []);
        _isEvaluating = false;
      });

      // Translate result content if not in English
      if (_selectedLanguage != 'English') {
        await _translateResultContent();
      }
    } catch (e) {
      setState(() {
        _isCheckingComplete = true;
        _isEligible = false;
        _resultType = 'not_eligible';
        _confidence = 'low';
        _eligibilityMessage = 'Error during evaluation. Please try again.';
        _failedCriteria = [];
        _missingDocuments = [];
        _recommendations = ['Contact scheme office for assistance'];
        _isEvaluating = false;
      });
    }
  }

  Future<void> _translateResultContent() async {
    try {
      // Translate eligibility message
      if (_eligibilityMessage.isNotEmpty) {
        final translatedMessage = await _translateTextWithRetry(
            _eligibilityMessage, _selectedLanguage);
        if (mounted) {
          setState(() {
            _eligibilityMessage = translatedMessage;
          });
        }
      }

      // Translate failed criteria
      List<String> translatedCriteria = [];
      for (String criteria in _failedCriteria) {
        final translated =
            await _translateTextWithRetry(criteria, _selectedLanguage);
        translatedCriteria.add(translated);
        await Future.delayed(Duration(milliseconds: 500));
      }
      if (mounted) {
        setState(() {
          _failedCriteria = translatedCriteria;
        });
      }

      // Translate missing documents
      List<String> translatedDocs = [];
      for (String doc in _missingDocuments) {
        final translated =
            await _translateTextWithRetry(doc, _selectedLanguage);
        translatedDocs.add(translated);
        await Future.delayed(Duration(milliseconds: 500));
      }
      if (mounted) {
        setState(() {
          _missingDocuments = translatedDocs;
        });
      }

      // Translate recommendations
      List<String> translatedRecs = [];
      for (String rec in _recommendations) {
        final translated =
            await _translateTextWithRetry(rec, _selectedLanguage);
        translatedRecs.add(translated);
        await Future.delayed(Duration(milliseconds: 500));
      }
      if (mounted) {
        setState(() {
          _recommendations = translatedRecs;
        });
      }
    } catch (e) {
      print('Error translating result content: $e');
    }
  }

  Future<String> _translateTextWithRetry(
      String text, String targetLanguage) async {
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        String scriptName = targetLanguage == 'Kannada' ? 'ಕನ್ನಡ' : 'हिंदी';
        String scriptInstruction = targetLanguage == 'Kannada'
            ? 'Use ONLY Kannada script (ಕನ್ನಡ ಲಿಪಿ), not Roman letters.'
            : 'Use ONLY Devanagari script (देवनागरी लिपि), not Roman letters.';

        final prompt =
            '''You are a translation API that returns ONLY valid JSON.

Translate this English text to $targetLanguage language.

CRITICAL REQUIREMENTS:
1. Write translation ONLY in native $scriptName script. $scriptInstruction
2. Return ONLY a JSON object in this EXACT format: {"translated": "your translation here"}
3. DO NOT include any other text, explanation, markdown, or formatting
4. Preserve the meaning and context accurately

English text: "$text"

JSON response (ONLY):''';

        final requestBody = jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 2048,
          },
        });

        final response = await http
            .post(
              Uri.parse('$geminiApiUrl?key=$geminiApiKey'),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: requestBody,
            )
            .timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data['candidates'] != null && data['candidates'].isNotEmpty) {
            String rawText =
                data['candidates'][0]['content']['parts'][0]['text'];
            String cleanedJson = _extractJsonSafely(rawText);

            try {
              final jsonData = jsonDecode(cleanedJson);
              if (jsonData is Map && jsonData.containsKey('translated')) {
                String translatedText =
                    jsonData['translated'].toString().trim();
                translatedText =
                    translatedText.replaceAll(RegExp(r'\n+'), ' ').trim();

                bool hasNativeScript = false;
                if (targetLanguage == 'Kannada') {
                  hasNativeScript =
                      RegExp(r'[\u0C80-\u0CFF]').hasMatch(translatedText);
                } else if (targetLanguage == 'Hindi') {
                  hasNativeScript =
                      RegExp(r'[\u0900-\u097F]').hasMatch(translatedText);
                }

                if (hasNativeScript && translatedText.isNotEmpty) {
                  return translatedText;
                }
              }
            } catch (e) {
              print('JSON parse error in text translation: $e');
            }
          }
        }
      } catch (e) {
        print('Text translation error (Attempt $attempt): $e');
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 1000));
          continue;
        }
      }
    }

    return text; // Return original if translation fails
  }

  void _resetCheck() {
    setState(() {
      _currentQuestionIndex = 0;
      _answers.clear();
      _isCheckingComplete = false;
      _isEligible = null;
      _resultType = '';
      _eligibilityMessage = '';
      _confidence = '';
      _failedCriteria = [];
      _missingDocuments = [];
      _recommendations = [];
      _numberController.clear();
    });
    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? Color(0xFF121212) : Colors.grey.shade50;
    final cardColor = widget.isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        widget.isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.assessment_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                _t('title'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18 * widget.textSizeMultiplier,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Container(
            width: 43,
            height: 43,
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                ],
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.language_rounded, color: Colors.white),
              onPressed: _showLanguageMenu,
              tooltip: _t('selectLanguage'),
            ),
          ),
        ],
      ),
      body: _isEvaluating
          ? _buildEvaluatingScreen(cardColor, textColor)
          : _isCheckingComplete
              ? _buildResultScreen(cardColor, textColor, secondaryTextColor)
              : _buildQuestionScreen(cardColor, textColor, secondaryTextColor),
    );
  }

  Widget _buildEvaluatingScreen(Color cardColor, Color textColor) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(32),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.15),
              blurRadius: 12,
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 24),
            Text(
              _t('evaluating'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18 * widget.textSizeMultiplier,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _t('analyzing'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14 * widget.textSizeMultiplier,
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionScreen(
      Color cardColor, Color textColor, Color? secondaryTextColor) {
    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                _t('noQuestions'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16 * widget.textSizeMultiplier,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.blue.shade400],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  _t('aiPowered'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * widget.textSizeMultiplier,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.1),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_t('questionOf')} ${_currentQuestionIndex + 1} ${_t('of')} ${_questions.length}',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14 * widget.textSizeMultiplier,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 14 * widget.textSizeMultiplier,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_isTranslating) ...[
                  SizedBox(height: 8),
                  Text(
                    '${_t('translatingProgress')} $_translationProgress/${_questions.length}',
                    style: TextStyle(
                      fontSize: 12 * widget.textSizeMultiplier,
                      color: Color(0xFF667eea),
                    ),
                  ),
                ],
                SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor:
                        widget.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.15),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.help_outline, color: Colors.blueAccent, size: 40),
                SizedBox(height: 16),
                Text(
                  _getCurrentQuestionText(),
                  style: TextStyle(
                    fontSize: 18 * widget.textSizeMultiplier,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
                if (currentQuestion['relatedCriteria'] != null) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${currentQuestion['relatedCriteria']}',
                            style: TextStyle(
                              fontSize: 13 * widget.textSizeMultiplier,
                              color: Colors.blueAccent,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 16),
                _buildTtsButton(),
                SizedBox(height: 24),
                if (currentQuestion['type'] == 'yesno')
                  _buildYesNoButtons(textColor)
                else if (currentQuestion['type'] == 'number')
                  _buildNumberInput(
                      currentQuestion, textColor, secondaryTextColor),
              ],
            ),
          ),
          SizedBox(height: 16),
          if (_currentQuestionIndex > 0)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentQuestionIndex--;
                  _numberController.clear();
                });
                flutterTts.stop();
              },
              icon: Icon(Icons.arrow_back, color: Colors.blueAccent),
              label: Text(
                _t('previous'),
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 16 * widget.textSizeMultiplier,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTtsButton() {
    return GestureDetector(
      onTap: _speakQuestion,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isSpeaking
                ? [Color(0xFFee0979), Color(0xFFff6a00)]
                : [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (_isSpeaking ? Color(0xFFee0979) : Color(0xFF667eea))
                  .withOpacity(0.4),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSpeaking ? Icons.stop_circle : Icons.volume_up_rounded,
              color: Colors.white,
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              _isSpeaking ? _t('stop') : _t('listen'),
              style: TextStyle(
                fontSize: 14 * widget.textSizeMultiplier,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYesNoButtons(Color textColor) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleAnswer(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 24),
                SizedBox(width: 8),
                Text(
                  _t('yes'),
                  style: TextStyle(
                    fontSize: 18 * widget.textSizeMultiplier,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleAnswer(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, size: 24),
                SizedBox(width: 8),
                Text(
                  _t('no'),
                  style: TextStyle(
                    fontSize: 18 * widget.textSizeMultiplier,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput(Map<String, dynamic> question, Color textColor,
      Color? secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _numberController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 18 * widget.textSizeMultiplier,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: '${_t('enter')} ${question['unit'] ?? 'value'}',
            hintStyle: TextStyle(color: secondaryTextColor),
            suffixText: question['unit'],
            suffixStyle: TextStyle(
              color: Colors.blueAccent,
              fontSize: 16 * widget.textSizeMultiplier,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blueAccent, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (_numberController.text.isNotEmpty) {
              final value = int.tryParse(_numberController.text);
              if (value != null) {
                _handleAnswer(value);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_forward, size: 24),
              SizedBox(width: 8),
              Text(
                _t('next'),
                style: TextStyle(
                  fontSize: 18 * widget.textSizeMultiplier,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultScreen(
      Color cardColor, Color textColor, Color? secondaryTextColor) {
    if (_resultType == 'eligible') {
      return _buildEligibleResultScreen(cardColor, textColor);
    } else if (_resultType == 'maybe_eligible') {
      return _buildMaybeEligibleResultScreen(cardColor, textColor);
    } else {
      return _buildNotEligibleResultScreen(cardColor, textColor);
    }
  }

  Widget _buildEligibleResultScreen(Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDarkMode
              ? [Color(0xFF1a3a2e), Color(0xFF121212)]
              : [Colors.green.shade50, Colors.white],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 800),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.green.shade400, Colors.teal.shade600],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: Icon(Icons.check_circle,
                          color: Colors.white, size: 80),
                    ),
                  );
                },
              ),
              SizedBox(height: 32),
              Text(
                _t('congratulations'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34 * widget.textSizeMultiplier,
                  fontWeight: FontWeight.w900,
                  color: Colors.green.shade700,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.teal.shade500],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _t('youAreEligible'),
                  style: TextStyle(
                    fontSize: 20 * widget.textSizeMultiplier,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.verified,
                        color: Colors.green.shade700, size: 40),
                    SizedBox(height: 16),
                    Text(
                      _eligibilityMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16 * widget.textSizeMultiplier,
                        color: textColor,
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              if (_recommendations.isNotEmpty)
                _buildInfoCard(
                  cardColor,
                  textColor,
                  _t('nextSteps'),
                  Icons.lightbulb,
                  Colors.green,
                  _recommendations,
                ),
              SizedBox(height: 32),
              _buildActionButtons(Colors.green.shade600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotEligibleResultScreen(Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDarkMode
              ? [Color(0xFF3a1a1a), Color(0xFF121212)]
              : [Colors.red.shade50, Colors.white],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 800),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.red.shade400, Colors.red.shade700],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: Icon(Icons.cancel, color: Colors.white, size: 80),
                    ),
                  );
                },
              ),
              SizedBox(height: 32),
              Text(
                _t('notEligible'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34 * widget.textSizeMultiplier,
                  fontWeight: FontWeight.w900,
                  color: Colors.red.shade800,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade700],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _t('forThisScheme'),
                  style: TextStyle(
                    fontSize: 18 * widget.textSizeMultiplier,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 40),
                    SizedBox(height: 16),
                    Text(
                      _eligibilityMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16 * widget.textSizeMultiplier,
                        color: textColor,
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              if (_failedCriteria.isNotEmpty)
                _buildListCard(
                  cardColor,
                  textColor,
                  _t('unmetCriteria'),
                  Icons.warning_amber_rounded,
                  Colors.red,
                  _failedCriteria,
                ),
              if (_missingDocuments.isNotEmpty) ...[
                SizedBox(height: 24),
                _buildListCard(
                  cardColor,
                  textColor,
                  _t('missingDocuments'),
                  Icons.description,
                  Colors.orange,
                  _missingDocuments,
                ),
              ],
              if (_recommendations.isNotEmpty) ...[
                SizedBox(height: 24),
                _buildInfoCard(
                  cardColor,
                  textColor,
                  _t('suggestions'),
                  Icons.lightbulb_outline,
                  Colors.blue,
                  _recommendations,
                ),
              ],
              SizedBox(height: 32),
              _buildActionButtons(Colors.red.shade600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaybeEligibleResultScreen(Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDarkMode
              ? [Color(0xFF3a2a1a), Color(0xFF121212)]
              : [Colors.orange.shade50, Colors.white],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 800),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.amber.shade400,
                            Colors.orange.shade600
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: Icon(Icons.info, color: Colors.white, size: 80),
                    ),
                  );
                },
              ),
              SizedBox(height: 32),
              Text(
                _t('almostThere'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34 * widget.textSizeMultiplier,
                  fontWeight: FontWeight.w900,
                  color: Colors.orange.shade800,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _t('potentiallyEligible'),
                  style: TextStyle(
                    fontSize: 18 * widget.textSizeMultiplier,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange.shade700, size: 40),
                    SizedBox(height: 16),
                    Text(
                      _eligibilityMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16 * widget.textSizeMultiplier,
                        color: textColor,
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              if (_missingDocuments.isNotEmpty)
                _buildListCard(
                  cardColor,
                  textColor,
                  _t('missingDocuments'),
                  Icons.description,
                  Colors.orange,
                  _missingDocuments,
                ),
              if (_recommendations.isNotEmpty) ...[
                SizedBox(height: 24),
                _buildInfoCard(
                  cardColor,
                  textColor,
                  _t('recommendations'),
                  Icons.assignment_outlined,
                  Colors.blue,
                  _recommendations,
                ),
              ],
              SizedBox(height: 32),
              _buildActionButtons(Colors.orange.shade600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(
    Color cardColor,
    Color textColor,
    String title,
    IconData icon,
    MaterialColor color,
    List<String> items,
  ) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color.shade700, size: 24),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20 * widget.textSizeMultiplier,
                  fontWeight: FontWeight.bold,
                  color: color.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ...items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.close_rounded, size: 24, color: color.shade600),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item
                            .replaceFirst('Required Documents: ', '')
                            .replaceFirst('Required Document: ', ''),
                        style: TextStyle(
                          fontSize: 15 * widget.textSizeMultiplier,
                          color: textColor,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    Color cardColor,
    Color textColor,
    String title,
    IconData icon,
    MaterialColor color,
    List<String> items,
  ) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color.shade700, size: 24),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20 * widget.textSizeMultiplier,
                  fontWeight: FontWeight.bold,
                  color: color.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ...items.asMap().entries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.shade400, color.shade600],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 15 * widget.textSizeMultiplier,
                          color: textColor,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _resetCheck,
            icon: Icon(Icons.refresh, size: 22),
            label: Text(
              _t('checkAgain'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 5,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              flutterTts.stop();
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back, size: 22),
            label: Text(
              _t('goBack'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 81, 166, 241),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 5,
            ),
          ),
        ),
      ],
    );
  }
}
