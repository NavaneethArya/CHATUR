import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneOTPverify extends StatefulWidget {
  const PhoneOTPverify({super.key});

  @override
  State<PhoneOTPverify> createState() => _PhoneOTPverifyState();
}

class _PhoneOTPverifyState extends State<PhoneOTPverify> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  String _otp = '';
  bool _loading = false;
  late String phoneNumber;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    phoneNumber = ModalRoute.of(context)!.settings.arguments as String;
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    setState(() => _loading = true);
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        if (mounted) Navigator.pushReplacementNamed(context, '/main');
      },
      verificationFailed: (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
      },
      codeSent: (verificationId, _) {
        setState(() {
          _verificationId = verificationId;
          _loading = false;
        });
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 6 || _verificationId == null) return;

    setState(() => _loading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otp,
      );
      await _auth.signInWithCredential(credential);
      if (mounted) _showMpinDialog(); // <-- show MPIN setup after OTP
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("OTP Verification failed: $e")));
    }
    setState(() => _loading = false);
  }

  void _showMpinDialog() {
    final mpinController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text("Set Your MPIN"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: mpinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: "Enter 6-digit MPIN",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: "Confirm MPIN",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final mpin = mpinController.text.trim();
                  final confirm = confirmController.text.trim();

                  if (mpin.length != 6 || confirm.length != 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("MPIN must be exactly 6 digits"),
                      ),
                    );
                    return;
                  }

                  if (mpin != confirm) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("MPINs do not match")),
                    );
                    return;
                  }

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      throw Exception("User not signed in");
                    }

                    final uid = user.uid;

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .set({
                          'phone': user.phoneNumber ?? '',
                          'email': user.email ?? '',
                          'mpin': mpin,
                          'created_at': FieldValue.serverTimestamp(),
                        });

                    if (mounted) {
                      Navigator.pop(context); // Close dialog
                      Navigator.pushReplacementNamed(context, '/main');
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to save MPIN: $e")),
                    );
                  }
                },
                child: const Text("Next"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Enter 6-digit OTP sent to $phoneNumber"),
            TextField(
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (value) => _otp = value,
              decoration: InputDecoration(labelText: "OTP"),
            ),
            const SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: _verifyOtp, child: Text("Verify")),
            TextButton(onPressed: _sendOtp, child: Text("Resend OTP")),
          ],
        ),
      ),
    );
  }
}
