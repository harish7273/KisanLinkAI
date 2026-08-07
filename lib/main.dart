import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'screens/language_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/role_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'navigation/bottom_nav_screen.dart';
import 'screens/buyer_login_screen.dart';
import 'screens/buyer_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FarmDirectApp());
}

class FarmDirectApp extends StatelessWidget {
  const FarmDirectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FarmDirect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Poppins',
      ),

      // First screen
      home: const SplashScreen(),

      // Named routes
      routes: {
        '/role': (context) => const RoleScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const Placeholder(),
        '/language': (context) => const LanguageScreen(),
        '/buyer-login': (context) => const BuyerLoginScreen(),
        '/buyer-home': (context) => const BuyerHomeScreen(),
      },
    );
  }
}