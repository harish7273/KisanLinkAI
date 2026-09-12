import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../navigation/bottom_nav_screen.dart';
import 'otp_screen.dart';
import 'farmer_register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isOtpMode = false;

  @override
  void dispose() {
    mobileController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // PASSWORD LOGIN
  // ============================================================
  Future<void> _loginWithPassword() async {
    final String mobile = mobileController.text.trim();
    final String password = passwordController.text;

    if (mobile.length != 10) {
      _showSnackBar("Please enter a valid 10-digit mobile number", isError: true);
      return;
    }

    if (password.isEmpty) {
      _showSnackBar("Please enter your password", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final String loginEmail = "$mobile@kisanai.app";

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const BottomNavScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = "Login failed. Please try again.";
      if (e.code == 'user-not-found') {
        message = "Account not found for this mobile number. Please register first.";
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = "Incorrect password or mobile number. Please verify.";
      } else {
        message = e.message ?? "Login failed.";
      }

      _showSnackBar(message, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Error: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ============================================================
  // OTP LOGIN
  // ============================================================
  Future<void> _sendOTP() async {
    final String mobile = mobileController.text.trim();

    if (mobile.length != 10) {
      _showSnackBar("Please enter a valid 10-digit mobile number", isError: true);
      return;
    }

    setState(() => isLoading = true);

    await _authService.sendOTP(
      phoneNumber: mobile,
      codeSent: (verificationId) {
        if (!mounted) return;
        setState(() => isLoading = false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              verificationId: verificationId,
              name: "",
              phone: mobile,
              email: "$mobile@kisanai.app",
              gender: "",
              dob: "",
              farmName: "",
              state: "",
              district: "",
              village: "",
              crop: "",
              farmSize: "",
            ),
          ),
        );
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => isLoading = false);

        final msg = e.message ?? "";
        if (msg.contains("BILLING_NOT_ENABLED") ||
            msg.contains("blocked") ||
            e.code == "too-many-requests") {
          _showBillingDialog(mobile);
        } else {
          _showSnackBar(e.message ?? "Failed to send OTP", isError: true);
        }
      },
    );
  }

  // ============================================================
  // DEMO / GUEST LOGIN
  // ============================================================
  Future<void> _quickDemoLogin() async {
    setState(() => isLoading = true);
    try {
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (_) {
        // Continue even if anonymous auth is disabled
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const BottomNavScreen(),
        ),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showBillingDialog(String mobile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF293A2E)),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.secondary),
            const SizedBox(width: 10),
            Text(
              "SMS Not Available",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          "Firebase Phone SMS requires Google Cloud Billing. You can sign in immediately using your password, or enter test OTP (123456).",
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => isOtpMode = false);
            },
            child: Text(
              "Use Password",
              style: GoogleFonts.poppins(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtpScreen(
                    verificationId: "mock-verification-id",
                    name: "Farmer",
                    phone: mobile,
                    email: "$mobile@kisanai.app",
                    gender: "",
                    dob: "",
                    farmName: "",
                    state: "",
                    district: "",
                    village: "",
                    crop: "",
                    farmSize: "",
                  ),
                ),
              );
            },
            child: Text(
              "Test OTP (123456)",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: isError ? const Color(0xFFB71C1C) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Official Kisan AI Logo
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.6),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      "assets/images/kisan_logo.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Text(
                  "Welcome to",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "KisanAI",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 38,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  isOtpMode
                      ? "Continue with your mobile number"
                      : "Login to your farmer account",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 25),

                // Mode Selector Toggle (Password / OTP)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isOtpMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isOtpMode
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Password Login",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: !isOtpMode
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isOtpMode = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isOtpMode
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "OTP Login",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: isOtpMode
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Mobile Number Field
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "+91",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        width: 1,
                        height: 26,
                        color: Colors.white24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: mobileController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                            counterText: "",
                            border: InputBorder.none,
                            hintText: "Enter Mobile Number",
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.white38,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Password Field (visible only in Password mode)
                if (!isOtpMode) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 1,
                          height: 26,
                          color: Colors.white24,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: passwordController,
                            obscureText: !isPasswordVisible,
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter Password",
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.white38,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                // OTP Notice (visible only in OTP mode)
                if (isOtpMode) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sms_outlined,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "We'll send a 6-digit verification code to this mobile number.",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // Main Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : (isOtpMode ? _sendOTP : _loginWithPassword),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isOtpMode ? "Send OTP" : "Login",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "New User?",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FarmerRegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Register",
                        style: GoogleFonts.poppins(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                // Demo Guest Login Option
                TextButton.icon(
                  onPressed: isLoading ? null : _quickDemoLogin,
                  icon: const Icon(
                    Icons.play_circle_outline_rounded,
                    color: Colors.white54,
                    size: 18,
                  ),
                  label: Text(
                    "Quick Demo / Explore without login",
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Terms & Privacy
                Text(
                  "By continuing, you agree to our",
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Terms",
                      style: GoogleFonts.poppins(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "|",
                        style: GoogleFonts.poppins(color: Colors.white38),
                      ),
                    ),
                    Text(
                      "Privacy Policy",
                      style: GoogleFonts.poppins(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
