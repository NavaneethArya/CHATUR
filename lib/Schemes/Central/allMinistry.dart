// allMinistry.dart - Updated with Navigation
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'allSchemeDetailMinistry.dart'; // Import the new page

class Ministry {
  final String ministryName;
  final String description;
  final int schemeCount;
  final String? imageUrl;

  Ministry({
    required this.ministryName,
    required this.description,
    required this.schemeCount,
    this.imageUrl,
  });

  factory Ministry.fromJson(dynamic json) {
    if (json is String) {
      return Ministry(
        ministryName: json,
        description: 'No description available',
        schemeCount: 0,
        imageUrl: null,
      );
    } else if (json is Map<String, dynamic>) {
      return Ministry(
        ministryName: json['ministry_name'] ?? json['name'] ?? '',
        description: json['description'] ?? 'No description available',
        schemeCount: json['scheme_count'] ?? json['schemes'] ?? 0,
        imageUrl: json['image_url'],
      );
    } else {
      throw Exception('Invalid ministry data format');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'ministry_name': ministryName,
      'description': description,
      'scheme_count': schemeCount,
      'image_url': imageUrl,
    };
  }
}

class MinistryDetailPage extends StatefulWidget {
  const MinistryDetailPage({super.key});

  @override
  _MinistryDetailPageState createState() => _MinistryDetailPageState();
}

