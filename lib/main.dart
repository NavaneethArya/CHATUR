import 'package:chatur_frontend/Authentication/E_login_page.dart';
import 'package:chatur_frontend/Authentication/E_register_page.dart';
import 'package:chatur_frontend/Authentication/P_login_page.dart';
import 'package:chatur_frontend/Authentication/P_register_page.dart';
import 'package:chatur_frontend/Authentication/Wrapper.dart';
import 'package:chatur_frontend/Authentication/P_OTP_verify.dart';
import 'package:chatur_frontend/Screens/OnboardingScreen.dart';
import 'package:chatur_frontend/Screens/main_screen.dart';
import 'package:chatur_frontend/Screens/profile_screen.dart';
import 'package:chatur_frontend/Skills/MySkills.dart';
import 'package:chatur_frontend/Skills/Post_skill.dart';
import 'package:chatur_frontend/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      //home: EmailLoginPage(),
      initialRoute: '/wrapper',
      routes: {
        '/wrapper': (context) => wrapper(),
        '/phoneAuth': (context) => PhoneOTPverify(),
        '/OnBoarding': (context) => OnboardingScreen(),
        '/main': (context) => MainScreen(),
        '/login': (context) => P_loginpage(),
        '/register': (context) => P_Registerpage(),
        '/Elogin': (context) => E_LoginPage(),
        '/Eregister': (context) => E_RegisterPage(),
        '/editProfile': (context) => ProfileScreen(),
        '/post-skill': (context) => ImprovedPostSkillScreen(),
        '/my-skills': (context) => const MySkillsScreen(),

      },
    );
  }
}
