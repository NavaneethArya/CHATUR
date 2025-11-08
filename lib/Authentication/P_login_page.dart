import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class P_loginpage extends StatefulWidget {
  const P_loginpage({super.key});

  @override
  State<P_loginpage> createState() => _P_loginpageState();
}

class _P_loginpageState extends State<P_loginpage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _mpinController = TextEditingController();
  bool _loading = false;

  Future<void> _loginWithMpin() async {
    final phone = _phoneController.text.trim();
    final mpin = _mpinController.text.trim();

    if (phone.length != 10 || mpin.length < 4 || mpin.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid phone number or MPIN")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc('+91$phone')
              .get();

      if (doc.exists && doc['mpin'] == mpin) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Incorrect MPIN or user not registered"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: ${e.toString()}")));
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        actions: [TextButton(onPressed: () {}, child: const Text('Skip'))],
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE6F2FE),
                  Color(0xFFFDFDFD),
                  Color(0xFFFEF5F0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
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
                    "Welcome back to your CHATUR account!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 15),
                  const Text("Mobile Number"),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Enter your Mobile Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text("MPIN"),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _mpinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter MPIN',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.visibility_off),
                        onPressed: () {},
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Forgot MPIN?'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                        onPressed: _loginWithMpin,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(45),
                          backgroundColor: Colors.deepOrange,
                        ),
                        child: const Text('Login'),
                      ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/Elogin');
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                    ),
                    child: const Text('Login with E-mail'),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Wrap(
                      children: [
                        const Text('New on CHATUR? '),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/register',
                            );
                          },
                          child: const Text(
                            'Register here',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 40),
                  const Center(child: Text('or Login/Register with')),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                    ),
                    child: const Text('GramPramukh'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'GramPramukh – A dedicated login for village coordinators and panchayat members to post official updates, health camps, and welfare activities for the local community.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                    textAlign: TextAlign.left,
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
