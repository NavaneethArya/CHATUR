// profile_icon.dart
import 'dart:convert';
import 'dart:io';
import 'package:chatur_frontend/Chatbot/chatbot.dart';
import 'package:chatur_frontend/Documents/document.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:chatur_frontend/Skills/Post_skill.dart';
import 'package:chatur_frontend/Other/support.dart'; // Add this line

class ProfileIcon extends StatefulWidget {
  const ProfileIcon({super.key});

  @override
  State<ProfileIcon> createState() => _ProfileIconState();
}

class _ProfileIconState extends State<ProfileIcon> {
  bool _loading = true;
  String? _photoUrl;
  String? _name;
  String? _phone;
  String? _email;
  String? _district;
  String? _state;
  final bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('Profile')
              .doc('main')
              .get();

      if (doc.exists) {
        final data = doc.data();
        debugPrint('Profile data loaded: $data');

        setState(() {
          _name = data?['name'] ?? 'User';
          _phone =
              data?['phone'] ??
              FirebaseAuth.instance.currentUser?.phoneNumber ??
              '';
          _email =
              data?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
          _district = data?['district'] ?? '';
          _state = data?['state'] ?? '';
          _photoUrl = data?['photoUrl'] ?? '';
          _loading = false;
        });

        debugPrint('Email loaded: $_email');
      } else {
        // If document doesn't exist, create it with Firebase Auth data
        final user = FirebaseAuth.instance.currentUser;
        setState(() {
          _name = user?.displayName ?? 'User';
          _phone = user?.phoneNumber ?? '';
          _email = user?.email ?? '';
          _loading = false;
        });

        // Save initial data to Firestore
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('Profile')
              .doc('main')
              .set({
                'name': user.displayName ?? 'User',
                'phone': user.phoneNumber ?? '',
                'email': user.email ?? '',
                'photoUrl': user.photoURL ?? '',
                'created_at': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _loading = false);
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'drxymvjkq';
    const uploadPreset = 'CHATUR';
    const folder = 'chatur/images';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    try {
      final request =
          http.MultipartRequest('POST', url)
            ..fields['upload_preset'] = uploadPreset
            ..fields['folder'] = folder
            ..files.add(
              await http.MultipartFile.fromPath('file', imageFile.path),
            );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        return data['secure_url'];
      }
    } catch (e) {
      debugPrint("Cloudinary upload error: $e");
    }
    return null;
  }

  Future<void> _changeProfilePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final imageFile = File(picked.path);
    final imageUrl = await _uploadImageToCloudinary(imageFile);

    if (!mounted) return;
    Navigator.pop(context); // Remove loading

    if (imageUrl != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('Profile')
            .doc('main')
            .set({'photoUrl': imageUrl}, SetOptions(merge: true));

        setState(() => _photoUrl = imageUrl);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  // Reload profile when returning from edit screen
  Future<void> _navigateToEditProfile() async {
    await Navigator.pushNamed(context, '/editProfile');
    // Reload profile after returning from edit screen
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // Profile Header with Photo
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.deepOrange,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.deepOrange, Colors.orange],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              _photoUrl != null && _photoUrl!.isNotEmpty
                                  ? NetworkImage(_photoUrl!)
                                  : null,
                          child:
                              _photoUrl == null || _photoUrl!.isEmpty
                                  ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.deepOrange,
                                  )
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _changeProfilePhoto,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _phone ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Profile Info Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Location Info Card
                  if (_district != null && _district!.isNotEmpty)
                    const SizedBox(height: 8),

                  // Email Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.email, color: Colors.deepOrange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _email != null && _email!.isNotEmpty
                                      ? _email!
                                      : 'No email provided',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.deepOrange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_district, $_state',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Edit Profile Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _navigateToEditProfile,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Menu Items
                  _buildSectionTitle('Quick Actions'),
                  _buildMenuCard(
                    Icons.handyman,
                    'Post Your Skill',
                    'Share your expertise with the community',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const ImprovedPostSkillScreen(),
                          ),
                        ),
                  ),
                  _buildMenuCard(
                    Icons.chat_bubble,
                    'CHATUR Chatbot',
                    'Get information about government schemes',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChaturChatbot(),
                          ),
                        ),
                  ),

                  const SizedBox(height: 24),

                  _buildSectionTitle('Support & Information'),

                  _buildMenuCard(
                    Icons.help_outline,
                    'Help & Support',
                    'Get assistance and documentation',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const SupportScreen(isAboutPage: false),
                          ),
                        ),
                  ),
                  _buildMenuCard(
                    Icons.info_outline,
                    'About CHATUR',
                    'Learn more about the app',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const SupportScreen(isAboutPage: true),
                          ),
                        ),
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    IconData icon,
    String title,
    String subtitle, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.deepOrange, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing:
            trailing ??
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}
