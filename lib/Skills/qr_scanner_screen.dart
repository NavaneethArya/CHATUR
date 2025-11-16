import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color secondary = Color(0xFF004E89);
  static const Color success = Color(0xFF00C896);
  static const Color text = Color(0xFF2C3E50);
  static const Color textLight = Color(0xFF95A5A6);
}

// QR Scanner Screen
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late final MobileScannerController cameraController;
  bool _isProcessing = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      autoStart: true,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.startsWith('chatur://rate-skill/')) {
        _isProcessing = true;
        _hasScanned = true;
        cameraController.stop();
        _handleQRCode(code);
        break;
      }
    }
  }

  void _handleQRCode(String qrData) {
    try {
      // Parse: chatur://rate-skill/{userId}/{skillId}
      final uri = Uri.parse(qrData);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length >= 2) {
        final userId = pathSegments[0];
        final skillId = pathSegments[1];

        if (userId.isNotEmpty && skillId.isNotEmpty) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        RateSkillScreen(userId: userId, skillId: skillId),
              ),
            );
          }
          return;
        }
      }

      // If parsing fails, show error
      _showError('Invalid QR code format');
    } catch (e) {
      debugPrint('Error parsing QR code: $e');
      _showError('Invalid QR code');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _isProcessing = false;
                _hasScanned = false;
              });
              cameraController.start();
            },
          ),
        ),
      );
      setState(() {
        _isProcessing = false;
        _hasScanned = false;
      });
      // Restart camera after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_hasScanned) {
          cameraController.start();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan QR Code'),
        actions: [
          ValueListenableBuilder(
            valueListenable: cameraController,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                  color: Colors.white,
                ),
                onPressed: () => cameraController.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _onDetect),
          // Scanning frame overlay
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Corner indicators
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.primary, width: 4),
                          left: BorderSide(color: AppColors.primary, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.primary, width: 4),
                          right: BorderSide(color: AppColors.primary, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.primary,
                            width: 4,
                          ),
                          left: BorderSide(color: AppColors.primary, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.primary,
                            width: 4,
                          ),
                          right: BorderSide(color: AppColors.primary, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 40,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Scan Service QR Code',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Align the QR code within the frame to rate the service',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Rating Screen
class RateSkillScreen extends StatefulWidget {
  final String userId;
  final String skillId;

  const RateSkillScreen({
    super.key,
    required this.userId,
    required this.skillId,
  });

  @override
  State<RateSkillScreen> createState() => _RateSkillScreenState();
}

class _RateSkillScreenState extends State<RateSkillScreen> {
  Map<String, dynamic>? _skillData;
  bool _isLoading = true;
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSkillData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSkillData() async {
    try {
      final skillDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('skills')
              .doc(widget.skillId)
              .get();

      if (!skillDoc.exists) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Skill not found')));
        }
        return;
      }

      setState(() {
        _skillData = skillDoc.data();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading skill: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to rate')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reviewId =
          FirebaseFirestore.instance.collection('reviews').doc().id;

      // Add review to skill's reviews subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('skills')
          .doc(widget.skillId)
          .collection('reviews')
          .doc(reviewId)
          .set({
            'reviewId': reviewId,
            'userId': currentUser.uid,
            'userName': currentUser.displayName ?? 'User',
            'userPhoto': currentUser.photoURL ?? '',
            'rating': _rating,
            'comment': _commentController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Update skill's overall rating
      final skillRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('skills')
          .doc(widget.skillId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final skillDoc = await transaction.get(skillRef);
        final currentRating = (skillDoc.data()?['rating'] ?? 0.0).toDouble();
        final reviewCount = (skillDoc.data()?['reviewCount'] ?? 0) as int;

        final newReviewCount = reviewCount + 1;
        final newRating =
            ((currentRating * reviewCount) + _rating) / newReviewCount;

        transaction.update(skillRef, {
          'rating': newRating,
          'reviewCount': newReviewCount,
        });
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✅ Thank you for your rating!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rate Service')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_skillData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service Not Found')),
        body: const Center(child: Text('This service is no longer available')),
      );
    }

    final images = List<String>.from(_skillData!['images'] ?? []);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Rate Service',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Service Info Card
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  if (images.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        images.first,
                        height: 180,
                        width: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _skillData!['skillTitle'] ?? 'Service',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _skillData!['category'] ?? 'General',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Rating Section
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'How was your experience?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => _rating = index + 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            size: 50,
                            color:
                                index < _rating
                                    ? Colors.amber
                                    : Colors.grey[300],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRatingText(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          _rating > 0 ? AppColors.primary : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _commentController,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Share your experience (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
              ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.send),
                              SizedBox(width: 12),
                              Text(
                                'Submit Rating',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }
}
