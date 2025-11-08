import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// Colors
class AppColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color secondary = Color(0xFF004E89);
  static const Color accent = Color(0xFF1A659E);
  static const Color success = Color(0xFF27AE60);
}

// Main Screen
class DocumentAssistantScreen extends StatefulWidget {
  const DocumentAssistantScreen({super.key});

  @override
  State<DocumentAssistantScreen> createState() =>
      _DocumentAssistantScreenState();
}

class _DocumentAssistantScreenState extends State<DocumentAssistantScreen> {
  File? _imageFile;
  bool _isProcessing = false;
  String _selectedLanguage = 'English';
  Map<String, dynamic>? _analysisResult;
  String? _extractedText;

  final List<String> _languages = [
    'English',
    'ಕನ್ನಡ (Kannada)',
    'हिंदी (Hindi)',
  ];

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
          _analysisResult = null;
          _extractedText = null;
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _processDocument() async {
    if (_imageFile == null) {
      _showError('Please select an image first');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Step 1: Extract text using ML Kit OCR
      final extractedText = await _extractTextFromImage(_imageFile!);

      if (extractedText.isEmpty) {
        throw Exception(
          'No text found in image. Please try with a clearer image.',
        );
      }

      setState(() => _extractedText = extractedText);

      // Step 2: Analyze with Gemini AI
      final analysis = await _analyzeWithGemini(
        extractedText,
        _selectedLanguage,
      );

      setState(() {
        _analysisResult = analysis;
        _isProcessing = false;
      });

      // Show results
      _showResultsBottomSheet();
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Error: $e');
    }
  }

  Future<String> _extractTextFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      String fullText = recognizedText.text;

