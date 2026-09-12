import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/buyer_avatar_selector.dart';
import '../widgets/profile_avatar.dart';

class BuyerProfileScreen
    extends StatefulWidget {
  const BuyerProfileScreen({
    super.key,
  });

  @override
  State<BuyerProfileScreen>
      createState() =>
          _BuyerProfileScreenState();
}

class _BuyerProfileScreenState
    extends State<BuyerProfileScreen> {
  static const Color orange =
      Color(0xFFFF9800);

  static const Color background =
      Color(0xFF050505);

  static const Color card =
      Color(0xFF151515);

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore
      _firestore =
      FirebaseFirestore.instance;

  String buyerName = 'Buyer';

  String shopName = 'My Store';

  String email = '';

  String selectedAvatar =
      'buyer_1';

  bool loadingProfile = true;

  bool loggingOut = false;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    final user =
        _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          loadingProfile = false;
        });
      }

      return;
    }

    email =
        user.email ?? '';

    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

      if (!mounted) return;

      if (doc.exists) {
        final data =
            doc.data();

        if (data != null) {
          final name =
              data['name']
                      ?.toString()
                      .trim() ??
                  '';

          final store =
              data['shopName']
                      ?.toString()
                      .trim() ??
                  '';

          final avatar =
              data['profileAvatar']
                      ?.toString()
                      .trim() ??
                  '';

          setState(() {
            buyerName =
                name.isNotEmpty
                    ? name
                    : 'Buyer';

            shopName =
                store.isNotEmpty
                    ? store
                    : 'My Store';

            selectedAvatar =
                avatar.startsWith(
                      'buyer_',
                    )
                    ? avatar
                    : 'buyer_1';

            loadingProfile =
                false;
          });

          return;
        }
      }

      setState(() {
        loadingProfile = false;
      });
    } catch (e) {
      debugPrint(
        'Buyer profile error: $e',
      );

      if (mounted) {
        setState(() {
          loadingProfile = false;
        });
      }
    }
  }

  // ============================================================
  // CHANGE AVATAR
  // ============================================================

  Future<void> _changeAvatar() async {
    String tempAvatar =
        selectedAvatar;

    final result =
        await showModalBottomSheet<
            String>(
      context: context,

      backgroundColor: card,

      isScrollControlled: true,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),

      builder: (context) {
        return StatefulBuilder(
          builder:
              (
            context,
            setModalState,
          ) {
            return SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  25,
                ),

                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    Container(
                      width: 42,
                      height: 4,

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white24,

                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    const Text(
                      'Choose your avatar',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    const Text(
                      'Select an avatar for your buyer profile',
                      style:
                          TextStyle(
                        color:
                            Colors.white54,
                        fontSize: 10,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    ProfileAvatar(
                      avatarId:
                          tempAvatar,
                      size: 90,
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    BuyerAvatarSelector(
                      selectedAvatar:
                          tempAvatar,

                      onSelected:
                          (avatar) {
                        setModalState(() {
                          tempAvatar =
                              avatar;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    SizedBox(
                      width:
                          double.infinity,

                      height: 48,

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
                              orange,

                          foregroundColor:
                              Colors.black,

                          elevation: 0,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              13,
                            ),
                          ),
                        ),

                        child:
                            const Text(
                          'Save Avatar',

                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null ||
        result ==
            selectedAvatar) {
      return;
    }

    await _saveAvatar(
      result,
    );
  }

  // ============================================================
  // SAVE AVATAR
  // ============================================================

  Future<void> _saveAvatar(
    String avatar,
  ) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'profileAvatar':
              avatar,

          'updatedAt':
              FieldValue
                  .serverTimestamp(),
        },

        SetOptions(
          merge: true,
        ),
      );

      if (!mounted) return;

      setState(() {
        selectedAvatar =
            avatar;
      });

      _showMessage(
        'Avatar updated successfully',
        success: true,
      );
    } catch (e) {
      debugPrint(
        'Avatar save error: $e',
      );

      _showMessage(
        'Unable to update avatar',
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    if (loggingOut) {
      return;
    }

    final confirm =
        await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          backgroundColor:
              const Color(
            0xFF181818,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),

          title: const Text(
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
                  ElevatedButton
                      .styleFrom(
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

      Navigator
          .pushNamedAndRemoveUntil(
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
  // OPTION CARD
  // ============================================================

  Widget _optionCard({
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
              Colors.white
                  .withValues(
            alpha: .06,
          ),
        ),
      ),

      child: Material(
        color:
            Colors.transparent,

        child: InkWell(
          onTap: onTap,

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          child: Padding(
            padding:
                const EdgeInsets.all(
              14,
            ),

            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,

                  decoration:
                      BoxDecoration(
                    color:
                        orange.withValues(
                      alpha: .10,
                    ),

                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                  ),

                  child:
                      Icon(
                    icon,
                    color:
                        orange,
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
                          fontSize:
                              13,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        subtitle,

                        maxLines:
                            1,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        style:
                            const TextStyle(
                          color:
                              Colors.white38,
                          fontSize:
                              9,
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

      appBar: AppBar(
        backgroundColor:
            background,

        elevation: 0,

        title:
            const Text(
          'Profile',

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

      body:
          loadingProfile
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color:
                        orange,
                    strokeWidth:
                        2,
                  ),
                )
              : RefreshIndicator(
                  color:
                      orange,

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
                        const EdgeInsets.fromLTRB(
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
                              BorderRadius.circular(
                            22,
                          ),

                          border:
                              Border.all(
                            color:
                                orange.withValues(
                              alpha:
                                  .14,
                            ),
                          ),
                        ),

                        child:
                            Column(
                          children: [
                            Stack(
                              clipBehavior:
                                  Clip.none,

                              children: [
                                ProfileAvatar(
                                  avatarId:
                                      selectedAvatar,

                                  size: 100,
                                ),

                                Positioned(
                                  right:
                                      -2,

                                  bottom:
                                      1,

                                  child:
                                      GestureDetector(
                                    onTap:
                                        _changeAvatar,

                                    child:
                                        Container(
                                      width:
                                          30,

                                      height:
                                          30,

                                      decoration:
                                          BoxDecoration(
                                        color:
                                            orange,

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
                                            14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            Text(
                              buyerName,

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

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,

                              children: [
                                const Icon(
                                  Icons
                                      .storefront_rounded,

                                  color:
                                      orange,

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
                                    shopName,

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

                            OutlinedButton
                                .icon(
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
                                    orange,

                                side:
                                    const BorderSide(
                                  color:
                                      orange,
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

                      _optionCard(
                        icon:
                            Icons
                                .person_outline_rounded,

                        title:
                            'Personal Details',

                        subtitle:
                            'View your buyer information',

                        onTap:
                            _showPersonalDetails,
                      ),

                      _optionCard(
                        icon:
                            Icons
                                .storefront_outlined,

                        title:
                            'Store Information',

                        subtitle:
                            'Manage your store details',

                        onTap:
                            _showStoreDetails,
                      ),

                      _optionCard(
                        icon:
                            Icons
                                .lock_outline_rounded,

                        title:
                            'Password & Security',

                        subtitle:
                            'Manage your account security',

                        onTap:
                            () {
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

                      _optionCard(
                        icon:
                            Icons
                                .notifications_none_rounded,

                        title:
                            'Notifications',

                        subtitle:
                            'Manage notifications',

                        onTap:
                            () {
                          _showMessage(
                            'Notification settings coming soon.',
                          );
                        },
                      ),

                      _optionCard(
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
                                BorderRadius.circular(
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
                                    ? const SizedBox(
                                        width:
                                            21,
                                        height:
                                            21,
                                        child:
                                            CircularProgressIndicator(
                                          color:
                                              Colors.redAccent,
                                          strokeWidth:
                                              2,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisSize:
                                            MainAxisSize.min,

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
                          'KisanAI • Buyer',

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
      context: context,

      backgroundColor:
          card,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(22),

            child: Column(
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
                  buyerName,
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
  // STORE DETAILS
  // ============================================================

  void _showStoreDetails() {
    showModalBottomSheet(
      context: context,

      backgroundColor:
          card,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(22),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                const Text(
                  'Store Information',

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
                      .storefront_outlined,
                  'Store Name',
                  shopName,
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
      context: context,

      builder: (context) {
        return AlertDialog(
          backgroundColor:
              const Color(
            0xFF181818,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),

          title:
              const Row(
            children: [
              Icon(
                Icons.eco_rounded,
                color:
                    orange,
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
            'A direct agricultural marketplace connecting buyers and farmers.',

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
                      orange,
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

      margin:
          const EdgeInsets.only(
        bottom:
            8,
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
                orange,

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
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    if (!mounted) {
      return;
    }

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