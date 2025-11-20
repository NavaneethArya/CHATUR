// filledForm.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF2D3561);
  static const Color accent = Color(0xFF4ECDC4);
  static const Color success = Color(0xFF44CF6C);
  static const Color background = Color(0xFFF8F9FA);
}

class FilledFormPage extends StatefulWidget {
  final File originalImage;
  final List<Map<String, dynamic>> formFields;
  final Map<String, String> answers;
  final String extractedText;

  const FilledFormPage({
    Key? key,
    required this.originalImage,
    required this.formFields,
    required this.answers,
    required this.extractedText,
  }) : super(key: key);

  @override
  State<FilledFormPage> createState() => _FilledFormPageState();
}

class _FilledFormPageState extends State<FilledFormPage> {
  bool _isGenerating = false;
  String? _generatedFormText;
  String? _errorMessage;
  bool _showHeader = true;
  final ScrollController _scrollController = ScrollController();

  static const String apiKey = 'AIzaSyDRJ80dwt7j5wL8WSJoINZRK3enlC8hVkw';
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';

  @override
  void initState() {
    super.initState();
    _generateFilledFormText();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      // Hide header when scrolled down more than 50 pixels
      if (_scrollController.offset > 50 && _showHeader) {
        setState(() => _showHeader = false);
      } else if (_scrollController.offset <= 50 && !_showHeader) {
        setState(() => _showHeader = true);
      }
    }
  }

  Future<void> _generateFilledFormText() async {
    if (mounted) {
      setState(() {
        _isGenerating = true;
        _errorMessage = null;
      });
    }

    try {
      final prompt = '''
You are an expert form filling system. Create a beautifully formatted text representation of this filled form.

ORIGINAL FORM TEMPLATE:
${widget.extractedText}

USER'S FILLED INFORMATION:
${widget.formFields.map((field) {
        final answer = widget.answers[field['field_id']] ?? '';
        return '${field['field_name']}: ${answer.isNotEmpty ? answer : '[Not Provided]'}';
      }).join('\n')}

CRITICAL FORMATTING REQUIREMENTS:

1. **Preserve Original Structure**: Keep the exact layout and formatting of the original form
2. **Use Simple Box Drawing**: Use these ASCII-safe characters for compatibility:
   ═══ for double lines (main sections)
   ─── for single lines (field separators)
   │ for vertical lines
   
3. **Highlight User Values**: Wrap ALL user-entered values with ▶ ◀ markers to make them stand out
   Example: Name: ▶ John Smith ◀
   Example: Date: ▶ 15/11/2024 ◀
   
4. **Visual Enhancements**:
   - Use clear section headers with separator lines
   - Add spacing between sections for readability
   - Use proper indentation for nested sections
   - Mark mandatory fields with ★

5. **Table Formatting** - Use simple ASCII tables:
═══════════════════════════════════════════════════
  Field Label              | Entered Value
═══════════════════════════════════════════════════
  Name:                    | ▶ John Smith ◀
  Date:                    | ▶ 15/11/2024 ◀
───────────────────────────────────────────────────

6. **Keep All Elements**:
   - Headers and titles
   - Section numbers and labels
   - ★ for mandatory fields
   - Checkbox markers (✓ for checked, □ for unchecked)
   - All instructional text
   - "For Office Use" sections

7. **Field Filling Rules**:
   - Put answers wrapped in ▶ ◀ markers in the exact location of blank fields
   - If no answer provided, show: [Not Provided]
   - Maintain proper alignment
   - Use clear spacing between fields

8. **Character Safety**:
   - Use only ASCII and basic Unicode characters
   - Avoid complex box-drawing characters that may not render properly
   - Test that all characters display correctly in monospace fonts

IMPORTANT:
- Output ONLY the filled form text
- No markdown code blocks
- No explanatory text before or after
- Make it clean, professional and easy to read
- ALL user-entered values MUST be wrapped in ▶ ◀ markers and displayed correctly in bold text to stand out
- Use characters that render properly in mobile apps
- Ensure proper spacing and alignment
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
            'temperature': 0.2,
            'maxOutputTokens': 8192,
          }
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final filledText =
              data['candidates'][0]['content']['parts'][0]['text'];

          // Clean up the response - remove markdown code blocks if present
          String cleanedText = filledText
              .replaceAll('```text', '')
              .replaceAll('```plaintext', '')
              .replaceAll('```', '')
              .trim();

          print('Generated text length: ${cleanedText.length}');
          print(
              'First 200 chars: ${cleanedText.substring(0, cleanedText.length > 200 ? 200 : cleanedText.length)}');

          if (cleanedText.isEmpty) {
            throw Exception('Generated text is empty');
          }

          if (mounted) {
            setState(() {
              _generatedFormText = cleanedText;
            });
          }
        } else {
          throw Exception('Invalid response structure from API');
        }
      } else {
        throw Exception(
            'API returned status code: ${response.statusCode}\nBody: ${response.body}');
      }
    } catch (e) {
      print('Error generating form: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
      _showError('Failed to generate form: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _copyToClipboard() async {
    if (_generatedFormText != null) {
      await Clipboard.setData(ClipboardData(text: _generatedFormText!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Form copied to clipboard!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
        duration: const Duration(seconds: 4),
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
        title: const Text(
          'Filled Form',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_generatedFormText != null)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyToClipboard,
              tooltip: 'Copy Form',
            ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Success Banner - Collapses on scroll
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showHeader ? null : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showHeader ? 1.0 : 0.0,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success,
                        AppColors.success.withOpacity(0.7)
                      ],
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 28),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Form successfully filled with your information!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tabs - Collapses on scroll
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showHeader ? null : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showHeader ? 1.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.article,
                                    size: 22, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'Filled Form',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Form Content - Expands to full screen
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, _showHeader ? 10 : 20, 20, 20),
              child: _buildFormText(),
            ),
          ),
        ],
      ),
      // Floating Action Buttons
      floatingActionButton: _generatedFormText != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'edit',
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: Colors.white,
                  child:
                      const Icon(Icons.edit_outlined, color: AppColors.primary),
                  tooltip: 'Edit Answers',
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'copy',
                  onPressed: _copyToClipboard,
                  backgroundColor: AppColors.success,
                  child: const Icon(Icons.content_copy, color: Colors.white),
                  tooltip: 'Copy Form',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildFormText() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.description_outlined,
                        color: AppColors.primary, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Formatted Text Form',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                if (_generatedFormText != null)
                  IconButton(
                    icon: const Icon(Icons.copy_all, color: AppColors.primary),
                    onPressed: _copyToClipboard,
                    tooltip: 'Copy to Clipboard',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Form Content
          Expanded(
            child: _isGenerating
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                            color: AppColors.primary),
                        const SizedBox(height: 20),
                        Text(
                          'Generating your filled form...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This may take a few seconds',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : _generatedFormText != null
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBF0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SelectableText(
                            _generatedFormText!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 15,
                              height: 1.6,
                              color: Color(0xFF212121),
                              letterSpacing: 0,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 56, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Unable to generate form',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_errorMessage != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _generateFilledFormText,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.checklist_rtl,
                    color: AppColors.accent, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Field-by-Field Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.formFields.length} fields filled',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Fields List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.formFields.length,
              itemBuilder: (context, index) {
                final field = widget.formFields[index];
                final answer =
                    widget.answers[field['field_id']] ?? 'Not provided';
                final isMandatory = field['is_mandatory'] ?? false;

                return _buildFieldRow(
                  field['field_name'],
                  answer,
                  isMandatory,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value, bool isMandatory) {
    final isFilled = value != 'Not provided' && value.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFilled ? AppColors.success.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMandatory
              ? AppColors.primary.withOpacity(0.4)
              : Colors.grey[300]!,
          width: isMandatory ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mandatory indicator
          if (isMandatory)
            Container(
              margin: const EdgeInsets.only(right: 12, top: 2),
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 10),
            ),

          // Field content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isFilled ? AppColors.secondary : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),

          // Status indicator
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isFilled
                  ? AppColors.success.withOpacity(0.15)
                  : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFilled ? Icons.check : Icons.remove,
              color: isFilled ? AppColors.success : Colors.grey,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}