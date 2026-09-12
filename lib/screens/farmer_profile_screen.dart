import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() =>
      _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color green = Color(0xFF4CAF50);
  static const Color orange = Color(0xFFFF9800);
  static const Color background = Color(0xFF050505);
  static const Color card = Color(0xFF151515);

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // PROFILE DATA
  // ============================================================

  String farmerName = 'Farmer';
  String farmName = 'My Farm';
  String email = '';

  String selectedAvatar = 'farmer_1';

  bool loading = true;
  bool loggingOut = false;

  // ============================================================
  // FARMER AVATARS
  // IMPORTANT:
  // Actual filenames are farmer_1.png ... farmer_5.png
  // ============================================================

  final List<String> _avatarAssets = [
    'assets/avatars/farmer_1.png',
    'assets/avatars/farmer_2.png',
    'assets/avatars/farmer_3.png',
    'assets/avatars/farmer_4.png',
    'assets/avatars/farmer_5.png',
  ];

  final List<String> _avatarNames = [
    'Farmer 1',
    'Farmer 2',
    'Farmer 3',
    'Farmer 4',
    'Farmer 5',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
      return;
    }

    email = user.email ?? '';

    try {
      final Map<String, dynamic> data = {};

      // 1. Try farmers collection first
      try {
        final farmerDoc = await _firestore.collection('farmers').doc(user.uid).get();
        if (farmerDoc.exists && farmerDoc.data() != null) {
          data.addAll(farmerDoc.data()!);
        }
      } catch (_) {}

      // 2. Try users collection second
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          userDoc.data()!.forEach((k, v) {
            if (v != null && (data[k] == null || data[k].toString().trim().isEmpty)) {
              data[k] = v;
            }
          });
        }
      } catch (_) {}

      if (!mounted) return;

      String name = data['name']?.toString().trim() ?? '';
      if (name.isEmpty) {
        name = user.displayName?.trim() ?? '';
      }
      if (name.isEmpty) {
        name = 'Farmer';
      }

      final farm = data['farmName']?.toString().trim() ?? '';
      final avatar = data['profileAvatar']?.toString().trim() ?? '';

      setState(() {
        farmerName = name;
        farmName = farm.isNotEmpty ? farm : 'My Farm';
        selectedAvatar = _isValidAvatar(avatar) ? avatar : 'farmer_1';
        loading = false;
      });
    } catch (e) {
      debugPrint(
        'Farmer profile error: $e',
      );

      if (mounted) {
        setState(() {
          farmerName = user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : 'Farmer';
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // VALID AVATAR
  // ============================================================

  bool _isValidAvatar(String avatar) {
    return avatar == 'farmer_1' ||
        avatar == 'farmer_2' ||
        avatar == 'farmer_3' ||
        avatar == 'farmer_4' ||
        avatar == 'farmer_5';
  }

  // ============================================================
  // AVATAR INDEX
  // ============================================================

  int _avatarIndex(String avatar) {
    final number = int.tryParse(
          avatar.replaceAll('farmer_', ''),
        ) ??
        1;

    final index = number - 1;

    if (index < 0 ||
        index >= _avatarAssets.length) {
      return 0;
    }

    return index;
  }

  // ============================================================
  // AVATAR IMAGE
  // ============================================================

  Widget _avatarImage(
    String avatar, {
    double size = 80,
  }) {
    final index = _avatarIndex(avatar);

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFF202020),
        child: Image.asset(
          _avatarAssets[index],
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return Container(
              color: green.withValues(alpha: .12),
              alignment: Alignment.center,
              child: Icon(
                Icons.person_rounded,
                color: green,
                size: size * .45,
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // CHANGE AVATAR
  // ============================================================

  Future<void> _changeAvatar() async {
    String tempAvatar = selectedAvatar;

    final result =
        await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setModalState,
          ) {
            return Container(
              decoration:
                  const BoxDecoration(
                color: card,
                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    24,
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      // ==================================================
                      // HANDLE
                      // ==================================================

                      Container(
                        width: 42,
                        height: 4,
                        decoration:
                            BoxDecoration(
                          color: Colors.white24,
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // ==================================================
                      // TITLE
                      // ==================================================

                      const Text(
                        'Choose Your Avatar',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      const Text(
                        'Pick the farmer avatar you want on your profile',
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          color:
                              Colors.white54,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      // ==================================================
                      // LARGE PREVIEW
                      // ==================================================

                      AnimatedSwitcher(
                        duration:
                            const Duration(
                          milliseconds: 250,
                        ),
                        transitionBuilder:
                            (
                          child,
                          animation,
                        ) {
                          return ScaleTransition(
                            scale:
                                animation,
                            child:
                                child,
                          );
                        },
                        child:
                            Container(
                          key: ValueKey(
                            tempAvatar,
                          ),
                          width: 120,
                          height: 120,
                          padding:
                              const EdgeInsets
                                  .all(
                            4,
                          ),
                          decoration:
                              BoxDecoration(
                            shape:
                                BoxShape
                                    .circle,
                            color: green
                                .withValues(
                              alpha: .08,
                            ),
                            border:
                                Border.all(
                              color:
                                  green,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: green
                                    .withValues(
                                  alpha:
                                      .12,
                                ),
                                blurRadius:
                                    20,
                                spreadRadius:
                                    2,
                              ),
                            ],
                          ),
                          child:
                              _avatarImage(
                            tempAvatar,
                            size: 112,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // ==================================================
                      // AVATAR NAME
                      // ==================================================

                      AnimatedSwitcher(
                        duration:
                            const Duration(
                          milliseconds: 200,
                        ),
                        child:
                            Text(
                          _avatarNames[
                              _avatarIndex(
                            tempAvatar,
                          )],
                          key: ValueKey(
                            tempAvatar,
                          ),
                          style:
                              const TextStyle(
                            color:
                                Colors.white70,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      // ==================================================
                      // FIVE AVATARS
                      // ==================================================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children:
                            List.generate(
                          _avatarAssets.length,
                          (index) {
                            final avatar =
                                'farmer_${index + 1}';

                            final isSelected =
                                tempAvatar ==
                                    avatar;

                            return Padding(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    4,
                              ),
                              child:
                                  GestureDetector(
                                onTap: () {
                                  setModalState(
                                    () {
                                      tempAvatar =
                                          avatar;
                                    },
                                  );
                                },
                                child:
                                    AnimatedContainer(
                                  duration:
                                      const Duration(
                                    milliseconds:
                                        220,
                                  ),
                                  curve:
                                      Curves
                                          .easeOut,
                                  width: 62,
                                  height: 78,
                                  padding:
                                      const EdgeInsets
                                          .all(
                                    3,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        isSelected
                                            ? green
                                                .withValues(
                                                alpha:
                                                    .12,
                                              )
                                            : const Color(
                                                0xFF1D1D1D,
                                              ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      16,
                                    ),
                                    border:
                                        Border.all(
                                      color:
                                          isSelected
                                              ? green
                                              : Colors
                                                  .white12,
                                      width:
                                          isSelected
                                              ? 2
                                              : 1,
                                    ),
                                  ),
                                  child:
                                      Stack(
                                    clipBehavior:
                                        Clip.none,
                                    children: [
                                      Center(
                                        child:
                                            AnimatedScale(
                                          scale:
                                              isSelected
                                                  ? 1.08
                                                  : 1.0,
                                          duration:
                                              const Duration(
                                            milliseconds:
                                                220,
                                          ),
                                          child:
                                              _avatarImage(
                                            avatar,
                                            size:
                                                55,
                                          ),
                                        ),
                                      ),

                                      // CHECK
                                      if (isSelected)
                                        Positioned(
                                          right:
                                              -7,
                                          top:
                                              -8,
                                          child:
                                              Container(
                                            width:
                                                21,
                                            height:
                                                21,
                                            decoration:
                                                const BoxDecoration(
                                              color:
                                                  green,
                                              shape:
                                                  BoxShape
                                                      .circle,
                                            ),
                                            child:
                                                const Icon(
                                              Icons
                                                  .check_rounded,
                                              color:
                                                  Colors.black,
                                              size:
                                                  14,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      // ==================================================
                      // SAVE BUTTON
                      // ==================================================

                      SizedBox(
                        width:
                            double.infinity,
                        height: 50,
                        child:
                            ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                              tempAvatar,
                            );
                          },
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                green,
                            foregroundColor:
                                Colors.black,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),
                          ),
                          child:
                              const Text(
                            'Save Avatar',
                            style:
                                TextStyle(
                              fontSize:
                                  14,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // ============================================================
    // RESULT
    // ============================================================

    if (result == null ||
        result == selectedAvatar) {
      return;
    }

    await _saveAvatar(result);
  }

  // ============================================================
  // SAVE AVATAR TO FIRESTORE
  // ============================================================

  Future<void> _saveAvatar(
    String avatar,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await Future.wait([
        _firestore.collection('users').doc(user.uid).set(
          {
            'profileAvatar': avatar,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        ),
        _firestore.collection('farmers').doc(user.uid).set(
          {
            'profileAvatar': avatar,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        ),
      ]);

      if (!mounted) return;

      setState(() {
        selectedAvatar = avatar;
      });

      _showMessage(
        'Avatar updated successfully',
        success: true,
      );
    } catch (e) {
      debugPrint(
        'Avatar update error: $e',
      );

      _showMessage(
        'Unable to update avatar',
      );
    }
  }

  // ============================================================
  // PROFILE OPTION
  // ============================================================

  Widget _profileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      decoration:
          BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color:
              Colors.white.withValues(
            alpha: .06,
          ),
        ),
      ),
      child:
          Material(
        color: Colors.transparent,
        child:
            InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          child:
              Padding(
            padding:
                const EdgeInsets.all(
              14,
            ),
            child:
                Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration:
                      BoxDecoration(
                    color:
                        green.withValues(
                      alpha: .10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child:
                      Icon(
                    icon,
                    color: green,
                    size: 21,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        title,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                      Colors.white30,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          background,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar:
          AppBar(
        backgroundColor:
            background,
        elevation: 0,
        title:
            const Text(
          'Farmer Profile',
          style:
              TextStyle(
            color:
                Colors.white,
            fontSize:
                21,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed:
                _loadProfile,
            icon:
                const Icon(
              Icons
                  .refresh_rounded,
              color:
                  Colors.white54,
            ),
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body:
          loading
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color:
                        green,
                  ),
                )
              : RefreshIndicator(
                  color:
                      green,
                  backgroundColor:
                      card,
                  onRefresh:
                      _loadProfile,
                  child:
                      ListView(
                    physics:
                        const BouncingScrollPhysics(
                      parent:
                          AlwaysScrollableScrollPhysics(),
                    ),
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      16,
                      8,
                      16,
                      35,
                    ),
                    children: [
                      // ==================================================
                      // PROFILE HEADER
                      // ==================================================

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets.all(
                          20,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              card,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            22,
                          ),
                          border:
                              Border.all(
                            color:
                                green.withValues(
                              alpha:
                                  .14,
                            ),
                          ),
                        ),
                        child:
                            Column(
                          children: [
                            // --------------------------------------------
                            // AVATAR
                            // --------------------------------------------

                            Stack(
                              clipBehavior:
                                  Clip.none,
                              children: [
                                Container(
                                  width:
                                      112,
                                  height:
                                      112,
                                  padding:
                                      const EdgeInsets
                                          .all(
                                    3,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    shape:
                                        BoxShape
                                            .circle,
                                    border:
                                        Border.all(
                                      color:
                                          green,
                                      width:
                                          2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            green.withValues(
                                          alpha:
                                              .10,
                                        ),
                                        blurRadius:
                                            20,
                                        spreadRadius:
                                            2,
                                      ),
                                    ],
                                  ),
                                  child:
                                      _avatarImage(
                                    selectedAvatar,
                                    size:
                                        106,
                                  ),
                                ),

                                // ------------------------------------------
                                // EDIT BUTTON
                                // ------------------------------------------

                                Positioned(
                                  right:
                                      -2,
                                  bottom:
                                      0,
                                  child:
                                      GestureDetector(
                                    onTap:
                                        _changeAvatar,
                                    child:
                                        Container(
                                      width:
                                          32,
                                      height:
                                          32,
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            green,
                                        shape:
                                            BoxShape
                                                .circle,
                                        border:
                                            Border.all(
                                          color:
                                              background,
                                          width:
                                              3,
                                        ),
                                      ),
                                      child:
                                          const Icon(
                                        Icons
                                            .edit_rounded,
                                        color:
                                            Colors.black,
                                        size:
                                            15,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            // --------------------------------------------
                            // NAME
                            // --------------------------------------------

                            Text(
                              farmerName,
                              maxLines:
                                  1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            // --------------------------------------------
                            // FARM
                            // --------------------------------------------

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                const Icon(
                                  Icons
                                      .agriculture_rounded,
                                  color:
                                      green,
                                  size:
                                      14,
                                ),

                                const SizedBox(
                                  width:
                                      5,
                                ),

                                Flexible(
                                  child:
                                      Text(
                                    farmName,
                                    maxLines:
                                        1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white54,
                                      fontSize:
                                          11,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (email
                                .isNotEmpty) ...[
                              const SizedBox(
                                height:
                                    4,
                              ),
                              Text(
                                email,
                                maxLines:
                                    1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white30,
                                  fontSize:
                                      9,
                                ),
                              ),
                            ],

                            const SizedBox(
                              height:
                                  16,
                            ),

                            // --------------------------------------------
                            // CHANGE AVATAR BUTTON
                            // --------------------------------------------

                            OutlinedButton.icon(
                              onPressed:
                                  _changeAvatar,
                              icon:
                                  const Icon(
                                Icons
                                    .face_retouching_natural_rounded,
                                size:
                                    17,
                              ),
                              label:
                                  const Text(
                                'Change Avatar',
                              ),
                              style:
                                  OutlinedButton
                                      .styleFrom(
                                foregroundColor:
                                    green,
                                side:
                                    const BorderSide(
                                  color:
                                      green,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height:
                            22,
                      ),

                      // ==================================================
                      // ACCOUNT
                      // ==================================================

                      const Text(
                        'Account',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize:
                              15,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height:
                            10,
                      ),

                      _profileOption(
                        icon:
                            Icons
                                .person_outline_rounded,
                        title:
                            'Personal Details',
                        subtitle:
                            'View your farmer information',
                        onTap:
                            _showPersonalDetails,
                      ),

                      _profileOption(
                        icon:
                            Icons
                                .agriculture_outlined,
                        title:
                            'Farm Information',
                        subtitle:
                            'Manage your farm details',
                        onTap:
                            _showFarmDetails,
                      ),

                      _profileOption(
                        icon:
                            Icons
                                .lock_outline_rounded,
                        title:
                            'Password & Security',
                        subtitle:
                            'Manage your account security',
                        onTap: () {
                          _showMessage(
                            'Password settings coming soon.',
                          );
                        },
                      ),

                      const SizedBox(
                        height:
                            12,
                      ),

                      // ==================================================
                      // APP
                      // ==================================================

                      const Text(
                        'App',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize:
                              15,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height:
                            10,
                      ),

                      _profileOption(
                        icon:
                            Icons
                                .notifications_none_rounded,
                        title:
                            'Notifications',
                        subtitle:
                            'Manage notifications',
                        onTap: () {
                          _showMessage(
                            'Notification settings coming soon.',
                          );
                        },
                      ),

                      _profileOption(
                        icon:
                            Icons
                                .info_outline_rounded,
                        title:
                            'About KisanAI',
                        subtitle:
                            'Direct agricultural marketplace',
                        onTap:
                            _showAbout,
                      ),

                      const SizedBox(
                        height:
                            14,
                      ),

                      // ==================================================
                      // LOGOUT
                      // ==================================================

                      GestureDetector(
                        onTap:
                            loggingOut
                                ? null
                                : _logout,
                        child:
                            Container(
                          width:
                              double.infinity,
                          height:
                              52,
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.redAccent
                                    .withValues(
                              alpha:
                                  .08,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                            border:
                                Border.all(
                              color:
                                  Colors.redAccent
                                      .withValues(
                                alpha:
                                    .30,
                              ),
                            ),
                          ),
                          child:
                              Center(
                            child:
                                loggingOut
                                    ? const CircularProgressIndicator(
                                        color:
                                            Colors.redAccent,
                                        strokeWidth:
                                            2,
                                      )
                                    : const Row(
                                        mainAxisSize:
                                            MainAxisSize
                                                .min,
                                        children: [
                                          Icon(
                                            Icons
                                                .logout_rounded,
                                            color:
                                                Colors.redAccent,
                                            size:
                                                19,
                                          ),
                                          SizedBox(
                                            width:
                                                8,
                                          ),
                                          Text(
                                            'Logout',
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.redAccent,
                                              fontSize:
                                                  13,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height:
                            16,
                      ),

                      const Center(
                        child:
                            Text(
                          'KisanAI • Farmer',
                          style:
                              TextStyle(
                            color:
                                Colors.white24,
                            fontSize:
                                9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ============================================================
  // PERSONAL DETAILS
  // ============================================================

  void _showPersonalDetails() {
    showModalBottomSheet(
      context:
          context,
      backgroundColor:
          card,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            24,
          ),
        ),
      ),
      builder:
          (context) {
        return SafeArea(
          child:
              Padding(
            padding:
                const EdgeInsets.all(
              22,
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'Personal Details',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height:
                      18,
                ),

                _detailRow(
                  Icons
                      .person_outline,
                  'Name',
                  farmerName,
                ),

                const SizedBox(
                  height:
                      10,
                ),

                _detailRow(
                  Icons
                      .email_outlined,
                  'Email',
                  email.isEmpty
                      ? 'Not available'
                      : email,
                ),

                const SizedBox(
                  height:
                      10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // FARM DETAILS
  // ============================================================

  void _showFarmDetails() {
    showModalBottomSheet(
      context:
          context,
      backgroundColor:
          card,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            24,
          ),
        ),
      ),
      builder:
          (context) {
        return SafeArea(
          child:
              Padding(
            padding:
                const EdgeInsets.all(
              22,
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'Farm Information',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height:
                      18,
                ),

                _detailRow(
                  Icons
                      .agriculture_outlined,
                  'Farm Name',
                  farmName,
                ),

                const SizedBox(
                  height:
                      10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ABOUT
  // ============================================================

  void _showAbout() {
    showDialog(
      context:
          context,
      builder:
          (context) {
        return AlertDialog(
          backgroundColor:
              const Color(
            0xFF181818,
          ),
          title:
              const Row(
            children: [
              Icon(
                Icons.eco_rounded,
                color:
                    green,
              ),
              SizedBox(
                width:
                    8,
              ),
              Text(
                'KisanAI',
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          content:
              const Text(
            'A direct agricultural marketplace connecting farmers and buyers.',
            style:
                TextStyle(
              color:
                  Colors.white60,
              fontSize:
                  12,
              height:
                  1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text(
                'Close',
                style:
                    TextStyle(
                  color:
                      green,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        12,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF101010,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
      child:
          Row(
        children: [
          Icon(
            icon,
            color:
                green,
            size:
                20,
          ),

          const SizedBox(
            width:
                10,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        Colors.white38,
                    fontSize:
                        8,
                  ),
                ),

                const SizedBox(
                  height:
                      3,
                ),

                Text(
                  value,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    if (loggingOut) return;

    final confirm =
        await showDialog<bool>(
      context:
          context,
      builder:
          (context) {
        return AlertDialog(
          backgroundColor:
              const Color(
            0xFF181818,
          ),
          title:
              const Text(
            'Logout?',
            style:
                TextStyle(
              color:
                  Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content:
              const Text(
            'Are you sure you want to logout?',
            style:
                TextStyle(
              color:
                  Colors.white60,
              fontSize:
                  12,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text(
                'Cancel',
                style:
                    TextStyle(
                  color:
                      Colors.white54,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    setState(() {
      loggingOut = true;
    });

    try {
      await _auth.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/role',
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        'Logout error: $e',
      );

      if (mounted) {
        setState(() {
          loggingOut = false;
        });

        _showMessage(
          'Unable to logout',
        );
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
        backgroundColor:
            success
                ? const Color(
                    0xFF2E7D32,
                  )
                : const Color(
                    0xFF242424,
                  ),
        behavior:
            SnackBarBehavior
                .floating,
      ),
    );
  }
}