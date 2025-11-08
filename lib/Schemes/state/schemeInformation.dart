// schemeInformation.dart
import 'package:flutter/material.dart';
import 'schemeAPI.dart';
import 'schemeEligibilityIndividual.dart';
import 'geminiAPI.dart';

class SchemeInformationPage extends StatefulWidget {
  final Scheme scheme;
  final bool isDarkMode;
  final double textSizeMultiplier;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;

  const SchemeInformationPage({
    super.key,
    required this.scheme,
    required this.isDarkMode,
    required this.textSizeMultiplier,
    required this.isBookmarked,
    required this.onBookmarkToggle,
  });

  @override
  _SchemeInformationPageState createState() => _SchemeInformationPageState();
}

class _SchemeInformationPageState extends State<SchemeInformationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isBookmarked;
  bool _isLoadingQuestions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _isBookmarked = widget.isBookmarked;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    widget.onBookmarkToggle();
    Navigator.pop(context, true);
  }

  Future<void> _navigateToEligibilityCheck() async {
    setState(() {
      _isLoadingQuestions = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor:
                widget.isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 20),
                  Text(
                    'AI is analyzing eligibility criteria...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16 * widget.textSizeMultiplier,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Generating personalized questions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14 * widget.textSizeMultiplier,
                      color:
                          widget.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Generate questions using Gemini AI
      final questions = await GeminiService.generateEligibilityQuestions(
        widget.scheme.eligibility,
        widget.scheme.documentsRequired,
      );

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to eligibility check with AI-generated questions
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SchemeEligibilityPage(
                scheme: widget.scheme,
                isDarkMode: widget.isDarkMode,
                textSizeMultiplier: widget.textSizeMultiplier,
                aiGeneratedQuestions: questions,
              ),
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);

      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor:
                widget.isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.orange),
                SizedBox(width: 12),
                Text(
                  'Connection Issue',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            content: Text(
              'Unable to connect to AI service. Please check your internet connection and try again.',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _isLoadingQuestions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.isDarkMode ? Color(0xFF121212) : Colors.grey.shade100;
    final cardColor = widget.isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        widget.isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          widget.scheme.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18 * widget.textSizeMultiplier,
          ),
        ),
        backgroundColor: const Color(0xFF3CACEF),
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.amber : Colors.white,
            ),
            onPressed: _toggleBookmark,
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Scheme Header Card
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color:
                      widget.isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.scheme.title,
                        style: TextStyle(
                          fontSize: 20 * widget.textSizeMultiplier,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isDarkMode
                                  ? Colors.blue.shade300
                                  : Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  widget.scheme.description,
                  style: TextStyle(
                    fontSize: 15 * widget.textSizeMultiplier,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isLoadingQuestions
                                ? null
                                : _navigateToEligibilityCheck,
                        icon:
                            _isLoadingQuestions
                                ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Icon(Icons.auto_awesome_outlined, size: 18),
                        label: Text(
                          _isLoadingQuestions
                              ? 'Preparing...'
                              : 'AI Eligibility Check',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Navigation
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      widget.isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.blue.withOpacity(0.1),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.blueAccent,
              indicatorWeight: 3,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: secondaryTextColor,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14 * widget.textSizeMultiplier,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14 * widget.textSizeMultiplier,
              ),
              tabs: [
                Tab(text: 'Details'),
                Tab(text: 'Benefits'),
                Tab(text: 'Eligibility'),
                Tab(text: 'Application Process'),
                Tab(text: 'Documents Required'),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildContentList(
                  widget.scheme.details,
                  'Details',
                  textColor,
                  secondaryTextColor,
                  cardColor,
                ),
                _buildContentList(
                  widget.scheme.benefits,
                  'Benefits',
                  textColor,
                  secondaryTextColor,
                  cardColor,
                ),
                _buildContentList(
                  widget.scheme.eligibility,
                  'Eligibility',
                  textColor,
                  secondaryTextColor,
                  cardColor,
                ),
                _buildContentList(
                  widget.scheme.applicationProcess,
                  'Application Process',
                  textColor,
                  secondaryTextColor,
                  cardColor,
                ),
                _buildContentList(
                  widget.scheme.documentsRequired,
                  'Documents Required',
                  textColor,
                  secondaryTextColor,
                  cardColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList(
    List<String> items,
    String title,
    Color textColor,
    Color? secondaryTextColor,
    Color cardColor,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: secondaryTextColor),
            SizedBox(height: 16),
            Text(
              'No $title Available',
              style: TextStyle(
                fontSize: 16 * widget.textSizeMultiplier,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.length > 500) {
          return SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color:
                    widget.isDarkMode
                        ? Colors.black.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.08),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(top: 4, right: 12),
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12 * widget.textSizeMultiplier,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 15 * widget.textSizeMultiplier,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
