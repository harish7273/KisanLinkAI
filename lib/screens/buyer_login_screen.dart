import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'buyer_registration_screen.dart';
import 'main_screen.dart';

class BuyerLoginScreen extends StatefulWidget {
  const BuyerLoginScreen({super.key});

  @override
  State<BuyerLoginScreen> createState() =>
      _BuyerLoginScreenState();
}

class _BuyerLoginScreenState
    extends State<BuyerLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;

  static const Color orange =
      Color(0xFFFF9800);

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginBuyer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawInput = _usernameController.text.trim();
    final bool isEmail = rawInput.contains('@');
    final String cleanUsername = isEmail
        ? rawInput.toLowerCase()
        : rawInput.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');

    if (cleanUsername.isEmpty) {
      _showMessage('Invalid username.');
      return;
    }

    final String email = isEmail ? rawInput.toLowerCase() : '$cleanUsername@kisanai.app';
    final String legacyEmail = isEmail ? rawInput.toLowerCase() : '$cleanUsername@vidhai.app';
    final password = _passwordController.text;

    setState(() {
      _loading = true;
    });

    try {
      UserCredential credential;
      try {
        credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (authError) {
        // If not found under current domain, try legacy domain for existing accounts
        if ((authError.code == 'user-not-found' || authError.code == 'invalid-credential') && !isEmail) {
          try {
            credential = await FirebaseAuth.instance
                .signInWithEmailAndPassword(
              email: legacyEmail,
              password: password,
            );
          } on FirebaseAuthException catch (_) {
            // If still not found, auto-register as new buyer
            try {
              credential = await FirebaseAuth.instance
                  .createUserWithEmailAndPassword(
                email: email,
                password: password,
              );
            } on FirebaseAuthException catch (createError) {
              if (createError.code == 'invalid-email') {
                credential = await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                  email: legacyEmail,
                  password: password,
                );
              } else if (createError.code == 'email-already-in-use') {
                throw FirebaseAuthException(
                  code: 'wrong-password',
                  message: 'Incorrect password for buyer $rawInput.',
                );
              } else {
                rethrow;
              }
            }
          }
        } else if (authError.code == 'user-not-found') {
          // If plain email and not found, auto-register
          credential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final user = credential.user;
      if (user == null) {
        throw Exception('Unable to authenticate buyer account.');
      }

      // Now authenticated: safely load or initialize profile document in Firestore
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) {
        await userDocRef.set({
          'uid': user.uid,
          'name': rawInput,
          'username': cleanUsername,
          'email': email,
          'role': 'buyer',
          'shopName': '$rawInput Store',
          'phone': '',
          'deliveryAddress': '',
          'location': '',
          'profileAvatar': 'buyer_1',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        final data = docSnapshot.data() ?? {};
        final role = data['role']?.toString().toLowerCase();

        if (role != null && role.isNotEmpty && role != 'buyer') {
          await FirebaseAuth.instance.signOut();
          throw Exception(
              'This account is registered as "$role". Please login via the $role screen.');
        } else if (role == null || role.isEmpty) {
          await userDocRef.set({
            'role': 'buyer',
            'name': data['name'] ?? rawInput,
            'username': cleanUsername,
          }, SetOptions(merge: true));
        }
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed.';

      if (e.code == 'invalid-email') {
        message = 'Invalid username.';
      } else if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        message = 'Invalid username or password.';
      } else if (e.code == 'weak-password') {
        message = 'Password must be at least 6 characters.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Try again later.';
      } else if (e.code == 'network-request-failed') {
        message = 'Check your internet connection.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }

      _showMessage(message);
    } catch (e) {
      _showMessage(
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

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            Colors.red.shade700,
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF080A08),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                IconButton(
                  onPressed: _loading
                      ? null
                      : () =>
                          Navigator.pop(
                            context,
                          ),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration:
                        BoxDecoration(
                      color:
                          orange.withValues(
                        alpha: .12,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons
                          .storefront_rounded,
                      color: orange,
                      size: 42,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                const Center(
                  child: Text(
                    'Login to your KisanAI buyer account',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 38),

                const Text(
                  'Username',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      _usernameController,
                  enabled: !_loading,
                  style:
                      const TextStyle(
                    color: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter username or email';
                    }

                    return null;
                  },
                  decoration:
                      _inputDecoration(
                    'e.g. buyer_kovai or name@email.com',
                    Icons
                        .person_outline_rounded,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      _passwordController,
                  enabled: !_loading,
                  obscureText:
                      _hidePassword,
                  style:
                      const TextStyle(
                    color: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return
                          'Enter password';
                    }

                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (!_loading) {
                      _loginBuyer();
                    }
                  },
                  decoration:
                      _inputDecoration(
                    'Enter password',
                    Icons
                        .lock_outline_rounded,
                    suffix:
                        IconButton(
                      onPressed:
                          _loading
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
                        color:
                            Colors.white38,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width:
                      double.infinity,
                  height: 54,

                  child:
                      ElevatedButton(
                    onPressed:
                        _loading
                            ? null
                            : _loginBuyer,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          orange,
                      foregroundColor:
                          Colors.black,
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
                              color:
                                  Colors.black,
                              strokeWidth:
                                  2.5,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),

                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const BuyerRegistrationScreen(),
                                ),
                              );
                            },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          color: orange,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                TextButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(
                    Icons.play_circle_outline_rounded,
                    color: orange,
                    size: 18,
                  ),
                  label: const Text(
                    'Quick Demo / Explore without login',
                    style: TextStyle(
                      color: orange,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  InputDecoration _inputDecoration(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle:
          const TextStyle(
        color: Colors.white30,
      ),

      prefixIcon:
          Icon(
        icon,
        color: Colors.white38,
      ),

      suffixIcon: suffix,

      filled: true,

      fillColor:
          const Color(0xFF151515),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            BorderSide(
          color:
              Colors.white.withValues(
            alpha: .06,
          ),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: orange,
          width: 1.2,
        ),
      ),
    );
  }
}