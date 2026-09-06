import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'main_screen.dart';

class BuyerRegistrationScreen extends StatefulWidget {
  const BuyerRegistrationScreen({super.key});

  @override
  State<BuyerRegistrationScreen> createState() =>
      _BuyerRegistrationScreenState();
}

class _BuyerRegistrationScreenState
    extends State<BuyerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  static const Color orange = Color(0xFFFF9800);
  static const Color background = Color(0xFF080A08);
  static const Color card = Color(0xFF151515);

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> _registerBuyer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final shopName = _shopNameController.text.trim();
    final username =
        _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text;

    setState(() {
      _loading = true;
    });

    try {
      // ========================================================
      // CHECK USERNAME
      // ========================================================

      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where(
            'username',
            isEqualTo: username,
          )
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception(
          'Username already exists. Please choose another one.',
        );
      }

      // ========================================================
      // INTERNAL EMAIL
      // ========================================================

      final email = '$username@vidhai.app';

      // ========================================================
      // FIREBASE AUTH
      // ========================================================

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception(
          'Unable to create your account.',
        );
      }

      // ========================================================
      // FIRESTORE
      // ========================================================

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': name,
        'shopName': shopName,
        'username': username,
        'email': email,
        'role': 'buyer',

        'phone': '',
        'location': '',
        'district': '',
        'state': '',

        'createdAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // ========================================================
      // GO TO BUYER MAIN SCREEN
      // ========================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const MainScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed.';

      switch (e.code) {
        case 'email-already-in-use':
          message =
              'This username is already registered.';
          break;

        case 'weak-password':
          message =
              'Password must be at least 6 characters.';
          break;

        case 'invalid-email':
          message =
              'Invalid username.';
          break;

        case 'operation-not-allowed':
          message =
              'Email/password authentication is not enabled in Firebase.';
          break;

        case 'network-request-failed':
          message =
              'Please check your internet connection.';
          break;

        default:
          message =
              e.message ?? 'Registration failed.';
      }

      _showError(message);
    } catch (e) {
      _showError(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            12,
            24,
            30,
          ),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ==================================================
                // BACK
                // ==================================================

                IconButton(
                  onPressed: _loading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // ICON
                // ==================================================

                Center(
                  child: Container(
                    width: 78,
                    height: 78,

                    decoration: BoxDecoration(
                      color: orange.withValues(
                        alpha: 0.12,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: orange.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),

                    child: const Icon(
                      Icons.storefront_rounded,
                      color: orange,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // TITLE
                // ==================================================

                const Center(
                  child: Text(
                    'Create Buyer Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                const Center(
                  child: Text(
                    'Buy fresh produce directly from farmers',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // NAME
                // ==================================================

                _fieldLabel('Your Name'),

                const SizedBox(height: 7),

                TextFormField(
                  controller: _nameController,
                  enabled: !_loading,
                  textCapitalization:
                      TextCapitalization.words,
                  textInputAction:
                      TextInputAction.next,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  cursorColor: orange,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter your name';
                    }

                    if (value.trim().length < 2) {
                      return 'Enter a valid name';
                    }

                    return null;
                  },
                  decoration: _inputDecoration(
                    hint: 'Enter your name',
                    icon: Icons.person_outline_rounded,
                  ),
                ),

                const SizedBox(height: 17),

                // ==================================================
                // SHOP NAME
                // ==================================================

                _fieldLabel('Store / Shop Name'),

                const SizedBox(height: 7),

                TextFormField(
                  controller: _shopNameController,
                  enabled: !_loading,
                  textCapitalization:
                      TextCapitalization.words,
                  textInputAction:
                      TextInputAction.next,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  cursorColor: orange,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter your store or shop name';
                    }

                    return null;
                  },
                  decoration: _inputDecoration(
                    hint: 'Example: Green Valley Store',
                    icon: Icons.storefront_outlined,
                  ),
                ),

                const SizedBox(height: 17),

                // ==================================================
                // USERNAME
                // ==================================================

                _fieldLabel('Username'),

                const SizedBox(height: 7),

                TextFormField(
                  controller: _usernameController,
                  enabled: !_loading,
                  textCapitalization:
                      TextCapitalization.none,
                  textInputAction:
                      TextInputAction.next,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  cursorColor: orange,
                  validator: (value) {
                    final username =
                        value?.trim() ?? '';

                    if (username.isEmpty) {
                      return 'Create a username';
                    }

                    if (username.length < 4) {
                      return 'Minimum 4 characters';
                    }

                    if (username.contains(' ')) {
                      return 'Username cannot contain spaces';
                    }

                    return null;
                  },
                  decoration: _inputDecoration(
                    hint: 'Create a username',
                    icon:
                        Icons.alternate_email_rounded,
                  ),
                ),

                const SizedBox(height: 17),

                // ==================================================
                // PASSWORD
                // ==================================================

                _fieldLabel('Password'),

                const SizedBox(height: 7),

                TextFormField(
                  controller: _passwordController,
                  enabled: !_loading,
                  obscureText: _hidePassword,
                  textInputAction:
                      TextInputAction.next,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  cursorColor: orange,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Create a password';
                    }

                    if (value.length < 6) {
                      return 'Minimum 6 characters';
                    }

                    return null;
                  },
                  decoration: _inputDecoration(
                    hint: 'Create a password',
                    icon:
                        Icons.lock_outline_rounded,
                    suffix: IconButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() {
                                _hidePassword =
                                    !_hidePassword;
                              });
                            },
                      icon: Icon(
                        _hidePassword
                            ? Icons
                                .visibility_off_outlined
                            : Icons
                                .visibility_outlined,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 17),

                // ==================================================
                // CONFIRM PASSWORD
                // ==================================================

                _fieldLabel('Confirm Password'),

                const SizedBox(height: 7),

                TextFormField(
                  controller:
                      _confirmPasswordController,
                  enabled: !_loading,
                  obscureText:
                      _hideConfirmPassword,
                  textInputAction:
                      TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_loading) {
                      _registerBuyer();
                    }
                  },
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  cursorColor: orange,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Confirm your password';
                    }

                    if (value !=
                        _passwordController.text) {
                      return 'Passwords do not match';
                    }

                    return null;
                  },
                  decoration: _inputDecoration(
                    hint: 'Re-enter your password',
                    icon:
                        Icons.lock_reset_rounded,
                    suffix: IconButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() {
                                _hideConfirmPassword =
                                    !_hideConfirmPassword;
                              });
                            },
                      icon: Icon(
                        _hideConfirmPassword
                            ? Icons
                                .visibility_off_outlined
                            : Icons
                                .visibility_outlined,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 27),

                // ==================================================
                // REGISTER BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    onPressed:
                        _loading
                            ? null
                            : _registerBuyer,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                          orange.withValues(
                        alpha: 0.45,
                      ),
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),
                    ),

                    child: _loading
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child:
                                CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons
                                    .person_add_alt_1_rounded,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // LOGIN LINK
                // ==================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),

                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                              );
                            },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: orange,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                const Center(
                  child: Text(
                    'Vidhai • Fresh from Farms',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ============================================================
  // INPUT
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(
        color: Colors.white30,
        fontSize: 13,
      ),

      prefixIcon: Icon(
        icon,
        color: Colors.white38,
        size: 21,
      ),

      suffixIcon: suffix,

      filled: true,
      fillColor: card,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: orange,
          width: 1.2,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
    );
  }
}