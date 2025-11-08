// allEligibilityQuestionsDisplay.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'geminiEligibilityQuestion.dart';
import 'allSchemeEligibility.dart';

class AllEligibilityQuestionsDisplay extends StatefulWidget {
  final bool isDarkMode;
  final double textSizeMultiplier;
  final String selectedLanguage;

  AllEligibilityQuestionsDisplay({
    this.isDarkMode = false,
    this.textSizeMultiplier = 1.0,
    this.selectedLanguage = 'English',
  });

  @override
  _AllEligibilityQuestionsDisplayState createState() =>
      _AllEligibilityQuestionsDisplayState();
}

class _AllEligibilityQuestionsDisplayState
    extends State<AllEligibilityQuestionsDisplay>
    with TickerProviderStateMixin {
  List<Map<String, String>> _questions = [];
  Map<int, String> _userAnswers = {};
  Map<int, Map<String, String>> _translatedQuestions = {};
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  String _selectedLanguage = 'English';
  PageController _pageController = PageController();
  late AnimationController _progressAnimController;
  late AnimationController _cardAnimController;
  late Animation<double> _progressAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<Offset> _cardSlideAnimation;

  FlutterTts flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _isTranslating = false;
  int _translationProgress = 0;

  static const String geminiApiKey = 'AIzaSyDRJ80dwt7j5wL8WSJoINZRK3enlC8hVkw';
  static const String geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // CRITICAL: Increased delays to prevent rate limiting
  static const int TRANSLATION_DELAY_MS =
      2000; // Increased from 800ms to 2000ms
  static const int MAX_RETRIES = 3;
  static const int RETRY_DELAY_MS = 3000;

  // UI Translations
  final Map<String, Map<String, String>> _uiTranslations = {
    'English': {
      'title': 'Eligibility Check',
      'subtitle': 'Answer all questions to find your schemes',
      'question': 'Question',
      'translating': 'Translating...',
      'translatingProgress': 'Translating question',
      'listen': 'Listen to Question',
      'stop': 'Stop',
      'yes': 'YES',
      'no': 'NO',
      'previous': 'Previous',
      'next': 'Next',
      'submit': 'Submit & View Results',
      'selectLanguage': 'Select Language',
      'loading': 'Loading Questions...',
      'evaluating': 'Evaluating Your Eligibility',
      'analyzing': 'Analyzing your responses...',
      'answerAll': 'Please answer all questions before submitting',
      'languageChanged': 'Language changed to',
      'translationFailed': 'Some translations failed, retrying...',
    },
    'Kannada': {
      'title': 'ಅರ್ಹತೆ ಪರಿಶೀಲನೆ',
      'subtitle': 'ನಿಮ್ಮ ಯೋಜನೆಗಳನ್ನು ಹುಡುಕಲು ಎಲ್ಲಾ ಪ್ರಶ್ನೆಗಳಿಗೆ ಉತ್ತರಿಸಿ',
      'question': 'ಪ್ರಶ್ನೆ',
      'translating': 'ಅನುವಾದ ಮಾಡಲಾಗುತ್ತಿದೆ...',
      'translatingProgress': 'ಪ್ರಶ್ನೆ ಅನುವಾದ',
      'listen': 'ಪ್ರಶ್ನೆಯನ್ನು ಕೇಳಿ',
      'stop': 'ನಿಲ್ಲಿಸಿ',
      'yes': 'ಹೌದು',
      'no': 'ಇಲ್ಲ',
      'previous': 'ಹಿಂದಿನದು',
      'next': 'ಮುಂದೆ',
      'submit': 'ಸಲ್ಲಿಸಿ ಮತ್ತು ಫಲಿತಾಂಶಗಳನ್ನು ವೀಕ್ಷಿಸಿ',
      'selectLanguage': 'ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ',
      'loading': 'ಪ್ರಶ್ನೆಗಳನ್ನು ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...',
      'evaluating': 'ನಿಮ್ಮ ಅರ್ಹತೆಯನ್ನು ಮೌಲ್ಯಮಾಪನ ಮಾಡಲಾಗುತ್ತಿದೆ',
      'analyzing': 'ನಿಮ್ಮ ಪ್ರತಿಕ್ರಿಯೆಗಳನ್ನು ವಿಶ್ಲೇಷಿಸಲಾಗುತ್ತಿದೆ...',
      'answerAll': 'ದಯವಿಟ್ಟು ಸಲ್ಲಿಸುವ ಮೊದಲು ಎಲ್ಲಾ ಪ್ರಶ್ನೆಗಳಿಗೆ ಉತ್ತರಿಸಿ',
      'languageChanged': 'ಭಾಷೆ ಬದಲಾಯಿಸಲಾಗಿದೆ',
      'translationFailed':
          'ಕೆಲವು ಅನುವಾದಗಳು ವಿಫಲವಾಗಿವೆ, ಮರುಪ್ರಯತ್ನಿಸಲಾಗುತ್ತಿದೆ...',
    },
    'Hindi': {
      'title': 'पात्रता जांच',
      'subtitle': 'अपनी योजनाओं को खोजने के लिए सभी प्रश्नों के उत्तर दें',
      'question': 'प्रश्न',
      'translating': 'अनुवाद हो रहा है...',
      'translatingProgress': 'प्रश्न अनुवाद',
      'listen': 'प्रश्न सुनें',
      'stop': 'रुकें',
      'yes': 'हाँ',
      'no': 'नहीं',
      'previous': 'पिछला',
      'next': 'अगला',
      'submit': 'जमा करें और परिणाम देखें',
      'selectLanguage': 'भाषा चुनें',
      'loading': 'प्रश्न लोड हो रहे हैं...',
      'evaluating': 'आपकी पात्रता का मूल्यांकन किया जा रहा है',
      'analyzing': 'आपकी प्रतिक्रियाओं का विश्लेषण किया जा रहा है...',
      'answerAll': 'कृपया जमा करने से पहले सभी प्रश्नों के उत्तर दें',
      'languageChanged': 'भाषा बदल दी गई',
      'translationFailed': 'कुछ अनुवाद विफल रहे, पुनः प्रयास कर रहे हैं...',
    },
  };

  String _t(String key) {
    return _uiTranslations[_selectedLanguage]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
    _loadQuestions();
    _initTts();

    _progressAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressAnimController, curve: Curves.easeInOut),
    );

    _cardAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _cardScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.elasticOut),
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _cardAnimController, curve: Curves.easeOut));
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

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimController.dispose();
    _cardAnimController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final allQuestions =
          await GeminiEligibilityQuestions.getStoredQuestions();

      if (allQuestions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('No questions found. Please generate questions first.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      allQuestions.shuffle();
      final selectedQuestions = allQuestions.take(20).toList();

      setState(() {
        _questions = selectedQuestions;
        _isLoading = false;
      });

      _cardAnimController.forward();
      _animateProgress();

      if (_selectedLanguage != 'English') {
        _translateAllQuestions();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: ${e.toString()}')),
        );
      }
    }
  }

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

  /// Enhanced translation with retry logic and better error handling
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
            .timeout(Duration(seconds: 15)); // Add timeout

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
          // Rate limit hit
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

    // All retries failed, return original question
    print(
        '✗ Q$questionIndex translation failed after $MAX_RETRIES attempts, using English');
    return question;
  }

  /// Translate all questions with proper rate limiting and progress tracking
  Future<void> _translateAllQuestions() async {
    if (_selectedLanguage == 'English') return;

    setState(() {
      _isTranslating = true;
      _translationProgress = 0;
    });

    List<int> failedIndices = [];

    // First pass: translate all questions
    for (int i = 0; i < _questions.length; i++) {
      if (_translatedQuestions[i]?[_selectedLanguage] == null) {
        final originalQuestion = _questions[i]['question'] ?? '';

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

            // Track if translation failed (returned English)
            if (translated == originalQuestion) {
              failedIndices.add(i);
            }
          });
        }

        // CRITICAL: Longer delay between translations to prevent rate limiting
        await Future.delayed(Duration(milliseconds: TRANSLATION_DELAY_MS));
      }
    }

    // Second pass: retry failed translations
    if (failedIndices.isNotEmpty) {
      print('Retrying ${failedIndices.length} failed translations...');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('translationFailed')),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }

      for (int i in failedIndices) {
        final originalQuestion = _questions[i]['question'] ?? '';

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
    if (_selectedLanguage == 'English') {
      return _questions[_currentQuestionIndex]['question'] ?? '';
    }
    return _translatedQuestions[_currentQuestionIndex]?[_selectedLanguage] ??
        _questions[_currentQuestionIndex]['question'] ??
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text-to-speech not available for this language'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _animateProgress() {
    final targetProgress = (_currentQuestionIndex + 1) / _questions.length;
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: targetProgress,
    ).animate(CurvedAnimation(
      parent: _progressAnimController,
      curve: Curves.easeInOut,
    ));
    _progressAnimController.forward(from: 0);
  }

  void _answerQuestion(String answer) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = answer;
    });
    flutterTts.stop();
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      flutterTts.stop();
      _cardAnimController.reset();
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.animateToPage(
        _currentQuestionIndex,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _cardAnimController.forward();
      _animateProgress();
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      flutterTts.stop();
      _cardAnimController.reset();
      setState(() {
        _currentQuestionIndex--;
      });
      _pageController.animateToPage(
        _currentQuestionIndex,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _cardAnimController.forward();
      _animateProgress();
    }
  }

  Future<void> _submitAnswers() async {
    if (_userAnswers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('answerAll')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await flutterTts.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isDarkMode
                    ? [Color(0xFF1E1E1E), Color(0xFF2C2C2C)]
                    : [Colors.white, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.purple.shade400],
                    ),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  _t('evaluating'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  _t('analyzing'),
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    final prefs = await SharedPreferences.getInstance();
    final answersMap =
        _userAnswers.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString('user_eligibility_answers', jsonEncode(answersMap));

    final questionsForEvaluation =
        _questions.asMap().map((index, q) => MapEntry(
              index.toString(),
              {
                'question': q['question'],
                'correctAnswer': q['answer'],
                'userAnswer': _userAnswers[index],
              },
            ));
    await prefs.setString(
        'questions_for_evaluation', jsonEncode(questionsForEvaluation));

    await Future.delayed(Duration(milliseconds: 800));
    Navigator.of(context).pop();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AllSchemeEligibility(
          userAnswers: _userAnswers,
          questions: _questions,
          isDarkMode: widget.isDarkMode,
          textSizeMultiplier: widget.textSizeMultiplier,
          selectedLanguage: _selectedLanguage,
        ),
      ),
    );
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
            Text(
              flag,
              style: TextStyle(fontSize: 28),
            ),
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
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDarkMode ? Color(0xFF1A1F3A) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        widget.isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: widget.isDarkMode
              ? LinearGradient(
                  colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : LinearGradient(
                  colors: [Colors.blue.shade50, Colors.purple.shade50],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _questions.isEmpty
                  ? _buildEmptyState(secondaryTextColor)
                  : Column(
                      children: [
                        _buildHeader(textColor, secondaryTextColor),
                        _buildProgressBar(),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _questions.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentQuestionIndex = index;
                              });
                              flutterTts.stop();
                            },
                            itemBuilder: (context, index) {
                              return _buildQuestionCard(
                                index,
                                textColor,
                                cardColor,
                              );
                            },
                          ),
                        ),
                        _buildNavigationBar(cardColor, textColor),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 4,
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            _t('loading'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color? secondaryTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: secondaryTextColor),
          SizedBox(height: 16),
          Text(
            'No questions available',
            style: TextStyle(color: secondaryTextColor, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color? secondaryTextColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isDarkMode ? Colors.white10 : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFF667eea)),
              onPressed: () {
                flutterTts.stop();
                Navigator.pop(context);
              },
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('title'),
                  style: TextStyle(
                    fontSize: 20 * widget.textSizeMultiplier,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _t('subtitle'),
                  style: TextStyle(
                    fontSize: 11 * widget.textSizeMultiplier,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.language_rounded, color: Colors.white),
              onPressed: _showLanguageMenu,
              tooltip: 'Change Language',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.question_answer_outlined,
                        color: Colors.white, size: 16),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_t('question')} ${_currentQuestionIndex + 1}',
                        style: TextStyle(
                          fontSize: 15 * widget.textSizeMultiplier,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (_isTranslating)
                        Text(
                          '${_t('translatingProgress')} $_translationProgress/${_questions.length}',
                          style: TextStyle(
                            fontSize: 9 * widget.textSizeMultiplier,
                            color: Color(0xFF667eea),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF667eea).withOpacity(0.2),
                      Color(0xFF764ba2).withOpacity(0.2)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_userAnswers.length}/${_questions.length}',
                  style: TextStyle(
                    fontSize: 12 * widget.textSizeMultiplier,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? Colors.white10
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: _progressAnimation.value,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF667eea).withOpacity(0.4),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, Color textColor, Color cardColor) {
    final hasAnswered = _userAnswers.containsKey(index);
    final userAnswer = _userAnswers[index];

    return SlideTransition(
      position: _cardSlideAnimation,
      child: ScaleTransition(
        scale: _cardScaleAnimation,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                constraints: BoxConstraints(
                  minHeight: 200,
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF667eea).withOpacity(0.1),
                            Color(0xFF764ba2).withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.help_outline_rounded,
                        size: 28,
                        color: Color(0xFF667eea),
                      ),
                    ),
                    SizedBox(height: 16),
                    Flexible(
                      child: Text(
                        _getCurrentQuestionText(),
                        style: TextStyle(
                          fontSize: 17 * widget.textSizeMultiplier,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 6,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildTtsButton(),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildAnswerButton(
                      label: _t('yes'),
                      icon: Icons.check_circle_rounded,
                      gradient: LinearGradient(
                        colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                      ),
                      isSelected: hasAnswered && userAnswer == 'yes',
                      onTap: () => _answerQuestion('yes'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildAnswerButton(
                      label: _t('no'),
                      icon: Icons.cancel_rounded,
                      gradient: LinearGradient(
                        colors: [Color(0xFFee0979), Color(0xFFff6a00)],
                      ),
                      isSelected: hasAnswered && userAnswer == 'no',
                      onTap: () => _answerQuestion('no'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  Widget _buildAnswerButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected
              ? null
              : (widget.isDarkMode ? Colors.white10 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (gradient.colors.first).withOpacity(0.4),
                    blurRadius: 15,
                    offset: Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16 * widget.textSizeMultiplier,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar(Color cardColor, Color textColor) {
    final allAnswered = _userAnswers.length == _questions.length;
    final isFirstQuestion = _currentQuestionIndex == 0;
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedOpacity(
              opacity: isFirstQuestion ? 0.5 : 1.0,
              duration: Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      widget.isDarkMode ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isFirstQuestion ? null : _goToPreviousQuestion,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF667eea),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            _t('previous'),
                            style: TextStyle(
                              color: Color(0xFF667eea),
                              fontWeight: FontWeight.bold,
                              fontSize: 14 * widget.textSizeMultiplier,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: isLastQuestion ? 2 : 1,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: (isLastQuestion && allAnswered)
                    ? LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      )
                    : (!isLastQuestion
                        ? LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          )
                        : null),
                color: (isLastQuestion && !allAnswered)
                    ? Colors.grey.shade300
                    : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: (isLastQuestion && allAnswered) || !isLastQuestion
                    ? [
                        BoxShadow(
                          color: Color(0xFF667eea).withOpacity(0.5),
                          blurRadius: 15,
                          offset: Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLastQuestion
                      ? (allAnswered ? _submitAnswers : null)
                      : _goToNextQuestion,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLastQuestion
                              ? Icons.check_circle_rounded
                              : Icons.arrow_forward_ios,
                          color: (isLastQuestion && !allAnswered)
                              ? Colors.grey.shade500
                              : Colors.white,
                          size: isLastQuestion ? 20 : 16,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isLastQuestion ? _t('submit') : _t('next'),
                            style: TextStyle(
                              fontSize: 14 * widget.textSizeMultiplier,
                              fontWeight: FontWeight.bold,
                              color: (isLastQuestion && !allAnswered)
                                  ? Colors.grey.shade500
                                  : Colors.white,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
