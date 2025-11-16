import 'package:chatur_frontend/Skills/my_review_screen.dart';
import 'package:chatur_frontend/Skills/qr_scanner_screen.dart';
import 'package:chatur_frontend/Skills/saved_skills_screen.dart';
import 'package:chatur_frontend/Skills/skill_detail_screen.dart';
import 'package:chatur_frontend/Skills/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5548E0);
  static const Color secondary = Color(0xFF00D4FF);
  static const Color accent = Color(0xFFFF6584);
  static const Color background = Color(0xFFF8F9FE);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF2D3142);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFFFAB00);
  static const Color danger = Color(0xFFFF5252);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF5548E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class SkillPost {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String description;
  final int? flatPrice;
  final int? perKmPrice;
  final List<String> imageUrls;
  final String address;
  final GeoPoint coordinates;
  final double serviceRadiusMeters;
  final DateTime createdAt;
  final double rating;
  final int reviewCount;
  final int viewCount;
  final int bookingCount;
  final String status;
  final bool isAtWork;
  final Map<String, dynamic>? availability;
  final Map<String, dynamic>? profile;
  final bool verified;

  SkillPost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc)
      : id = doc.id,
        userId = doc.data()?['userId'] ?? '',
        title = doc.data()?['skillTitle'] ?? 'Service',
        category = doc.data()?['category'] ?? 'General',
        description = doc.data()?['description'] ?? '',
        flatPrice = doc.data()?['flatPrice'] as int?,
        perKmPrice = doc.data()?['perKmPrice'] as int?,
        imageUrls = (doc.data()?['images'] is List)
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

