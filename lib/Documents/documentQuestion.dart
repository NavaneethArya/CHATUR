// documentQuestion.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'filledForm.dart';

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF2D3561);
  static const Color accent = Color(0xFF4ECDC4);
  static const Color success = Color(0xFF44CF6C);
  static const Color background = Color(0xFFF8F9FA);
}

class DocumentQuestionPage extends StatefulWidget {
  final List<Map<String, dynamic>> formFields;
  final File originalImage;
  final String extractedText;
  final String selectedLanguage;

  const DocumentQuestionPage({
    Key? key,
    required this.formFields,
    required this.originalImage,
    required this.extractedText,
    required this.selectedLanguage,
  }) : super(key: key);

  @override
  State<DocumentQuestionPage> createState() => _DocumentQuestionPageState();
}

class _DocumentQuestionPageState extends State<DocumentQuestionPage> {
  final PageController _pageController = PageController();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _answers = {};
  int _currentPage = 0;
  String _selectedLanguage = 'English';
  bool _isTranslating = false;

  static const String apiKey = 'AIzaSyDRJ80dwt7j5wL8WSJoINZRK3enlC8hVkw';
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'kn', 'name': 'ಕನ್ನಡ', 'flag': '🇮🇳'},
    {'code': 'hi', 'name': 'हिंदी', 'flag': '🇮🇳'},
  ];

  List<Map<String, dynamic>> _translatedFields = [];

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
    _translatedFields = List.from(widget.formFields);

    for (var field in widget.formFields) {
      _controllers[field['field_id']] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _translateFields(String targetLanguage) async {
    if (targetLanguage == 'English') {
      setState(() {
        _translatedFields = List.from(widget.formFields);
      });
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final fieldsToTranslate = widget.formFields
          .map((f) => {
                'field_id': f['field_id'],
                'question': f['question'],
                'placeholder': f['placeholder'],
              })
          .toList();

      final prompt = '''
Translate the following form fields to $targetLanguage language:

${json.encode(fieldsToTranslate)}

Return ONLY a valid JSON array with the same structure but translated text. Keep field_id unchanged.
Use simple, easy-to-understand language.
Do not include any markdown formatting or code blocks, just return the JSON array.
''';

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
            'maxOutputTokens': 2048,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final textResponse =
            data['candidates'][0]['content']['parts'][0]['text'];

        String jsonText = textResponse.trim();
        if (jsonText.contains('```json')) {
          jsonText = jsonText.split('```json')[1].split('```')[0].trim();
        } else if (jsonText.contains('```')) {
          jsonText = jsonText.split('```')[1].split('```')[0].trim();
        }

        final List<dynamic> translated = json.decode(jsonText);

        setState(() {
          _translatedFields = widget.formFields.map((field) {
            final translatedField = translated.firstWhere(
              (t) => t['field_id'] == field['field_id'],
              orElse: () => field,
            );
            return {
              ...field,
              'question': translatedField['question'] ?? field['question'],
              'placeholder':
                  translatedField['placeholder'] ?? field['placeholder'],
            };
          }).toList();
          _isTranslating = false;
        });
      } else {
        throw Exception('Translation failed');
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      setState(() => _isTranslating = false);
      _showError('Translation failed. Using original language.');
    }
  }

  Future<void> _selectDate(BuildContext context, String fieldId) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.secondary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {
        _controllers[fieldId]!.text = formattedDate;
      });
    }
  }

  void _nextPage() {
    final currentField = _translatedFields[_currentPage];
    final controller = _controllers[currentField['field_id']]!;
    final isMandatory = currentField['is_mandatory'] ?? false;

    // Validate mandatory field
    if (isMandatory && controller.text.trim().isEmpty) {
      _showError('This field is required');
      return;
    }

    // Save the answer
    _answers[currentField['field_id']] = controller.text.trim();

    if (_currentPage < _translatedFields.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitForm();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitForm() {
    // Collect all answers
    for (var field in _translatedFields) {
      final fieldId = field['field_id'];
      if (_controllers[fieldId] != null) {
        _answers[fieldId] = _controllers[fieldId]!.text.trim();
      }
    }

    // Navigate to filled form page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FilledFormPage(
          originalImage: widget.originalImage,
          formFields: widget.formFields,
          answers: _answers,
          extractedText: widget.extractedText,
        ),
      ),
    );
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
        duration: const Duration(seconds: 2),
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
          'Question ${_currentPage + 1} of ${_translatedFields.length}',
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
            onSelected: (value) {
              if (value != _selectedLanguage) {
                setState(() => _selectedLanguage = value);
                _translateFields(value);
              }
            },
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
      body: _isTranslating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Translating questions...'),
                ],
              ),
            )
          : Column(
              children: [
                // Progress Bar
                Container(
                  height: 6,
                  color: Colors.grey[200],
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / _translatedFields.length,
                    backgroundColor: Colors.transparent,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.success),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: _translatedFields.length,
                    itemBuilder: (context, index) {
                      final field = _translatedFields[index];
                      return _buildQuestionCard(field, index);
                    },
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> field, int index) {
    final controller = _controllers[field['field_id']]!;
    final isMandatory = field['is_mandatory'] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Number Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.help_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Question Text
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        field['question'] ?? 'Enter information',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (isMandatory)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Required',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  field['field_name'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Input Field
          _buildInputField(field, controller),

          // Helper Text
          if (field['validation'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      field['validation'],
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField(
      Map<String, dynamic> field, TextEditingController controller) {
    final fieldType = field['field_type'] ?? 'text';

    // Date picker field
    if (fieldType == 'date') {
      return _buildDateField(field, controller);
    }

    // Dropdown field
    if (fieldType == 'dropdown' && field['options'] != null) {
      return _buildDropdown(field, controller);
    }

    // Radio buttons for fields with options (alternative to dropdown)
    if (field['options'] != null && (field['options'] as List).length <= 5) {
      return _buildRadioButtons(field, controller);
    }

    // Regular text/number/email/phone field
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: _getKeyboardType(fieldType),
        inputFormatters: _getInputFormatters(fieldType),
        maxLines: fieldType == 'text' ? 1 : null,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        onChanged: (value) {
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: field['placeholder'] ?? 'Enter your answer',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(_getFieldIcon(fieldType), color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildDateField(
      Map<String, dynamic> field, TextEditingController controller) {
    return GestureDetector(
      onTap: () => _selectDate(context, field['field_id']),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AbsorbPointer(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: field['placeholder'] ?? 'Select date (DD/MM/YYYY)',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon:
                  const Icon(Icons.calendar_today, color: AppColors.primary),
              suffixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.event, color: AppColors.primary, size: 20),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      Map<String, dynamic> field, TextEditingController controller) {
    final options = (field['options'] as List).cast<String>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.text.isEmpty ? null : controller.text,
          hint: Text(
            field['placeholder'] ?? 'Select an option',
            style: TextStyle(color: Colors.grey[400]),
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down,
              size: 30, color: AppColors.primary),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.secondary,
          ),
          items: options
              .map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              controller.text = value ?? '';
            });
          },
        ),
      ),
    );
  }

  Widget _buildRadioButtons(
      Map<String, dynamic> field, TextEditingController controller) {
    final options = (field['options'] as List).cast<String>();

    return Column(
      children: options.map((option) {
        final isSelected = controller.text == option;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: RadioListTile<String>(
            value: option,
            groupValue: controller.text.isEmpty ? null : controller.text,
            onChanged: (value) {
              setState(() {
                controller.text = value ?? '';
              });
            },
            title: Text(
              option,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.secondary,
              ),
            ),
            activeColor: AppColors.primary,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavigationButtons() {
    final isLastPage = _currentPage == _translatedFields.length - 1;
    final currentField = _translatedFields[_currentPage];
    final controller = _controllers[currentField['field_id']]!;
    final isMandatory = currentField['is_mandatory'] ?? false;
    final canProceed = !isMandatory || controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.arrow_back),
                    SizedBox(width: 8),
                    Text(
                      'Previous',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: canProceed
                      ? [AppColors.success, AppColors.success.withOpacity(0.7)]
                      : [Colors.grey[400]!, Colors.grey[400]!],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: canProceed
                    ? [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: ElevatedButton(
                onPressed: canProceed ? _nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastPage ? 'Generate Form' : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastPage ? Icons.check_circle : Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextInputType _getKeyboardType(String fieldType) {
    switch (fieldType) {
      case 'number':
        return TextInputType.number;
      case 'phone':
        return TextInputType.phone;
      case 'email':
        return TextInputType.emailAddress;
      case 'date':
        return TextInputType.datetime;
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> _getInputFormatters(String fieldType) {
    if (fieldType == 'number' || fieldType == 'phone') {
      return [FilteringTextInputFormatter.digitsOnly];
    }
    return [];
  }

  IconData _getFieldIcon(String fieldType) {
    switch (fieldType) {
      case 'number':
        return Icons.numbers;
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'date':
        return Icons.calendar_today;
      default:
        return Icons.edit;
    }
  }
}