import 'package:chatur_frontend/Skills/qr_scanner_screen.dart';
import 'package:chatur_frontend/Skills/skill_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math' as math;

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF00D4FF);
  static const Color accent = Color(0xFFFF6584);
  static const Color background = Color(0xFFF8F9FE);
  static const Color text = Color(0xFF2D3142);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFFFAB00);
  static const Color danger = Color(0xFFFF5252);

  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF5548E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFFFF6584), Color(0xFFFF8A9B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const successGradient = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF00E5B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class SkillPost {
  final String id, userId, title, category, description, address, status;
  final int? flatPrice, perKmPrice;
  final List<String> imageUrls;
  final GeoPoint coordinates;
  final double serviceRadiusMeters, rating;
  final int reviewCount, viewCount, bookingCount;
  final DateTime createdAt;
  final bool isAtWork, verified;
  final Map<String, dynamic>? availability, profile;

  SkillPost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc)
    : id = doc.id,
      userId = doc.data()?['userId'] ?? '',
      title = doc.data()?['skillTitle'] ?? 'Service',
      category = doc.data()?['category'] ?? 'General',
      description = doc.data()?['description'] ?? '',
      flatPrice = doc.data()?['flatPrice'] as int?,
      perKmPrice = doc.data()?['perKmPrice'] as int?,
      imageUrls =
          (doc.data()?['images'] is List)
              ? List<String>.from(doc.data()!['images'])
              : [],
      address = doc.data()?['address'] ?? '',
      coordinates = doc.data()?['coordinates'] ?? const GeoPoint(0, 0),
      serviceRadiusMeters =
          (doc.data()?['serviceRadiusMeters'] ?? 5000).toDouble(),
      createdAt =
          (doc.data()?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating = (doc.data()?['rating'] ?? 0.0).toDouble(),
      reviewCount = doc.data()?['reviewCount'] ?? 0,
      viewCount = doc.data()?['viewCount'] ?? 0,
      bookingCount = doc.data()?['bookingCount'] ?? 0,
      status = doc.data()?['status'] ?? 'active',
      isAtWork = doc.data()?['isAtWork'] ?? false,
      availability = doc.data()?['availability'] as Map<String, dynamic>?,
      profile = doc.data()?['profile'] as Map<String, dynamic>?,
      verified = doc.data()?['verified'] ?? false;

  String get priceDisplay {
    if (flatPrice != null && flatPrice! > 0) return '₹$flatPrice';
    if (perKmPrice != null && perKmPrice! > 0) return '₹$perKmPrice/km';
    return 'Negotiable';
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  String? get phoneNumber => profile?['phone'] as String?;
  bool get isVerified => verified || (rating >= 4.5 && reviewCount >= 10);
}

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen>
    with TickerProviderStateMixin {
  String _searchQuery = '', _selectedCategory = 'All', _sortBy = 'recent';
  RangeValues _priceRange = const RangeValues(0, 5000);
  double _maxDistance = 50;
  bool _showVerifiedOnly = false,
      _isLoadingLocation = true,
      _hasLoadedOnce = false;

  final Set<String> _savedSkillIds = {};
  LatLng? _userLocation;
  Timer? _searchDebounce;
  List<SkillPost> _cachedSkills = [];

  late AnimationController _fabController, _headerController;
  final ScrollController _scrollController = ScrollController();

  final _categories = [
    {
      'name': 'All',
      'icon': Icons.grid_view_rounded,
      'color': Color(0xFF6C63FF),
      'gradient': [Color(0xFF6C63FF), Color(0xFF8B7FFF)],
    },
    {
      'name': 'Carpenter',
      'icon': Icons.carpenter_outlined,
      'color': Color(0xFFFF6B6B),
      'gradient': [Color(0xFFFF6B6B), Color(0xFFFF8787)],
    },
    {
      'name': 'Electrician',
      'icon': Icons.electric_bolt,
      'color': Color(0xFFFFD93D),
      'gradient': [Color(0xFFFFD93D), Color(0xFFFFE66D)],
    },
    {
      'name': 'Plumber',
      'icon': Icons.plumbing,
      'color': Color(0xFF4ECDC4),
      'gradient': [Color(0xFF4ECDC4), Color(0xFF6FE0D8)],
    },
    {
      'name': 'Cook',
      'icon': Icons.restaurant,
      'color': Color(0xFFFF6584),
      'gradient': [Color(0xFFFF6584), Color(0xFFFF8A9B)],
    },
    {
      'name': 'Painter',
      'icon': Icons.palette,
      'color': Color(0xFF95E1D3),
      'gradient': [Color(0xFF95E1D3), Color(0xFFAFECE0)],
    },
    {
      'name': 'Driver',
      'icon': Icons.local_taxi,
      'color': Color(0xFF6C5CE7),
      'gradient': [Color(0xFF6C5CE7), Color(0xFF8B7FFF)],
    },
    {
      'name': 'Mechanic',
      'icon': Icons.build,
      'color': Color(0xFFFF7675),
      'gradient': [Color(0xFFFF7675), Color(0xFFFF9999)],
    },
    {
      'name': 'Tutor',
      'icon': Icons.school,
      'color': Color(0xFF74B9FF),
      'gradient': [Color(0xFF74B9FF), Color(0xFF94CBFF)],
    },
    {
      'name': 'Gardener',
      'icon': Icons.grass,
      'color': Color(0xFF55EFC4),
      'gradient': [Color(0xFF55EFC4), Color(0xFF7FF5D8)],
    },
    {
      'name': 'Tailor',
      'icon': Icons.checkroom,
      'color': Color(0xFFFD79A8),
      'gradient': [Color(0xFFFD79A8), Color(0xFFFF99BD)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedSkills();
    _getUserLocation();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _fabController.dispose();
    _headerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled())
        throw Exception('Location disabled');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permission denied');
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _userLocation = const LatLng(12.9716, 77.5946);
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadSavedSkills() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('savedSkills')
              .get();
      setState(() => _savedSkillIds.addAll(snapshot.docs.map((doc) => doc.id)));
    } catch (e) {
      debugPrint('Error loading saved skills: $e');
    }
  }

  Future<void> _toggleSave(SkillPost skill) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginPrompt();
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savedSkills')
        .doc(skill.id);

    try {
      if (_savedSkillIds.contains(skill.id)) {
        await docRef.delete();
        setState(() => _savedSkillIds.remove(skill.id));
        _showSnackBar('Removed from saved', AppColors.warning);
      } else {
        await docRef.set({
          'skillId': skill.id,
          'userId': skill.userId,
          'skillTitle': skill.title,
          'category': skill.category,
          'images': skill.imageUrls,
          'savedAt': FieldValue.serverTimestamp(),
        });
        setState(() => _savedSkillIds.add(skill.id));
        _showSnackBar('Saved successfully', AppColors.success);
      }
    } catch (e) {
      _showSnackBar('Error: $e', AppColors.danger);
    }
  }

  Future<void> _makeCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showSnackBar('Phone number not available', AppColors.danger);
      return;
    }

    try {
      final uri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (e) {
      _showSnackBar('Cannot make call', AppColors.danger);
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
    });
  }

  List<SkillPost> _filterAndSortSkills(List<SkillPost> skills) {
    var filtered =
        skills.where((skill) {
          final matchesSearch =
              _searchQuery.isEmpty ||
              skill.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              skill.category.toLowerCase().contains(_searchQuery.toLowerCase());

          final matchesCategory =
              _selectedCategory == 'All' || skill.category == _selectedCategory;

          final price = skill.flatPrice ?? skill.perKmPrice ?? 0;
          final matchesPrice =
              price == 0 ||
              (price >= _priceRange.start && price <= _priceRange.end);

          var matchesDistance = true;
          if (_userLocation != null &&
              !_isLoadingLocation &&
              _maxDistance < 100) {
            try {
              final distance = const Distance().as(
                LengthUnit.Kilometer,
                _userLocation!,
                LatLng(skill.coordinates.latitude, skill.coordinates.longitude),
              );
              matchesDistance = distance <= _maxDistance;
            } catch (e) {
              matchesDistance = true;
            }
          }

          return matchesSearch &&
              matchesCategory &&
              matchesPrice &&
              matchesDistance &&
              (!_showVerifiedOnly || skill.isVerified) &&
              skill.status == 'active';
        }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'nearby':
          if (_userLocation == null) return 0;
          try {
            final distA = const Distance().as(
              LengthUnit.Kilometer,
              _userLocation!,
              LatLng(a.coordinates.latitude, a.coordinates.longitude),
            );
            final distB = const Distance().as(
              LengthUnit.Kilometer,
              _userLocation!,
              LatLng(b.coordinates.latitude, b.coordinates.longitude),
            );
            return distA.compareTo(distB);
          } catch (e) {
            return 0;
          }
        case 'rating':
          return b.rating.compareTo(a.rating);
        case 'price_low':
          return (a.flatPrice ?? a.perKmPrice ?? 99999).compareTo(
            b.flatPrice ?? b.perKmPrice ?? 99999,
          );
        case 'price_high':
          return (b.flatPrice ?? b.perKmPrice ?? 0).compareTo(
            a.flatPrice ?? a.perKmPrice ?? 0,
          );
        case 'popular':
          return b.bookingCount.compareTo(a.bookingCount);
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return filtered;
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.lock_outline, color: AppColors.primary),
                SizedBox(width: 12),
                Text('Login Required'),
              ],
            ),
            content: const Text('Please login to access this feature.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Login'),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildSearchHeader()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryHeaderDelegate(
              child: _buildCategoryChips(),
              minHeight: 85,
              maxHeight: 85,
            ),
          ),
          _buildSkillsList(),
        ],
      ),
      drawer: _buildDrawer(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: FlexibleSpaceBar(
          title: FadeTransition(
            opacity: _headerController,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.explore,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Discover Services',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: TextField(
          onChanged: _onSearchChanged,
          style: const TextStyle(color: AppColors.text, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search services...',
            hintStyle: TextStyle(color: AppColors.textLight.withOpacity(0.6)),
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIconButton(
                  Icons.tune_rounded,
                  _showFilterSheet,
                  AppColors.accentGradient,
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  Icons.sort_rounded,
                  _showSortSheet,
                  AppColors.successGradient,
                ),
                const SizedBox(width: 8),
              ],
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon,
    VoidCallback onPressed,
    LinearGradient gradient,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 85,
      color: AppColors.background,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['name'];

          return GestureDetector(
            onTap:
                () => setState(
                  () => _selectedCategory = category['name'] as String,
                ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                gradient:
                    isSelected
                        ? LinearGradient(
                          colors: (category['gradient'] as List).cast<Color>(),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                        : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        isSelected
                            ? (category['color'] as Color).withOpacity(0.4)
                            : Colors.black.withOpacity(0.08),
                    blurRadius: isSelected ? 12 : 8,
                    offset: Offset(0, isSelected ? 6 : 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    color:
                        isSelected ? Colors.white : category['color'] as Color,
                    size: isSelected ? 20 : 18,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['name'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkillsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collectionGroup('skills').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_hasLoadedOnce) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback:
                        (bounds) =>
                            AppColors.primaryGradient.createShader(bounds),
                    child: const Icon(
                      Icons.explore,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Loading services...',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState());
        }

        try {
          var skills =
              snapshot.data!.docs
                  .map((doc) {
                    try {
                      return SkillPost.fromFirestore(doc);
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<SkillPost>()
                  .toList();

          skills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _cachedSkills = skills;
          _hasLoadedOnce = true;

          final filteredSkills = _filterAndSortSkills(skills);

          if (filteredSkills.isEmpty) {
            return SliverFillRemaining(child: _buildNoResultsState());
          }

          return SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSkillCard(filteredSkills[index]),
                childCount: filteredSkills.length,
              ),
            ),
          );
        } catch (e) {
          return SliverFillRemaining(child: Center(child: Text('Error: $e')));
        }
      },
    );
  }

  Widget _buildSkillCard(SkillPost skill) {
    final isSaved = _savedSkillIds.contains(skill.id);
    final distance =
        _userLocation != null
            ? const Distance().as(
              LengthUnit.Kilometer,
              _userLocation!,
              LatLng(skill.coordinates.latitude, skill.coordinates.longitude),
            )
            : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EnhancedSkillDetailScreen(
                          skillId: skill.id,
                          userId: skill.userId,
                        ),
                  ),
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      skill.imageUrls.isNotEmpty
                          ? Image.network(
                            skill.imageUrls.first,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                          : _buildPlaceholder(),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _toggleSave(skill),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      isSaved
                                          ? AppColors.danger.withOpacity(0.4)
                                          : Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              isSaved ? Icons.favorite : Icons.favorite_border,
                              color:
                                  isSaved
                                      ? AppColors.danger
                                      : AppColors.textLight,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                skill.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                skill.priceDisplay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.description,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildChip(
                            Icons.category,
                            skill.category,
                            AppColors.primaryGradient,
                          ),
                          if (distance != null)
                            _buildChip(
                              Icons.location_on,
                              '${distance.toStringAsFixed(1)} km',
                              AppColors.accentGradient,
                            ),
                          _buildChip(
                            Icons.access_time,
                            skill.timeAgo,
                            LinearGradient(
                              colors: [Colors.grey[600]!, Colors.grey[500]!],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildButton(
                              Icons.phone,
                              'Call',
                              AppColors.successGradient,
                              () => _makeCall(skill.phoneNumber),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildButton(
                              Icons.visibility,
                              'View',
                              LinearGradient(
                                colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
                              ),
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => EnhancedSkillDetailScreen(
                                        skillId: skill.id,
                                        userId: skill.userId,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.secondary.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: 60,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, LinearGradient gradient) {
    final color = gradient.colors.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, // Changed: white background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // Added: colored border
          width: 1.5,
          color: color,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1), // Changed: lighter shadow
            blurRadius: 4, // Changed: reduced blur
            offset: const Offset(0, 2), // Changed: reduced offset
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color), // Changed: colored icon
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              // Changed: colored text
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    IconData icon,
    String label,
    LinearGradient gradient,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
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
          ShaderMask(
            shaderCallback:
                (bounds) => AppColors.primaryGradient.createShader(bounds),
            child: const Icon(Icons.work_off, size: 100, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'No services available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Be the first to post a service!'),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback:
                (bounds) => AppColors.accentGradient.createShader(bounds),
            child: const Icon(Icons.search_off, size: 100, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'No results found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedCategory = 'All';
                _maxDistance = 50;
                _priceRange = const RangeValues(0, 5000);
                _showVerifiedOnly = false;
              });
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
      child: FloatingActionButton.extended(
        onPressed: () {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            _showLoginPrompt();
          } else {
            Navigator.pushNamed(context, '/post-skill');
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: const [
              Icon(Icons.add_circle, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Post Service',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                  child:
                      user?.photoURL == null
                          ? const Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.primary,
                          )
                          : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? 'Guest User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'Not logged in',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children:
                  user != null
                      ? [
                        _buildDrawerItem(
                          Icons.add_circle,
                          'Post New Service',
                          AppColors.primaryGradient,
                          () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/post-skill');
                          },
                        ),
                        _buildDrawerItem(
                          Icons.work,
                          'My Services',
                          AppColors.accentGradient,
                          () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/my-skills');
                          },
                        ),
                        _buildDrawerItem(
                          Icons.favorite,
                          'Saved Services',
                          LinearGradient(
                            colors: [AppColors.danger, Color(0xFFFF8A9B)],
                          ),
                          () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/saved-skills');
                          },
                        ),
                        const Divider(height: 32),
                        _buildDrawerItem(
                          Icons.qr_code_scanner,
                          'Scan QR to Rate',
                          AppColors.successGradient,
                          () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QRScannerScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          Icons.person,
                          'My Profile',
                          AppColors.primaryGradient,
                          () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/profile');
                          },
                        ),
                        const Divider(height: 32),
                        _buildDrawerItem(
                          Icons.logout,
                          'Logout',
                          LinearGradient(
                            colors: [Colors.grey[600]!, Colors.grey[500]!],
                          ),
                          () async {
                            Navigator.pop(context);
                            await FirebaseAuth.instance.signOut();
                            _showSnackBar(
                              'Logged out successfully',
                              AppColors.success,
                            );
                          },
                        ),
                      ]
                      : [
                        _buildDrawerItem(
                          Icons.login,
                          'Login',
                          AppColors.primaryGradient,
                          () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/login');
                          },
                        ),
                      ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _maxDistance = 50;
                          _priceRange = const RangeValues(0, 5000);
                          _showVerifiedOnly = false;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Max Distance: ${_maxDistance.toInt()} km',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Slider(
                  value: _maxDistance,
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: '${_maxDistance.toInt()} km',
                  onChanged: (val) => setState(() => _maxDistance = val),
                ),
                const SizedBox(height: 24),
                Text(
                  'Price Range: ₹${_priceRange.start.toInt()} - ₹${_priceRange.end.toInt()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 10000,
                  divisions: 100,
                  labels: RangeLabels(
                    '₹${_priceRange.start.toInt()}',
                    '₹${_priceRange.end.toInt()}',
                  ),
                  onChanged: (val) => setState(() => _priceRange = val),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text(
                    'Verified Providers Only',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('4.5+ rating & 10+ reviews'),
                  value: _showVerifiedOnly,
                  activeColor: AppColors.success,
                  onChanged: (val) => setState(() => _showVerifiedOnly = val),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showSortSheet() {
    final sortOptions = [
      {'key': 'recent', 'label': 'Most Recent', 'icon': Icons.access_time},
      {'key': 'nearby', 'label': 'Nearest First', 'icon': Icons.location_on},
      {'key': 'rating', 'label': 'Highest Rated', 'icon': Icons.star},
      {'key': 'popular', 'label': 'Most Popular', 'icon': Icons.trending_up},
      {
        'key': 'price_low',
        'label': 'Price: Low to High',
        'icon': Icons.arrow_upward,
      },
      {
        'key': 'price_high',
        'label': 'Price: High to Low',
        'icon': Icons.arrow_downward,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort By',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ...sortOptions.map((option) {
                  final isSelected = _sortBy == option['key'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _sortBy = option['key'] as String);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                option['icon'] as IconData,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  option['label'] as String,
                                  style: TextStyle(
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : AppColors.text,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight, maxHeight;

  _CategoryHeaderDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow:
            shrinkOffset > 0
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: child,
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
