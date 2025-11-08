// add_event.dart - Enhanced UI/UX
import 'dart:io';
import 'package:chatur_frontend/Events/services/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'screens/event_store.dart';

class AddEventPage extends StatefulWidget {
  final Event? event;
  final DateTime? initialDate;

  const AddEventPage({super.key, this.event, this.initialDate});

  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage>
    with SingleTickerProviderStateMixin {
  final _headingController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _selectedDate;
  File? _selectedImage;
  bool _isUploading = false;
  Event? _originalEvent;

  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    if (widget.event != null) {
      _originalEvent = widget.event;
      _headingController.text = _originalEvent!.heading;
      _descriptionController.text = _originalEvent!.description;
      _selectedDate = widget.initialDate;
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    } else if (widget.initialDate != null) {
      _selectedDate = widget.initialDate;
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
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
      firstDate: DateTime(2000),
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

  Future<void> _saveEvent() async {
    if (_headingController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text("Please fill all required fields")),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await CloudinaryService.uploadImage(_selectedImage!);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text("Failed to upload image")),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() => _isUploading = false);
        return;
      }
    }

    if (_originalEvent != null) {
      EventStore.instance.deleteEvent(widget.initialDate!, _originalEvent!);
    }

    final newEvent = Event(
      heading: _headingController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: imageUrl ?? _originalEvent?.imageUrl,
    );
    EventStore.instance.addEvent(_selectedDate!, newEvent);

    setState(() => _isUploading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("Event saved successfully!"),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    await EventStore.instance.loadEventsFromFirebase(_selectedDate!);

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _headingController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.event != null ? "Update Event" : "Create Event",
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

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      _buildImageSection(),
                      SizedBox(height: 24),

                      // Form Fields
                      _buildFormSection(),
                      SizedBox(height: 30),

                      // Save Button
                      _buildSaveButton(),
                      SizedBox(height: 20),
                    ],
                  ),
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
          if (_selectedImage != null || _originalEvent?.imageUrl != null)
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
                        _originalEvent!.imageUrl!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                  // Overlay gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Delete button
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

          // Add Image Button
          InkWell(
            onTap: _showImageSourceDialog,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
              top:
                  _selectedImage != null || _originalEvent?.imageUrl != null
                      ? Radius.zero
                      : Radius.circular(20),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                  top:
                      _selectedImage != null || _originalEvent?.imageUrl != null
                          ? Radius.zero
                          : Radius.circular(20),
                ),
              ),
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
                      _selectedImage != null || _originalEvent?.imageUrl != null
                          ? Icons.edit_rounded
                          : Icons.add_photo_alternate_rounded,
                      color: Colors.deepPurple,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    _selectedImage != null || _originalEvent?.imageUrl != null
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
            hint: 'Enter a catchy title...',
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
                          widget.event != null
                              ? Icons.update_rounded
                              : Icons.save_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          widget.event != null ? "Update Event" : "Save Event",
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
