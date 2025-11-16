import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color secondary = Color(0xFF004E89);
  static const Color text = Color(0xFF2C3E50);
  static const Color textLight = Color(0xFF95A5A6);
}

class EditSkillScreen extends StatefulWidget {
  final String skillId;
  final Map<String, dynamic> skillData;

  const EditSkillScreen({
    super.key,
    required this.skillId,
    required this.skillData, required String userId,
  });

  @override
  State<EditSkillScreen> createState() => _EditSkillScreenState();
}

class _EditSkillScreenState extends State<EditSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();

  List<String> _existingImages = [];
  List<XFile> _newImages = [];
  List<String> _availableDays = [];
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadSkillData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadSkillData() {
    _titleController.text = widget.skillData['skillTitle'] ?? '';
    _descriptionController.text = widget.skillData['description'] ?? '';
    _priceController.text = (widget.skillData['flatPrice'] ?? '').toString();
    _addressController.text = widget.skillData['address'] ?? '';
    
    _existingImages = List<String>.from(widget.skillData['images'] ?? []);
    
    final availability = widget.skillData['availability'] as Map<String, dynamic>?;
    if (availability != null) {
      _availableDays = List<String>.from(availability['days'] ?? []);
      
      if (availability['startTime'] != null) {
        final parts = availability['startTime'].toString().split(':');
        if (parts.length >= 2) {
          _startTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 9,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
      
      if (availability['endTime'] != null) {
        final parts = availability['endTime'].toString().split(':');
        if (parts.length >= 2) {
          _endTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 18,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
    }
  }

  bool _isTimeRangeValid() {
    if (_startTime == null || _endTime == null) return false;
    final startMinutes = (_startTime!.hour * 60) + _startTime!.minute;
    final endMinutes = (_endTime!.hour * 60) + _endTime!.minute;
    return endMinutes > startMinutes;
  }

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 70);
      if (picked.isNotEmpty && mounted) {
        setState(() {
          _newImages.addAll(picked);
          // Limit total images to 5
          final totalImages = _existingImages.length + _newImages.length;
          if (totalImages > 5) {
            _newImages = _newImages.take(5 - _existingImages.length).toList();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maximum 5 images allowed')),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<String?> _uploadImage(File imageFile) async {
    const cloudName = 'drxymvjkq';
    const uploadPreset = 'CHATUR';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_existingImages.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    if (_availableDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select available days')),
      );
      return;
    }

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set working hours')),
      );
      return;
    }

    if (!_isTimeRangeValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // Upload new images
      List<String> newImageUrls = [];
      for (var imageFile in _newImages) {
        final url = await _uploadImage(File(imageFile.path));
        if (url != null) {
          newImageUrls.add(url);
        }
      }

      // Combine existing and new images
      final allImages = [..._existingImages, ...newImageUrls];

      final updatedData = {
        'skillTitle': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'flatPrice': int.tryParse(_priceController.text.trim()),
        'address': _addressController.text.trim(),
        'images': allImages,
        'availability': {
          'days': _availableDays,
          'startTime': _startTime?.format(context),
          'endTime': _endTime?.format(context),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('skills')
          .doc(widget.skillId)
          .update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Skill updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Skill'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Service Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Describe your service...',
                  counterText: '',
                ),
                maxLines: 6,
                maxLength: 500,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 20) {
                    return 'Please enter at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if ((int.tryParse(value) ?? 0) <= 0) {
                    return 'Price must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
                maxLength: 200,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Images Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Images',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_existingImages.length + _newImages.length}/5',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Existing images
                    ..._existingImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final url = entry.value;
                      return _buildImageCard(
                        child: Image.network(url, fit: BoxFit.cover),
                        onRemove: () => _removeExistingImage(index),
                      );
                    }),
                    // New images
                    ..._newImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      return _buildImageCard(
                        child: Image.file(File(file.path), fit: BoxFit.cover),
                        onRemove: () => _removeNewImage(index),
                      );
                    }),
                    // Add button
                    if (_existingImages.length + _newImages.length < 5)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, 
                                size: 40, 
                                color: AppColors.primary),
                              const SizedBox(height: 8),
                              Text(
                                'Add Image',
                                style: TextStyle(color: AppColors.textLight),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Max 5',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              )
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Available Days
              const Text(
                'Available Days',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _weekDays.map((day) {
                  final isSelected = _availableDays.contains(day);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _availableDays.remove(day);
                        } else {
                          _availableDays.add(day);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey[300]!,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        day,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Working Hours
              const Text(
                'Working Hours',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _startTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => _startTime = time);
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _startTime?.format(context) ?? 'Start Time',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _endTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => _endTime = time);
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _endTime?.format(context) ?? 'End Time',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              if (_startTime != null && _endTime != null && !_isTimeRangeValid())
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: const [
                      Icon(Icons.error_outline, color: Colors.red, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'End time must be later than start time',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard({
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}