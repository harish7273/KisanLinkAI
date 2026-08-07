import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';
import 'farmer_register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController mobileController =
      TextEditingController();

  final AuthService _authService = AuthService();

  bool isLoading = false;

  Future<void> login() async {
    if (mobileController.text.trim().length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter a valid mobile number"),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    await _authService.sendOTP(
      phoneNumber: mobileController.text.trim(),

      codeSent: (verificationId) {
        setState(() {
          isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              verificationId: verificationId,
              name: "",
              phone: mobileController.text.trim(),
              email: "",
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
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? "Failed to send OTP",
            ),
          ),
        );
      },
    );
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
            ),
            child: Column(
              children: [

                const SizedBox(height: 25),

                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  width: 95,
                  height: 95,
                  decoration: BoxDecoration(
                    gradient:
                        AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withOpacity(.35),
                        blurRadius: 25,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  "Welcome to",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  "VIDHAI",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  "Continue with your mobile number",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 45),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.06),
                    borderRadius:
                        BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white12,
                    ),
                  ),
                  child: Row(
                    children: [

                      Text(
                        "+91",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.white24,
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: TextField(
                          controller:
                              mobileController,
                          keyboardType:
                              TextInputType.phone,
                          maxLength: 10,
                          style:
                              GoogleFonts.poppins(
                            color: Colors.white,
                          ),
                          decoration:
                              InputDecoration(
                            counterText: "",
                            border:
                                InputBorder.none,
                            hintText:
                                "Enter Mobile Number",
                            hintStyle:
                                GoogleFonts.poppins(
                              color:
                                  Colors.white38,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                                const SizedBox(height: 25),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white10,
                    ),
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
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 58,
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
                      onPressed: isLoading ? null : login,
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
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Continue",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      "New User?",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const FarmerRegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Register",
                        style: GoogleFonts.poppins(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  "By continuing, you agree to our",
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "Terms",
                        style: GoogleFonts.poppins(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      "|",
                      style: GoogleFonts.poppins(
                        color: Colors.white38,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "Privacy Policy",
                        style: GoogleFonts.poppins(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}