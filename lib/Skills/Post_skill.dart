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
  // Dark Blue to Purple Gradient Theme
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFF8B5CF6); // Purple
  static const Color accent = Color(0xFF7C3AED); // Violet
  static const Color tertiary = Color(0xFFFF6B6B); // Soft Red-Orange
  static const Color darkBlue = Color(0xFF1E293B); // Dark Blue
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color text = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
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
  double serviceRadiusKm = 5.0;

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
  State<ImprovedPostSkillScreen> createState() =>
      _ImprovedPostSkillScreenState();
}

class _ImprovedPostSkillScreenState extends State<ImprovedPostSkillScreen>
    with TickerProviderStateMixin {
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
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Carpenter',
      'icon': Icons.construction,
      'color': Color(0xFFD84315),
    }, // Deep Orange
    {
      'name': 'Electrician',
      'icon': Icons.electrical_services,
      'color': Color(0xFFFDD835),
    }, // Bright Yellow
    {
      'name': 'Plumber',
      'icon': Icons.plumbing,
      'color': Color(0xFF1976D2),
    }, // Deep Blue
    {
      'name': 'Cook',
      'icon': Icons.restaurant,
      'color': Color(0xFFD32F2F),
    }, // Red
    {
      'name': 'Painter',
      'icon': Icons.format_paint,
      'color': Color(0xFF7B1FA2),
    }, // Deep Purple
    {
      'name': 'Driver',
      'icon': Icons.local_taxi,
      'color': Color(0xFF00796B),
    }, // Teal
    {
      'name': 'Mechanic',
      'icon': Icons.build,
      'color': Color(0xFF455A64),
    }, // Blue Grey
    {'name': 'Tutor', 'icon': Icons.school, 'color': Color(0xFF0097A7)}, // Cyan
    {
      'name': 'Gardener',
      'icon': Icons.grass,
      'color': Color(0xFF388E3C),
    }, // Green
    {
      'name': 'Cleaner',
      'icon': Icons.cleaning_services,
      'color': Color(0xFFAFB42B),
    }, // Lime
    {
      'name': 'Tailor',
      'icon': Icons.checkroom,
      'color': Color(0xFFC2185B),
    }, // Pink
    {
      'name': 'Other',
      'icon': Icons.add_circle_outline,
      'color': Color(0xFF5D4037),
    }, // Brown
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _tryFetchLocation();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _titleController.dispose();
    _speech.stop();
    _fadeController.dispose();
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

    if (mounted && _mapController.mapEventStream != null) {
      _mapController.move(_currentLatLng!, 14);
      setState(() {});
    }
  }

  void _nextPage() {
    if (_pageController.hasClients) {
      _fadeController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
      _fadeController.forward();
    }
  }

  void _previousPage() {
    if (_currentPage > 0 && _pageController.hasClients) {
      _fadeController.reset();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
      _fadeController.forward();
    }
  }

  bool _validateTimeRange() {
    if (_formData.startTime == null || _formData.endTime == null) return true;

    final start = _formData.startTime!.hour * 60 + _formData.startTime!.minute;
    final end = _formData.endTime!.hour * 60 + _formData.endTime!.minute;

    return start < end;
  }

  Future<void> _publishSkill() async {
    if (!_formData.isValid()) {
      _showSnackBar('⚠️ Please complete all required fields', AppColors.error);
      return;
    }

    if (!_validateTimeRange()) {
      _showSnackBar('⚠️ End time must be after start time', AppColors.error);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _showLoadingDialog();

    try {
      List<String> urls = [];
      for (var file in _formData.imageFiles) {
        final url = await uploadImageToCloudinary(File(file.path));
        if (url != null) urls.add(url);
      }

      final skillId = FirebaseFirestore.instance.collection('users').doc().id;

      final profileDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('Profile')
              .doc('main')
              .get();

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
            'qrCodeData': 'chatur://rate-skill/${user.uid}/$skillId',
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
        _showSnackBar('✅ Service posted successfully!', AppColors.success);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Error: $e', AppColors.error);
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Publishing your service...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _currentPage == 0 ? Icons.close : Icons.arrow_back,
              color: AppColors.darkBlue,
              size: 20,
            ),
          ),
          onPressed:
              _currentPage == 0 ? () => Navigator.pop(context) : _previousPage,
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'Post a Service',
            style: TextStyle(
              color: AppColors.darkBlue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12),
          child: Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Colors.white.withOpacity(0.3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 4,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: PageView(
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
        ),
      ),
    );
  }

  Widget _buildCategoryPage() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                        AppColors.accent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What service do you offer?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your primary skill category',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                        HapticFeedback.lightImpact();
                        if (cat['name'] == 'Other') {
                          _showCustomCategoryDialog();
                        } else {
                          setState(
                            () => _formData.category = cat['name'] as String,
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient:
                              isSelected
                                  ? LinearGradient(
                                    colors: [
                                      cat['color'] as Color,
                                      (cat['color'] as Color).withOpacity(0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                  : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isSelected
                                    ? cat['color'] as Color
                                    : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isSelected
                                      ? cat['color'] as Color
                                      : Colors.black)
                                  .withOpacity(0.1),
                              blurRadius: isSelected ? 15 : 5,
                              offset: Offset(0, isSelected ? 8 : 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              size: 36,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : cat['color'] as Color,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cat['name'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    isSelected ? Colors.white : AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: _buildContinueButton(
              onPressed: _formData.category.isNotEmpty ? _nextPage : null,
              label: 'Continue',
            ),
          ),
        ),
      ],
    );
  }

  void _showCustomCategoryDialog() async {
    final controller = TextEditingController();
    final custom = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Add Custom Skill', style: TextStyle(fontSize: 20)),
            ],
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter your skill name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Add',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Describe your ${_formData.category} service',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),
              _buildModernTextField(
                controller: _titleController,
                label: 'Service Title (Optional)',
                hint: 'e.g., "Expert ${_formData.category}"',
                icon: Icons.title,
                onChanged: (v) => _formData.title = v,
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 8,
                  maxLength: 500,
                  onChanged: (v) => _formData.description = v,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText:
                        'Describe your experience, skills, and what makes you unique...',
                    hintStyle: TextStyle(
                      color: AppColors.textLight.withOpacity(0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(20),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient:
                            _isListening
                                ? LinearGradient(
                                  colors: [
                                    AppColors.tertiary,
                                    AppColors.primary,
                                  ],
                                )
                                : null,
                        color: _isListening ? null : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color:
                              _isListening ? Colors.white : AppColors.textLight,
                        ),
                        onPressed: _toggleListening,
                        tooltip: 'Voice input',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient:
                        _formData.imageFiles.isEmpty
                            ? LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.1),
                                AppColors.secondary.withOpacity(0.1),
                              ],
                            )
                            : null,
                    color: _formData.imageFiles.isEmpty ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child:
                      _formData.imageFiles.isEmpty
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Add Photos (up to 5)',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to select from gallery',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                          : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: _formData.imageFiles.length,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      File(_formData.imageFiles[index].path),
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              _formData.imageFiles.removeAt(
                                                index,
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
              ),
              const SizedBox(height: 32),
              _buildContinueButton(
                onPressed:
                    _formData.description.isNotEmpty &&
                            _formData.imageFiles.isNotEmpty
                        ? _nextPage
                        : null,
                label: 'Continue',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingPage() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pricing & Availability',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.currency_rupee,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Service Price',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildModernTextField(
                      label: 'Flat Rate (₹)',
                      hint: 'e.g., 500',
                      icon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      onChanged:
                          (v) => setState(
                            () => _formData.flatPrice = int.tryParse(v),
                          ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.accent, AppColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'OR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      label: 'Per KM Rate (₹)',
                      hint: 'e.g., 50',
                      icon: Icons.route,
                      keyboardType: TextInputType.number,
                      onChanged:
                          (v) => setState(
                            () => _formData.perKmPrice = int.tryParse(v),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Available Days',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    days.map((day) {
                      final selected = _formData.availableDays.contains(day);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            selected
                                ? _formData.availableDays.remove(day)
                                : _formData.availableDays.add(day);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient:
                                selected
                                    ? LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.accent,
                                      ],
                                    )
                                    : null,
                            color: selected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  selected
                                      ? Colors.transparent
                                      : AppColors.primary.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow:
                                selected
                                    ? [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(
                                          0.4,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Text(
                            day,
                            style: TextStyle(
                              color: selected ? Colors.white : AppColors.text,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.secondary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Working Hours',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeButton(
                      label:
                          _formData.startTime?.format(context) ?? 'Start Time',
                      icon: Icons.wb_sunny_outlined,
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 9, minute: 0),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (time != null) {
                          setState(() => _formData.startTime = time);
                          if (_formData.endTime != null &&
                              !_validateTimeRange()) {
                            _showSnackBar(
                              '⚠️ Start time must be before end time',
                              AppColors.error,
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeButton(
                      label: _formData.endTime?.format(context) ?? 'End Time',
                      icon: Icons.nightlight_outlined,
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 18, minute: 0),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (time != null) {
                          setState(() => _formData.endTime = time);
                          if (_formData.startTime != null &&
                              !_validateTimeRange()) {
                            _showSnackBar(
                              '⚠️ End time must be after start time',
                              AppColors.error,
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (_formData.startTime != null &&
                  _formData.endTime != null &&
                  !_validateTimeRange())
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'End time must be after start time',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              _buildContinueButton(
                onPressed:
                    (_formData.flatPrice != null ||
                                _formData.perKmPrice != null) &&
                            _formData.availableDays.isNotEmpty &&
                            _formData.startTime != null &&
                            _formData.endTime != null &&
                            _validateTimeRange()
                        ? _nextPage
                        : null,
                label: 'Continue',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPage() {
    final center = _currentLatLng ?? const LatLng(12.9716, 77.5946);
    final radiusMeters = _formData.serviceRadiusKm * 1000;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Service Location',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.accent.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.radar,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Service Radius',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.tertiary, AppColors.primary],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            '${_formData.serviceRadiusKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'How far can you travel for service?',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                        thumbColor: Colors.white,
                        overlayColor: AppColors.primary.withOpacity(0.2),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 14,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 28,
                        ),
                        valueIndicatorColor: AppColors.primary,
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        trackHeight: 6,
                      ),
                      child: Slider(
                        value: _formData.serviceRadiusKm,
                        min: 1,
                        max: 50,
                        divisions: 49,
                        label:
                            '${_formData.serviceRadiusKm.toStringAsFixed(1)} km',
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          setState(() => _formData.serviceRadiusKm = value);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1 km',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '50 km',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your service will be visible to users within this radius',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
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
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                            child: const Icon(
                              Icons.location_pin,
                              color: AppColors.tertiary,
                              size: 50,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.secondary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _tryFetchLocation,
                  icon: const Icon(Icons.my_location, size: 22),
                  label: const Text(
                    'Use Current Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _addressController,
                label: 'Address',
                hint: 'Enter your service location',
                icon: Icons.location_on,
                maxLines: 3,
                onChanged: (v) => _formData.address = v,
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  gradient:
                      _formData.isValid() && _validateTimeRange()
                          ? const LinearGradient(
                            colors: [AppColors.success, Color(0xFF059669)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                          : null,
                  color:
                      !(_formData.isValid() && _validateTimeRange())
                          ? Colors.grey[300]
                          : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow:
                      _formData.isValid() && _validateTimeRange()
                          ? [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ]
                          : [],
                ),
                child: ElevatedButton(
                  onPressed:
                      _formData.isValid() && _validateTimeRange()
                          ? _publishSkill
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.rocket_launch_rounded, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Publish Service',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    TextEditingController? controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters:
            keyboardType == TextInputType.number
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textLight.withOpacity(0.5)),
          labelStyle: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.secondary.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 2),
        ),
      ),
    );
  }

  Widget _buildContinueButton({
    required VoidCallback? onPressed,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient:
            onPressed != null
                ? const LinearGradient(
                  colors: [
                    Color(0xFFFF6B35), // Orange-Red
                    Color(0xFFFF8C42), // Orange
                    Color(0xFFFFA726), // Light Orange-Yellow
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
                : null,
        color: onPressed == null ? Colors.grey[300] : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            onPressed != null
                ? [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
                : [],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 24),
          ],
        ),
      ),
    );
  }
}
