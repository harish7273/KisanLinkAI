import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class FarmerRegisterScreen extends StatefulWidget {
  const FarmerRegisterScreen({super.key});

  @override
  State<FarmerRegisterScreen> createState() =>
      _FarmerRegisterScreenState();
}

class _FarmerRegisterScreenState
    extends State<FarmerRegisterScreen> {

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final AuthService _authService = AuthService();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController farmNameController =
      TextEditingController();

  final TextEditingController villageController =
      TextEditingController();

  final TextEditingController farmSizeController =
      TextEditingController();

  final TextEditingController dobController =
      TextEditingController();

  bool isLoading = false;

  String? selectedGender;
  String? selectedState;
  String? selectedDistrict;
  String? selectedCrop;

  final List<String> genders = [
    "Male",
    "Female",
    "Other",
  ];

  final List<String> states = [
    "Tamil Nadu",
    "Kerala",
    "Karnataka",
    "Andhra Pradesh",
    "Telangana",
  ];

  final List<String> districts = [
    "Chennai",
    "Coimbatore",
    "Madurai",
    "Salem",
    "Trichy",
    "Erode",
    "Tirunelveli",
    "Thanjavur",
  ];

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
  ];

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    farmNameController.dispose();
    villageController.dispose();
    farmSizeController.dispose();
    dobController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final DateTime? picked =
        await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );

    if (picked != null) {
      dobController.text =
          "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  Future<void> registerFarmer() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedGender == null ||
        selectedState == null ||
        selectedDistrict == null ||
        selectedCrop == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all fields",
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    await _authService.sendOTP(

      phoneNumber: phoneController.text.trim(),

      codeSent: (verificationId) {

        setState(() {
          isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(

              verificationId: verificationId,

              name: nameController.text.trim(),

              phone: phoneController.text.trim(),

              email: emailController.text.trim(),

              gender: selectedGender!,

              dob: dobController.text.trim(),

              farmName:
                  farmNameController.text.trim(),

              state: selectedState!,

              district: selectedDistrict!,

              village:
                  villageController.text.trim(),

              crop: selectedCrop!,

              farmSize:
                  farmSizeController.text.trim(),
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
              e.message ?? "OTP Failed",
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
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

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

                  const SizedBox(height: 15),

                  Center(
                    child: Container(
                      height: 90,
                      width: 90,
                      decoration: const BoxDecoration(
                        gradient:
                            AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.agriculture,
                        color: Colors.white,
                        size: 45,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Center(
                    child: Text(
                      "Farmer Registration",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      "Create your farmer account",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  Text(
                    "Personal Information",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildTextField(
                    controller: nameController,
                    label: "Full Name",
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return "Enter your name";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  _buildTextField(
                    controller: phoneController,
                    label: "Mobile Number",
                    icon: Icons.phone_android,
                    keyboardType:
                        TextInputType.phone,
                    maxLength: 10,
                    validator: (value) {
                      if (value == null ||
                          value.length != 10) {
                        return "Enter a valid mobile number";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  _buildTextField(
                    controller: emailController,
                    label: "Email (Optional)",
                    icon: Icons.email_outlined,
                    keyboardType:
                        TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 18),

                  _buildDropdown<String>(
                    value: selectedGender,
                    label: "Gender",
                    icon: Icons.people_outline,
                    items: genders,
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  GestureDetector(
                    onTap: pickDate,
                    child: AbsorbPointer(
                      child: _buildTextField(
                        controller: dobController,
                        label: "Date of Birth",
                        icon: Icons.calendar_month,
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  Text(
                    "Farm Information",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),
                                    _buildTextField(
                    controller: farmNameController,
                    label: "Farm Name",
                    icon: Icons.agriculture_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter farm name";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  _buildDropdown<String>(
                    value: selectedState,
                    label: "State",
                    icon: Icons.location_on_outlined,
                    items: states,
                    onChanged: (value) {
                      setState(() {
                        selectedState = value;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  _buildDropdown<String>(
                    value: selectedDistrict,
                    label: "District",
                    icon: Icons.location_city_outlined,
                    items: districts,
                    onChanged: (value) {
                      setState(() {
                        selectedDistrict = value;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  _buildTextField(
                    controller: villageController,
                    label: "Village",
                    icon: Icons.home_work_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter village";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  _buildDropdown<String>(
                    value: selectedCrop,
                    label: "Primary Crop",
                    icon: Icons.eco_outlined,
                    items: crops,
                    onChanged: (value) {
                      setState(() {
                        selectedCrop = value;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  _buildTextField(
                    controller: farmSizeController,
                    label: "Farm Size (Acres)",
                    icon: Icons.square_foot_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter farm size";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : registerFarmer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.transparent,
                          shadowColor:
                              Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    18),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                "Register",
                                style:
                                    GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style:
                              GoogleFonts.poppins(
                            color: Colors.white70,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Login",
                            style:
                                GoogleFonts.poppins(
                              color:
                                  AppColors.secondary,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
    Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      style: GoogleFonts.poppins(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        counterText: "",
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.white70,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white70,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      dropdownColor: const Color(0xFF1E2A38),
      style: GoogleFonts.poppins(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.white70,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white70,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
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
      validator: (value) {
        if (value == null) {
          return "Please select $label";
        }
        return null;
      },
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            item.toString(),
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}