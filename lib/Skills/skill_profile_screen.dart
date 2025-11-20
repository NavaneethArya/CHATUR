import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color secondary = Color(0xFF004E89);
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFFFAB00);
  static const Color danger = Color(0xFFFF5252);
  static const Color text = Color(0xFF2C3E50);
  static const Color textLight = Color(0xFF95A5A6);
}

class SkillProfileScreen extends StatefulWidget {
  final String skillId;
  final String userId;

  const SkillProfileScreen({
    super.key,
    required this.skillId,
    required this.userId,
  });

  @override
  State<SkillProfileScreen> createState() => _SkillProfileScreenState();
}

class _SkillProfileScreenState extends State<SkillProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _skillData;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSkillData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSkillData() async {
    try {
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

      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('skills')
          .doc(widget.skillId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _skillData = skillDoc.data();
        _reviews = reviewsSnapshot.docs.map((doc) => doc.data()).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading skill: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWorkStatus() async {
    if (_skillData == null) return;
    
    final currentStatus = _skillData!['isAtWork'] ?? false;
    final newStatus = !currentStatus;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('skills')
          .doc(widget.skillId)
          .update({
        'isAtWork': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _skillData!['isAtWork'] = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? '🟡 Status: At Work' : '🟢 Status: Available'),
          backgroundColor: newStatus ? AppColors.warning : AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  void _showQRCode() {
    final qrData = 'chatur://rate-skill/${widget.userId}/${widget.skillId}';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service QR Code',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Scan to rate service',
                          style: TextStyle(fontSize: 14, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
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
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 280,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ask customers to scan this code after completing the service to receive genuine ratings',
                        style: TextStyle(fontSize: 13, color: AppColors.text.withOpacity(0.8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Share.share(
                          'Rate my ${_skillData!['skillTitle']} service on CHATUR!\n\nScan QR: $qrData',
                          subject: 'Rate My Service',
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('📸 QR Code saved to gallery')),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editSkill() async {
    final result = await Navigator.pushNamed(
      context,
      '/edit-skill',
      arguments: {
        'skillId': widget.skillId,
        'skillData': _skillData,
      },
    );

    if (result == true) {
      _loadSkillData(); // Reload data after edit
    }
  }

  Future<void> _deleteSkill() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning, color: AppColors.danger),
            SizedBox(width: 12),
            Text('Delete Skill?'),
          ],
        ),
        content: const Text(
          'This will permanently delete this skill and all associated data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('skills')
            .doc(widget.skillId)
            .delete();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Skill deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting skill: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Skill Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_skillData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Skill Not Found')),
        body: const Center(child: Text('This skill is no longer available')),
      );
    }

    final images = List<String>.from(_skillData!['images'] ?? []);
    final rating = (_skillData!['rating'] ?? 0.0).toDouble();
    final reviewCount = _skillData!['reviewCount'] ?? 0;
    final viewCount = _skillData!['viewCount'] ?? 0;
    final bookingCount = _skillData!['bookingCount'] ?? 0;
    final isAtWork = _skillData!['isAtWork'] ?? false;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _editSkill,
                tooltip: 'Edit Skill',
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_2),
                onPressed: _showQRCode,
                tooltip: 'Show QR Code',
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 20),
                        SizedBox(width: 12),
                        Text('Share'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.danger, size: 20),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteSkill();
                  } else if (value == 'share') {
                    Share.share('Check out my ${_skillData!['skillTitle']} service on CHATUR!');
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  images.isNotEmpty
                      ? Image.network(images.first, fit: BoxFit.cover)
                      : Container(color: Colors.grey[300]),
                  Container(
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
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _skillData!['skillTitle'] ?? 'Service',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _skillData!['category'] ?? 'General',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isAtWork ? AppColors.warning : AppColors.success,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isAtWork ? Icons.work : Icons.check_circle,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isAtWork ? 'At Work' : 'Available',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _showQRCode,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.qr_code_2, color: Colors.white, size: 40),
                              SizedBox(height: 4),
                              Text('QR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Work Status Toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isAtWork ? AppColors.warning : AppColors.success).withOpacity(0.1),
                          (isAtWork ? AppColors.warning : AppColors.success).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isAtWork ? AppColors.warning : AppColors.success).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isAtWork ? Icons.work : Icons.check_circle,
                          color: isAtWork ? AppColors.warning : AppColors.success,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAtWork ? 'Currently at Work' : 'Available for Work',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAtWork
                                    ? 'Customers will know you\'re busy'
                                    : 'Ready to take new work',
                                style: TextStyle(fontSize: 12, color: AppColors.textLight),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isAtWork,
                          activeColor: AppColors.warning,
                          inactiveThumbColor: AppColors.success,
                          onChanged: (_) => _toggleWorkStatus(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Stats
                  Row(
                    children: [
                      _buildStatCard(Icons.star, rating.toStringAsFixed(1), 'Rating', Colors.amber),
                      const SizedBox(width: 12),
                      _buildStatCard(Icons.rate_review, '$reviewCount', 'Reviews', Colors.blue),
                      const SizedBox(width: 12),
                      _buildStatCard(Icons.visibility, '$viewCount', 'Views', Colors.purple),
                      const SizedBox(width: 12),
                      _buildStatCard(Icons.work, '$reviewCount', 'Jobs', AppColors.success),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textLight,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'About'),
                  Tab(text: 'Reviews'),
                  Tab(text: 'Stats'),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildReviewsTab(),
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
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
          const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            _skillData!['description'] ?? 'No description available',
            style: const TextStyle(fontSize: 15, color: AppColors.text, height: 1.6),
          ),
          const SizedBox(height: 24),
          const Text('Pricing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.currency_rupee, color: AppColors.primary, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_skillData!['flatPrice'] != null)
                      Text(
                        '₹${_skillData!['flatPrice']} (Flat Rate)',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    if (_skillData!['perKmPrice'] != null)
                      Text(
                        '₹${_skillData!['perKmPrice']}/km',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Availability', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ((_skillData!['availability']?['days'] ?? []) as List).map((day) {
              return Chip(
                label: Text(day),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.secondary),
                const SizedBox(width: 12),
                Text(
                  '${_skillData!['availability']?['startTime']} - ${_skillData!['availability']?['endTime']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No reviews yet', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
            const SizedBox(height: 8),
            const Text('Share your QR code to get ratings', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showQRCode,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Show QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _reviews.length,
      separatorBuilder: (_, __) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(review['userPhoto'] ?? ''),
                  child: review['userPhoto'] == null || review['userPhoto'].isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review['userName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < (review['rating'] ?? 0) ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(review['createdAt']),
                            style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(review['comment'] ?? '', style: const TextStyle(color: AppColors.text)),
          ],
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildDetailedStatCard(
            'Total Views',
            _skillData!['viewCount'] ?? 0,
            Icons.visibility,
            Colors.purple,
            'People who viewed your skill',
          ),
          const SizedBox(height: 16),
          _buildDetailedStatCard(
            'Total Jobs',
            _skillData!['reviewCount'] ?? 0,
            Icons.work,
            AppColors.success,
            'Jobs completed (based on reviews)',
          ),
          const SizedBox(height: 16),
          _buildDetailedStatCard(
            'Average Rating',
            (_skillData!['rating'] ?? 0.0).toStringAsFixed(1),
            Icons.star,
            Colors.amber,
            'Based on ${_skillData!['reviewCount']} reviews',
          ),
          const SizedBox(height: 16),
          _buildDetailedStatCard(
            'Service Radius',
            '${(_skillData!['serviceRadiusMeters'] ?? 5000) / 1000} km',
            Icons.location_on,
            Colors.red,
            'Your service coverage area',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatCard(String title, dynamic value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textLight)),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    try {
      final date = (timestamp as Timestamp?)?.toDate() ?? DateTime.now();
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Recently';
    }
  }
}