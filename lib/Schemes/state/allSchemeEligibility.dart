// allSchemeEligibility.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'schemeInformation.dart';
import 'schemeAPI.dart';

class AllSchemeEligibility extends StatefulWidget {
  final Map<int, String> userAnswers;
  final List<Map<String, String>> questions;
  final bool isDarkMode;
  final double textSizeMultiplier;
  final String selectedLanguage;

  AllSchemeEligibility({
    required this.userAnswers,
    required this.questions,
    this.isDarkMode = false,
    this.textSizeMultiplier = 1.0,
    this.selectedLanguage = 'English',
  });

  @override
  _AllSchemeEligibilityState createState() => _AllSchemeEligibilityState();
}

class _AllSchemeEligibilityState extends State<AllSchemeEligibility> {
  List<Scheme> _eligibleSchemes = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _showHeader = true; // Controls header visibility

  @override
  void initState() {
    super.initState();
    _evaluateEligibility();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show header when scrolling up or at the top
    if (_scrollController.offset <= 100) {
      if (!_showHeader) {
        setState(() {
          _showHeader = true;
        });
      }
    } else {
      // Hide header when scrolling down
      if (_scrollController.position.userScrollDirection
          .toString()
          .contains('reverse')) {
        if (_showHeader) {
          setState(() {
            _showHeader = false;
          });
        }
      } else if (_scrollController.position.userScrollDirection
          .toString()
          .contains('forward')) {
        if (!_showHeader) {
          setState(() {
            _showHeader = true;
          });
        }
      }
    }
  }

