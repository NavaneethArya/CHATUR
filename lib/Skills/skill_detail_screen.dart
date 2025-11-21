import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color secondary = Color(0xFF004E89);
  static const Color accent = Color(0xFF1A659E);
  static const Color background = Color(0xFFF7F9FC);
  static const Color text = Color(0xFF2C3E50);
  static const Color textLight = Color(0xFF95A5A6);
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFFFAB00);
}

class EnhancedSkillDetailScreen extends StatefulWidget {
  final String skillId;
  final String userId;

  const EnhancedSkillDetailScreen({
    super.key,
    required this.skillId,
    required this.userId,
  });

  @override
  State<EnhancedSkillDetailScreen> createState() => _EnhancedSkillDetailScreenState();
}

class _EnhancedSkillDetailScreenState extends State<EnhancedSkillDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _skillData;
  Map<String, dynamic>? _providerProfile;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Fetch skill data
      final skillDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('skills')
          .doc(widget.skillId)
          .get();

      if (!skillDoc.exists) {
        if (mounted) Navigator.pop(context);
        return;
      }

      // Fetch provider profile
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('Profile')
          .doc('main')
          .get();

      // Fetch reviews
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('skills')
          .doc(widget.skillId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      // Check if saved
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final savedDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('savedSkills')
            .doc(widget.skillId)
            .get();
        _isSaved = savedDoc.exists;
      }

      // Increment view count
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('skills')
          .doc(widget.skillId)
          .update({'viewCount': FieldValue.increment(1)});

      setState(() {
        _skillData = skillDoc.data();
        _providerProfile = profileDoc.data();
        _reviews = reviewsSnapshot.docs.map((doc) => doc.data()).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSave() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to save')),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('savedSkills')
        .doc(widget.skillId);

    try {
      if (_isSaved) {
        await docRef.delete();
        setState(() => _isSaved = false);
      } else {
        await docRef.set(_skillData!);
        setState(() => _isSaved = true);
      }
    } catch (e) {
      debugPrint('Toggle save error: $e');
    }
  }

  Future<void> _makeCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot make call')),
      );
    }
  }

  Future<void> _openWhatsApp(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanNumber.startsWith('+')) {
      cleanNumber = '+91$cleanNumber';
    }

    final message = 'Hi! I found your ${_skillData!['skillTitle']} service on CHATUR. I would like to know more about it.';
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp not installed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_skillData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Skill Not Found')),
        body: const Center(child: Text('This skill is no longer available')),
      );
    }

    final images = List<String>.from(_skillData!['images'] ?? []);
    final GeoPoint geo = _skillData!['coordinates'] ?? const GeoPoint(0, 0);
    final availability = _skillData!['availability'] as Map<String, dynamic>?;
    final profile = _skillData!['profile'] as Map<String, dynamic>? ?? _providerProfile;
    final isAtWork = _skillData!['isAtWork'] ?? false;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Images
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSaved ? Icons.favorite : Icons.favorite_border,
                    color: _isSaved ? Colors.red : Colors.white,
                  ),
                ),
                onPressed: _toggleSave,
              ),
              // IconButton(
              //   icon: const Icon(Icons.share),
              //   onPressed: () {
              //     // Share functionality
              //   },
              // ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  images.isNotEmpty
                      ? PageView.builder(
                          itemCount: images.length,
                          itemBuilder: (context, index) => Image.network(
                            images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 80),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 80),
                        ),
                  // Gradient overlay at top for app bar visibility
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Price Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _skillData!['skillTitle'] ?? 'Service',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getPriceDisplay(),
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _skillData!['category'] ?? 'General',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${(_skillData!['rating'] ?? 0.0).toStringAsFixed(1)} (${_skillData!['reviewCount'] ?? 0} reviews)',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            '${_skillData!['viewCount'] ?? 0} views',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      
                      // Work Status Indicator
                      if (isAtWork) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.work, color: AppColors.warning, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Currently at work - May not be immediately available',
                                  style: TextStyle(
                                    color: Colors.orange[900],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Provider Info Card
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 0,
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundImage: NetworkImage(
                              profile?['photoUrl'] ?? 'https://via.placeholder.com/100',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?['name'] ?? 'Service Provider',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Phone: ${profile?['phone'] ?? 'Not specified'}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.phone, color: Colors.green),
                                onPressed: () => _makeCall(profile?['phone'] ?? ''),
                              ),
                              // IconButton(
                              //   icon: const Icon(Icons.chat, color: Colors.blue),
                              //   onPressed: () => _openWhatsApp(profile?['phone'] ?? ''),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(text: 'About'),
                    Tab(text: 'Availability'),
                    Tab(text: 'Reviews'),
                  ],
                ),

                // Tab Content
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAboutTab(),
                      _buildAvailabilityTab(availability),
                      _buildReviewsTab(),
                    ],
                  ),
                ),

                // Map Section
                if (geo.latitude != 0 && geo.longitude != 0) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Service Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(geo.latitude, geo.longitude),
                              initialZoom: 14,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              ),
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: LatLng(geo.latitude, geo.longitude),
                                    color: Colors.blue.withOpacity(0.2),
                                    borderColor: Colors.blue,
                                    borderStrokeWidth: 2,
                                    radius: _skillData!['serviceRadiusMeters']?.toDouble() ?? 5000,
                                    useRadiusInMeter: true,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(geo.latitude, geo.longitude),
                                    width: 60,
                                    height: 60,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _skillData!['address'] ?? 'Location not specified',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _makeCall(profile?['phone'] ?? ''),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Expanded(
              //   child: OutlinedButton.icon(
              //     onPressed: () => _openWhatsApp(profile?['phone'] ?? ''),
              //     icon: const Icon(Icons.chat),
              //     label: const Text('Chat'),
              //     style: OutlinedButton.styleFrom(
              //       foregroundColor: Colors.green,
              //       side: const BorderSide(color: Colors.green),
              //       padding: const EdgeInsets.symmetric(vertical: 16),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _skillData!['description'] ?? 'No description available',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Service Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.category,
            'Category',
            _skillData!['category'] ?? 'General',
          ),
          _buildInfoRow(
            Icons.location_on,
            'Service Area',
            '${(_skillData!['serviceRadiusMeters'] ?? 5000) / 1000} km radius',
          ),
          _buildInfoRow(
            Icons.access_time,
            'Posted',
            _formatDate(_skillData!['createdAt']),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityTab(Map<String, dynamic>? availability) {
    if (availability == null) {
      return const Center(child: Text('Availability not specified'));
    }

    final days = List<String>.from(availability['days'] ?? []);
    final startTime = availability['startTime'] ?? 'Not specified';
    final endTime = availability['endTime'] ?? 'Not specified';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Days',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: days
                .map(
                  (day) => Chip(
                    label: Text(day),
                    backgroundColor: Colors.green[50],
                    labelStyle: TextStyle(color: Colors.green[700]),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Working Hours',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time, color: Colors.blue),
              title: Text('$startTime - $endTime'),
              subtitle: const Text('Daily working hours'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_reviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _reviews.length,
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    review['userPhoto'] ?? 'https://via.placeholder.com/50',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['userName'] ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < (review['rating'] ?? 0)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(review['createdAt']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review['comment'] ?? '',
              style: TextStyle(color: Colors.grey[800]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  String _getPriceDisplay() {
    final flatPrice = _skillData!['flatPrice'];
    final perKmPrice = _skillData!['perKmPrice'];
    if (flatPrice != null && flatPrice > 0) return '₹$flatPrice';
    if (perKmPrice != null && perKmPrice > 0) return '₹$perKmPrice/km';
    return 'Negotiable';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    try {
      final date = (timestamp as Timestamp?)?.toDate() ?? DateTime.now();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 30) return DateFormat('MMM d, yyyy').format(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return 'Just now';
    } catch (e) {
      return 'Recently';
    }
  }
}