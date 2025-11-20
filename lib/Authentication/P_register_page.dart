import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ignore: camel_case_types
class P_Registerpage extends StatefulWidget {
  const P_Registerpage({super.key});

  @override
  State<P_Registerpage> createState() => _P_RegisterpageState();
}

// ignore: camel_case_types
class _P_RegisterpageState extends State<P_Registerpage> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedState = 'Karnataka';
  bool _agree = false;

  final List<String> _states = [
    'Karnataka',
    'Tamil Nadu',
    'Kerala',
    'Maharashtra',
    'Uttar Pradesh',
    'Bihar',
    'West Bengal',
  ];

  void _navigateToOtpScreen() {
    String phone = _phoneController.text.trim();
    if (phone.startsWith("+91")) {
      phone = phone.substring(3);
    }
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid 10-digit mobile number")),
      );
      return;
    }

    Navigator.pushNamed(context, '/phoneAuth', arguments: '+91$phone');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [TextButton(onPressed: () {}, child: const Text('Skip'))],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F2FE), Color(0xFFFDFDFD), Color(0xFFFEF5F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Let's start by verifying your mobile number",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              const Text("We will send an OTP on this number for verification"),
              const SizedBox(height: 30),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Remember, this number will be used for login and recovery",
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedState,
                decoration: const InputDecoration(
                  labelText: "Select State/UT",
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedState = value!;
                  });
                },
                items:
                    _states
                        .map(
                          (state) => DropdownMenuItem(
                            value: state,
                            child: Text(state),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _agree,
                    onChanged: (value) => setState(() => _agree = value!),
                  ),
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'I agree to the terms and conditions of the ',
                        children: [
                          TextSpan(
                            text: 'CHATUR Privacy Policy',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _agree ? _navigateToOtpScreen : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                  backgroundColor: _agree ? Colors.deepOrange : Colors.grey,
                ),
                child: const Text('Register'),
              ),
              const SizedBox(height: 10),
              Center(
                child: Wrap(
                  children: [
                    const Text('Already have an account? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text(
                        'Login here',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
