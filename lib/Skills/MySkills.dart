import 'package:chatur_frontend/Skills/edit_skill_screen.dart';
import 'package:chatur_frontend/Skills/skill_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color secondary = Color(0xFF004E89);
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFFFAB00);
  static const Color danger = Color(0xFFFF5252);
  static const Color text = Color(0xFF2C3E50);
  static const Color textLight = Color(0xFF95A5A6);
}

class MySkillsScreen extends StatefulWidget {
  const MySkillsScreen({super.key});  // ✅ Simple constructor, no parameters

  @override
  State<MySkillsScreen> createState() => _MySkillsScreenState();
}

class _MySkillsScreenState extends State<MySkillsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Skills')),
        body: const Center(child: Text('Please login to view your skills')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.check_circle), text: 'Active'),
            Tab(icon: Icon(Icons.pause_circle), text: 'Paused'),
            Tab(icon: Icon(Icons.archive), text: 'Archived'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSkillsList(user.uid, 'active'),
          _buildSkillsList(user.uid, 'paused'),
          _buildSkillsList(user.uid, 'archived'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/post-skill').then((_) {
            // Refresh the list after posting
            setState(() {});
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Add New Service'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildSkillsList(String userId, String status) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('skills')
          .where('status', isEqualTo: status)
          //.orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // Debug: Print connection state
        debugPrint('Connection state: ${snapshot.connectionState}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Debug: Print document count
        debugPrint('Documents found: ${snapshot.data?.docs.length ?? 0}');

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'active' ? Icons.work_off : Icons.archive,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No $status services',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  status == 'active'
                      ? 'Post your first service to get started'
                      : 'No services in this category',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                if (status == 'active') ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/post-skill').then((_) {
                        setState(() {});
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Post New Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
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
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final skillData = doc.data();
              
              // Debug: Print skill data
              debugPrint('Skill ${index + 1}: ${skillData['skillTitle']}');
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: MySkillCard(
                  skillId: doc.id,
                  userId: userId,
                  skillData: skillData,
                  onUpdate: () => setState(() {}),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class MySkillCard extends StatelessWidget {
  final String skillId;
  final String userId;
  final Map<String, dynamic> skillData;
  final VoidCallback onUpdate;

  const MySkillCard({
    super.key,
    required this.skillId,
    required this.userId,
    required this.skillData,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(skillData['images'] ?? []);
    final status = skillData['status'] ?? 'active';
    final viewCount = skillData['viewCount'] ?? 0;
    final bookingCount = skillData['bookingCount'] ?? 0;
    final rating = (skillData['rating'] ?? 0.0).toDouble();
    final isAtWork = skillData['isAtWork'] ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image & Status Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: images.isNotEmpty
                    ? Image.network(
                        images.first,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      )
                    : Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image, size: 50),
                        ),
                      ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (isAtWork)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.work, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'AT WORK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skillData['skillTitle'] ?? 'Skill',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  skillData['category'] ?? 'General',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),

                // Stats Row
                Row(
                  children: [
                    _buildStatChip(Icons.visibility, '$viewCount views'),
                    const SizedBox(width: 12),
                    _buildStatChip(Icons.work, '$bookingCount jobs'),
                    const SizedBox(width: 12),
                    _buildStatChip(Icons.star, rating.toStringAsFixed(1)),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToProfile(context),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToEdit(context),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleStatus(context),
                        icon: Icon(
                          status == 'active' ? Icons.pause : Icons.play_arrow,
                          size: 18,
                        ),
                        label: Text(status == 'active' ? 'Pause' : 'Activate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              status == 'active' ? Colors.orange : Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SkillProfileScreen(
          skillId: skillId,  // ✅ Required argument 1
          userId: userId,     // ✅ Required argument 2
        ),
      ),
    ).then((_) => onUpdate());  // Refresh list when returning
  }

  void _navigateToEdit(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditSkillScreen(
        skillId: skillId,
        userId: userId,        // ✅ Added userId
        skillData: skillData,
      ),
    ),
  ).then((result) {
    if (result == true) {
      onUpdate();
    }
  });
}

  Future<void> _toggleStatus(BuildContext context) async {
    final currentStatus = skillData['status'] ?? 'active';
    final newStatus = currentStatus == 'active' ? 'paused' : 'active';

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('skills')
          .doc(skillId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Service ${newStatus == 'active' ? 'activated' : 'paused'}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      onUpdate();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// Analytics Dashboard Widget for the top of My Skills screen
class SkillAnalyticsDashboard extends StatelessWidget {
  final String userId;

  const SkillAnalyticsDashboard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('skills')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        int totalViews = 0;
        int totalBookings = 0;
        double totalRating = 0;
        int skillCount = snapshot.data!.docs.length;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data();
          totalViews += (data['viewCount'] ?? 0) as int;
          totalBookings += (data['bookingCount'] ?? 0) as int;
          totalRating += (data['rating'] ?? 0.0) as double;
        }

        double avgRating = skillCount > 0 ? totalRating / skillCount : 0;

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Performance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.work,
                      label: 'Active Services',
                      value: '$skillCount',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.visibility,
                      label: 'Total Views',
                      value: '$totalViews',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.work_outline,
                      label: 'Jobs',
                      value: '$totalBookings',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.star,
                      label: 'Avg Rating',
                      value: avgRating.toStringAsFixed(1),
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}