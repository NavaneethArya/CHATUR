import 'package:chatur_frontend/Skills/skill_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

// Enhanced Color Theme with Gradients
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

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6584), Color(0xFFFF8A80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF00E5A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Skill Model (keeping the same as original)
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
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String? get phoneNumber => profile?['phone'] as String?;
  bool get isVerified => verified || (rating >= 4.5 && reviewCount >= 10);

  Map<String, dynamic> toMap() => {
    'skillId': id,
    'skillTitle': title,
    'category': category,
    'description': description,
    'flatPrice': flatPrice,
    'perKmPrice': perKmPrice,
    'images': imageUrls,
    'address': address,
    'coordinates': coordinates,
    'serviceRadiusMeters': serviceRadiusMeters,
    'createdAt': Timestamp.fromDate(createdAt),
    'rating': rating,
    'reviewCount': reviewCount,
    'viewCount': viewCount,
    'bookingCount': bookingCount,
    'userId': userId,
    'status': status,
    'availability': availability,
    'profile': profile,
    'verified': verified,
  };
}

// Main Skills Screen with Enhanced UI
class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimController;
  late AnimationController _fabAnimController;
  late Animation<double> _headerSlideAnim;
  late Animation<double> _fabScaleAnim;

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
  bool _isSearchFocused = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'All',
      'icon': Icons.grid_view_rounded,
      'color': AppColors.primary,
    },
    {
      'name': 'Carpenter',
      'icon': Icons.carpenter_outlined,
      'color': Color(0xFFFF6B6B),
    },
    {
      'name': 'Electrician',
      'icon': Icons.electric_bolt,
      'color': Color(0xFFFFD93D),
    },
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
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _headerSlideAnim = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(
        parent: _headerAnimController,
        curve: Curves.easeOutCubic,
      ),
    );
    _fabScaleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.elasticOut),
    );

    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fabAnimController.forward();
    });

    _loadSavedSkills();
    _getUserLocation();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _fabAnimController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // Keep all the original methods (getUserLocation, loadSavedSkills, etc.)
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
        _showModernSnackBar(
          'Removed from saved',
          AppColors.warning,
          Icons.bookmark_remove,
        );
      } else {
        await docRef.set(skill.toMap());
        setState(() => _savedSkillIds.add(skill.id));
        _showModernSnackBar(
          'Saved successfully',
          AppColors.success,
          Icons.bookmark_added,
        );
      }
    } catch (e) {
      _showModernSnackBar('Error: $e', AppColors.danger, Icons.error);
    }
  }

  Future<void> _makeCall(String? phoneNumber, String skillTitle) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showModernSnackBar(
        'Phone number not available',
        AppColors.danger,
        Icons.phone_disabled,
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      _showModernSnackBar('Cannot make call', AppColors.danger, Icons.error);
    }
  }

  Future<void> _openWhatsApp(String? phoneNumber, String skillTitle) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showModernSnackBar(
        'Phone number not available',
        AppColors.danger,
        Icons.phone_disabled,
      );
      return;
    }

    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanNumber.startsWith('+')) {
      cleanNumber = '+91$cleanNumber';
    }

    final message =
        'Hi! I found your $skillTitle service on CHATUR. I would like to know more about it.';
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        _showModernSnackBar(
          'WhatsApp not installed',
          AppColors.danger,
          Icons.error,
        );
      }
    } catch (e) {
      _showModernSnackBar(
        'Cannot open WhatsApp',
        AppColors.danger,
        Icons.error,
      );
    }
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
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
              skill.category.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              skill.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );

          final matchesCategory =
              _selectedCategory == 'All' || skill.category == _selectedCategory;
          final price = skill.flatPrice ?? skill.perKmPrice ?? 0;
          final matchesPrice =
              price == 0 ||
              (price >= _priceRange.start && price <= _priceRange.end);

          bool matchesDistance = true;
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

  void _openSkillDetails(SkillPost skill) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(skill.userId)
          .collection('skills')
          .doc(skill.id)
          .update({'viewCount': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }

    if (mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => SkillDetailScreen(
                skillData: skill.toMap(),
                skillId: skill.id,
                userId: skill.userId,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
        ),
      );
    }
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
            content: const Text(
              'Please login to save skills and book services.',
            ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Login'),
              ),
            ],
          ),
    );
  }

  void _showModernSnackBar(String message, Color color, IconData icon) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(),
            _buildCategoryChips(),
            Expanded(child: _buildSkillsList()),
          ],
        ),
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildModernHeader() {
    return AnimatedBuilder(
      animation: _headerSlideAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _headerSlideAnim.value),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.miscellaneous_services_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Local Services',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildHeaderAction(
                  icon: Icons.favorite_rounded,
                  badge: _savedSkillIds.length,
                  onTap: () => Navigator.pushNamed(context, '/saved-skills'),
                ),
                const SizedBox(width: 8),
                _buildHeaderAction(
                  icon: Icons.person_rounded,
                  onTap: () => Navigator.pushNamed(context, '/my-skills'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildModernSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    int? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            badge != null && badge > 0
                ? Badge(
                  label: Text('$badge'),
                  backgroundColor: AppColors.accent,
                  child: Icon(icon, color: Colors.white, size: 22),
                )
                : Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildModernSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        onChanged: _onSearchChanged,
        onTap: () => setState(() => _isSearchFocused = true),
        onSubmitted: (_) => setState(() => _isSearchFocused = false),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search services, skills, location...',
          hintStyle: TextStyle(color: AppColors.textLight, fontSize: 15),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSearchAction(
                icon: Icons.tune_rounded,
                hasBadge:
                    _maxDistance != 50 ||
                    _priceRange != const RangeValues(0, 5000) ||
                    _showVerifiedOnly,
                onTap: _showModernFilterSheet,
              ),
              _buildSearchAction(
                icon: Icons.swap_vert_rounded,
                onTap: _showModernSortSheet,
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSearchAction({
    required IconData icon,
    bool hasBadge = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              hasBadge
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: hasBadge ? AppColors.primary : AppColors.text,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['name'];

          return TweenAnimationBuilder(
            duration: Duration(milliseconds: 300 + (index * 50)),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: GestureDetector(
              onTap:
                  () => setState(
                    () => _selectedCategory = category['name'] as String,
                  ),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isSelected ? AppColors.primary : Colors.black)
                          .withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Colors.white.withOpacity(0.2)
                                : (category['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        category['icon'] as IconData,
                        color:
                            isSelected
                                ? Colors.white
                                : category['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildModernSkeletonList();
        }

        if (snapshot.hasError) {
          return _buildModernErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildModernEmptyState(
            'No services available',
            'Be the first to post a service!',
          );
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

          final filteredSkills = _filterAndSortSkills(skills);

          if (filteredSkills.isEmpty) {
            return _buildModernEmptyState(
              'No results found',
              'Try adjusting your filters or search terms',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(seconds: 1));
            },
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: filteredSkills.length,
              itemBuilder: (context, index) {
                return TweenAnimationBuilder(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  tween: Tween<double>(begin: 0, end: 1),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: _buildModernSkillCard(filteredSkills[index]),
                );
              },
            ),
          );
        } catch (e) {
          return _buildModernErrorState('Error loading skills: $e');
        }
      },
    );
  }

  Widget _buildModernSkillCard(SkillPost skill) {
    final isSaved = _savedSkillIds.contains(skill.id);
    final distance =
        _userLocation != null
            ? const Distance().as(
              LengthUnit.Kilometer,
              _userLocation!,
              LatLng(skill.coordinates.latitude, skill.coordinates.longitude),
            )
            : null;

    return GestureDetector(
      onTap: () => _openSkillDetails(skill),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Overlays
            Stack(
              children: [
                Hero(
                  tag: 'skill_${skill.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child:
                        skill.imageUrls.isNotEmpty
                            ? Image.network(
                              skill.imageUrls.first,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 220,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey.shade200,
                                        Colors.grey.shade100,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    height: 220,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey.shade200,
                                          Colors.grey.shade100,
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                            )
                            : Container(
                              height: 220,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.1),
                                    AppColors.secondary.withOpacity(0.1),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                  ),
                ),
                // Gradient Overlay
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
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
                // Top Badges
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (skill.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.successGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (skill.rating > 0) ...[
                            if (skill.isVerified) const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    skill.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (skill.reviewCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${skill.reviewCount})',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _toggleSave(skill),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isSaved
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color:
                                isSaved
                                    ? AppColors.danger
                                    : AppColors.textLight,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom Info on Image
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              skill.category,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              skill.priceDisplay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.description,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  // Stats Row
                  Row(
                    children: [
                      _buildStatChip(
                        icon: Icons.location_on_rounded,
                        text:
                            distance != null
                                ? '${distance.toStringAsFixed(1)} km'
                                : skill.address.split(',').first,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      if (skill.bookingCount > 0)
                        _buildStatChip(
                          icon: Icons.shopping_bag_rounded,
                          text: '${skill.bookingCount}',
                          color: AppColors.success,
                        ),
                      const Spacer(),
                      Text(
                        skill.timeAgo,
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.phone_rounded,
                          label: 'Call',
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondary,
                              AppColors.secondary.withOpacity(0.7),
                            ],
                          ),
                          onTap:
                              () => _makeCall(skill.phoneNumber, skill.title),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.chat_rounded,
                          label: 'Chat',
                          gradient: AppColors.successGradient,
                          onTap:
                              () =>
                                  _openWhatsApp(skill.phoneNumber, skill.title),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.arrow_forward_rounded,
                          label: 'View',
                          gradient: AppColors.primaryGradient,
                          onTap: () => _openSkillDetails(skill),
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
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade200, Colors.grey.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
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
  }

  Widget _buildModernEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textLight, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed:
                () => setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'All';
                  _maxDistance = 50;
                  _priceRange = const RangeValues(0, 5000);
                  _showVerifiedOnly = false;
                }),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Something went wrong',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              style: TextStyle(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFAB() {
    return ScaleTransition(
      scale: _fabScaleAnim,
      child: FloatingActionButton.extended(
        onPressed: () {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            _showLoginPrompt();
          } else {
            Navigator.pushNamed(
              context,
              '/SkillPost',
            ).then((_) => setState(() {}));
          }
        },
        backgroundColor: AppColors.primary,
        elevation: 8,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_rounded, size: 20),
        ),
        label: const Text(
          'Post Service',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showModernFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ModernFilterSheet(
            maxDistance: _maxDistance,
            priceRange: _priceRange,
            showVerifiedOnly: _showVerifiedOnly,
            onApply: (distance, price, verified) {
              setState(() {
                _maxDistance = distance;
                _priceRange = price;
                _showVerifiedOnly = verified;
              });
            },
            onReset: () {
              setState(() {
                _maxDistance = 50;
                _priceRange = const RangeValues(0, 5000);
                _showVerifiedOnly = false;
              });
            },
          ),
    );
  }

  void _showModernSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.swap_vert_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...[
                  {
                    'key': 'recent',
                    'label': 'Most Recent',
                    'icon': Icons.access_time_rounded,
                  },
                  {
                    'key': 'nearby',
                    'label': 'Nearest First',
                    'icon': Icons.location_on_rounded,
                  },
                  {
                    'key': 'rating',
                    'label': 'Highest Rated',
                    'icon': Icons.star_rounded,
                  },
                  {
                    'key': 'popular',
                    'label': 'Most Popular',
                    'icon': Icons.trending_up_rounded,
                  },
                  {
                    'key': 'price_low',
                    'label': 'Price: Low to High',
                    'icon': Icons.arrow_upward_rounded,
                  },
                  {
                    'key': 'price_high',
                    'label': 'Price: High to Low',
                    'icon': Icons.arrow_downward_rounded,
                  },
                ].map((option) {
                  final isSelected = _sortBy == option['key'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _sortBy = option['key'] as String);
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.primaryGradient : null,
                        color: isSelected ? null : AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            option['icon'] as IconData,
                            color:
                                isSelected ? Colors.white : AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            option['label'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }
}

// Modern Filter Sheet
class ModernFilterSheet extends StatefulWidget {
  final double maxDistance;
  final RangeValues priceRange;
  final bool showVerifiedOnly;
  final Function(double, RangeValues, bool) onApply;
  final VoidCallback onReset;

  const ModernFilterSheet({
    super.key,
    required this.maxDistance,
    required this.priceRange,
    required this.showVerifiedOnly,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<ModernFilterSheet> createState() => _ModernFilterSheetState();
}

class _ModernFilterSheetState extends State<ModernFilterSheet> {
  late double _maxDistance;
  late RangeValues _priceRange;
  late bool _showVerifiedOnly;

  @override
  void initState() {
    super.initState();
    _maxDistance = widget.maxDistance;
    _priceRange = widget.priceRange;
    _showVerifiedOnly = widget.showVerifiedOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder:
            (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          widget.onReset();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildFilterSection(
                    title: 'Max Distance',
                    subtitle: '${_maxDistance.toInt()} km away',
                    child: Slider(
                      value: _maxDistance,
                      min: 1,
                      max: 100,
                      divisions: 99,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.primary.withOpacity(0.2),
                      onChanged: (val) => setState(() => _maxDistance = val),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildFilterSection(
                    title: 'Price Range',
                    subtitle:
                        '₹${_priceRange.start.toInt()} - ₹${_priceRange.end.toInt()}',
                    child: RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 10000,
                      divisions: 100,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.primary.withOpacity(0.2),
                      onChanged: (val) => setState(() => _priceRange = val),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient:
                          _showVerifiedOnly ? AppColors.successGradient : null,
                      color: _showVerifiedOnly ? null : AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color:
                              _showVerifiedOnly
                                  ? Colors.white
                                  : AppColors.success,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Providers',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      _showVerifiedOnly
                                          ? Colors.white
                                          : AppColors.text,
                                ),
                              ),
                              Text(
                                '4.5+ stars & 10+ reviews',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      _showVerifiedOnly
                                          ? Colors.white70
                                          : AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _showVerifiedOnly,
                          activeColor: Colors.white,
                          activeTrackColor: Colors.white.withOpacity(0.5),
                          inactiveThumbColor: AppColors.success,
                          inactiveTrackColor: AppColors.success.withOpacity(
                            0.3,
                          ),
                          onChanged:
                              (val) => setState(() => _showVerifiedOnly = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(
                          _maxDistance,
                          _priceRange,
                          _showVerifiedOnly,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                subtitle,
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
        child,
      ],
    );
  }
}
