import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class AppColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color secondary = Color(0xFF004E89);
  static const Color accent = Color(0xFF1A659E);
  static const Color background = Color(0xFFF7F9FC);
  static const Color text = Color(0xFF2C3E50);
  static const Color textLight = Color(0xFF95A5A6);
  static const Color success = Color(0xFF00C896);
}

class PostSkillData {
  String category = '';
  String title = '';
  String description = '';
  List<XFile> imageFiles = [];
  int? flatPrice;
  int? perKmPrice;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  List<String> availableDays = [];
  String address = '';
  GeoPoint coordinates = const GeoPoint(0, 0);
  double serviceRadiusKm = 5.0; // Default 5 km, user can adjust

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

class ImprovedPostSkillScreen extends StatefulWidget {
  const ImprovedPostSkillScreen({super.key});

  @override
  State<ImprovedPostSkillScreen> createState() => _ImprovedPostSkillScreenState();
}

class _ImprovedPostSkillScreenState extends State<ImprovedPostSkillScreen> {
  final PageController _pageController = PageController();
  final MapController _mapController = MapController();
  final PostSkillData _formData = PostSkillData();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ImagePicker _picker = ImagePicker();

  int _currentPage = 0;
  bool _isListening = false;
  bool _speechAvailable = false;
  LatLng? _currentLatLng;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Carpenter', 'icon': Icons.construction, 'color': Color(0xFFE67E22)},
    {'name': 'Electrician', 'icon': Icons.electrical_services, 'color': Color(0xFFF39C12)},
    {'name': 'Plumber', 'icon': Icons.plumbing, 'color': Color(0xFF3498DB)},
    {'name': 'Cook', 'icon': Icons.restaurant, 'color': Color(0xFFE74C3C)},
    {'name': 'Painter', 'icon': Icons.format_paint, 'color': Color(0xFF9B59B6)},
    {'name': 'Driver', 'icon': Icons.local_taxi, 'color': Color(0xFF16A085)},
    {'name': 'Mechanic', 'icon': Icons.build, 'color': Color(0xFF34495E)},
    {'name': 'Tutor', 'icon': Icons.school, 'color': Color(0xFF1ABC9C)},
    {'name': 'Gardener', 'icon': Icons.grass, 'color': Color(0xFF27AE60)},
    {'name': 'Cleaner', 'icon': Icons.cleaning_services, 'color': Color(0xFF2ECC71)},
    {'name': 'Tailor', 'icon': Icons.checkroom, 'color': Color(0xFFE91E63)},
    {'name': 'Other', 'icon': Icons.add_circle_outline, 'color': Color(0xFF95A5A6)},
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
    _titleController.dispose();
    _speech.stop();
    super.dispose();
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
      if (mounted && picked.isNotEmpty) {
        setState(() => _formData.imageFiles = picked.take(5).toList());
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'drxymvjkq';
    const uploadPreset = 'CHATUR';

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'chatur/skills'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

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
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
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
        final address = [p.street, p.locality, p.administrativeArea, p.country]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
        setState(() {
          _formData.address = address;
          _addressController.text = address;
        });
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }

