import 'package:chatur_frontend/Authentication/g_auth_service.dart';
import 'package:chatur_frontend/components/square_tile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class E_LoginPage extends StatefulWidget {
  const E_LoginPage({super.key});

  @override
  State<E_LoginPage> createState() => _E_LoginPageState();
}

class _E_LoginPageState extends State<E_LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool isLoading = false;

  void googleSignIn() async {
    setState(() => isLoading = true);
    final userCred = await AuthService().signInWithGoogle();
    if (userCred != null) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Google Sign-in failed')));
    }
    setState(() => isLoading = false);
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Navigator.pushReplacementNamed(context, '/main');
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
                "Welcome back to your CHATUR account!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 15),
              const Text("Email ID"),
              const SizedBox(height: 15),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Password"),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Forgot Password?"),
                ),
              ),
              const SizedBox(height: 10),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                      backgroundColor: Colors.deepOrange,
                    ),
                    child: const Text("Login"),
                  ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                ),
                child: const Text('Login with Phone Number'),
              ),
              const SizedBox(height: 16),
              Center(
                child: Wrap(
                  children: [
                    const Text('New on CHATUR? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/Eregister');
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SquareTile(
                    onTap: googleSignIn,
                    imagePath: 'assets/images/google.png',
                  ),
                  const SizedBox(width: 25),
                  SquareTile(imagePath: 'assets/images/apple.png'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
