import 'dart:ui';
import 'dart:convert';
import 'package:chatur_frontend/Chatbot/chatbot.dart';
import 'package:chatur_frontend/Other/profile_icon.dart';
import 'package:chatur_frontend/Schemes/state/allEligibilityQuestionDisplay.dart';
import 'package:chatur_frontend/Schemes/state/allSchemeDetailState.dart';
import 'package:chatur_frontend/Schemes/state/geminiEligibilityQuestion.dart';
import 'package:chatur_frontend/Schemes/state/schemeInformation.dart';
import 'package:chatur_frontend/Skills/skills_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatur_frontend/Events/screens/main_event_screen.dart';
import 'package:chatur_frontend/Events/services/notification_service.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController(viewportFraction: 0.9);
  
  int currentPage = 0;
  List<dynamic> recommendedSchemes = [];
  bool isLoadingSchemes = false;
  String? schemesError;

  final List<Map<String, String>> promoCards = [
    {
      "title": "Find Local Jobs",
      "sub": "Quick access to jobs near you",
      "img": "https://images.unsplash.com/photo-1521737711867-e3b97375f902?w=800"
    },
    {
      "title": "Government Schemes",
      "sub": "Latest schemes for everyone",
      "img": "https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=800"
    },
    {
      "title": "Post Skills",
      "sub": "Earn by offering your talent",
      "img": "https://images.unsplash.com/photo-1552664730-d307ca884978?w=800"
    },
    {
      "title": "Community Events",
      "sub": "Discover events happening near you",
      "img": "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800"
    },
    {
      "title": "Ask AI Assistant",
      "sub": "Clear doubts instantly",
      "img": "https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800"
    }
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    _fetchRecommendedSchemes();
  }

  Future<void> _fetchRecommendedSchemes() async {
    setState(() {
      isLoadingSchemes = true;
      schemesError = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://navarasa-chathur-api.hf.space/en/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "tags": ["farmer", "rural", "women", "loan"]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          recommendedSchemes = data is List ? data : [data];
          isLoadingSchemes = false;
        });
      } else {
        setState(() {
          schemesError = 'Failed to load schemes';
          isLoadingSchemes = false;
        });
      }
    } catch (e) {
      setState(() {
        schemesError = 'Network error: ${e.toString()}';
        isLoadingSchemes = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userName = currentUser?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: Colors.grey[50],

      /// ✅ Enhanced Modern AppBar
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5D3FD3), Color(0xFF7A5AF8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF5D3FD3).withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// Enhanced App Logo
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Image.asset(
                      "assets/images/app_logo.png",
                      height: 36, // Increased from 30
                      width: 36,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.apps, color: Colors.white, size: 36);
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Chatur",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        "Community Hub",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              /// Chatbot + Profile Icons
              Row(
                children: [
                  // Chatbot icon with badge
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.smart_toy_outlined, color: Colors.white, size: 26),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChaturChatbot()),
                        );
                      },

                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Enhanced Profile icon
                  GestureDetector(
                    onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfileIcon()),
                        );
                      },

                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        backgroundImage: currentUser?.photoURL != null
                            ? NetworkImage(currentUser!.photoURL!)
                            : null,
                        child: currentUser?.photoURL == null
                            ? Icon(Icons.person, color: Colors.deepPurple, size: 20)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(Duration(seconds: 1));
              await _fetchRecommendedSchemes();
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),

                  /// ✅ Enhanced Search bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Searching for "$value"...'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        decoration: InputDecoration(
                          hintText: 'Search services, schemes, skills...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.search, color: Colors.deepPurple, size: 24),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: Container(
                            margin: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(Icons.mic, color: Colors.deepPurple, size: 20),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  /// ✅ Enhanced Greeting
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          "👋",
                          style: TextStyle(fontSize: 28),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hey, $userName",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "What would you like to explore today?",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  /// ✅ Enhanced Horizontal cards carousel
                  Container(
                    height: 220,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: promoCards.length,
                      onPageChanged: (index) {
                        setState(() => currentPage = index);
                      },
                      itemBuilder: (context, index) {
                        final card = promoCards[index];
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double value = 1.0;
                            if (_pageController.position.haveDimensions) {
                              value = _pageController.page! - index;
                              value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                            }
                            return Center(
                              child: SizedBox(
                                height: Curves.easeOut.transform(value) * 220,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: card["img"]!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[300],
                                      child: Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[300],
                                      child: Icon(Icons.error, size: 50),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withOpacity(0.7),
                                          Colors.transparent,
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 20,
                                    left: 20,
                                    right: 20,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          card["title"]!,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.5),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          card["sub"]!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.9),
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.5),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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

                  /// ✅ Enhanced Page indicator with dots
                  SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        promoCards.length,
                        (index) => AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: currentPage == index
                                ? Colors.deepPurple
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Recommended Schemes Section
                  _buildRecommendedSchemes(),

                  SizedBox(height: 32),

                  // Main Features Grid
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Explore Features',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text('See all →'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  _buildFeaturesGrid(),

                  SizedBox(height: 32),

                  // Quick Access Section
                  _buildQuickAccessSection(),

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // RECOMMENDED SCHEMES SECTION
  // ============================================
  Widget _buildRecommendedSchemes() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.stars_rounded, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded( // 👈 ensures long text wraps properly on small screens
              child: Text(
                'Recommended Schemes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis, // 👈 prevents pixel overflow
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 4),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Personalized schemes based on your profile',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ),
      SizedBox(height: 16),

      if (isLoadingSchemes)
        _buildSchemesLoading()
      else if (schemesError != null)
        _buildSchemesError()
      else if (recommendedSchemes.isEmpty)
        _buildNoSchemes()
      else
        _buildSchemesList(),
    ],
  );
}


  Widget _buildSchemesLoading() {
    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 320,
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSchemesError() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 48),
          SizedBox(height: 12),
          Text(
            'Failed to load schemes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red[900],
            ),
          ),
          SizedBox(height: 8),
          Text(
            schemesError ?? 'Unknown error',
            style: TextStyle(fontSize: 13, color: Colors.red[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchRecommendedSchemes,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSchemes() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, color: Colors.grey[400], size: 64),
          SizedBox(height: 16),
          Text(
            'No schemes available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Check back later for personalized recommendations',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSchemesList() {
    return Container(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: recommendedSchemes.length,
        itemBuilder: (context, index) {
          final scheme = recommendedSchemes[index];
          return _buildSchemeCard(scheme, index);
        },
      ),
    );
  }

  Widget _buildSchemeCard(dynamic scheme, int index) {
    final colors = [
      [Color(0xFF667eea), Color(0xFF764ba2)],
      [Color(0xFFf093fb), Color(0xFFf5576c)],
      [Color(0xFF4facfe), Color(0xFF00f2fe)],
      [Color(0xFF43e97b), Color(0xFF38f9d7)],
      [Color(0xFFfa709a), Color(0xFFfee140)],
    ];
    
    final cardColors = colors[index % colors.length];
    
    // Extract scheme details safely
    final title = scheme['title']?.toString() ?? scheme['name']?.toString() ?? 'Untitled Scheme';
    final description = scheme['description']?.toString() ?? scheme['details']?.toString() ?? 'No description available';
    final category = scheme['category']?.toString() ?? scheme['type']?.toString() ?? 'General';
    final benefits = scheme['benefits']?.toString() ?? scheme['amount']?.toString() ?? '';
    
    return Container(
      width: 320,
      margin: EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showSchemeDetails(scheme);
          },
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: cardColors,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: cardColors[1].withOpacity(0.4),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.bookmark_border, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  Spacer(),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (benefits.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.currency_rupee, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            benefits,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Learn More',
                              style: TextStyle(
                                color: cardColors[1],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.share, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSchemeDetails(dynamic scheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final title = scheme['title']?.toString() ?? scheme['name']?.toString() ?? 'Scheme Details';
        final description = scheme['description']?.toString() ?? scheme['details']?.toString() ?? 'No description available';
        final category = scheme['category']?.toString() ?? scheme['type']?.toString() ?? 'General';
        final eligibility = scheme['eligibility']?.toString() ?? 'Not specified';
        final benefits = scheme['benefits']?.toString() ?? scheme['amount']?.toString() ?? 'Not specified';
        final howToApply = scheme['how_to_apply']?.toString() ?? scheme['application']?.toString() ?? 'Visit nearest government office';
        
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.all(24),
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 24),
                        _buildDetailSection(
                          'Description',
                          Icons.description,
                          description,
                        ),
                        SizedBox(height: 20),
                        _buildDetailSection(
                          'Benefits',
                          Icons.card_giftcard,
                          benefits,
                        ),
                        SizedBox(height: 20),
                        _buildDetailSection(
                          'Eligibility',
                          Icons.check_circle_outline,
                          eligibility,
                        ),
                        SizedBox(height: 20),
                        _buildDetailSection(
                          'How to Apply',
                          Icons.assignment_turned_in,
                          howToApply,
                        ),
                        SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Navigate to application page
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Application process coming soon!'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Apply Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildDetailSection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.deepPurple, size: 20),
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
          ],
        ),
        SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ============================================
  // ENHANCED FEATURES GRID
  // ============================================
  Widget _buildFeaturesGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.05,
        children: [
          _buildFeatureCard(
            icon: Icons.work_outline_rounded,
            title: 'Find Skills',
            subtitle: 'Discover talent',
            gradient: [Color(0xFF4A90E2), Color(0xFF357ABD)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SkillsScreen()),
              );
            },
          ),
          _buildFeatureCard(
            icon: Icons.event_rounded,
            title: 'Events',
            subtitle: 'Community hub',
            gradient: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MainEventScreen()),
              );
            },
          ),
          _buildFeatureCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Chatbot',
            subtitle: 'Ask schemes',
            gradient: [Color(0xFF27AE60), Color(0xFF229954)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChaturChatbot()),
              );
            },
          ),
          _buildFeatureCard(
            icon: Icons.account_balance_rounded,
            title: 'Schemes',
            subtitle: 'Govt benefits',
            gradient: [Color(0xFFE67E22), Color(0xFFD35400)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SchemeDetailPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradient[1].withOpacity(0.4),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // ENHANCED QUICK ACCESS SECTION
  // ============================================
  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Access',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        _buildQuickAccessTile(
          icon: Icons.post_add,
          title: 'Post Your Skill',
          subtitle: 'Let employers find you',
          color: Colors.teal,
          onTap: () {
            // TODO: Navigate to post skill
          },
        ),
        _buildQuickAccessTile(
          icon: Icons.calendar_today,
          title: 'View Calendar',
          subtitle: 'Check upcoming events',
          color: Colors.indigo,
          onTap: () {
            // TODO: Navigate to calendar
          },
        ),
        _buildQuickAccessTile(
          icon: Icons.location_on,
          title: 'Find Nearby',
          subtitle: 'Workers in your area',
          color: Colors.red,
          onTap: () {
            // TODO: Navigate to nearby skills
          },
        ),
      ],
    );
  }

  Widget _buildQuickAccessTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}