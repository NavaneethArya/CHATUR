// allSchemeDetailMinistry.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'schemeImformationCentral.dart';

class MinistrySchemeDetailPage extends StatefulWidget {
  final String ministryName;
  final String selectedLanguage;
  final bool isDarkMode;
  final double textSizeMultiplier;

  const MinistrySchemeDetailPage({
    super.key,
    required this.ministryName,
    this.selectedLanguage = 'English',
    this.isDarkMode = false,
    this.textSizeMultiplier = 1.0,
  });

  @override
  _MinistrySchemeDetailPageState createState() =>
      _MinistrySchemeDetailPageState();
}

class _MinistrySchemeDetailPageState extends State<MinistrySchemeDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _schemes = [];
  List<Map<String, dynamic>> _filteredSchemes = [];
  List<Map<String, dynamic>> _bookmarkedSchemes = [];
  bool _isLoading = false;
  int _schemeCount = 0;
  bool _showHeader = true;
  bool _showingBookmarks = false;
  bool _isDarkMode = false;
  String _selectedLanguage = 'English';
  double _textSizeMultiplier = 1.0;

  // Cache keys
  static const String _cacheKeyPrefix = 'cached_ministry_schemes_';
  static const String _cacheKeyTimestamp = '_timestamp';
  static const String _cacheKeyLanguage = '_language';
  static const int _cacheDurationDays = 7;

  final Map<String, String> _translations = {
    'en_search': 'Search schemes...',
    'kn_search': 'ಯೋಜನೆಗಳನ್ನು ಹುಡುಕಿ...',
    'hi_search': 'योजनाओं को खोजें...',
    'en_found': 'schemes found',
    'kn_found': 'ಯೋಜನೆಗಳು ಕಂಡುಬಂದಿವೆ',
    'hi_found': 'योजनाएं मिलीं',
    'en_no_schemes': 'No schemes found',
    'kn_no_schemes': 'ಯಾವುದೇ ಯೋಜನೆಗಳು ಕಂಡುಬಂದಿಲ್ಲ',
    'hi_no_schemes': 'कोई योजना नहीं मिली',
    'en_bookmarks': 'Bookmarked Schemes',
    'kn_bookmarks': 'ಬುಕ್‌ಮಾರ್ಕ್ ಮಾಡಿದ ಯೋಜನೆಗಳು',
    'hi_bookmarks': 'बुकमार्क की गई योजनाएं',
    'en_no_bookmarks': 'No bookmarked schemes',
    'kn_no_bookmarks': 'ಯಾವುದೇ ಬುಕ್‌ಮಾರ್ಕ್ ಮಾಡಿದ ಯೋಜನೆಗಳಿಲ್ಲ',
    'hi_no_bookmarks': 'कोई बुकमार्क योजना नहीं',
    'en_loading': 'Loading schemes...',
    'kn_loading': 'ಯೋಜನೆಗಳನ್ನು ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...',
    'hi_loading': 'योजनाएं लोड हो रही हैं...',
  };

  String _t(String key) {
    String langPrefix =
        _selectedLanguage == 'English'
            ? 'en'
            : _selectedLanguage == 'Kannada'
            ? 'kn'
            : 'hi';
    return _translations['${langPrefix}_$key'] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
    _isDarkMode = widget.isDarkMode;
    _textSizeMultiplier = widget.textSizeMultiplier;
    _loadSchemes();
    _loadBookmarks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection.toString().contains(
      'forward',
    )) {
      if (!_showHeader) {
        setState(() {
          _showHeader = true;
        });
      }
    } else if (_scrollController.position.userScrollDirection
        .toString()
        .contains('reverse')) {
      if (_showHeader && _scrollController.offset > 50) {
        setState(() {
          _showHeader = false;
        });
      }
    }
  }

  String _getCacheKey() {
    return '$_cacheKeyPrefix${widget.ministryName}_$_selectedLanguage';
  }

  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey();
      final timestampString = prefs.getString('$cacheKey$_cacheKeyTimestamp');
      final cachedLanguage = prefs.getString('$cacheKey$_cacheKeyLanguage');

      if (timestampString == null || cachedLanguage == null) {
        return false;
      }

      if (cachedLanguage != _selectedLanguage) {
        return false;
      }

      final cacheTimestamp = DateTime.parse(timestampString);
      final currentTime = DateTime.now();
      final difference = currentTime.difference(cacheTimestamp);

      return difference.inDays < _cacheDurationDays;
    } catch (e) {
      print('Error checking cache validity: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> _loadSchemesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey();
      final schemesJson = prefs.getStringList(cacheKey);

      if (schemesJson == null || schemesJson.isEmpty) {
        return null;
      }

      return schemesJson
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Error loading schemes from cache: $e');
      return null;
    }
  }

  Future<void> _saveSchemesToCache(List<Map<String, dynamic>> schemes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey();

      final schemesJson = schemes.map((scheme) => jsonEncode(scheme)).toList();

      await prefs.setStringList(cacheKey, schemesJson);
      await prefs.setString(
        '$cacheKey$_cacheKeyTimestamp',
        DateTime.now().toIso8601String(),
      );
      await prefs.setString('$cacheKey$_cacheKeyLanguage', _selectedLanguage);

      print(
        'Ministry schemes cached successfully. Count: ${schemes.length} for ${widget.ministryName}',
      );
    } catch (e) {
      print('Error saving schemes to cache: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey();
      await prefs.remove(cacheKey);
      await prefs.remove('$cacheKey$_cacheKeyTimestamp');
      await prefs.remove('$cacheKey$_cacheKeyLanguage');
      print('Cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson =
        prefs.getStringList('bookmarked_central_schemes') ?? [];
    setState(() {
      _bookmarkedSchemes =
          bookmarksJson
              .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
              .toList();
    });
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson =
        _bookmarkedSchemes.map((scheme) => jsonEncode(scheme)).toList();
    await prefs.setStringList('bookmarked_central_schemes', bookmarksJson);
  }

  bool _isBookmarked(Map<String, dynamic> scheme) {
    return _bookmarkedSchemes.any(
      (s) => s['Title']?.toString() == scheme['Title']?.toString(),
    );
  }

  void _toggleBookmark(Map<String, dynamic> scheme) {
    setState(() {
      if (_isBookmarked(scheme)) {
        _bookmarkedSchemes.removeWhere(
          (s) => s['Title']?.toString() == scheme['Title']?.toString(),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Removed from bookmarks')));
      } else {
        _bookmarkedSchemes.add(scheme);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Added to bookmarks')));
      }
    });
    _saveBookmarks();
  }

  void _showBookmarks() {
    setState(() {
      _showingBookmarks = true;
      _filteredSchemes = _bookmarkedSchemes;
      _schemeCount = _bookmarkedSchemes.length;
      _searchController.clear();
    });
  }

  void _hideBookmarks() {
    setState(() {
      _showingBookmarks = false;
      _filteredSchemes = _schemes;
      _schemeCount = _schemes.length;
      _searchController.clear();
    });
  }

  Future<void> _loadSchemes() async {
    setState(() {
      _isLoading = true;
      _showingBookmarks = false;
    });

    try {
      final cacheValid = await _isCacheValid();

      if (cacheValid) {
        print('Loading schemes from cache for ${widget.ministryName}...');
        final cachedSchemes = await _loadSchemesFromCache();

        if (cachedSchemes != null && cachedSchemes.isNotEmpty) {
          setState(() {
            _schemes = cachedSchemes;
            _filteredSchemes = cachedSchemes;
            _schemeCount = cachedSchemes.length;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded schemes from cache'),
              duration: Duration(seconds: 1),
            ),
          );
          return;
        }
      }

      print('Fetching schemes from API for ${widget.ministryName}...');
      final data = await _fetchSchemesFromAPI();

      await _saveSchemesToCache(data);

      setState(() {
        _schemes = data;
        _filteredSchemes = data;
        _schemeCount = data.length;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Schemes loaded successfully'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to fetch schemes: $e"),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSchemesFromAPI() async {
    final langCode =
        _selectedLanguage == 'English'
            ? 'en'
            : _selectedLanguage == 'Kannada'
            ? 'kn'
            : 'hi';
    final url =
        //'https://navarasa-chathur-api.hf.space/$langCode/central/all_schemes';
        'https://navarasa-chathur-api.hf.space/central/all_schemes?lang=$langCode';

    try {
      print('Fetching from URL: $url');
      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(Duration(seconds: 30));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data is Map<String, dynamic>) {
          // Find schemes for the specific ministry
          final ministrySchemes = data[widget.ministryName];

          if (ministrySchemes != null && ministrySchemes is List) {
            print(
              'Found ${ministrySchemes.length} schemes for ${widget.ministryName}',
            );
            return List<Map<String, dynamic>>.from(ministrySchemes);
          } else {
            print('No schemes found for ministry: ${widget.ministryName}');
            return [];
          }
        } else {
          throw Exception('Unexpected API response format');
        }
      }

      throw Exception('Failed to load schemes: HTTP ${response.statusCode}');
    } catch (e) {
      print('Error fetching schemes: $e');
      throw Exception('Failed to fetch schemes: $e');
    }
  }

  void _filterSchemes(String query) {
    final searchList = _showingBookmarks ? _bookmarkedSchemes : _schemes;
    final results =
        searchList.where((scheme) {
          final lowerQuery = query.toLowerCase();
          final titleMatch =
              scheme['Title']?.toString().toLowerCase().contains(lowerQuery) ??
              false;
          final descMatch =
              scheme['Description']?.toString().toLowerCase().contains(
                lowerQuery,
              ) ??
              false;
          final tagMatch =
              scheme['Tags']?.toString().toLowerCase().contains(lowerQuery) ??
              false;
          return titleMatch || descMatch || tagMatch;
        }).toList();
    setState(() {
      _filteredSchemes = results;
      _schemeCount = results.length;
    });
  }

  void _onTagPressed(String tag) {
    setState(() {
      _searchController.text = tag;
    });
    _filterSchemes(tag);
  }

  List<String> _getUniqueTags(String? tagsString) {
    if (tagsString == null || tagsString.isEmpty) return [];

    final tagList =
        tagsString
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

  void _openSchemeDetails(Map<String, dynamic> scheme) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SchemeInformationCentralPage(
              scheme: scheme,
              isDarkMode: _isDarkMode,
              textSizeMultiplier: _textSizeMultiplier,
              isBookmarked: _isBookmarked(scheme),
              onBookmarkToggle: () => _toggleBookmark(scheme),
            ),
      ),
    );

    if (result == true) {
      _loadBookmarks();
    }
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _changeLanguage(String newLanguage) {
    setState(() {
      _selectedLanguage = newLanguage;
      _searchController.clear();
    });
    _clearCache();
    _loadSchemes();
  }

  void _changeTextSize(double multiplier) {
    setState(() {
      _textSizeMultiplier = multiplier;
    });
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bgColor = _isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
            final textColor = _isDarkMode ? Colors.white : Colors.black87;

            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Language',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildLanguageChip('English', 'English', setModalState),
                      _buildLanguageChip('ಕನ್ನಡ', 'Kannada', setModalState),
                      _buildLanguageChip('हिंदी', 'Hindi', setModalState),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_isDarkMode) {
                              _toggleDarkMode();
                              setModalState(() {});
                              setState(() {});
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color:
                                  !_isDarkMode
                                      ? Colors.blueAccent
                                      : Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.light_mode,
                                  color:
                                      !_isDarkMode
                                          ? Colors.white
                                          : Colors.black54,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Light',
                                  style: TextStyle(
                                    color:
                                        !_isDarkMode
                                            ? Colors.white
                                            : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!_isDarkMode) {
                              _toggleDarkMode();
                              setModalState(() {});
                              setState(() {});
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color:
                                  _isDarkMode
                                      ? Colors.blueAccent
                                      : Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.dark_mode,
                                  color:
                                      _isDarkMode
                                          ? Colors.white
                                          : Colors.black54,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Dark',
                                  style: TextStyle(
                                    color:
                                        _isDarkMode
                                            ? Colors.white
                                            : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Text Size',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTextSizeButton('Small', 0.85, setModalState),
                      _buildTextSizeButton('Medium', 1.0, setModalState),
                      _buildTextSizeButton('Large', 1.15, setModalState),
                    ],
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        await _clearCache();
                        Navigator.pop(context);
                        _loadSchemes();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cache cleared. Refreshing schemes...',
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.refresh, color: Colors.redAccent),
                      label: Text(
                        'Clear Cache & Refresh',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLanguageChip(
    String label,
    String value,
    StateSetter setModalState,
  ) {
    final isSelected = _selectedLanguage == value;
    return GestureDetector(
      onTap: () {
        _changeLanguage(value);
        setModalState(() {});
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTextSizeButton(
    String label,
    double multiplier,
    StateSetter setModalState,
  ) {
    final isSelected = _textSizeMultiplier == multiplier;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _changeTextSize(multiplier);
          setModalState(() {});
          setState(() {});
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedFAB() {
    bool isFabExpanded = false;

    return Positioned(
      right: 18,
      bottom: 16,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setFabState) {
          return MouseRegion(
            onEnter: (_) => setFabState(() => isFabExpanded = true),
            onExit: (_) => setFabState(() => isFabExpanded = false),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 60,
              width: isFabExpanded ? 200 : 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: isFabExpanded ? 5 : 2,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Demo functionality - show a message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Eligibility Check - Demo Feature\nThis will be connected to the eligibility system in future updates.',
                        ),
                        duration: Duration(seconds: 3),
                        backgroundColor: Colors.blueAccent,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 16,
                        top: 16,
                        child: Icon(
                          Icons.question_answer_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      if (isFabExpanded)
                        Positioned.fill(
                          left: 48,
                          child: Center(
                            child: AnimatedOpacity(
                              duration: Duration(milliseconds: 200),
                              opacity: isFabExpanded ? 1.0 : 0.0,
                              child: Text(
                                'Check Eligibility',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient:
                                isFabExpanded
                                    ? LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                    : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = _searchController.text.toLowerCase();

    final bgColor = _isDarkMode ? Color(0xFF121212) : Colors.grey.shade100;
    final cardColor = _isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        _isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final cardGradient =
        _isDarkMode
            ? [Color(0xFF1E1E1E), Color(0xFF2C2C2C)]
            : [Colors.white, Colors.blue.shade50.withOpacity(0.6)];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          widget.ministryName.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
            fontSize: 16 * _textSizeMultiplier,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF3CACEF),
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _showingBookmarks ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
            onPressed: () {
              if (_showingBookmarks) {
                _hideBookmarks();
              } else {
                _showBookmarks();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.language, color: Colors.white),
            onPressed: _showSettingsMenu,
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: _showHeader ? null : 0,
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: _showHeader ? 1.0 : 0.0,
                    child: Column(
                      children: [
                        if (_showingBookmarks)
                          Text(
                            _t('bookmarks'),
                            style: TextStyle(
                              fontSize: 18 * _textSizeMultiplier,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        SizedBox(height: 2),
                        if (_filteredSchemes.isNotEmpty)
                          Text(
                            "$_schemeCount ${_t('found')}",
                            style: TextStyle(
                              color:
                                  _isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                              fontSize: 16 * _textSizeMultiplier,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color:
                            _isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Colors.blue.withOpacity(0.15),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterSchemes,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16 * _textSizeMultiplier,
                    ),
                    decoration: InputDecoration(
                      hintText: _t('search'),
                      hintStyle: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 16 * _textSizeMultiplier,
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child:
                      _isLoading
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.blueAccent,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  _t('loading'),
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 14 * _textSizeMultiplier,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : _filteredSchemes.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _showingBookmarks
                                      ? Icons.bookmark_border
                                      : Icons.search_off,
                                  size: 64,
                                  color: secondaryTextColor,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  _showingBookmarks
                                      ? _t('no_bookmarks')
                                      : _t('no_schemes'),
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 16 * _textSizeMultiplier,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            controller: _scrollController,
                            itemCount: _filteredSchemes.length,
                            itemBuilder: (context, index) {
                              final scheme = _filteredSchemes[index];
                              final tagList = _getUniqueTags(
                                scheme['Tags']?.toString() ?? '',
                              );
                              final isBookmarked = _isBookmarked(scheme);

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
                                        color:
                                            _isDarkMode
                                                ? Colors.black.withOpacity(0.3)
                                                : Colors.blueAccent.withOpacity(
                                                  0.1,
                                                ),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.description_outlined,
                                              color: Colors.blueAccent,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: RichText(
                                                text: _highlightText(
                                                  scheme['Title']?.toString() ??
                                                      'Untitled Scheme',
                                                  searchQuery,
                                                  TextStyle(
                                                    fontSize:
                                                        17 *
                                                        _textSizeMultiplier,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        _isDarkMode
                                                            ? Colors
                                                                .blue
                                                                .shade300
                                                            : Colors
                                                                .blue
                                                                .shade900,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                isBookmarked
                                                    ? Icons.bookmark
                                                    : Icons.bookmark_border,
                                                color:
                                                    isBookmarked
                                                        ? Colors.amber
                                                        : Colors.blueAccent,
                                                size: 24,
                                              ),
                                              onPressed:
                                                  () => _toggleBookmark(scheme),
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              color: Colors.blueAccent,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        RichText(
                                          text: _highlightText(
                                            scheme['Description']?.toString() ??
                                                'No description available',
                                            searchQuery,
                                            TextStyle(
                                              fontSize:
                                                  15 * _textSizeMultiplier,
                                              color: textColor,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        if (tagList.isNotEmpty)
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children:
                                                tagList.map((tag) {
                                                  final isHighlighted =
                                                      searchQuery.isNotEmpty &&
                                                      tag
                                                          .toLowerCase()
                                                          .contains(
                                                            searchQuery,
                                                          );
                                                  return GestureDetector(
                                                    onTap:
                                                        () =>
                                                            _onTagPressed(tag),
                                                    child: Chip(
                                                      label: Text(
                                                        tag,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize:
                                                              12 *
                                                              _textSizeMultiplier,
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          isHighlighted
                                                              ? Colors.amber
                                                              : Colors
                                                                  .blueAccent,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                            vertical: 0,
                                                          ),
                                                    ),
                                                  );
                                                }).toList(),
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
          ),
          _buildAnimatedFAB(),
        ],
      ),
    );
  }

  TextSpan _highlightText(String text, String query, TextStyle baseStyle) {
    if (query.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    int start = 0;

    while (start < text.length) {
      final index = lowerText.indexOf(query, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: baseStyle),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: baseStyle.copyWith(
            backgroundColor: Colors.yellow.shade300,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
    }

    return TextSpan(children: spans);
  }
}