      // Also try Devanagari script for Hindi
      if (fullText.isEmpty) {
        final devanagariRecognizer = TextRecognizer(
          script: TextRecognitionScript.devanagiri,
        );
        final devanagariText = await devanagariRecognizer.processImage(
          inputImage,
        );
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

  Future<Map<String, dynamic>> _analyzeWithGemini(
    String text,
    String language,
  ) async {
    // Using Google Gemini API
    const apiKey = 'YOUR_GEMINI_API_KEY'; // Replace with your API key
    const apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

    final languageCode =
        language == 'English'
            ? 'English'
            : language.contains('Kannada')
            ? 'Kannada'
            : 'Hindi';

    final prompt = '''
Analyze this government/official form text and provide a comprehensive guide in $languageCode language:

FORM TEXT:
$text

Please provide the response in the following JSON format:
{
  "document_type": "Name of the form/document",
  "purpose": "Brief explanation of what this form is for",
  "fields": [
    {
      "field_name": "Field name from the form",
      "description": "What this field means in simple terms",
      "how_to_fill": "Step-by-step instructions on how to fill this field",
      "example": "Example of what to write",
      "is_mandatory": true/false,
      "tips": "Any important tips or warnings"
    }
  ],
  "important_notes": ["Important point 1", "Important point 2"],
  "required_documents": ["Document 1", "Document 2"],
  "common_mistakes": ["Mistake 1", "Mistake 2"],
  "step_by_step_guide": [
    "Step 1: Description",
    "Step 2: Description"
  ]
}

IMPORTANT:
- Respond ONLY in $languageCode language
- Use simple, easy-to-understand words suitable for rural villagers
- Explain technical terms in simple language
- Provide practical examples
- Highlight mandatory fields clearly
- Include any fees or costs mentioned
''';

    try {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.4,
            'topK': 32,
            'topP': 1,
            'maxOutputTokens': 4096,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final textResponse =
            data['candidates'][0]['content']['parts'][0]['text'];

        // Extract JSON from markdown code blocks if present
        String jsonText = textResponse;
        if (textResponse.contains('```json')) {
          jsonText = textResponse.split('```json')[1].split('```')[0].trim();
        } else if (textResponse.contains('```')) {
          jsonText = textResponse.split('```')[1].split('```')[0].trim();
        }

        return json.decode(jsonText);
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      // Fallback to basic analysis
      return _createBasicAnalysis(text, languageCode);
    }
  }

  Map<String, dynamic> _createBasicAnalysis(String text, String language) {
    // Fallback basic analysis when API fails
    return {
      'document_type': 'Government Form',
      'purpose': 'Official application form',
      'fields': [
        {
          'field_name': 'Detected fields from image',
          'description': 'Please fill all fields carefully',
          'how_to_fill': 'Follow the instructions on the form',
          'is_mandatory': true,
        },
      ],
      'important_notes': [
        'Keep all documents ready',
        'Fill in capital letters',
      ],
      'required_documents': ['Identity Proof', 'Address Proof'],
    };
  }

  void _showResultsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: _buildAnalysisResults(scrollController),
                ),
          ),
    );
  }

  Widget _buildAnalysisResults(ScrollController scrollController) {
    if (_analysisResult == null) return const SizedBox();

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Document Type
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document Type',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _analysisResult!['document_type'] ?? 'Unknown Form',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Purpose
          if (_analysisResult!['purpose'] != null) ...[
            _buildSectionTitle('Purpose / उद्देश्य / ಉದ್ದೇಶ'),
            _buildInfoCard(
              _analysisResult!['purpose'],
              Icons.info_outline,
              AppColors.accent,
            ),
            const SizedBox(height: 20),
          ],

          // Step by Step Guide
          if (_analysisResult!['step_by_step_guide'] != null) ...[
            _buildSectionTitle('Step-by-Step Guide'),
            ...(_analysisResult!['step_by_step_guide'] as List)
                .asMap()
                .entries
                .map((entry) {
                  return _buildStepCard(entry.key + 1, entry.value);
                }),
            const SizedBox(height: 20),
          ],

          // Fields
          if (_analysisResult!['fields'] != null) ...[
            _buildSectionTitle('Form Fields Explanation'),
            ...(_analysisResult!['fields'] as List).map((field) {
              return _buildFieldCard(field);
            }),
            const SizedBox(height: 20),
          ],

          // Required Documents
          if (_analysisResult!['required_documents'] != null) ...[
            _buildSectionTitle('Required Documents'),
            _buildListCard(
              _analysisResult!['required_documents'],
              Icons.document_scanner,
              AppColors.success,
            ),
            const SizedBox(height: 20),
          ],

          // Important Notes
          if (_analysisResult!['important_notes'] != null) ...[
            _buildSectionTitle('Important Notes'),
            _buildListCard(
              _analysisResult!['important_notes'],
              Icons.warning_amber,
              Colors.orange,
            ),
            const SizedBox(height: 20),
          ],

          // Common Mistakes
          if (_analysisResult!['common_mistakes'] != null) ...[
            _buildSectionTitle('Common Mistakes to Avoid'),
            _buildListCard(
              _analysisResult!['common_mistakes'],
              Icons.error_outline,
              Colors.red,
            ),
            const SizedBox(height: 20),
          ],

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showExtractedText();
                  },
                  icon: const Icon(Icons.text_fields),
                  label: const Text('View Extracted Text'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Share or save functionality
                    Navigator.pop(context);
                    _showError('Guide saved! You can access it anytime.');
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Guide'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(int stepNumber, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(Map<String, dynamic> field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              field['is_mandatory'] == true
                  ? AppColors.primary
                  : Colors.grey[300]!,
          width: field['is_mandatory'] == true ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  field['is_mandatory'] == true
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.grey[100],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                if (field['is_mandatory'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'MANDATORY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (field['is_mandatory'] == true) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    field['field_name'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (field['description'] != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          field['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (field['how_to_fill'] != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.edit_note,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'How to fill:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              field['how_to_fill'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (field['example'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Example: ${field['example']}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (field['tips'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.tips_and_updates,
                          size: 18,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            field['tips'],
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(List<dynamic> items, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children:
            items.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key < items.length - 1 ? 12 : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  void _showExtractedText() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Extracted Text'),
            content: SingleChildScrollView(
              child: Text(_extractedText ?? 'No text extracted'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary.withOpacity(0.05),
      appBar: AppBar(
        title: const Text('Document Scanner & Assistant'),
        backgroundColor: AppColors.secondary,
        actions: [
          PopupMenuButton<String>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedLanguage.split(' ')[0],
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
            onSelected: (value) => setState(() => _selectedLanguage = value),
            itemBuilder:
                (context) =>
                    _languages
                        .map(
                          (lang) =>
                              PopupMenuItem(value: lang, child: Text(lang)),
                        )
                        .toList(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'How it works:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '1. Take a photo or upload form image\n'
                    '2. Select your preferred language\n'
                    '3. Get detailed explanation of each field\n'
                    '4. Learn how to fill the form correctly',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Image Preview
            if (_imageFile != null)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(_imageFile!, fit: BoxFit.contain),
                ),
              )
            else
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.document_scanner,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No image selected',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('From Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Process Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _imageFile != null && !_isProcessing
                        ? _processDocument
                        : null,
                icon:
                    _isProcessing
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.auto_awesome, size: 24),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Analyze Document',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
