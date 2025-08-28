import 'package:chatur_frontend/initial_pages/OnboardingScreen.dart';
import 'package:flutter/material.dart';
import 'package:chatur_frontend/initial_pages/SplashScreen.dart'; // Import the new SplashScreen

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => const Text("Login Screen"),
      },
    );
  }
}