// document.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'documentQuestion.dart';

// Colors
class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF2D3561);
  static const Color accent = Color(0xFF4ECDC4);
  static const Color success = Color(0xFF44CF6C);
  static const Color background = Color(0xFFF8F9FA);
}

// Localization Class
class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Smart Document Assistant',
      'aiPoweredTitle': 'AI-Powered Form Assistant',
      'step1': '📸 Scan your form',
      'step2': '🤖 AI analyzes fields',
      'step3': '✍️ Answer simple questions',
      'step4': '📄 Get filled form',
      'noDocument': 'No document selected',
      'uploadCapture': 'Upload or capture a form',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'analyzeDocument': 'Analyze Document',
      'analyzing': 'Analyzing...',
      'whyChooseUs': 'Why Choose Us?',
      'fastProcessing': 'Fast Processing',
      'fastProcessingDesc': 'AI analyzes your form in seconds',
      'multiLanguage': 'Multi-Language',
      'multiLanguageDesc': 'English, Kannada, and Hindi support',
      'securePrivate': 'Secure & Private',
      'securePrivateDesc': 'Your data stays on your device',
      'errorPickImage': 'Error picking image',
      'selectImageFirst': 'Please select an image first',
      'noTextFound': 'No text found in image. Please try with a clearer image.',
    },
    'kn': {
      'appTitle': 'ಸ್ಮಾರ್ಟ್ ಡಾಕ್ಯುಮೆಂಟ್ ಸಹಾಯಕ',
      'aiPoweredTitle': 'AI-ಚಾಲಿತ ಫಾರ್ಮ್ ಸಹಾಯಕ',
      'step1': '📸 ನಿಮ್ಮ ಫಾರ್ಮ್ ಅನ್ನು ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
      'step2': '🤖 AI ಕ್ಷೇತ್ರಗಳನ್ನು ವಿಶ್ಲೇಷಿಸುತ್ತದೆ',
      'step3': '✍️ ಸರಳ ಪ್ರಶ್ನೆಗಳಿಗೆ ಉತ್ತರಿಸಿ',
      'step4': '📄 ತುಂಬಿದ ಫಾರ್ಮ್ ಪಡೆಯಿರಿ',
      'noDocument': 'ಯಾವುದೇ ದಾಖಲೆಯನ್ನು ಆಯ್ಕೆ ಮಾಡಲಾಗಿಲ್ಲ',
      'uploadCapture': 'ಫಾರ್ಮ್ ಅನ್ನು ಅಪ್‌ಲೋಡ್ ಮಾಡಿ ಅಥವಾ ಸೆರೆಹಿಡಿಯಿರಿ',
      'camera': 'ಕ್ಯಾಮೆರಾ',
      'gallery': 'ಗ್ಯಾಲರಿ',
      'analyzeDocument': 'ದಾಖಲೆಯನ್ನು ವಿಶ್ಲೇಷಿಸಿ',
      'analyzing': 'ವಿಶ್ಲೇಷಿಸಲಾಗುತ್ತಿದೆ...',
      'whyChooseUs': 'ನಮ್ಮನ್ನು ಏಕೆ ಆಯ್ಕೆ ಮಾಡಬೇಕು?',
      'fastProcessing': 'ವೇಗದ ಪ್ರಕ್ರಿಯೆ',
      'fastProcessingDesc':
          'AI ಸೆಕೆಂಡುಗಳಲ್ಲಿ ನಿಮ್ಮ ಫಾರ್ಮ್ ಅನ್ನು ವಿಶ್ಲೇಷಿಸುತ್ತದೆ',
      'multiLanguage': 'ಬಹು-ಭಾಷೆ',
      'multiLanguageDesc': 'ಇಂಗ್ಲಿಷ್, ಕನ್ನಡ ಮತ್ತು ಹಿಂದಿ ಬೆಂಬಲ',
      'securePrivate': 'ಸುರಕ್ಷಿತ ಮತ್ತು ಖಾಸಗಿ',
      'securePrivateDesc': 'ನಿಮ್ಮ ಡೇಟಾ ನಿಮ್ಮ ಸಾಧನದಲ್ಲಿ ಉಳಿಯುತ್ತದೆ',
      'errorPickImage': 'ಚಿತ್ರವನ್ನು ಆಯ್ಕೆ ಮಾಡುವಲ್ಲಿ ದೋಷ',
      'selectImageFirst': 'ದಯವಿಟ್ಟು ಮೊದಲು ಚಿತ್ರವನ್ನು ಆಯ್ಕೆ ಮಾಡಿ',
      'noTextFound':
          'ಚಿತ್ರದಲ್ಲಿ ಯಾವುದೇ ಪಾಠ ಕಂಡುಬಂದಿಲ್ಲ. ದಯವಿಟ್ಟು ಸ್ಪಷ್ಟವಾದ ಚಿತ್ರದೊಂದಿಗೆ ಪ್ರಯತ್ನಿಸಿ.',
    },
    'hi': {
      'appTitle': 'स्मार्ट दस्तावेज़ सहायक',
      'aiPoweredTitle': 'AI-संचालित फॉर्म सहायक',
      'step1': '📸 अपना फॉर्म स्कैन करें',
      'step2': '🤖 AI फ़ील्ड का विश्लेषण करता है',
      'step3': '✍️ सरल प्रश्नों के उत्तर दें',
      'step4': '📄 भरा हुआ फॉर्म प्राप्त करें',
      'noDocument': 'कोई दस्तावेज़ चयनित नहीं',
      'uploadCapture': 'फॉर्म अपलोड या कैप्चर करें',
      'camera': 'कैमरा',
      'gallery': 'गैलरी',
      'analyzeDocument': 'दस्तावेज़ का विश्लेषण करें',
      'analyzing': 'विश्लेषण हो रहा है...',
      'whyChooseUs': 'हमें क्यों चुनें?',
      'fastProcessing': 'तेज़ प्रसंस्करण',
      'fastProcessingDesc': 'AI सेकंड में आपके फॉर्म का विश्लेषण करता है',
      'multiLanguage': 'बहु-भाषा',
      'multiLanguageDesc': 'अंग्रेजी, कन्नड़ और हिंदी समर्थन',
      'securePrivate': 'सुरक्षित और निजी',
      'securePrivateDesc': 'आपका डेटा आपके डिवाइस पर रहता है',
      'errorPickImage': 'छवि चुनने में त्रुटि',
      'selectImageFirst': 'कृपया पहले एक छवि चुनें',
      'noTextFound':
          'छवि में कोई टेक्स्ट नहीं मिला। कृपया स्पष्ट छवि के साथ प्रयास करें.',
    },
  };

  String translate(String key) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
}

