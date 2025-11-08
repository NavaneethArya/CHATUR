import 'dart:io';
import 'package:chatur_frontend/Events/models/event_model.dart';
import 'package:chatur_frontend/Events/services/cloudinary_service.dart';
import 'package:chatur_frontend/Events/services/event_firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEventWithLocationPage extends StatefulWidget {
  final Map<String, dynamic>? panchayatData;
  final EventModel? existingEvent;

  const AddEventWithLocationPage({
    super.key,
    this.panchayatData,
    this.existingEvent,
  });

  @override
  _AddEventWithLocationPageState createState() =>
      _AddEventWithLocationPageState();
}

class _AddEventWithLocationPageState extends State<AddEventWithLocationPage>
    with SingleTickerProviderStateMixin {
  final _headingController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationNameController = TextEditingController();

  DateTime? _selectedDate;
  File? _selectedImage;
  GeoPoint? _selectedLocation;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Load existing event data if editing
    if (widget.existingEvent != null) {
      _headingController.text = widget.existingEvent!.heading;
      _descriptionController.text = widget.existingEvent!.description;
      _selectedDate = widget.existingEvent!.eventDate;
      _dateController.text = DateFormat('MMM dd, yyyy').format(_selectedDate!);
      _selectedLocation = widget.existingEvent!.location;
      _locationNameController.text = widget.existingEvent!.locationName ?? '';
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _captureImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Add Event Photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                    ),
                    _buildImageSourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _captureImage();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 140,
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat(
          'MMM dd, yyyy',
        ).format(_selectedDate!);
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (_) => LocationPickerScreen(initialLocation: _selectedLocation),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result['location'] as GeoPoint;
        _locationNameController.text = result['name'] as String;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_headingController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedDate == null) {
      _showSnackBar(
        'Please fill all required fields',
        Colors.orange[700]!,
        Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl = widget.existingEvent?.imageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        imageUrl = await CloudinaryService.uploadImage(_selectedImage!);
        if (imageUrl == null) {
          _showSnackBar(
            'Failed to upload image',
            Colors.red[700]!,
            Icons.error_outline,
          );
          setState(() => _isUploading = false);
          return;
        }
      }

      // Get panchayat member info
      final memberName =
          widget.panchayatData?['name'] ??
          widget.existingEvent?.createdBy ??
          FirebaseAuth.instance.currentUser?.displayName ??
          'Panchayat Member';
      final memberEmail =
          widget.panchayatData?['email'] ??
          widget.existingEvent?.createdByEmail ??
          FirebaseAuth.instance.currentUser?.email ??
          'admin@chatur.com';

      final event = EventModel(
        id: widget.existingEvent?.id ?? '',
        heading: _headingController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        createdBy: memberName,
        createdByEmail: memberEmail,
        eventDate: _selectedDate!,
        location: _selectedLocation, // Can be null
        locationName:
            _locationNameController.text.trim().isEmpty
                ? null
                : _locationNameController.text.trim(),
        createdAt: widget.existingEvent?.createdAt ?? DateTime.now(),
        likes: widget.existingEvent?.likes ?? 0,
        likedBy: widget.existingEvent?.likedBy ?? [],
        comments: widget.existingEvent?.comments ?? [],
      );

      if (widget.existingEvent != null) {
        // Update existing event
        await EventFirebaseService.updateEvent(
          widget.existingEvent!.eventDate,
          widget.existingEvent!.id,
          event.toFirestore(),
        );
        _showSnackBar(
          'Event updated successfully!',
          Colors.green[700]!,
          Icons.check_circle,
        );
      } else {
        // Add new event
        await EventFirebaseService.addEvent(event);
        _showSnackBar(
          'Event created successfully!',
          Colors.green[700]!,
          Icons.check_circle,
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      print('Error saving event: $e');
      _showSnackBar(
        'Failed to save event: $e',
        Colors.red[700]!,
        Icons.error_outline,
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _headingController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _locationNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.existingEvent != null ? "Update Event" : "Create Event",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepPurple,
                      Colors.deepPurple[300]!,
                      Colors.purple[200]!,
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(),
                    SizedBox(height: 24),
                    _buildFormSection(),
                    SizedBox(height: 30),
                    _buildSaveButton(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedImage != null || widget.existingEvent?.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  _selectedImage != null
                      ? Image.file(
                        _selectedImage!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                      : Image.network(
                        widget.existingEvent!.imageUrl!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.red[400],
                      borderRadius: BorderRadius.circular(30),
                      child: InkWell(
                        onTap: () => setState(() => _selectedImage = null),
                        borderRadius: BorderRadius.circular(30),
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          InkWell(
            onTap: _showImageSourceDialog,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
              top:
                  _selectedImage != null ||
                          widget.existingEvent?.imageUrl != null
                      ? Radius.zero
                      : Radius.circular(20),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedImage != null ||
                              widget.existingEvent?.imageUrl != null
                          ? Icons.edit_rounded
                          : Icons.add_photo_alternate_rounded,
                      color: Colors.deepPurple,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    _selectedImage != null ||
                            widget.existingEvent?.imageUrl != null
                        ? 'Change Image'
                        : 'Add Event Image',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextField(
            controller: _headingController,
            label: 'Event Title',
            icon: Icons.title_rounded,
            hint: 'Enter event title...',
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            icon: Icons.description_rounded,
            hint: 'Describe your event...',
            maxLines: 4,
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _dateController,
            label: 'Event Date',
            icon: Icons.calendar_today_rounded,
            hint: 'Select date',
            readOnly: true,
            onTap: _pickDate,
            suffixIcon: Icon(
              Icons.arrow_drop_down_rounded,
              color: Colors.deepPurple,
            ),
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _locationNameController,
            label: 'Location Name (Optional)',
            icon: Icons.location_on_rounded,
            hint: 'e.g., Village Community Hall',
          ),
          SizedBox(height: 12),
          _buildLocationPicker(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.deepPurple, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPicker() {
    return InkWell(
      onTap: _pickLocation,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              _selectedLocation != null
                  ? Colors.deepPurple.withOpacity(0.1)
                  : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _selectedLocation != null
                    ? Colors.deepPurple
                    : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _selectedLocation != null
                  ? Icons.check_circle
                  : Icons.map_rounded,
              color:
                  _selectedLocation != null
                      ? Colors.deepPurple
                      : Colors.grey[600],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedLocation != null
                    ? 'Location selected on map'
                    : 'Pick location on map (Optional)',
                style: TextStyle(
                  fontSize: 15,
                  color:
                      _selectedLocation != null
                          ? Colors.deepPurple
                          : Colors.grey[600],
                  fontWeight:
                      _selectedLocation != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purple[400]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.4),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isUploading ? null : _saveEvent,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child:
                _isUploading
                    ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.existingEvent != null
                              ? Icons.update_rounded
                              : Icons.save_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          widget.existingEvent != null
                              ? "Update Event"
                              : "Create Event",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// LOCATION PICKER SCREEN (FIXED)
// ============================================

class LocationPickerScreen extends StatefulWidget {
  final GeoPoint? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  LatLng _currentCenter = LatLng(12.9716, 77.5946); // Default: Bangalore
  bool _isLoadingLocation = false;
  final _locationNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _currentCenter = _selectedLocation!;
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Please enable location services');
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permission permanently denied');
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _selectedLocation = _currentCenter;
      });

      _mapController.move(_currentCenter, 15.0);
    } catch (e) {
      _showSnackBar('Failed to get location: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _confirmLocation() {
    if (_selectedLocation == null) {
      _showSnackBar('Please select a location on the map');
      return;
    }

    if (_locationNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter a location name');
      return;
    }

    Navigator.pop(context, {
      'location': GeoPoint(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      ),
      'name': _locationNameController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Event Location'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Get current location',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.chatur.app',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Loading indicator
          if (_isLoadingLocation)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Bottom sheet with location name input
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _locationNameController,
                      decoration: InputDecoration(
                        labelText: 'Location Name',
                        hintText: 'e.g., Village Community Hall',
                        prefixIcon: Icon(
                          Icons.location_on,
                          color: Colors.deepPurple,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.deepPurple,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_selectedLocation != null)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                                'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Confirm Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Tap anywhere on the map to select location',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    super.dispose();
  }
}
