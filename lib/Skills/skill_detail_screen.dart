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
}

class SkillDetailScreen extends StatefulWidget {
  final Map<String, dynamic> skillData;
  final String? skillId;
  final String? userId;

  const SkillDetailScreen({
    super.key,
    required this.skillData,
    this.skillId,
    this.userId,
  });

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _providerProfile;
  final List<Map<String, dynamic>> _reviews = [];
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
      final userId = widget.userId ?? widget.skillData['userId'];

      // Fetch provider profile
      if (userId != null) {
        final profileDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('Profile')
                .doc('main')
                .get();

        if (profileDoc.exists) {
          _providerProfile = profileDoc.data();
        }
      }

      // Check if saved
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && widget.skillId != null) {
        final savedDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .collection('savedSkills')
                .doc(widget.skillId)
                .get();
        _isSaved = savedDoc.exists;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSave() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to save')));
      return;
    }

    if (widget.skillId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('savedSkills')
        .doc(widget.skillId);

    try {
      if (_isSaved) {
        await docRef.delete();
        setState(() => _isSaved = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Removed from saved')));
        }
      } else {
        await docRef.set(widget.skillData);
        setState(() => _isSaved = true);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved successfully')));
        }
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
      debugPrint('Call error: $e');
    }
  }

  Future<void> _openWhatsApp(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    final message =
        'Hi, I found your ${widget.skillData['skillTitle']} service on CHATUR. I would like to know more.';
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('WhatsApp error: $e');
    }
  }

  void _showBookingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => BookingSheet(
            skillData: widget.skillData,
            providerId: widget.userId ?? widget.skillData['userId'],
            skillId: widget.skillId,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final images = List<String>.from(widget.skillData['images'] ?? []);
    final GeoPoint? geo = widget.skillData['coordinates'];
    final availability =
        widget.skillData['availability'] as Map<String, dynamic>?;
    final profile =
        widget.skillData['profile'] as Map<String, dynamic>? ??
        _providerProfile;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Images
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: Icon(_isSaved ? Icons.favorite : Icons.favorite_border),
                color: _isSaved ? Colors.red : Colors.white,
                onPressed: _toggleSave,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // Share functionality
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background:
                  images.isNotEmpty
                      ? PageView.builder(
                        itemCount: images.length,
                        itemBuilder:
                            (context, index) => Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 80,
                                    ),
                                  ),
                            ),
                      )
                      : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 80),
                      ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price Section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.skillData['skillTitle'] ?? 'Service',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getPriceDisplay(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
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
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.skillData['category'] ?? 'General',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(widget.skillData['rating'] ?? 0.0).toStringAsFixed(1)} (${widget.skillData['reviewCount'] ?? 0} reviews)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Provider Info Card
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: NetworkImage(
                            profile?['photoUrl'] ??
                                'https://via.placeholder.com/100',
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
                                style: TextStyle(color: AppColors.textLight),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.phone,
                                color: AppColors.secondary,
                              ),
                              onPressed: () => _makeCall(profile?['phone']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat, color: Colors.green),
                              onPressed: () => _openWhatsApp(profile?['phone']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tabs
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textLight,
                      indicatorColor: AppColors.primary,
                      tabs: const [
                        Tab(text: 'About'),
                        Tab(text: 'Availability'),
                        Tab(text: 'Location'),
                      ],
                    ),
                  ),

                  // Tab Content
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAboutTab(),
                        _buildAvailabilityTab(availability),
                        _buildLocationTab(geo),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _showBookingSheet,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Book Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makeCall(profile?['phone']),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.skillData['description'] ?? 'No description available',
            style: TextStyle(fontSize: 15, color: AppColors.text, height: 1.6),
          ),
          const SizedBox(height: 24),
          const Text(
            'Service Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.category,
            'Category',
            widget.skillData['category'] ?? 'General',
          ),
          _buildInfoRow(
            Icons.location_on,
            'Service Area',
            '${(widget.skillData['serviceRadiusMeters'] ?? 5000) / 1000} km radius',
          ),
          _buildInfoRow(
            Icons.access_time,
            'Posted',
            _formatDate(widget.skillData['createdAt']),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                days
                    .map(
                      (day) => Chip(
                        label: Text(day),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Working Hours',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: AppColors.accent,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Working Hours',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$startTime - $endTime',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

  Widget _buildLocationTab(GeoPoint? geo) {
    if (geo == null || (geo.latitude == 0 && geo.longitude == 0)) {
      return const Center(child: Text('Location not specified'));
    }

    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(geo.latitude, geo.longitude),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.chatur.app',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(geo.latitude, geo.longitude),
                    color: AppColors.primary.withOpacity(0.2),
                    borderColor: AppColors.primary,
                    borderStrokeWidth: 2,
                    radius:
                        (widget.skillData['serviceRadiusMeters'] ?? 5000)
                            .toDouble(),
                    useRadiusInMeter: true,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(geo.latitude, geo.longitude),
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
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Address',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                widget.skillData['address'] ?? 'Address not specified',
                style: TextStyle(color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textLight),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: TextStyle(color: AppColors.textLight)),
          ),
        ],
      ),
    );
  }

  String _getPriceDisplay() {
    final flatPrice = widget.skillData['flatPrice'];
    final perKmPrice = widget.skillData['perKmPrice'];
    if (flatPrice != null && flatPrice > 0) return '₹$flatPrice';
    if (perKmPrice != null && perKmPrice > 0) return '₹$perKmPrice/km';
    return 'Negotiable';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    try {
      final date = (timestamp as Timestamp).toDate();
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Recently';
    }
  }
}

// Booking Sheet Widget
class BookingSheet extends StatefulWidget {
  final Map<String, dynamic> skillData;
  final String providerId;
  final String? skillId;

  const BookingSheet({
    super.key,
    required this.skillData,
    required this.providerId,
    this.skillId,
  });

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to book')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bookingId =
          FirebaseFirestore.instance.collection('bookings').doc().id;
      final bookingData = {
        'bookingId': bookingId,
        'skillId': widget.skillId,
        'providerId': widget.providerId,
        'customerId': currentUser.uid,
        'customerName': currentUser.displayName ?? 'Customer',
        'customerPhone': currentUser.phoneNumber ?? '',
        'skillTitle': widget.skillData['skillTitle'],
        'providerName': widget.skillData['profile']?['name'] ?? 'Provider',
        'providerPhone': widget.skillData['profile']?['phone'] ?? '',
        'scheduledDate': Timestamp.fromDate(_selectedDate!),
        'scheduledTime': '${_selectedTime!.hour}:${_selectedTime!.minute}',
        'notes': _notesController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'price':
            widget.skillData['flatPrice'] ?? widget.skillData['perKmPrice'],
      };

      // Create booking in provider's collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.providerId)
          .collection('bookings')
          .doc(bookingId)
          .set(bookingData);

      // Create booking in customer's collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('myBookings')
          .doc(bookingId)
          .set(bookingData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Booking request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Booking error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to book: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Book This Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.skillData['skillTitle'] ?? '',
              style: TextStyle(fontSize: 16, color: AppColors.textLight),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? DateFormat(
                            'EEEE, MMM d, yyyy',
                          ).format(_selectedDate!)
                          : 'Choose a date',
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            _selectedDate != null
                                ? AppColors.text
                                : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) setState(() => _selectedTime = time);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Choose a time',
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            _selectedTime != null
                                ? AppColors.text
                                : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Additional Notes (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Any specific requirements...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Confirm Booking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
