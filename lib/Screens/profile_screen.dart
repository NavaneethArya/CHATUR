//profile screen
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final bool autoEdit;
  
  const ProfileScreen({super.key, this.autoEdit = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _editing = false;
  bool _loading = true;
  String? _photoUrl;

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _districtController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedGender;
  String? _selectedState;

  final List<String> _states = [
    'Karnataka',
    'Tamil Nadu',
    'Kerala',
    'Maharashtra',
    'Uttar Pradesh',
    'Bihar',
    'West Bengal',
  ];

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // Auto-enable editing if autoEdit is true
    if (widget.autoEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _editing = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _districtController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
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

      final data = doc.data();

      setState(() {
        _nameController.text = data?['name'] ?? '';
        final genderValue = data?['gender'] as String?;
        _selectedGender = _genders.contains(genderValue) ? genderValue : null;
        _dobController.text = data?['dob'] ?? '';
        final stateValue = data?['state'] as String?;
        _selectedState = _states.contains(stateValue) ? stateValue : null;
        _districtController.text = data?['district'] ?? '';
        _phoneController.text =
            data?['phone'] ??
            FirebaseAuth.instance.currentUser?.phoneNumber ??
            '';
        _emailController.text =
            data?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
        _photoUrl = data?['photoUrl'] ?? '';
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final profileData = {
        'name': _nameController.text.trim(),
        'gender': _selectedGender ?? '',
        'dob': _dobController.text.trim(),
        'state': _selectedState ?? '',
        'district': _districtController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'photoUrl': _photoUrl ?? '',
        'updated_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Profile')
          .doc('main')
          .set(profileData, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context); // Remove loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _editing = false);

      // Reload profile to ensure data is synced
      await _loadProfile();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Remove loading dialog

      debugPrint("Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
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
      } else {
        debugPrint("Cloudinary upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Cloudinary upload error: $e");
      return null;
    }
  }

  Future<void> _pickAndUploadImage() async {
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
    final imageUrl = await uploadImageToCloudinary(imageFile);

    if (!mounted) return;
    Navigator.pop(context); // Remove loading

    if (imageUrl != null) {
      setState(() => _photoUrl = imageUrl);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('Profile')
            .doc('main')
            .set({'photoUrl': imageUrl}, SetOptions(merge: true));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image upload failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/wrapper', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              if (_editing) {
                _saveProfile();
              } else {
                setState(() => _editing = true);
              }
            },
            child: Text(
              _editing ? 'Save' : 'Edit',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: _editing ? _pickAndUploadImage : null,
              child: Stack(
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
                  if (_editing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.deepOrange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Name', _nameController),
              _buildDropdown('Gender', _genders, _selectedGender, (val) {
                setState(() => _selectedGender = val);
              }),
              _buildDateField(),
              _buildDropdown('State', _states, _selectedState, (val) {
                setState(() => _selectedState = val);
              }),
              _buildTextField('District', _districtController),
              _buildTextField('Phone Number', _phoneController),
              _buildTextField('Email', _emailController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: _editing,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: !_editing,
          fillColor: !_editing ? Colors.grey[100] : Colors.white,
        ),
        validator: (val) {
          if (_editing && (val == null || val.trim().isEmpty)) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        items:
            items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
        onChanged: _editing ? onChanged : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: !_editing,
          fillColor: !_editing ? Colors.grey[100] : Colors.white,
        ),
        validator: (val) {
          if (_editing && (val == null || val.isEmpty)) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _dobController,
        readOnly: true,
        onTap: _editing ? _pickDOB : null,
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
          filled: !_editing,
          fillColor: !_editing ? Colors.grey[100] : Colors.white,
        ),
        validator: (val) {
          if (_editing && (val == null || val.isEmpty)) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }
}