import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'delivery_home_screen.dart';

class DeliveryLoginScreen extends StatefulWidget {
  const DeliveryLoginScreen({super.key});

  @override
  State<DeliveryLoginScreen> createState() => _DeliveryLoginScreenState();
}

class _DeliveryLoginScreenState extends State<DeliveryLoginScreen> {
  static const Color yellow = Color(0xFFFFC107);
  static const Color background = Color(0xFF080A08);
  static const Color card = Color(0xFF151515);

  bool isLogin = true;
  bool loading = false;
  bool hidePassword = true;

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  String selectedVehicleType = 'Bike';

  final List<String> vehicleTypes = ['Bike', 'Scooter', 'Mini-Truck'];

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _snack('Please enter your phone number and password');
      return;
    }

    setState(() => loading = true);

    try {
      final email = '$phone@delivery.vidhai.app';

      if (isLogin) {
        // Sign in
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Verify role
        final doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
        if (doc.exists && doc.data()?['role'] != 'delivery_partner') {
          await FirebaseAuth.instance.signOut();
          throw Exception('This account is not registered as a Delivery Partner.');
        }
      } else {
        // Register
        final name = _nameController.text.trim();
        final vehicleNum = _vehicleNumberController.text.trim();

        if (name.isEmpty || vehicleNum.isEmpty) {
          throw Exception('Please fill in your name and vehicle number.');
        }

        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = cred.user!;
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'phone': phone,
          'email': email,
          'role': 'delivery_partner',
          'vehicleType': selectedVehicleType,
          'vehicleNumber': vehicleNum,
          'isOnline': false,
          'currentLat': 11.0168,
          'currentLng': 76.9558,
          'activeOrderId': null,
          'totalDeliveries': 0,
          'todayDeliveries': 0,
          'inProgressDeliveries': 0,
          'rating': 5.0,
          'verificationStatus': 'verified',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DeliveryHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: yellow.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: yellow, width: 2),
                  ),
                  child: const Icon(Icons.electric_moped_rounded, color: yellow, size: 42),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Vidhai Delivery',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Connecting Farms to Families',
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                ),
              ),
              const SizedBox(height: 28),

              // Toggle Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isLogin = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isLogin ? yellow : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: isLogin ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isLogin = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isLogin ? yellow : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Register',
                            style: TextStyle(
                              color: !isLogin ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (!isLogin) ...[
                _buildField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_rounded,
                  hint: 'e.g. Ravi Kumar',
                ),
                const SizedBox(height: 14),
                // Vehicle Type
                Text('Vehicle Type', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedVehicleType,
                      dropdownColor: card,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: yellow),
                      items: vehicleTypes.map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text(v, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedVehicleType = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _vehicleNumberController,
                  label: 'Vehicle Number',
                  icon: Icons.confirmation_number_rounded,
                  hint: 'e.g. TN 39 BK 2049',
                ),
                const SizedBox(height: 14),
              ],

              _buildField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_rounded,
                hint: '10-digit mobile number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_rounded,
                hint: 'Enter your password',
                isPassword: true,
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                        )
                      : Text(
                          isLogin ? 'Sign In as Delivery Partner' : 'Complete Registration',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && hidePassword,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              prefixIcon: Icon(icon, color: yellow, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        hidePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                      onPressed: () => setState(() => hidePassword = !hidePassword),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
