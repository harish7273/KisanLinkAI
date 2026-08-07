import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/farmer_bottom_nav.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;

  final String name;
  final String phone;
  final String email;

  final String gender;
  final String dob;

  final String farmName;
  final String state;
  final String district;
  final String village;

  final String crop;
  final String farmSize;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.name,
    required this.phone,
    required this.email,
    required this.gender,
    required this.dob,
    required this.farmName,
    required this.state,
    required this.district,
    required this.village,
    required this.crop,
    required this.farmSize,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController =
      TextEditingController();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService =
      FirestoreService();

  bool isLoading = false;

  Future<void> verifyOtp() async {
    if (otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid OTP"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final User? firebaseUser =
          await _authService.verifyOTP(
        verificationId: widget.verificationId,
        otp: otpController.text.trim(),
      );

      if (firebaseUser == null) {
        throw FirebaseAuthException(
          code: "login-failed",
          message: "Unable to verify OTP",
        );
      }

      final user = UserModel(
  uid: firebaseUser.uid,
  role: "farmer",

  name: widget.name,
  phone: widget.phone,
  email: widget.email,

  gender: widget.gender,
  dob: widget.dob,

  state: widget.state,
  district: widget.district,
  village: widget.village,

  farmName: widget.farmName,

  primaryCrop: widget.crop,
  farmSize: widget.farmSize,

  createdAt: Timestamp.now(),
);

      await _firestoreService.saveUser(user);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const FarmerBottomNav(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? "OTP Verification Failed",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  height: 90,
                  width: 90,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sms_rounded,
                    color: Colors.white,
                    size: 45,
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  "Verify OTP",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Enter the OTP sent to +91 ${widget.phone}",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 40),

                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 12,
                  ),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "------",
                    hintStyle: const TextStyle(
                      color: Colors.white24,
                      letterSpacing: 12,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: AppColors.secondary,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.lock_outline,
                      color: Colors.greenAccent,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Your OTP is securely verified by Firebase",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ElevatedButton(
                      onPressed:
                          isLoading ? null : verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Verify OTP",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Resend OTP",
                    style: GoogleFonts.poppins(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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