    if (mounted && _mapController.mapEventStream != null) {
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
        SnackBar(
          content: const Text('⚠️ Please complete all required fields'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Publishing your service...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );

    try {
      // Upload images
      List<String> urls = [];
      for (var file in _formData.imageFiles) {
        final url = await uploadImageToCloudinary(File(file.path));
        if (url != null) urls.add(url);
      }

      final skillId = FirebaseFirestore.instance.collection('users').doc().id;

      // Get user profile
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('Profile')
          .doc('main')
          .get();

      // Create skill document with QR code data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('skills')
          .doc(skillId)
          .set({
        'skillId': skillId,
        'userId': user.uid,
        'skillTitle': _formData.title.isNotEmpty ? _formData.title : _formData.category,
        'category': _formData.category,
        'description': _formData.description,
        'flatPrice': _formData.flatPrice,
        'perKmPrice': _formData.perKmPrice,
        'images': urls,
        'address': _formData.address,
        'coordinates': _formData.coordinates,
        'serviceRadiusMeters': _formData.serviceRadiusKm * 1000,
        'availability': {
          'days': _formData.availableDays,
          'startTime': _formData.startTime?.format(context),
          'endTime': _formData.endTime?.format(context),
        },
        'profile': {
          'name': profileDoc.data()?['name'] ?? user.displayName ?? 'User',
          'phone': profileDoc.data()?['phone'] ?? user.phoneNumber ?? '',
          'photoUrl': profileDoc.data()?['photoUrl'] ?? user.photoURL ?? '',
        },
        // QR CODE DATA - This is the key part for ratings
        'qrCodeData': 'chatur://rate-skill/$user.uid/$skillId',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'isAtWork': false,
        'rating': 0.0,
        'reviewCount': 0,
        'viewCount': 0,
        'bookingCount': 0,
        'verified': false,
      });

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('✅ Service posted successfully!')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
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
          icon: Icon(_currentPage == 0 ? Icons.close : Icons.arrow_back, color: AppColors.text),
          onPressed: _currentPage == 0 ? () => Navigator.pop(context) : _previousPage,
        ),
        title: const Text('Post a Service',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 4,
                backgroundColor: Colors.grey[200],
                color: AppColors.primary,
                minHeight: 8,
              ),
            ),
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
          const Text('What service do you offer?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 8),
          Text('Choose your primary skill category',
              style: TextStyle(color: AppColors.textLight, fontSize: 16)),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _formData.category == cat['name'];
              return GestureDetector(
                onTap: () {
                  if (cat['name'] == 'Other') {
                    _showCustomCategoryDialog();
                  } else {
                    setState(() => _formData.category = cat['name'] as String);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [cat['color'] as Color, (cat['color'] as Color).withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? cat['color'] as Color : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isSelected ? cat['color'] as Color : Colors.black).withOpacity(0.1),
                        blurRadius: isSelected ? 15 : 5,
                        offset: Offset(0, isSelected ? 8 : 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat['icon'] as IconData,
                          size: 36, color: isSelected ? Colors.white : cat['color'] as Color),
                      const SizedBox(height: 8),
                      Text(cat['name'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.text)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _formData.category.isNotEmpty ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Continue →',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomCategoryDialog() async {
    final controller = TextEditingController();
    final custom = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.add_circle, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Add Custom Skill'),
            ],
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter your skill name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (custom != null && custom.isNotEmpty) {
      setState(() => _formData.category = custom);
    }
  }

  Widget _buildDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Describe your ${_formData.category} service',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            onChanged: (v) => _formData.title = v,
            decoration: InputDecoration(
              labelText: 'Service Title (Optional)',
              hintText: 'e.g., "Expert ${_formData.category}"',
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 8,
              maxLength: 500,
              onChanged: (v) => _formData.description = v,
              decoration: InputDecoration(
                hintText: 'Describe your experience, skills, and what makes you unique...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? AppColors.primary : Colors.grey),
                  onPressed: _toggleListening,
                  tooltip: 'Voice input',
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
              ),
              child: _formData.imageFiles.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 56, color: AppColors.primary),
                        const SizedBox(height: 12),
                        Text('Add Photos (up to 5)',
                            style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Tap to select from gallery',
                            style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _formData.imageFiles.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(_formData.imageFiles[index].path), fit: BoxFit.cover),
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
              onPressed: _formData.description.isNotEmpty && _formData.imageFiles.isNotEmpty ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Continue →', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          const Text('Pricing & Availability',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Service Price', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Flat Rate (₹)',
                    hintText: 'e.g., 500',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (v) => setState(() => _formData.flatPrice = int.tryParse(v)),
                ),
                const SizedBox(height: 16),
                Center(child: Text('OR', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight))),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Per KM Rate (₹)',
                    hintText: 'e.g., 50',
                    prefixIcon: const Icon(Icons.route),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (v) => setState(() => _formData.perKmPrice = int.tryParse(v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Available Days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: days.map((day) {
              final selected = _formData.availableDays.contains(day);
              return GestureDetector(
                onTap: () => setState(() {
                  selected ? _formData.availableDays.remove(day) : _formData.availableDays.add(day);
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          )
                        : null,
                    color: selected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? AppColors.primary : Colors.grey[300]!),
                  ),
                  child: Text(day,
                      style: TextStyle(
                          color: selected ? Colors.white : AppColors.text, fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Working Hours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                    if (time != null) setState(() => _formData.startTime = time);
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(_formData.startTime?.format(context) ?? 'Start Time'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
                    if (time != null) setState(() => _formData.endTime = time);
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(_formData.endTime?.format(context) ?? 'End Time'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_formData.flatPrice != null || _formData.perKmPrice != null) &&
                      _formData.availableDays.isNotEmpty &&
                      _formData.startTime != null &&
                      _formData.endTime != null
                  ? _nextPage
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Continue →', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    final center = _currentLatLng ?? const LatLng(12.9716, 77.5946);
    final radiusMeters = _formData.serviceRadiusKm * 1000;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Service Location',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 24),
          
          // Adjustable Service Radius Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.1), AppColors.accent.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Service Radius', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Text(
                        '${_formData.serviceRadiusKm.toStringAsFixed(1)} km',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('How far can you travel for service?', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                    valueIndicatorColor: AppColors.primary,
                    valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  child: Slider(
                    value: _formData.serviceRadiusKm,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${_formData.serviceRadiusKm.toStringAsFixed(1)} km',
                    onChanged: (value) {
                      setState(() => _formData.serviceRadiusKm = value);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 km', style: TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('50 km', style: TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your service will be visible to users within this radius from your location',
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Map Preview
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            clipBehavior: Clip.antiAlias,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14,
                onTap: (_, latLng) => _setLocation(latLng.latitude, latLng.longitude),
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
                        color: AppColors.primary.withOpacity(0.2),
                        borderColor: AppColors.primary,
                        borderStrokeWidth: 3,
                        useRadiusInMeter: true,
                        radius: radiusMeters,
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
                        child: const Icon(Icons.location_pin, color: AppColors.primary, size: 50),
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
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Address',
              hintText: 'Enter your service location',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
            onChanged: (v) => _formData.address = v,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _formData.isValid() ? _publishSkill : null,
              icon: const Icon(Icons.publish),
              label: const Text('Publish Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
                