import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FarmerRegisterScreen extends StatefulWidget {
  const FarmerRegisterScreen({super.key});

  @override
  State<FarmerRegisterScreen> createState() =>
      _FarmerRegisterScreenState();
}

class _FarmerRegisterScreenState
    extends State<FarmerRegisterScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  final TextEditingController villageController =
      TextEditingController();

  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String? selectedCrop;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color pageBackground =
      Color(0xFF06100A);

  static const Color cardColor =
      Color(0xFF0C1810);

  static const Color inputColor =
      Color(0xFF111E15);

  static const Color sectionColor =
      Color(0xFF0F1C13);

  static const Color primaryGreen =
      Color(0xFF24983F);

  static const Color buttonGreen =
      Color(0xFF269B3D);

  static const Color brightGreen =
      Color(0xFF50D269);

  static const Color whiteText =
      Color(0xFFF5F8F5);

  static const Color secondaryText =
      Color(0xFF9AA59D);

  static const Color hintText =
      Color(0xFF78847C);

  static const Color borderColor =
      Color(0xFF293A2E);

  // ============================================================
  // CROPS
  // ============================================================

  final List<String> crops = [
    "Rice",
    "Wheat",
    "Tomato",
    "Potato",
    "Onion",
    "Cotton",
    "Sugarcane",
    "Banana",
    "Mango",
    "Groundnut",
    "Other",
  ];

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    villageController.dispose();

    super.dispose();
  }

  // ============================================================
  // REGISTER FARMER
  // ============================================================

  Future<void> registerFarmer() async {
    FocusScope.of(context).unfocus();

    // ----------------------------------------------------------
    // VALIDATE
    // ----------------------------------------------------------

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCrop == null) {
      _showMessage(
        "Please select your main crop",
        isError: true,
      );
      return;
    }

    final String name =
        nameController.text.trim();

    final String mobile =
        phoneController.text.trim();

    final String password =
        passwordController.text;

    final String village =
        villageController.text.trim();

    setState(() {
      isLoading = true;
    });

    try {
      // ========================================================
      // VIDHAI INTERNAL EMAIL
      // ========================================================

      final String loginEmail =
          "$mobile@vidhai.app";

      // ========================================================
      // CREATE FIREBASE AUTH ACCOUNT
      // ========================================================

      final UserCredential credential =
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      final User? user =
          credential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: "registration-failed",
          message:
              "Unable to create your account.",
        );
      }

      // ========================================================
      // UPDATE DISPLAY NAME
      // ========================================================

      await user.updateDisplayName(name);

      // ========================================================
      // SAVE FARMER PROFILE
      // ========================================================

      await FirebaseFirestore.instance
          .collection("farmers")
          .doc(user.uid)
          .set(
        {
          "uid": user.uid,
          "name": name,
          "phone": mobile,
          "email": loginEmail,
          "crop": selectedCrop,
          "village": village,
          "role": "farmer",

          // Optional profile fields.
          // These can be completed later.
          "farmName": "",
          "farmSize": "",
          "state": "",
          "district": "",
          "gender": "",
          "dob": "",

          "createdAt":
              FieldValue.serverTimestamp(),

          "updatedAt":
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      // ========================================================
      // IMPORTANT
      // ========================================================
      //
      // Firebase automatically signs the user in after
      // createUserWithEmailAndPassword().
      //
      // We DON'T want to keep the farmer logged in.
      //
      // So sign them out and send them back to Login.
      //
      // ========================================================

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // ========================================================
      // SUCCESS MESSAGE
      // ========================================================

      _showMessage(
        "Account created successfully! 🌱",
        isError: false,
      );

      await Future.delayed(
        const Duration(milliseconds: 900),
      );

      if (!mounted) return;

      // ========================================================
      // RETURN TO LOGIN
      // ========================================================

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      String message;

      switch (e.code) {
        case "email-already-in-use":
          message =
              "This mobile number is already registered. Please login.";
          break;

        case "weak-password":
          message =
              "Please choose a stronger password.";
          break;

        case "invalid-email":
          message =
              "Unable to create your account.";
          break;

        case "network-request-failed":
          message =
              "Please check your internet connection.";
          break;

        case "operation-not-allowed":
          message =
              "Email/password login is not enabled in Firebase.";
          break;

        default:
          message =
              e.message ??
              "Registration failed. Please try again.";
      }

      _showMessage(
        message,
        isError: true,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        e.message ??
            "Unable to save your farmer profile.",
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        "Something went wrong. Please try again.",
        isError: true,
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFB83232)
            : primaryGreen,
        behavior:
            SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTopBar(),

              Expanded(
                child: SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    8,
                    18,
                    30,
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),

                      const SizedBox(height: 18),

                      _buildFormCard(),

                      const SizedBox(height: 18),

                      _buildRegisterButton(),

                      const SizedBox(height: 18),

                      _buildLoginBottom(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return SizedBox(
      height: 55,
      child: Row(
        children: [
          const SizedBox(width: 7),

          IconButton(
            onPressed: isLoading
                ? null
                : () {
                    Navigator.pop(context);
                  },
            icon: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: inputColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: whiteText,
                size: 16,
              ),
            ),
          ),

          const Spacer(),

          Row(
            children: [
              const Icon(
                Icons.eco_rounded,
                color: brightGreen,
                size: 19,
              ),

              const SizedBox(width: 5),

              Text(
                "VIDHAI",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
                  color: brightGreen,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),

          const SizedBox(width: 20),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        20,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: primaryGreen
                  .withValues(alpha: 0.13),
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryGreen
                    .withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: brightGreen,
              size: 29,
            ),
          ),

          const SizedBox(height: 13),

          Text(
            "Create your account",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: whiteText,
              fontSize: 20,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            "Just a few details to get started",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: secondaryText,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORM CARD
  // ============================================================

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        15,
        17,
        15,
        17,
      ),
      decoration: BoxDecoration(
        color: sectionColor,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ======================================================
          // SECTION TITLE
          // ======================================================

          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: primaryGreen
                      .withValues(alpha: 0.13),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: brightGreen,
                  size: 18,
                ),
              ),

              const SizedBox(width: 10),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Details",
                    style:
                        GoogleFonts.poppins(
                      color: whiteText,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  Text(
                    "Only the essentials",
                    style:
                        GoogleFonts.poppins(
                      color: secondaryText,
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ======================================================
          // NAME
          // ======================================================

          _buildTextField(
            controller: nameController,
            label: "Your Name",
            hint: "Enter your name",
            icon:
                Icons.person_outline_rounded,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return "Please enter your name";
              }

              return null;
            },
          ),

          const SizedBox(height: 12),

          // ======================================================
          // MOBILE
          // ======================================================

          _buildTextField(
            controller: phoneController,
            label: "Mobile Number",
            hint: "10-digit mobile number",
            icon: Icons.phone_outlined,
            keyboardType:
                TextInputType.phone,
            maxLength: 10,
            validator: (value) {
              if (value == null ||
                  value.length != 10) {
                return "Enter a valid 10-digit number";
              }

              return null;
            },
          ),

          const SizedBox(height: 12),

          // ======================================================
          // PASSWORD
          // ======================================================

          _buildPasswordField(
            controller:
                passwordController,
            label: "Create Password",
            hint: "At least 6 characters",
            obscure: obscurePassword,
            onToggle: () {
              setState(() {
                obscurePassword =
                    !obscurePassword;
              });
            },
            validator: (value) {
              if (value == null ||
                  value.isEmpty) {
                return "Please create a password";
              }

              if (value.length < 6) {
                return "Password must have at least 6 characters";
              }

              return null;
            },
          ),

          const SizedBox(height: 12),

          // ======================================================
          // CONFIRM PASSWORD
          // ======================================================

          _buildPasswordField(
            controller:
                confirmPasswordController,
            label: "Confirm Password",
            hint: "Enter password again",
            obscure:
                obscureConfirmPassword,
            onToggle: () {
              setState(() {
                obscureConfirmPassword =
                    !obscureConfirmPassword;
              });
            },
            validator: (value) {
              if (value == null ||
                  value.isEmpty) {
                return "Please confirm your password";
              }

              if (value !=
                  passwordController.text) {
                return "Passwords do not match";
              }

              return null;
            },
          ),

          const SizedBox(height: 12),

          // ======================================================
          // CROP
          // ======================================================

          _buildCropDropdown(),

          const SizedBox(height: 12),

          // ======================================================
          // VILLAGE
          // ======================================================

          _buildTextField(
            controller:
                villageController,
            label: "Village / Area",
            hint: "Where is your farm?",
            icon:
                Icons.location_on_outlined,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return "Please enter your village or area";
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      style: GoogleFonts.poppins(
        color: whiteText,
        fontSize: 10.5,
      ),
      cursorColor: brightGreen,
      decoration: InputDecoration(
        counterText: "",
        labelText: label,
        hintText: hint,

        labelStyle:
            GoogleFonts.poppins(
          color: secondaryText,
          fontSize: 9.5,
        ),

        hintStyle:
            GoogleFonts.poppins(
          color: hintText,
          fontSize: 9.5,
        ),

        prefixIcon: Icon(
          icon,
          color: brightGreen,
          size: 18,
        ),

        filled: true,
        fillColor: inputColor,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide: BorderSide(
            color: borderColor,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide: BorderSide(
            color: borderColor,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide:
              const BorderSide(
            color: brightGreen,
            width: 1.2,
          ),
        ),

        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide:
              const BorderSide(
            color: Color(0xFFB83232),
          ),
        ),

        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide:
              const BorderSide(
            color: Color(0xFFB83232),
            width: 1.2,
          ),
        ),

        errorStyle:
            GoogleFonts.poppins(
          fontSize: 8,
          color:
              const Color(0xFFFF7070),
        ),
      ),
    );
  }

  // ============================================================
  // PASSWORD FIELD
  // ============================================================

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.poppins(
        color: whiteText,
        fontSize: 10.5,
      ),
      cursorColor: brightGreen,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        labelStyle:
            GoogleFonts.poppins(
          color: secondaryText,
          fontSize: 9.5,
        ),

        hintStyle:
            GoogleFonts.poppins(
          color: hintText,
          fontSize: 9.5,
        ),

        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: brightGreen,
          size: 18,
        ),

        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: hintText,
            size: 19,
          ),
        ),

        filled: true,
        fillColor: inputColor,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide: BorderSide(
            color: borderColor,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide: BorderSide(
            color: borderColor,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide:
              const BorderSide(
            color: brightGreen,
            width: 1.2,
          ),
        ),

        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide:
              const BorderSide(
            color: Color(0xFFB83232),
          ),
        ),

        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide:
              const BorderSide(
            color: Color(0xFFB83232),
            width: 1.2,
          ),
        ),

        errorStyle:
            GoogleFonts.poppins(
          fontSize: 8,
          color:
              const Color(0xFFFF7070),
        ),
      ),
    );
  }

  // ============================================================
  // CROP DROPDOWN
  // ============================================================

  Widget _buildCropDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCrop,
      isExpanded: true,

      dropdownColor:
          const Color(0xFF17251B),

      style: GoogleFonts.poppins(
        color: whiteText,
        fontSize: 10.5,
      ),

      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: secondaryText,
        size: 19,
      ),

      decoration: InputDecoration(
        labelText: "Main Crop",
        hintText:
            "What do you mainly grow?",

        labelStyle:
            GoogleFonts.poppins(
          color: secondaryText,
          fontSize: 9.5,
        ),

        hintStyle:
            GoogleFonts.poppins(
          color: hintText,
          fontSize: 9.5,
        ),

        prefixIcon: const Icon(
          Icons.eco_outlined,
          color: brightGreen,
          size: 18,
        ),

        filled: true,
        fillColor: inputColor,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide: BorderSide(
            color: borderColor,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide: BorderSide(
            color: borderColor,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide:
              const BorderSide(
            color: brightGreen,
            width: 1.2,
          ),
        ),

        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide:
              const BorderSide(
            color: Color(0xFFB83232),
          ),
        ),

        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide:
              const BorderSide(
            color: Color(0xFFB83232),
            width: 1.2,
          ),
        ),

        errorStyle:
            GoogleFonts.poppins(
          fontSize: 8,
          color:
              const Color(0xFFFF7070),
        ),
      ),

      validator: (value) {
        if (value == null) {
          return "Please select your main crop";
        }

        return null;
      },

      items: crops.map((crop) {
        return DropdownMenuItem<String>(
          value: crop,
          child: Text(
            crop,
            overflow:
                TextOverflow.ellipsis,
            style:
                GoogleFonts.poppins(
              color: whiteText,
              fontSize: 10.5,
            ),
          ),
        );
      }).toList(),

      onChanged: (value) {
        setState(() {
          selectedCrop = value;
        });
      },
    );
  }

  // ============================================================
  // REGISTER BUTTON
  // ============================================================

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 47,
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.centerLeft,
          end:
              Alignment.centerRight,
          colors: [
            Color(0xFF2BA947),
            Color(0xFF208B38),
          ],
        ),

        borderRadius:
            BorderRadius.circular(11),

        boxShadow: [
          BoxShadow(
            color: primaryGreen
                .withValues(alpha: 0.24),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: ElevatedButton(
        onPressed:
            isLoading
                ? null
                : registerFarmer,

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              Colors.transparent,
          disabledBackgroundColor:
              Colors.transparent,
          shadowColor:
              Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(11),
          ),
        ),

        child: isLoading
            ? const SizedBox(
                width: 19,
                height: 19,
                child:
                    CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    "Create Account",
                    style:
                        GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Icon(
                    Icons
                        .arrow_forward_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // LOGIN BOTTOM
  // ============================================================

  Widget _buildLoginBottom() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account?",
          style: GoogleFonts.poppins(
            color: secondaryText,
            fontSize: 9.5,
          ),
        ),

        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  Navigator.pop(context);
                },
          style:
              TextButton.styleFrom(
            minimumSize: Size.zero,
            padding:
                const EdgeInsets.only(
              left: 5,
              right: 2,
            ),
          ),
          child: Text(
            "Login",
            style:
                GoogleFonts.poppins(
              color: brightGreen,
              fontSize: 9.5,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}