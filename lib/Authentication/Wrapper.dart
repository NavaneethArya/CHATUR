import 'package:chatur_frontend/Screens/OnboardingScreen.dart';
import 'package:chatur_frontend/Screens/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class wrapper extends StatelessWidget {
  const wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return MainScreen();
        } else {
          return OnboardingScreen();
        }
      },
    );
  }
}