class _MinistryDetailPageState extends State<MinistryDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Ministry> _ministries = [];
  List<Ministry> _filteredMinistries = [];
  bool _isLoading = false;
  int _ministryCount = 0;
  bool _isDarkMode = false;
  String _selectedLanguage = 'English';
  double _textSizeMultiplier = 1.0;

  static const String _cacheKeyMinistries = 'cached_ministries';
  static const String _cacheKeyTimestamp = 'ministries_cache_timestamp';
  static const String _cacheKeyLanguage = 'cached_ministries_language';
  static const int _cacheDurationDays = 7;

  final Map<String, IconData> _ministryIcons = {
    'agriculture': Icons.agriculture,
    'auditor': Icons.account_balance_wallet,
    'comptroller': Icons.account_balance_wallet,
    'chemicals': Icons.science,
    'fertilizers': Icons.eco,
    'commerce': Icons.business_center,
    'industry': Icons.factory,
    'communication': Icons.language,
    'consumer': Icons.shopping_cart,
    'corporate': Icons.business,
    'culture': Icons.theater_comedy,
    'defence': Icons.shield,
    'development': Icons.trending_up,
    'earth': Icons.public,
    'education': Icons.school,
    'electronics': Icons.devices,
    'environment': Icons.eco,
    'forests': Icons.forest,
    'climate': Icons.wb_sunny,
    'external': Icons.flag,
    'affairs': Icons.flag,
    'finance': Icons.account_balance,
    'fisheries': Icons.set_meal,
    'animal': Icons.pets,
    'husbandry': Icons.agriculture,
    'dairying': Icons.local_drink,
    'food': Icons.restaurant,
    'processing': Icons.precision_manufacturing,
    'health': Icons.health_and_safety,
    'family': Icons.family_restroom,
    'welfare': Icons.favorite,
    'heavy': Icons.engineering,
    'home': Icons.home,
    'housing': Icons.home_work,
    'urban': Icons.location_city,
    'information': Icons.info,
    'broadcasting': Icons.broadcast_on_home,
    'jal': Icons.water_drop,
    'shakti': Icons.water,
    'labour': Icons.work,
    'employment': Icons.work_outline,
    'law': Icons.gavel,
    'justice': Icons.balance,
    'micro': Icons.business_center,
    'small': Icons.store,
    'medium': Icons.store_mall_directory,
    'enterprises': Icons.business,
    'mines': Icons.terrain,
    'minority': Icons.groups,
    'new': Icons.energy_savings_leaf,
    'renewable': Icons.solar_power,
    'energy': Icons.bolt,
    'panchayat': Icons.location_city,
    'raj': Icons.account_balance,
    'personnel': Icons.people,
    'public': Icons.emoji_people,
    'grievances': Icons.report_problem,
    'pensions': Icons.elderly,
    'petroleum': Icons.local_gas_station,
    'natural': Icons.eco,
    'gas': Icons.propane_tank,
    'planning': Icons.edit_note,
    'ports': Icons.directions_boat,
    'shipping': Icons.local_shipping,
    'waterways': Icons.waves,
    'power': Icons.power,
    'railways': Icons.train,
    'road': Icons.directions_car,
    'transport': Icons.commute,
    'highways': Icons.nordic_walking,
    'rural': Icons.cottage,
    'science': Icons.science,
    'technology': Icons.computer,
    'skill': Icons.workspace_premium,
    'entrepreneurship': Icons.lightbulb,
    'social': Icons.groups,
    'empowerment': Icons.trending_up,
    'space': Icons.rocket_launch,
    'statistics': Icons.analytics,
    'programme': Icons.event_note,
    'implementation': Icons.check_circle,
    'steel': Icons.warehouse,
    'textiles': Icons.checkroom,
    'tourism': Icons.flight,
    'tribal': Icons.nature_people,
    'women': Icons.woman,
    'child': Icons.child_care,
    'youth': Icons.sports,
    'sports': Icons.sports_soccer,
    'niti': Icons.lightbulb,
    'aayog': Icons.account_balance,
    'lokpal': Icons.gavel,
    'india': Icons.flag,
  };

  final Map<String, String> _translations = {
    'en_search': 'Search ministries...',
    'kn_search': 'ಸಚಿವಾಲಯಗಳನ್ನು ಹುಡುಕಿ...',
    'hi_search': 'मंत्रालयों को खोजें...',
    'en_ministries': 'Central Ministries',
    'kn_ministries': 'ಕೇಂದ್ರ ಸಚಿವಾಲಯಗಳು',
    'hi_ministries': 'केंद्रीय मंत्रालय',
    'en_schemes': 'Schemes',
    'kn_schemes': 'ಯೋಜನೆಗಳು',
    'hi_schemes': 'योजनाएं',
    'en_no_ministries': 'No ministries found',
    'kn_no_ministries': 'ಯಾವುದೇ ಸಚಿವಾಲಯಗಳು ಕಂಡುಬಂದಿಲ್ಲ',
    'hi_no_ministries': 'कोई मंत्रालय नहीं मिला',
    'en_loading': 'Loading ministries...',
    'kn_loading': 'ಸಚಿವಾಲಯಗಳನ್ನು ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...',
    'hi_loading': 'मंत्रालय लोड हो रहे हैं...',
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
    _loadMinistries();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  IconData _getMinistryIcon(String ministryName) {
    String lowerName = ministryName.toLowerCase();
    for (var key in _ministryIcons.keys) {
      if (lowerName.contains(key)) {
        return _ministryIcons[key]!;
      }
    }
    return Icons.account_balance;
  }

  Color _getMinistryColor(int index) {
    List<Color> colors = [
      Color(0xFF2196F3),
      Color(0xFF4CAF50),
      Color(0xFFFF9800),
      Color(0xFF9C27B0),
      Color(0xFFE91E63),
      Color(0xFF00BCD4),
      Color(0xFFFF5722),
      Color(0xFF3F51B5),
      Color(0xFF009688),
      Color(0xFFCDDC39),
    ];
    return colors[index % colors.length];
  }

  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(_cacheKeyTimestamp);
      final cachedLanguage = prefs.getString(_cacheKeyLanguage);

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

  Future<List<Ministry>?> _loadMinistriesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ministriesJson = prefs.getStringList(_cacheKeyMinistries);

      if (ministriesJson == null || ministriesJson.isEmpty) {
        return null;
      }

      return ministriesJson
          .map((json) => Ministry.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Error loading ministries from cache: $e');
      return null;
    }
  }

  Future<void> _saveMinistryToCache(List<Ministry> ministries) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final ministriesJson =
          ministries.map((ministry) => jsonEncode(ministry.toJson())).toList();

      await prefs.setStringList(_cacheKeyMinistries, ministriesJson);
      await prefs.setString(
        _cacheKeyTimestamp,
        DateTime.now().toIso8601String(),
      );
      await prefs.setString(_cacheKeyLanguage, _selectedLanguage);

      print('Ministries cached successfully. Count: ${ministries.length}');
    } catch (e) {
      print('Error saving ministries to cache: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKeyMinistries);
      await prefs.remove(_cacheKeyTimestamp);
      await prefs.remove(_cacheKeyLanguage);
      print('Cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<List<Ministry>> _fetchMinistriesFromAPI() async {
    final langCode =
        _selectedLanguage == 'English'
            ? 'en'
            : _selectedLanguage == 'Kannada'
            ? 'kn'
            : 'hi';
    final url =
        //'https://navarasa-chathur-api.hf.space/$langCode/central/ministries';
        'https://navarasa-chathur-api.hf.space/central/ministries?lang=$langCode';

    try {
      print('Fetching from URL: $url');
      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print(
        'Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        print('Data type: ${data.runtimeType}');

        if (data is List) {
          print('Parsing ${data.length} ministries from array');
          return data.map((item) => Ministry.fromJson(item)).toList();
        } else if (data is Map) {
          if (data.containsKey('ministries')) {
            final ministriesList = data['ministries'] as List;
            print('Parsing ${ministriesList.length} ministries from map');
            return ministriesList
                .map((item) => Ministry.fromJson(item))
                .toList();
          } else if (data.containsKey('data')) {
            final ministriesList = data['data'] as List;
            print('Parsing ${ministriesList.length} ministries from data key');
            return ministriesList
                .map((item) => Ministry.fromJson(item))
                .toList();
          }
        }

        throw Exception('Unexpected API response format');
      }

      throw Exception('Failed to load ministries: HTTP ${response.statusCode}');
    } catch (e) {
      print('Error fetching ministries: $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Failed to fetch ministries: $e');
    }
  }

  Future<void> _loadMinistries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cacheValid = await _isCacheValid();

      if (cacheValid) {
        print('Loading ministries from cache...');
        final cachedMinistries = await _loadMinistriesFromCache();

        if (cachedMinistries != null && cachedMinistries.isNotEmpty) {
          setState(() {
            _ministries = cachedMinistries;
            _filteredMinistries = cachedMinistries;
            _ministryCount = cachedMinistries.length;
            _isLoading = false;
          });
          return;
        }
      }

      print('Fetching ministries from API...');
      final data = await _fetchMinistriesFromAPI();

      await _saveMinistryToCache(data);

      setState(() {
        _ministries = data;
        _filteredMinistries = data;
        _ministryCount = data.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Load ministries error: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to fetch ministries: ${e.toString()}"),
            duration: Duration(seconds: 5),
            action: SnackBarAction(label: 'Retry', onPressed: _loadMinistries),
          ),
        );
      }
    }
  }

  void _filterMinistries(String query) {
    final results =
        _ministries.where((ministry) {
          final lowerQuery = query.toLowerCase();
          final nameMatch = ministry.ministryName.toLowerCase().contains(
            lowerQuery,
          );
          final descMatch = ministry.description.toLowerCase().contains(
            lowerQuery,
          );
          return nameMatch || descMatch;
        }).toList();
    setState(() {
      _filteredMinistries = results;
      _ministryCount = results.length;
    });
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
    _loadMinistries();
  }

  void _changeTextSize(double multiplier) {
    setState(() {
      _textSizeMultiplier = multiplier;
    });
  }

  // Navigate to Ministry Schemes Page
  void _navigateToMinistrySchemes(Ministry ministry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MinistrySchemeDetailPage(
              ministryName: ministry.ministryName,
              selectedLanguage: _selectedLanguage,
              isDarkMode: _isDarkMode,
              textSizeMultiplier: _textSizeMultiplier,
            ),
      ),
    );
  }

  void _showMinistryDetails(Ministry ministry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final bgColor = _isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
        final textColor = _isDarkMode ? Colors.white : Colors.black87;

        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getMinistryIcon(ministry.ministryName),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        ministry.ministryName,
                        style: TextStyle(
                          fontSize: 18 * _textSizeMultiplier,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ministry.schemeCount > 0)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.1),
                                Colors.purple.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.description,
                                color: Colors.blueAccent,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Schemes',
                                      style: TextStyle(
                                        fontSize: 14 * _textSizeMultiplier,
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${ministry.schemeCount} ${_t('schemes')}',
                                      style: TextStyle(
                                        fontSize: 20 * _textSizeMultiplier,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 20),
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18 * _textSizeMultiplier,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        ministry.description,
                        style: TextStyle(
                          fontSize: 15 * _textSizeMultiplier,
                          color: textColor,
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Add button to view schemes
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToMinistrySchemes(ministry);
                        },
                        icon: Icon(Icons.list_alt),
                        label: Text('View All Schemes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          minimumSize: Size(double.infinity, 48),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
                        _loadMinistries();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cache cleared. Refreshing ministries...',
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

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? Color(0xFF0D1117) : Color(0xFFF5F5F5);
    final cardColor = _isDarkMode ? Color(0xFF1C2128) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final appBarColor = _isDarkMode ? Color(0xFF1E293B) : Color(0xFF1976D2);
    final searchBgColor = _isDarkMode ? Color(0xFF2D3748) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          _t('ministries').toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsMenu,
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appBarColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMinistries,
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: _t('search'),
                hintStyle: TextStyle(
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                filled: true,
                fillColor: searchBgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.blueAccent),
                          SizedBox(height: 16),
                          Text(
                            _t('loading'),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14 * _textSizeMultiplier,
                            ),
                          ),
                        ],
                      ),
                    )
                    : _filteredMinistries.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            _t('no_ministries'),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16 * _textSizeMultiplier,
                            ),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadMinistries,
                            icon: Icon(Icons.refresh),
                            label: Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : GridView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _filteredMinistries.length,
                      itemBuilder: (context, index) {
                        final ministry = _filteredMinistries[index];
                        final color = _getMinistryColor(index);

                        return GestureDetector(
                          onTap: () => _navigateToMinistrySchemes(ministry),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _isDarkMode
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                width: 1,
                              ),
                              boxShadow:
                                  _isDarkMode
                                      ? []
                                      : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          _getMinistryIcon(
                                            ministry.ministryName,
                                          ),
                                          color: color,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Expanded(
                                    child: Text(
                                      ministry.ministryName,
                                      style: TextStyle(
                                        fontSize: 13 * _textSizeMultiplier,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                        height: 1.3,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  if (ministry.schemeCount > 0)
                                    Text(
                                      '${ministry.schemeCount} ${_t('schemes')}',
                                      style: TextStyle(
                                        fontSize: 12 * _textSizeMultiplier,
                                        color:
                                            _isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
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
