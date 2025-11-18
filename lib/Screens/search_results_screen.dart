import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatur_frontend/Schemes/state/allSchemeDetailState.dart';
import 'package:chatur_frontend/Schemes/state/schemeAPI.dart';
import 'package:chatur_frontend/Skills/skills_screen.dart';
import 'package:chatur_frontend/Skills/skill_detail_screen.dart';
import 'package:chatur_frontend/Events/screens/main_event_screen.dart';
import 'package:chatur_frontend/Events/models/event_model.dart';
import 'package:chatur_frontend/Events/services/event_firebase_service.dart';
import 'package:chatur_frontend/My_Store/MainStorePage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;

  const SearchResultsScreen({super.key, required this.searchQuery});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  String _searchQuery = '';
  bool _isSearching = false;

  // Search results
  List<Scheme> _schemeResults = [];
  List<SkillPost> _skillResults = [];
  List<EventModel> _eventResults = [];
  List<Map<String, dynamic>> _storeResults = [];

  // Loading states
  bool _loadingSchemes = false;
  bool _loadingSkills = false;
  bool _loadingEvents = false;
  bool _loadingStores = false;

  // Error states
  String? _schemeError;
  String? _skillError;
  String? _eventError;
  String? _storeError;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.searchQuery;
    _searchController = TextEditingController(text: widget.searchQuery);
    _tabController = TabController(length: 4, vsync: this);
    _saveSearchHistory();
    _performSearch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList('search_history') ?? [];
      if (!history.contains(_searchQuery) && _searchQuery.trim().isNotEmpty) {
        history.insert(0, _searchQuery);
        if (history.length > 10) history = history.take(10).toList();
        await prefs.setStringList('search_history', history);
      }
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.trim().isEmpty) return;

    setState(() => _isSearching = true);

    // Search all categories in parallel
    await Future.wait([
      _searchSchemes(),
      _searchSkills(),
      _searchEvents(),
      _searchStores(),
    ]);

    setState(() => _isSearching = false);
  }

  Future<void> _searchSchemes() async {
    setState(() {
      _loadingSchemes = true;
      _schemeError = null;
    });
    try {
      // Try to load from cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedSchemesJson = prefs.getStringList('cached_schemes');

      List<Scheme> schemes = [];
      if (cachedSchemesJson != null && cachedSchemesJson.isNotEmpty) {
        schemes =
            cachedSchemesJson
                .map((json) => Scheme.fromJson(jsonDecode(json)))
                .toList();
      } else {
        // Fetch from API if cache is empty
        schemes = await fetchKarnatakaSchemes();
      }

      final query = _searchQuery.toLowerCase();
      _schemeResults =
          schemes.where((scheme) {
            final title = scheme.title.toLowerCase();
            final description = scheme.description.toLowerCase();
            final tags = scheme.tags.toLowerCase();
            final benefits = scheme.benefits.join(' ').toLowerCase();
            final eligibility = scheme.eligibility.join(' ').toLowerCase();

            return title.contains(query) ||
                description.contains(query) ||
                tags.contains(query) ||
                benefits.contains(query) ||
                eligibility.contains(query);
          }).toList();
    } catch (e) {
      _schemeError = 'Failed to search schemes: ${e.toString()}';
      debugPrint('Error searching schemes: $e');
    }
    setState(() => _loadingSchemes = false);
  }

  Future<void> _searchSkills() async {
    setState(() => _loadingSkills = true);
    try {
      final query = _searchQuery.toLowerCase();
      final skillsSnapshot =
          await FirebaseFirestore.instance
              .collectionGroup('skills')
              .where('status', isEqualTo: 'active')
              .get();

      _skillResults =
          skillsSnapshot.docs
              .map((doc) {
                try {
                  return SkillPost.fromFirestore(doc);
                } catch (e) {
                  return null;
                }
              })
              .whereType<SkillPost>()
              .where((skill) {
                final title = skill.title.toLowerCase();
                final category = skill.category.toLowerCase();
                final description = skill.description.toLowerCase();
                return title.contains(query) ||
                    category.contains(query) ||
                    description.contains(query);
              })
              .toList();
    } catch (e) {
      debugPrint('Error searching skills: $e');
    }
    setState(() => _loadingSkills = false);
  }

  Future<void> _searchEvents() async {
    setState(() => _loadingEvents = true);
    try {
      final query = _searchQuery.toLowerCase();
      final events = await EventFirebaseService.getRecentEvents(
        daysBefore: 30,
        daysAfter: 60,
        forceRefresh: true,
      );

      _eventResults =
          events.where((event) {
            final heading = event.heading.toLowerCase();
            final description = event.description.toLowerCase();
            final location = event.locationName?.toLowerCase() ?? '';
            return heading.contains(query) ||
                description.contains(query) ||
                location.contains(query);
          }).toList();
    } catch (e) {
      debugPrint('Error searching events: $e');
    }
    setState(() => _loadingEvents = false);
  }

  Future<void> _searchStores() async {
    setState(() => _loadingStores = true);
    try {
      final query = _searchQuery.toLowerCase();
      final storesSnapshot =
          await FirebaseFirestore.instance
              .collection('stores')
              .where('status', isEqualTo: 'active')
              .get();

      _storeResults =
          storesSnapshot.docs
              .map((doc) {
                final data = doc.data();
                final storeName =
                    (data['storeName'] ?? '').toString().toLowerCase();
                final description =
                    (data['storeDescription'] ?? '').toString().toLowerCase();

                if (storeName.contains(query) || description.contains(query)) {
                  return {'id': doc.id, ...data};
                }
                return null;
              })
              .whereType<Map<String, dynamic>>()
              .toList();
    } catch (e) {
      debugPrint('Error searching stores: $e');
    }
    setState(() => _loadingStores = false);
  }

  int get _totalResults =>
      _schemeResults.length +
      _skillResults.length +
      _eventResults.length +
      _storeResults.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5D3FD3), Color(0xFF7A5AF8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Search Results',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Text(
                '"$_searchQuery"',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _searchQuery = _searchController.text.trim();
              if (_searchQuery.isNotEmpty) {
                _performSearch();
              }
            },
            tooltip: 'Search again',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('All'),
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_totalResults',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Schemes'),
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_schemeResults.length}',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Skills'),
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_skillResults.length}',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Events'),
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_eventResults.length}',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar at top
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search again...',
                prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.search, color: Colors.deepPurple),
                      onPressed: () {
                        _searchQuery = _searchController.text.trim();
                        if (_searchQuery.isNotEmpty) {
                          _saveSearchHistory();
                          _performSearch();
                        }
                      },
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (value) {
                _searchQuery = value.trim();
                if (_searchQuery.isNotEmpty) {
                  _saveSearchHistory();
                  _performSearch();
                }
              },
              onChanged: (value) => setState(() {}),
            ),
          ),
          // Results
          Expanded(
            child:
                _isSearching
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF5D3FD3),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Searching...',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllResults(),
                        _buildSchemesTab(),
                        _buildSkillsTab(),
                        _buildEventsTab(),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllResults() {
    if (_totalResults == 0) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_schemeResults.isNotEmpty) ...[
            _buildSectionHeader(
              'Government Schemes',
              _schemeResults.length,
              Icons.account_balance,
              Color(0xFFE67E22),
            ),
            SizedBox(height: 12),
            ..._schemeResults.take(3).map((scheme) => _buildSchemeCard(scheme)),
            if (_schemeResults.length > 3)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: TextButton(
                    onPressed: () => _tabController.animateTo(1),
                    child: Text(
                      'See all ${_schemeResults.length} schemes →',
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  ),
                ),
              ),
            SizedBox(height: 24),
          ],
          if (_skillResults.isNotEmpty) ...[
            _buildSectionHeader(
              'Skills & Services',
              _skillResults.length,
              Icons.handyman,
              Color(0xFF10B981),
            ),
            SizedBox(height: 12),
            ..._skillResults.take(3).map((skill) => _buildSkillCard(skill)),
            if (_skillResults.length > 3)
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: Text('See all ${_skillResults.length} skills →'),
              ),
            SizedBox(height: 24),
          ],
          if (_eventResults.isNotEmpty) ...[
            _buildSectionHeader(
              'Events',
              _eventResults.length,
              Icons.event,
              Color(0xFFF59E0B),
            ),
            SizedBox(height: 12),
            ..._eventResults.take(3).map((event) => _buildEventCard(event)),
            if (_eventResults.length > 3)
              TextButton(
                onPressed: () => _tabController.animateTo(3),
                child: Text('See all ${_eventResults.length} events →'),
              ),
            SizedBox(height: 24),
          ],
          if (_storeResults.isNotEmpty) ...[
            _buildSectionHeader(
              'Stores',
              _storeResults.length,
              Icons.store,
              Color(0xFFC85CF6),
            ),
            SizedBox(height: 12),
            ..._storeResults.take(3).map((store) => _buildStoreCard(store)),
            SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSchemesTab() {
    if (_loadingSchemes) {
      return Center(child: CircularProgressIndicator());
    }
    if (_schemeError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            SizedBox(height: 16),
            Text(
              _schemeError!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _searchSchemes, child: Text('Retry')),
          ],
        ),
      );
    }
    if (_schemeResults.isEmpty) {
      return _buildEmptyTab('No schemes found');
    }
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _schemeResults.length,
      itemBuilder: (context, index) => _buildSchemeCard(_schemeResults[index]),
    );
  }

  Widget _buildSkillsTab() {
    if (_loadingSkills) {
      return Center(child: CircularProgressIndicator());
    }
    if (_skillResults.isEmpty) {
      return _buildEmptyTab('No skills found');
    }
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _skillResults.length,
      itemBuilder: (context, index) => _buildSkillCard(_skillResults[index]),
    );
  }

  Widget _buildEventsTab() {
    if (_loadingEvents) {
      return Center(child: CircularProgressIndicator());
    }
    if (_eventResults.isEmpty) {
      return _buildEmptyTab('No events found');
    }
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _eventResults.length,
      itemBuilder: (context, index) => _buildEventCard(_eventResults[index]),
    );
  }

  Widget _buildSectionHeader(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSchemeCard(Scheme scheme) {
    final title = scheme.title;
    final description = scheme.description;
    final tags = scheme.tags;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to scheme details page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SchemeDetailPage()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE67E22), Color(0xFFD35400)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.account_balance, color: Colors.white),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHighlightedText(
                        title,
                        _searchQuery,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                      ),
                      SizedBox(height: 4),
                      _buildHighlightedText(
                        description,
                        _searchQuery,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 2,
                      ),
                      if (tags.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              tags.split(',').take(3).map((tag) {
                                final trimmedTag = tag.trim();
                                if (trimmedTag.isEmpty)
                                  return SizedBox.shrink();
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE67E22).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    trimmedTag,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFE67E22),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillCard(SkillPost skill) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => EnhancedSkillDetailScreen(
                      skillId: skill.id,
                      userId: skill.userId,
                    ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child:
                      skill.imageUrls.isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: skill.imageUrls.first,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Icon(Icons.work),
                            ),
                          )
                          : Icon(Icons.work, color: Colors.grey[400]),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHighlightedText(
                        skill.title,
                        _searchQuery,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                      ),
                      SizedBox(height: 4),
                      _buildHighlightedText(
                        skill.description,
                        _searchQuery,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 2,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              skill.category,
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            skill.priceDisplay,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MainEventScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child:
                      event.imageUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: event.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Icon(Icons.event),
                            ),
                          )
                          : Icon(Icons.event, color: Colors.grey[400]),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHighlightedText(
                        event.heading,
                        _searchQuery,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                      ),
                      SizedBox(height: 4),
                      _buildHighlightedText(
                        event.description,
                        _searchQuery,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 2,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(event.eventDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (event.locationName != null) ...[
                            SizedBox(width: 12),
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.locationName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final storeName = store['storeName']?.toString() ?? 'Store';
    final description = store['storeDescription']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => StoreProductsPage(
                      storeData: store,
                      storeId: store['id'] ?? '',
                    ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFC85CF6), Color(0xFF9B59B6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      store['storeLogoUrl'] != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: store['storeLogoUrl'],
                              fit: BoxFit.cover,
                              errorWidget:
                                  (_, __, ___) =>
                                      Icon(Icons.store, color: Colors.white),
                            ),
                          )
                          : Icon(Icons.store, color: Colors.white),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHighlightedText(
                        storeName,
                        _searchQuery,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                      ),
                      SizedBox(height: 4),
                      _buildHighlightedText(
                        description,
                        _searchQuery,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          SizedBox(height: 24),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          Text(
            'Searched for: "$_searchQuery"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Helper method to highlight search terms in text
  Widget _buildHighlightedText(
    String text,
    String query, {
    TextStyle? style,
    int? maxLines,
  }) {
    if (query.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final matches = <Match>[];

    int startIndex = 0;
    while (true) {
      final index = textLower.indexOf(queryLower, startIndex);
      if (index == -1) break;
      matches.add(Match(index, index + query.length));
      startIndex = index + 1;
    }

    if (matches.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final spans = <TextSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(text: text.substring(lastIndex, match.start), style: style),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: (style ?? TextStyle()).copyWith(
            backgroundColor: Colors.yellow.withOpacity(0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: style));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// Helper class for match positions
class Match {
  final int start;
  final int end;
  Match(this.start, this.end);
}