  Future<void> _evaluateEligibility() async {
    try {
      final schemes = await _fetchSchemes();

      if (schemes.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final eligibleSchemes = await _evaluateWithGemini(schemes);

      setState(() {
        _eligibleSchemes = eligibleSchemes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error evaluating eligibility: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error evaluating eligibility: ${e.toString()}')),
      );
    }
  }

  Future<List<Scheme>> _fetchSchemes() async {
    try {
      final languageCode = widget.selectedLanguage == 'English'
          ? 'en'
          : widget.selectedLanguage == 'Kannada'
              ? 'kn'
              : 'hi';
      final url = 'https://navarasa-chathur-api.hf.space/$languageCode/schemes';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> schemesData = [];

        if (data is Map && data.containsKey('karnataka')) {
          schemesData = data['karnataka'];
        } else if (data is List) {
          schemesData = data;
        }

        return schemesData.map((json) => Scheme.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching schemes: $e');
      return [];
    }
  }

  Future<List<Scheme>> _evaluateWithGemini(List<Scheme> allSchemes) async {
    try {
      const String apiKey = 'AIzaSyDRJ80dwt7j5wL8WSJoINZRK3enlC8hVkw';
      const String apiUrl =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

      String userProfile = 'User answered the following questions:\n';
      for (int i = 0; i < widget.questions.length; i++) {
        final question = widget.questions[i]['question'];
        final userAnswer = widget.userAnswers[i];
        userProfile +=
            '${i + 1}. $question - Answer: ${userAnswer?.toUpperCase()}\n';
      }

      String schemesInfo = '';
      for (int i = 0; i < allSchemes.length; i++) {
        final scheme = allSchemes[i];
        schemesInfo += '\nScheme ${i + 1}: ${scheme.title}\n';
        schemesInfo += 'Eligibility: ${scheme.eligibility.join(' ')}\n';
      }

      final prompt = '''
Based on the user's answers and scheme eligibility criteria, determine which schemes the user is eligible for.

$userProfile

Schemes Information:
$schemesInfo

Instructions:
1. Carefully analyze each scheme's eligibility criteria
2. Match the user's answers with each scheme's requirements
3. A user is eligible if they meet ALL the eligibility criteria of a scheme
4. Return ONLY the scheme numbers (1, 2, 3, etc.) that the user is eligible for
5. Format your response as a comma-separated list of numbers ONLY

Example response format: 1,3,5,7,12

Your response:
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
          'temperature': 0.3,
          'maxOutputTokens': 1024,
        }
      });

      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText =
            data['candidates'][0]['content']['parts'][0]['text'];

        final eligibleIndices = generatedText
            .replaceAll(RegExp(r'[^\d,]'), '')
            .split(',')
            .where((s) => s.isNotEmpty)
            .map((s) => int.tryParse(s.trim()))
            .where((i) => i != null && i > 0 && i <= allSchemes.length)
            .map((i) => i! - 1)
            .toList();

        return eligibleIndices.map((i) => allSchemes[i]).toList();
      } else {
        print('Gemini API error: ${response.statusCode}');
        return _fallbackEligibilityCheck(allSchemes);
      }
    } catch (e) {
      print('Error with Gemini evaluation: $e');
      return _fallbackEligibilityCheck(allSchemes);
    }
  }

  List<Scheme> _fallbackEligibilityCheck(List<Scheme> allSchemes) {
    int yesCount = widget.userAnswers.values.where((a) => a == 'yes').length;

    List<Scheme> filtered = allSchemes.where((scheme) {
      return scheme.eligibility.isNotEmpty;
    }).toList();

    filtered
        .sort((a, b) => a.eligibility.length.compareTo(b.eligibility.length));

    int returnCount =
        (yesCount / widget.questions.length * filtered.length).ceil();
    return filtered.take(returnCount.clamp(1, filtered.length)).toList();
  }

  void _openSchemeDetails(Scheme scheme) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SchemeInformationPage(
          scheme: scheme,
          isDarkMode: widget.isDarkMode,
          textSizeMultiplier: widget.textSizeMultiplier,
          isBookmarked: false,
          onBookmarkToggle: () {},
        ),
      ),
    );
  }

  List<String> _getUniqueTags(String tagsString) {
    final tagList = tagsString
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final uniqueTags = <String>{};
    final result = <String>[];

    for (var tag in tagList) {
      final lowerTag = tag.toLowerCase();
      if (!uniqueTags.contains(lowerTag)) {
        uniqueTags.add(lowerTag);
        result.add(tag);
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.isDarkMode ? Color(0xFF121212) : Colors.grey.shade100;
    final cardColor = widget.isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        widget.isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final cardGradient = widget.isDarkMode
        ? [Color(0xFF1E1E1E), Color(0xFF2C2C2C)]
        : [Colors.white, Colors.blue.shade50.withOpacity(0.6)];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'ELIGIBLE SCHEMES',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF3CACEF),
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 20),
                  Text(
                    'Evaluating your eligibility...',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16 * widget.textSizeMultiplier,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Animated Header with scheme count
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: _showHeader ? null : 0,
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: _showHeader ? 1.0 : 0.0,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'You are eligible for',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16 * widget.textSizeMultiplier,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${_eligibleSchemes.length} ${_eligibleSchemes.length == 1 ? 'Scheme' : 'Schemes'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32 * widget.textSizeMultiplier,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Schemes list
                Expanded(
                  child: _eligibleSchemes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 64,
                                color: secondaryTextColor,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No eligible schemes found',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 18 * widget.textSizeMultiplier,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Based on your answers, we couldn\'t find matching schemes. Please try again or contact support.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 14 * widget.textSizeMultiplier,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(16),
                          itemCount: _eligibleSchemes.length,
                          itemBuilder: (context, index) {
                            final scheme = _eligibleSchemes[index];
                            final tagList = _getUniqueTags(scheme.tags);

                            return GestureDetector(
                              onTap: () => _openSchemeDetails(scheme),
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: cardGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.isDarkMode
                                          ? Colors.black.withOpacity(0.3)
                                          : Colors.blueAccent.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.green.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 24,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              scheme.title,
                                              style: TextStyle(
                                                fontSize: 17 *
                                                    widget.textSizeMultiplier,
                                                fontWeight: FontWeight.w700,
                                                color: widget.isDarkMode
                                                    ? Colors.blue.shade300
                                                    : Colors.blue.shade900,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.blueAccent,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        scheme.description,
                                        style: TextStyle(
                                          fontSize:
                                              15 * widget.textSizeMultiplier,
                                          color: textColor,
                                          height: 1.4,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 12),
                                      if (tagList.isNotEmpty)
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: tagList.take(5).map((tag) {
                                            return Chip(
                                              label: Text(
                                                tag,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12 *
                                                      widget.textSizeMultiplier,
                                                ),
                                              ),
                                              backgroundColor:
                                                  Colors.blueAccent,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 0,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      SizedBox(height: 8),
                                      Divider(
                                          color: secondaryTextColor
                                              ?.withOpacity(0.3)),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.verified_user,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'You are eligible for this scheme',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 13 *
                                                  widget.textSizeMultiplier,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
