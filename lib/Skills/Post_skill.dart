import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// THEME COLORS (CarSpark inspired)
class AppColors {
  static const Color primary = Color(0xFFFF6B35); // Orange
  static const Color secondary = Color(0xFF004E89); // Blue
  static const Color accent = Color(0xFF1A659E);
  static const Color background = Color(0xFFF7F9FC);
  static const Color text = Color(0xFF2C3E50);
  static const Color textLight = Color(0xFF95A5A6);
}

class PostSkillData {
  String category = '';
  String title = '';
  String description = '';
  List<XFile> imageFiles = [];
  List<String> imageUrls = [];
  int? flatPrice;
  int? perKmPrice;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  List<String> availableDays = [];
  String address = '';
  GeoPoint coordinates = const GeoPoint(0, 0);
  double serviceRadius = 5000;

  bool isValid() {
    return category.isNotEmpty &&
        description.isNotEmpty &&
        imageFiles.isNotEmpty &&
        (flatPrice != null || perKmPrice != null) &&
        availableDays.isNotEmpty &&
        startTime != null &&
        endTime != null &&
        address.isNotEmpty;
  }
}

class PostSkillScreen extends StatefulWidget {
  const PostSkillScreen({super.key});

  @override
  State<PostSkillScreen> createState() => _PostSkillScreenState();
}

class _PostSkillScreenState extends State<PostSkillScreen> {
  final PageController _pageController = PageController();
  final MapController _mapController = MapController();
  final PostSkillData _formData = PostSkillData();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ImagePicker _picker = ImagePicker();