// Main Screen
class DocumentAssistantScreen extends StatefulWidget {
  const DocumentAssistantScreen({super.key});

  @override
  State<DocumentAssistantScreen> createState() =>
      _DocumentAssistantScreenState();
}

class _DocumentAssistantScreenState extends State<DocumentAssistantScreen>
    with SingleTickerProviderStateMixin {
  File? _imageFile;
  bool _isProcessing = false;
  String _selectedLanguage = 'English';
  String _selectedLanguageCode = 'en';
  String? _extractedText;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const String apiKey = 'AIzaSyDRJ80dwt7j5wL8WSJoINZRK3enlC8hVkw';
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'kn', 'name': 'ಕನ್ನಡ', 'flag': '🇮🇳'},
    {'code': 'hi', 'name': 'हिंदी', 'flag': '🇮🇳'},
  ];

  late AppLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations(_selectedLanguageCode);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _changeLanguage(String languageName) {
    setState(() {
      _selectedLanguage = languageName;
      _selectedLanguageCode =
          _languages.firstWhere((l) => l['name'] == languageName)['code']!;
      _localizations = AppLocalizations(_selectedLanguageCode);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _extractedText = null;
        });
      }
    } catch (e) {
      _showError('${_localizations.translate('errorPickImage')}: $e');
    }
  }

  Future<void> _processDocument() async {
    if (_imageFile == null) {
      _showError(_localizations.translate('selectImageFirst'));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Step 1: Extract text using ML Kit OCR
      final extractedText = await _extractTextFromImage(_imageFile!);

      if (extractedText.isEmpty) {
        throw Exception(_localizations.translate('noTextFound'));
      }

      setState(() => _extractedText = extractedText);

      // Step 2: Analyze form fields with Gemini AI
      final formFields = await _analyzeFormFields(extractedText);

      setState(() => _isProcessing = false);

      // Navigate to question page
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentQuestionPage(
              formFields: formFields,
              originalImage: _imageFile!,
              extractedText: extractedText,
              selectedLanguage: _selectedLanguage,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Error: $e');
    }
  }

  Future<String> _extractTextFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      String fullText = recognizedText.text;

      if (fullText.isEmpty) {
        final devanagariRecognizer =
            TextRecognizer(script: TextRecognitionScript.devanagiri);
        final devanagariText =
            await devanagariRecognizer.processImage(inputImage);
        fullText = devanagariText.text;
        await devanagariRecognizer.close();
      }

      await textRecognizer.close();
      return fullText;
    } catch (e) {
      debugPrint('OCR Error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _analyzeFormFields(String text) async {
    final languageCode = _selectedLanguage;

    final prompt = '''
Analyze this form and identify ONLY the fields where the user needs to provide NEW information (empty fields to be filled).

IMPORTANT RULES:
1. DO NOT ask for information that is already present in the form (like form titles, account numbers, dates, office use fields)
2. DO NOT ask for pre-printed or pre-filled information
3. ONLY identify truly empty fields that require user input
4. Focus on fields that have blank spaces, underscores (____), or empty boxes
5. Common fields to ask for: Name, Address, Contact details, Date of Birth, Signature requirements
6. DO NOT include: Form numbers, Office use sections, Pre-filled data, Instructions

FORM TEXT:
$text

Provide a JSON array of ONLY the empty fields that need user input in this format:
[
  {
    "field_id": "unique_field_identifier",
    "field_name": "Field label from form",
    "question": "Question to ask user in $languageCode",
    "field_type": "text|number|date|email|phone|dropdown",
    "is_mandatory": true|false,
    "placeholder": "Example of what to enter",
    "validation": "Any validation rules",
    "options": ["Option 1", "Option 2"]
  }
]

IMPORTANT:
- Ask questions in $languageCode language
- Use simple, clear language
- Only include fields that are currently EMPTY
- Provide helpful placeholders
- Maximum 10-12 questions
''';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'topK': 32,
            'topP': 1,
            'maxOutputTokens': 4096,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final textResponse =
            data['candidates'][0]['content']['parts'][0]['text'];

        String jsonText = textResponse.trim();
        if (textResponse.contains('```json')) {
          jsonText = textResponse.split('```json')[1].split('```')[0].trim();
        } else if (textResponse.contains('```')) {
          jsonText = textResponse.split('```')[1].split('```')[0].trim();
        }

        final List<dynamic> fieldsJson = json.decode(jsonText);
        return fieldsJson.cast<Map<String, dynamic>>();
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      return _createDefaultFields();
    }
  }

  List<Map<String, dynamic>> _createDefaultFields() {
    return [
      {
        'field_id': 'name',
        'field_name': 'Full Name',
        'question': 'What is your full name?',
        'field_type': 'text',
        'is_mandatory': true,
        'placeholder': 'John Doe',
      },
      {
        'field_id': 'phone',
        'field_name': 'Phone Number',
        'question': 'What is your phone number?',
        'field_type': 'phone',
        'is_mandatory': true,
        'placeholder': '9876543210',
      },
    ];
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text(
          _localizations.translate('appTitle'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _languages.firstWhere(
                        (l) => l['name'] == _selectedLanguage)['flag']!,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
            onSelected: _changeLanguage,
            itemBuilder: (context) => _languages
                .map((lang) => PopupMenuItem(
                      value: lang['name']!,
                      child: Row(
                        children: [
                          Text(lang['flag']!,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Text(lang['name']!),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _localizations.translate('aiPoweredTitle'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_localizations.translate('step1')}\n'
                      '${_localizations.translate('step2')}\n'
                      '${_localizations.translate('step3')}\n'
                      '${_localizations.translate('step4')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Image Preview Section
              Container(
                height: 350,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: IconButton(
                                onPressed: () =>
                                    setState(() => _imageFile = null),
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.document_scanner_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _localizations.translate('noDocument'),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _localizations.translate('uploadCapture'),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.camera_alt,
                      label: _localizations.translate('camera'),
                      gradient: [AppColors.primary, AppColors.accent],
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.photo_library,
                      label: _localizations.translate('gallery'),
                      gradient: [AppColors.accent, AppColors.success],
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Process Button
              _buildProcessButton(),

              const SizedBox(height: 32),

              // Features Section
              _buildFeaturesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessButton() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success, AppColors.success.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed:
            _imageFile != null && !_isProcessing ? _processDocument : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.grey[300],
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _localizations.translate('analyzing'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 28, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    _localizations.translate('analyzeDocument'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.speed,
        'title': _localizations.translate('fastProcessing'),
        'desc': _localizations.translate('fastProcessingDesc'),
        'color': AppColors.primary
      },
      {
        'icon': Icons.translate,
        'title': _localizations.translate('multiLanguage'),
        'desc': _localizations.translate('multiLanguageDesc'),
        'color': AppColors.accent
      },
      {
        'icon': Icons.privacy_tip,
        'title': _localizations.translate('securePrivate'),
        'desc': _localizations.translate('securePrivateDesc'),
        'color': AppColors.success
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _localizations.translate('whyChooseUs'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (feature['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: feature['color'] as Color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature['desc'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}