class _SkillsScreenState extends State<SkillsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'recent';
  RangeValues _priceRange = const RangeValues(0, 5000);
  double _maxDistance = 50;
  bool _showVerifiedOnly = false;

  final Set<String> _savedSkillIds = {};
  LatLng? _userLocation;
  Timer? _searchDebounce;
  bool _isLoadingLocation = true;

  // Cache for skills to prevent flickering
  List<SkillPost> _cachedSkills = [];
  bool _hasLoadedOnce = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded, 'color': AppColors.primary},
    {'name': 'Carpenter', 'icon': Icons.carpenter_outlined, 'color': Color(0xFFFF6B6B)},
    {'name': 'Electrician', 'icon': Icons.electric_bolt, 'color': Color(0xFFFFD93D)},
    {'name': 'Plumber', 'icon': Icons.plumbing, 'color': Color(0xFF4ECDC4)},
    {'name': 'Cook', 'icon': Icons.restaurant, 'color': Color(0xFFFF6584)},
    {'name': 'Painter', 'icon': Icons.palette, 'color': Color(0xFF95E1D3)},
    {'name': 'Driver', 'icon': Icons.local_taxi, 'color': Color(0xFF6C5CE7)},
    {'name': 'Mechanic', 'icon': Icons.build, 'color': Color(0xFFFF7675)},
    {'name': 'Tutor', 'icon': Icons.school, 'color': Color(0xFF74B9FF)},
    {'name': 'Gardener', 'icon': Icons.grass, 'color': Color(0xFF55EFC4)},
    {'name': 'Tailor', 'icon': Icons.checkroom, 'color': Color(0xFFFD79A8)},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedSkills();
    _getUserLocation();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _userLocation = const LatLng(12.9716, 77.5946);
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _userLocation = const LatLng(12.9716, 77.5946);
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint('Location error: $e');
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
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedSkills')
          .get();

      setState(() {
        _savedSkillIds.addAll(snapshot.docs.map((doc) => doc.id));
      });
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

  Future<void> _makeCall(String? phoneNumber, String skillTitle) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showSnackBar('Phone number not available', AppColors.danger);
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      _showSnackBar('Cannot make call', AppColors.danger);
    }
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
    });
  }

  List<SkillPost> _filterAndSortSkills(List<SkillPost> skills) {
    var filtered = skills.where((skill) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          skill.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          skill.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'All' || skill.category == _selectedCategory;
      
      final price = skill.flatPrice ?? skill.perKmPrice ?? 0;
      final matchesPrice =
          price == 0 || (price >= _priceRange.start && price <= _priceRange.end);

      bool matchesDistance = true;
      if (_userLocation != null && !_isLoadingLocation && _maxDistance < 100) {
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

      final matchesVerified = !_showVerifiedOnly || skill.isVerified;
      final isActive = skill.status == 'active';

      return matchesSearch &&
          matchesCategory &&
          matchesPrice &&
          matchesDistance &&
          matchesVerified &&
          isActive;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'nearby':
          if (_userLocation == null) return 0;
          try {
            final distA = const Distance().as(LengthUnit.Kilometer, _userLocation!,
                LatLng(a.coordinates.latitude, a.coordinates.longitude));
            final distB = const Distance().as(LengthUnit.Kilometer, _userLocation!,
                LatLng(b.coordinates.latitude, b.coordinates.longitude));
            return distA.compareTo(distB);
          } catch (e) {
            return 0;
          }
        case 'rating':
          return b.rating.compareTo(a.rating);
        case 'price_low':
          final priceA = a.flatPrice ?? a.perKmPrice ?? 99999;
          final priceB = b.flatPrice ?? b.perKmPrice ?? 99999;
          return priceA.compareTo(priceB);
        case 'price_high':
          final priceA = a.flatPrice ?? a.perKmPrice ?? 0;
          final priceB = b.flatPrice ?? b.perKmPrice ?? 0;
          return priceB.compareTo(priceA);
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      appBar: AppBar(
        title: const Text('Discover Services'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      drawer: _buildAppDrawer(),
      body: Column(
        children: [
          _buildSearchHeader(),
          _buildCategoryChips(),
          Expanded(child: _buildSkillsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            _showLoginPrompt();
          } else {
            Navigator.pushNamed(context, '/post-skill');
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Post Service'),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        onChanged: _onSearchChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search services...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.white),
                onPressed: _showFilterSheet,
              ),
              IconButton(
                icon: const Icon(Icons.sort, color: Colors.white),
                onPressed: _showSortSheet,
              ),
            ],
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['name'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category['name'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    color: isSelected ? Colors.white : category['color'] as Color,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['name'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
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
      // CRITICAL FIX: Fetch ALL skills from ALL users
      // This query gets EVERY skill document across ALL user collections
      stream: FirebaseFirestore.instance
          .collectionGroup('skills')
          .snapshots(),
      builder: (context, snapshot) {
        // Extensive debug information
        debugPrint('=== SKILLS SCREEN DEBUG ===');
        debugPrint('Connection state: ${snapshot.connectionState}');
        debugPrint('Has data: ${snapshot.hasData}');
        debugPrint('Has error: ${snapshot.hasError}');
        
        if (snapshot.hasError) {
          debugPrint('Error details: ${snapshot.error}');
          debugPrint('Stack trace: ${snapshot.stackTrace}');
        }
        
        if (snapshot.hasData) {
          debugPrint('Total documents received: ${snapshot.data!.docs.length}');
          // Print each skill for verification
          for (var doc in snapshot.data!.docs) {
            debugPrint('  - Skill: ${doc.data()['skillTitle']} (User: ${doc.data()['userId']})');
          }
        }
        
        if (snapshot.hasError) {
          debugPrint('Error: ${snapshot.error}');
          debugPrint('Stack trace: ${snapshot.stackTrace}');
        }

        if (snapshot.connectionState == ConnectionState.waiting && !_hasLoadedOnce) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Error loading skills'),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          debugPrint('No documents found');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No services available', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Be the first to post a service!'),
              ],
            ),
          );
        }

        try {
          var skills = snapshot.data!.docs
              .map((doc) {
                try {
                  return SkillPost.fromFirestore(doc);
                } catch (e) {
                  debugPrint('Error parsing skill ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<SkillPost>()
              .toList();

          debugPrint('Total skills loaded: ${skills.length}');
          
          // Sort in-memory after fetching (no index needed)
          skills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          // Update cache
          _cachedSkills = skills;
          _hasLoadedOnce = true;

          final filteredSkills = _filterAndSortSkills(skills);
          debugPrint('Filtered skills: ${filteredSkills.length}');

          if (filteredSkills.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No results found', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedCategory = 'All';
                        _maxDistance = 50;
                        _priceRange = const RangeValues(0, 5000);
                        _showVerifiedOnly = false;
                      });
                    },
                    child: const Text('Reset Filters'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredSkills.length,
              itemBuilder: (context, index) {
                return _buildSkillCard(filteredSkills[index]);
              },
            ),
          );
        } catch (e) {
          debugPrint('Error building skills list: $e');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildSkillCard(SkillPost skill) {
    final isSaved = _savedSkillIds.contains(skill.id);
    final distance = _userLocation != null
        ? const Distance().as(
            LengthUnit.Kilometer,
            _userLocation!,
            LatLng(skill.coordinates.latitude, skill.coordinates.longitude),
          )
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: skill.imageUrls.isNotEmpty
                    ? Image.network(
                        skill.imageUrls.first,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 60),
                        ),
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 60),
                      ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    if (skill.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.verified, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Verified',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    if (skill.isAtWork) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.work, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('At Work',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    if (skill.rating > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              skill.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              ' (${skill.reviewCount})',
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _toggleSave(skill),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSaved ? Icons.favorite : Icons.favorite_border,
                          color: isSaved ? AppColors.danger : AppColors.textLight,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        skill.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        skill.priceDisplay,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  skill.description,
                  style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        skill.category,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (distance != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 12, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              '${distance.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      skill.timeAgo,
                      style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _makeCall(skill.phoneNumber, skill.title),
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EnhancedSkillDetailScreen(
                                  skillId: skill.id,
                                  userId: skill.userId,
                                ),
                              ),
                            );
                          },
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
    );
  }

  Widget _buildAppDrawer() {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  child: user?.photoURL == null
                      ? const Icon(Icons.person, size: 40, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? 'Guest User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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
              children: [
                if (user != null) ...[
                  _buildDrawerItem(
                    icon: Icons.add_circle,
                    title: 'Post New Service',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/post-skill');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.work,
                    title: 'My Services',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/my-skills');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.favorite,
                    title: 'Saved Services',
                    badge: _savedSkillIds.length > 0 ? _savedSkillIds.length.toString() : null,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SavedSkillsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.qr_code_scanner,
                    title: 'Scan QR to Rate',
                    subtitle: 'Rate a service',
                    onTap: () {
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
                    icon: Icons.rate_review,
                    title: 'My Reviews',
                    subtitle: 'View & edit reviews',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyReviewsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () async {
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                      _showSnackBar('Logged out successfully', AppColors.success);
                    },
                  ),
                ] else ...[
                  _buildDrawerItem(
                    icon: Icons.login,
                    title: 'Login',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/login');
                    },
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'CHATUR v1.0.0',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      onTap: onTap,
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Max Distance: ${_maxDistance.toInt()} km',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Slider(
              value: _maxDistance,
              min: 1,
              max: 100,
              divisions: 99,
              label: '${_maxDistance.toInt()} km',
              onChanged: (val) => setState(() => _maxDistance = val),
            ),
            const SizedBox(height: 16),
            Text(
                'Price Range: ₹${_priceRange.start.toInt()} - ₹${_priceRange.end.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
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
              title: const Text('Verified Providers Only'),
              subtitle: const Text('4.5+ rating & 10+ reviews'),
              value: _showVerifiedOnly,
              onChanged: (val) => setState(() => _showVerifiedOnly = val),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply Filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...[
              {'key': 'recent', 'label': 'Most Recent', 'icon': Icons.access_time},
              {'key': 'nearby', 'label': 'Nearest First', 'icon': Icons.location_on},
              {'key': 'rating', 'label': 'Highest Rated', 'icon': Icons.star},
              {'key': 'popular', 'label': 'Most Popular', 'icon': Icons.trending_up},
              {'key': 'price_low', 'label': 'Price: Low to High', 'icon': Icons.arrow_upward},
              {'key': 'price_high', 'label': 'Price: High to Low', 'icon': Icons.arrow_downward},
            ].map((option) {
              final isSelected = _sortBy == option['key'];
              return ListTile(
                leading: Icon(option['icon'] as IconData,
                    color: isSelected ? AppColors.primary : AppColors.textLight),
                title: Text(
                  option['label'] as String,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.text,
                  ),
                ),
                trailing:
                    isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _sortBy = option['key'] as String);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}