  int _currentPage = 0;
  bool _isListening = false;
  bool _speechAvailable = false;
  LatLng? _currentLatLng;
  final double _radiusMeters = 5000;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Carpenter', 'icon': Icons.construction},
    {'name': 'Electrician', 'icon': Icons.electrical_services},
    {'name': 'Plumber', 'icon': Icons.plumbing},
    {'name': 'Cook', 'icon': Icons.restaurant},
    {'name': 'Painter', 'icon': Icons.format_paint},
    {'name': 'Driver', 'icon': Icons.local_taxi},
    {'name': 'Mechanic', 'icon': Icons.build},
    {'name': 'Tutor', 'icon': Icons.school},
    {'name': 'Other', 'icon': Icons.add_circle_outline}, // 👈 Added
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _tryFetchLocation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _onCategorySelected(String selectedCategory) async {
    if (selectedCategory == 'Other') {
      final custom = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: Text('Add Custom Skill'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'Enter your skill name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text('Add'),
              ),
            ],
          );
        },
      );

      if (custom != null && custom.isNotEmpty) {
        setState(() => _formData.category = custom);
      }
    } else {
      setState(() => _formData.category = selectedCategory);
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize();
    } catch (e) {
      _speechAvailable = false;
    }
    if (mounted) setState(() {});
  }

  void _toggleListening() async {
    if (!_speechAvailable) return;

    if (!_isListening) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _descriptionController.text = result.recognizedWords;
            _formData.description = result.recognizedWords;
          });
          if (result.finalResult) {
            _speech.stop();
            setState(() => _isListening = false);
          }
        },
      );
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 70);
      if (mounted) {
        setState(() => _formData.imageFiles = picked.take(5).toList());
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'drxymvjkq';
    const uploadPreset = 'CHATUR';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request =
        http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = uploadPreset
          ..fields['folder'] = 'chatur/skills'
          ..files.add(
            await http.MultipartFile.fromPath('file', imageFile.path),
          );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final data = json.decode(await response.stream.bytesToString());
        return data['secure_url'];
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    }
    return null;
  }

  Future<void> _tryFetchLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      await _setLocation(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _setLocation(double lat, double lon) async {
    _currentLatLng = LatLng(lat, lon);
    _formData.coordinates = GeoPoint(lat, lon);

    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final address = [
          p.street,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
        setState(() {
          _formData.address = address;
          _addressController.text = address;
        });
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }

    if (mounted) {
      _mapController.move(_currentLatLng!, 14);
      setState(() {});
    }
  }

  void _nextPage() {
    if (_pageController.hasClients) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 0 && _pageController.hasClients) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _publishSkill() async {
    if (!_formData.isValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Upload images
      List<String> urls = [];
      for (var file in _formData.imageFiles) {
        final url = await uploadImageToCloudinary(File(file.path));
        if (url != null) urls.add(url);
      }

      final skillId = FirebaseFirestore.instance.collection('users').doc().id;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('skills')
          .doc(skillId)
          .set({
            'skillId': skillId,
            'userId': user.uid,
            'skillTitle':
                _formData.title.isNotEmpty
                    ? _formData.title
                    : _formData.category,
            'category': _formData.category,
            'description': _formData.description,
            'flatPrice': _formData.flatPrice,
            'perKmPrice': _formData.perKmPrice,
            'images': urls,
            'address': _formData.address,
            'coordinates': _formData.coordinates,
            'serviceRadiusMeters': _radiusMeters,
            'availability': {
              'days': _formData.availableDays,
              'startTime': _formData.startTime?.format(context),
              'endTime': _formData.endTime?.format(context),
            },
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'active',
            'rating': 0.0,
            'reviewCount': 0,
            'viewCount': 0,
          });

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Skill posted successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _currentPage == 0 ? Icons.close : Icons.arrow_back,
            color: AppColors.text,
          ),
          onPressed:
              _currentPage == 0 ? () => Navigator.pop(context) : _previousPage,
        ),
        title: Text(
          'Post a Service',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / 4,
            backgroundColor: Colors.grey[200],
            color: AppColors.primary,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          _buildCategoryPage(),
          _buildDetailsPage(),
          _buildPricingPage(),
          _buildLocationPage(),
        ],
      ),
    );
  }

  Widget _buildCategoryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What service do you offer?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your primary skill category',
            style: TextStyle(color: AppColors.textLight, fontSize: 16),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _formData.category == cat['name'];
              return GestureDetector(
                onTap: () => _onCategorySelected(cat['name']),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat['icon'],
                        size: 40,
                        color: isSelected ? Colors.white : AppColors.secondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cat['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _formData.category.isNotEmpty ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe your ${_formData.category} service',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 8,
              onChanged: (v) => _formData.description = v,
              decoration: InputDecoration(
                hintText:
                    'Describe your experience, skills, and what makes you unique...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic_off : Icons.mic,
                    color: _isListening ? AppColors.primary : Colors.grey,
                  ),
                  onPressed: _toggleListening,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child:
                  _formData.imageFiles.isEmpty
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Add Photos (up to 5)',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                      : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: _formData.imageFiles.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_formData.imageFiles[index].path),
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  _formData.description.isNotEmpty &&
                          _formData.imageFiles.isNotEmpty
                      ? _nextPage
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingPage() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pricing & Availability',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Price',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Flat Rate (₹)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (v) => _formData.flatPrice = int.tryParse(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Available Days',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                days.map((day) {
                  final selected = _formData.availableDays.contains(day);
                  return GestureDetector(
                    onTap:
                        () => setState(() {
                          selected
                              ? _formData.availableDays.remove(day)
                              : _formData.availableDays.add(day);
                        }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        day,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Working Hours',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null)
                      setState(() => _formData.startTime = time);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _formData.startTime?.format(context) ?? 'Start Time',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) setState(() => _formData.endTime = time);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_formData.endTime?.format(context) ?? 'End Time'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  _formData.flatPrice != null &&
                          _formData.availableDays.isNotEmpty &&
                          _formData.startTime != null &&
                          _formData.endTime != null
                      ? _nextPage
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    final center = _currentLatLng ?? const LatLng(12.9716, 77.5946);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Location',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14,
                onTap:
                    (_, latLng) =>
                        _setLocation(latLng.latitude, latLng.longitude),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.chatur.app',
                ),
                if (_currentLatLng != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _currentLatLng!,
                        color: AppColors.primary.withOpacity(0.3),
                        borderColor: AppColors.primary,
                        borderStrokeWidth: 2,
                        useRadiusInMeter: true,
                        radius: _radiusMeters,
                      ),
                    ],
                  ),
                if (_currentLatLng != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLatLng!,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_pin,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _tryFetchLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Use Current Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 2,
            onChanged: (v) => _formData.address = v,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _formData.isValid() ? _publishSkill : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Publish Service',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
