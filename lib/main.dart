import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/language_service.dart';

// ============================================================
// SCREENS
// ============================================================

import 'screens/language_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/role_screen.dart';
import 'screens/login_screen.dart';

// ============================================================
// FARMER NAVIGATION
// ============================================================

import 'navigation/bottom_nav_screen.dart';

// ============================================================
// FARMER PROFILE
// ============================================================

import 'screens/farmer_profile_screen.dart';

// ============================================================
// BUYER
// ============================================================

import 'screens/buyer_login_screen.dart';
import 'screens/buyer_registration_screen.dart';
import 'screens/buyer_home_screen.dart';

// ============================================================
// DELIVERY PARTNER
// ============================================================

import 'screens/delivery/delivery_login_screen.dart';
import 'screens/delivery/delivery_home_screen.dart';

// ============================================================
// OTHER
// ============================================================

import 'screens/ui_showcase_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/kisan_voice_screen.dart';
import 'screens/quality_scanner_screen.dart';
import 'screens/kisan_pool_screen.dart';
import 'screens/offline_sync_screen.dart';

import 'package:flutter/foundation.dart';

// ============================================================
// MAIN
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================================================
  // FIREBASE INITIALIZATION
  // ==========================================================

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ==========================================================
  // APP CHECK (DISABLED IN DEBUG TO AVOID ERRORS)
  // ==========================================================

  if (!kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );
  }

  // ==========================================================
  // NOTIFICATIONS INITIALIZATION
  // ==========================================================

  await NotificationService.initialize();
  await LanguageService.instance.initialize();

  runApp(
    const FarmDirectApp(),
  );
}

// ============================================================
// ROOT APPLICATION
// ============================================================

class FarmDirectApp extends StatelessWidget {
  const FarmDirectApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLocaleNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          locale: Locale(locale),
          title: 'KisanAI',

          debugShowCheckedModeBanner: false,

      // ========================================================
      // THEME
      // ========================================================

      theme: ThemeData(
        primarySwatch: Colors.green,

        scaffoldBackgroundColor:
            const Color(0xFF121212),

        fontFamily: 'Poppins',

        useMaterial3: true,

        appBarTheme: const AppBarTheme(
          backgroundColor:
              Color(0xFF080A09),

          foregroundColor:
              Colors.white,

          elevation: 0,
        ),
      ),

      // ========================================================
      // FIRST SCREEN
      // ========================================================

      home: const SplashScreen(),

      // ========================================================
      // ROUTES
      // ========================================================

      routes: {
        // ======================================================
        // LANGUAGE
        // ======================================================

        '/language': (context) {
          return const LanguageScreen();
        },

        // ======================================================
        // ROLE
        // ======================================================

        '/role': (context) {
          return const RoleScreen();
        },

        // ======================================================
        // FARMER LOGIN
        // ======================================================

        '/login': (context) {
          return const LoginScreen();
        },

        // ======================================================
        // FARMER HOME
        // ======================================================

        '/farmer-home': (context) {
          return const BottomNavScreen();
        },

        // ======================================================
        // FARMER HOME ALIAS
        // ======================================================

        '/home': (context) {
          return const BottomNavScreen();
        },

        // ======================================================
        // FARMER BOTTOM NAVIGATION
        // ======================================================

        '/bottom-nav': (context) {
          return const BottomNavScreen();
        },

        // ======================================================
        // FARMER PROFILE
        //
        // Profile is NOT in bottom navigation.
        // It is opened from the farmer HomeScreen.
        // ======================================================

        '/farmer-profile': (context) {
          return const FarmerProfileScreen();
        },

        // ======================================================
        // BUYER LOGIN
        // ======================================================

        '/buyer-login': (context) {
          return const BuyerLoginScreen();
        },

        // ======================================================
        // BUYER REGISTRATION
        // ======================================================

        '/buyer-register': (context) {
          return const BuyerRegistrationScreen();
        },

        // ======================================================
        // BUYER HOME
        // ======================================================

        '/buyer-home': (context) {
          return const BuyerHomeScreen();
        },

        // ======================================================
        // UI SHOWCASE
        // ======================================================

        '/showcase': (context) {
          return const UiShowcaseScreen();
        },

        // ======================================================
        // ADD PRODUCT
        // ======================================================

        '/add-crop': (context) {
          return const AddProductScreen();
        },

        // ======================================================
        // DELIVERY PARTNER
        // ======================================================

        '/delivery-login': (context) {
          return const DeliveryLoginScreen();
        },

        '/delivery-home': (context) {
          return const DeliveryHomeScreen();
        },

        // ======================================================
        // KISAN AI ROUTES
        // ======================================================

        '/kisan-voice': (context) {
          return const KisanVoiceScreen();
        },

        '/quality-scanner': (context) {
          return const QualityScannerScreen();
        },

        '/kisan-pool': (context) {
          return const KisanPoolScreen();
        },

        '/offline-sync': (context) {
          return const OfflineSyncScreen();
        },
      },
    );
      },
    );
  }
}