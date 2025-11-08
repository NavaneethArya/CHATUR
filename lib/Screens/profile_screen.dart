import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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
    'Karnataka', 'Tamil Nadu', 'Kerala', 'Maharashtra',
    'Uttar Pradesh', 'Bihar', 'West Bengal',
  ];

  final List<String> _genders = ['Male', 'Female', 'Other'];

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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Profile')
          .doc('main')
          .get();

      final data = doc.data();

      _nameController.text = data?['name'] ?? '';
      final genderValue = data?['gender'] as String?;
      _selectedGender = _genders.contains(genderValue) ? genderValue : null;
      _dobController.text = data?['dob'] ?? '';
      final stateValue = data?['state'] as String?;
      _selectedState = _states.contains(stateValue) ? stateValue : null;
      _districtController.text = data?['district'] ?? '';
      _phoneController.text = data?['phone'] ?? FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
      _emailController.text = data?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
      _photoUrl = data?['photoUrl'] ?? '';
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Profile')
          .doc('main')
          .set({
        'name': _nameController.text.trim(),
        'gender': _selectedGender ?? '',
        'dob': _dobController.text.trim(),
        'state': _selectedState ?? '',
        'district': _districtController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'photoUrl': _photoUrl ?? '',
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );

      setState(() => _editing = false);
    } catch (e) {
      debugPrint("Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile: $e")),
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
    const cloudName = 'drxymvjkq'; // Cloudinary cloud name
    const uploadPreset = 'CHATUR'; // unsigned preset
    const folder = 'chatur/images'; // optional folder

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      return data['secure_url'];
    } else {
      print("Cloudinary upload failed: ${response.statusCode}");
      return null;
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final imageFile = File(picked.path);
    final imageUrl = await uploadImageToCloudinary(imageFile);

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
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image upload failed')),
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
    // Show only a full-screen loader until profile is ready
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  return Scaffold(
    appBar: AppBar(
      title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: false,
      actions: [
        TextButton(
          onPressed: () {
            if (_editing) {
              _saveProfile();
            } else {
              setState(() => _editing = true);
            }
          },
          child: Text(_editing ? 'Save' : 'Edit', style: const TextStyle(color: Colors.black)),
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
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.deepOrange,
              backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                  ? NetworkImage(_photoUrl!)
                  : null,
              child: _photoUrl == null || _photoUrl!.isEmpty
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
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


  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: _editing,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (val) => _editing && val!.trim().isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: _editing ? onChanged : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (val) => _editing && (val == null || val.isEmpty) ? 'Required' : null,
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
        decoration: const InputDecoration(
          labelText: 'Date of Birth',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        validator: (val) => _editing && (val == null || val.isEmpty) ? 'Required' : null,
      ),
    );
  }
}
