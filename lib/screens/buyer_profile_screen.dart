import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({
    super.key,
  });

  @override
  State<BuyerProfileScreen> createState() =>
      _BuyerProfileScreenState();
}

class _BuyerProfileScreenState
    extends State<BuyerProfileScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange =
      Color(0xFFFF9800);

  static const Color background =
      Color(0xFF050505);

  static const Color card =
      Color(0xFF151515);

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // DATA
  // ============================================================

  String buyerName = 'Buyer';

  String email = '';

  String shopName = 'My Store';

  String selectedAvatar = 'buyer_1';

  bool loading = true;

  // ============================================================
  // ANIMATION
  // ============================================================

  late AnimationController _avatarController;

  late Animation<double> _avatarAnimation;

  @override
  void initState() {
    super.initState();

    _avatarController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(
        seconds: 2,
      ),
    );

    _avatarAnimation =
        Tween<double>(
      begin: -3,
      end: 3,
    ).animate(
      CurvedAnimation(
        parent: _avatarController,
        curve: Curves.easeInOut,
      ),
    );

    _avatarController.repeat(
      reverse: true,
    );

    _loadProfile();
  }

  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
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
          loading = false;
        });
      }
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final data = doc.data();

      if (data != null) {
        final name =
            data['name']?.toString() ?? '';

        final store =
            data['shopName']?.toString() ?? '';

        final avatar =
            data['profileAvatar']?.toString() ??
                '';

        setState(() {
          buyerName =
              name.trim().isEmpty
                  ? 'Buyer'
                  : name.trim();

          shopName =
              store.trim().isEmpty
                  ? 'My Store'
                  : store.trim();

          email =
              user.email ?? '';

          if (avatar.startsWith('buyer_')) {
            selectedAvatar = avatar;
          }

          loading = false;
        });
      } else {
        setState(() {
          buyerName = 'Buyer';
          email = user.email ?? '';
          loading = false;
        });
      }
    } catch (e) {
      debugPrint(
        'Profile loading error: $e',
      );

      if (!mounted) return;

      setState(() {
        email = user.email ?? '';
        loading = false;
      });
    }
  }

  // ============================================================
  // SAVE AVATAR
  // ============================================================

  Future<void> _saveAvatar(
    String avatar,
  ) async {
    final user =
        _auth.currentUser;

    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'profileAvatar': avatar,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      if (!mounted) return;

      setState(() {
        selectedAvatar = avatar;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Avatar updated successfully'),
          backgroundColor:
              Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Unable to update avatar'),
          backgroundColor:
              Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // AVATAR PICKER
  // ============================================================

  void _openAvatarPicker() {
    String temporaryAvatar =
        selectedAvatar;

    showModalBottomSheet(
      context: context,
      backgroundColor: card,
      isScrollControlled: true,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),

      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  25,
                ),

                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    // HANDLE
                    Container(
                      width: 42,
                      height: 4,

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white24,

                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    const Text(
                      'Choose Your Avatar',
                      style:
                          TextStyle(
                        color:
                            Colors.white,

                        fontSize: 19,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    const Text(
                      'Pick an avatar for your buyer profile',
                      style:
                          TextStyle(
                        color:
                            Colors.white54,

                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // PREVIEW
                    AnimatedBuilder(
                      animation:
                          _avatarAnimation,

                      builder:
                          (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            0,
                            _avatarAnimation
                                .value,
                          ),
                          child: child,
                        );
                      },

                      child: _avatarImage(
                        temporaryAvatar,
                        100,
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // FIVE AVATARS
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,

                      children:
                          List.generate(
                        5,
                        (index) {
                          final avatar =
                              'buyer_${index + 1}';

                          final selected =
                              temporaryAvatar ==
                                  avatar;

                          return GestureDetector(
                            onTap: () {
                              setModalState(
                                () {
                                  temporaryAvatar =
                                      avatar;
                                },
                              );
                            },

                            child:
                                AnimatedScale(
                              scale:
                                  selected
                                      ? 1.08
                                      : 1.0,

                              duration:
                                  const Duration(
                                milliseconds:
                                    180,
                              ),

                              child:
                                  Stack(
                                clipBehavior:
                                    Clip.none,

                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,

                                    padding:
                                        const EdgeInsets
                                            .all(
                                      2,
                                    ),

                                    decoration:
                                        BoxDecoration(
                                      shape:
                                          BoxShape.circle,

                                      border:
                                          Border.all(
                                        color:
                                            selected
                                                ? orange
                                                : Colors
                                                    .white12,

                                        width:
                                            selected
                                                ? 2.5
                                                : 1,
                                      ),
                                    ),

                                    child:
                                        ClipOval(
                                      child:
                                          Image.asset(
                                        'assets/avatars/$avatar.png',

                                        fit:
                                            BoxFit.cover,

                                        errorBuilder:
                                            (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            color:
                                                const Color(
                                              0xFF222222,
                                            ),
                                            child:
                                                const Icon(
                                              Icons
                                                  .person_rounded,
                                              color:
                                                  orange,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  if (selected)
                                    Positioned(
                                      right:
                                          -3,
                                      top:
                                          -4,

                                      child:
                                          Container(
                                        width:
                                            20,
                                        height:
                                            20,

                                        decoration:
                                            const BoxDecoration(
                                          color:
                                              orange,
                                          shape:
                                              BoxShape.circle,
                                        ),

                                        child:
                                            const Icon(
                                          Icons
                                              .check_rounded,
                                          color:
                                              Colors.black,
                                          size:
                                              13,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    // SAVE
                    SizedBox(
                      width:
                          double.infinity,

                      height: 50,

                      child:
                          ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(
                            context,
                          );

                          await _saveAvatar(
                            temporaryAvatar,
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
            );
          },
        );
      },
    );
  }

  // ============================================================
  // AVATAR IMAGE
  // ============================================================

  Widget _avatarImage(
    String avatar,
    double size,
  ) {
    return Container(
      width: size,
      height: size,

      decoration:
          BoxDecoration(
        shape:
            BoxShape.circle,

        border:
            Border.all(
          color: orange,
          width: 3,
        ),

        boxShadow: [
          BoxShadow(
            color:
                orange.withValues(
              alpha: .25,
            ),

            blurRadius: 18,

            spreadRadius: 2,
          ),
        ],
      ),

      child:
          ClipOval(
        child:
            Image.asset(
          'assets/avatars/$avatar.png',

          width: size,
          height: size,

          fit: BoxFit.cover,

          errorBuilder:
              (
            context,
            error,
            stackTrace,
          ) {
            return Container(
              color:
                  const Color(0xFF1A1A1A),

              child:
                  const Icon(
                Icons.person_rounded,
                color: orange,
                size: 42,
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // OPTION
  // ============================================================

  Widget _option({
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
                      orange.withValues(
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
                  color: orange,
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

                      maxLines: 1,

                      overflow:
                          TextOverflow.ellipsis,

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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    try {
      await _auth.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/role',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Logout failed: $e'),
          backgroundColor:
              Colors.redAccent,
        ),
      );
    }
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

      body:
          loading
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color: orange,
                    strokeWidth: 2,
                  ),
                )
              : SafeArea(
                  child:
                      RefreshIndicator(
                    color: orange,

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
                        18,
                        16,
                        30,
                      ),

                      children: [
                        // ==================================================
                        // HEADER
                        // ==================================================

                        Row(
                          children: [
                            const Expanded(
                              child:
                                  Text(
                                'My Profile',

                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,

                                  fontSize:
                                      23,

                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

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

                        const SizedBox(
                          height: 15,
                        ),

                        // ==================================================
                        // PROFILE CARD
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
                                alpha: .15,
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
                                  AnimatedBuilder(
                                    animation:
                                        _avatarAnimation,

                                    builder:
                                        (
                                      context,
                                      child,
                                    ) {
                                      return Transform.translate(
                                        offset:
                                            Offset(
                                          0,
                                          _avatarAnimation
                                              .value,
                                        ),
                                        child:
                                            child,
                                      );
                                    },

                                    child:
                                        _avatarImage(
                                      selectedAvatar,
                                      105,
                                    ),
                                  ),

                                  Positioned(
                                    right:
                                        0,

                                    bottom:
                                        0,

                                    child:
                                        GestureDetector(
                                      onTap:
                                          _openAvatarPicker,

                                      child:
                                          Container(
                                        width:
                                            32,

                                        height:
                                            32,

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
                                              15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 16,
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
                                      21,

                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 6,
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
                                        15,
                                  ),

                                  const SizedBox(
                                    width: 5,
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
                                  height: 4,
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
                                height: 17,
                              ),

                              OutlinedButton
                                  .icon(
                                onPressed:
                                    _openAvatarPicker,

                                icon:
                                    const Icon(
                                  Icons
                                      .face_rounded,

                                  size:
                                      18,
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
                                        BorderRadius.circular(
                                      12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 24,
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
                                16,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        _option(
                          icon:
                              Icons
                                  .person_outline_rounded,

                          title:
                              'Personal Details',

                          subtitle:
                              'View your buyer information',

                          onTap: () {
                            _showDetails(
                              'Personal Details',
                              [
                                [
                                  'Name',
                                  buyerName,
                                ],
                                [
                                  'Email',
                                  email.isEmpty
                                      ? 'Not available'
                                      : email,
                                ],
                              ],
                            );
                          },
                        ),

                        _option(
                          icon:
                              Icons
                                  .storefront_outlined,

                          title:
                              'Store Information',

                          subtitle:
                              'Manage your store details',

                          onTap: () {
                            _showDetails(
                              'Store Information',
                              [
                                [
                                  'Store',
                                  shopName,
                                ],
                              ],
                            );
                          },
                        ),

                        _option(
                          icon:
                              Icons
                                  .lock_outline_rounded,

                          title:
                              'Security',

                          subtitle:
                              'Manage your account security',

                          onTap: () {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content:
                                    Text(
                                  'Security settings coming soon.',
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(
                          height: 15,
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
                                16,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        _option(
                          icon:
                              Icons
                                  .notifications_none_rounded,

                          title:
                              'Notifications',

                          subtitle:
                              'Manage your notifications',

                          onTap: () {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content:
                                    Text(
                                  'Notification settings coming soon.',
                                ),
                              ),
                            );
                          },
                        ),

                        _option(
                          icon:
                              Icons
                                  .info_outline_rounded,

                          title:
                              'About Vidhai',

                          subtitle:
                              'Direct farmer-to-buyer marketplace',

                          onTap: () {
                            showAboutDialog(
                              context:
                                  context,

                              applicationName:
                                  'Vidhai',

                              applicationVersion:
                                  '1.0.0',

                              applicationIcon:
                                  const Icon(
                                Icons
                                    .eco_rounded,

                                color:
                                    orange,

                                size:
                                    35,
                              ),

                              children: const [
                                Text(
                                  'Vidhai connects buyers directly with farmers.',
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        // ==================================================
                        // LOGOUT
                        // ==================================================

                        GestureDetector(
                          onTap:
                              _logout,

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
                                alpha: .08,
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
                                  alpha: .30,
                                ),
                              ),
                            ),

                            child:
                                const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,

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
                                  width: 8,
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

                        const SizedBox(
                          height: 18,
                        ),

                        const Center(
                          child:
                              Text(
                            'Vidhai • Buyer',

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
                ),
    );
  }

  // ============================================================
  // DETAILS BOTTOM SHEET
  // ============================================================

  void _showDetails(
    String title,
    List<List<String>> details,
  ) {
    showModalBottomSheet(
      context: context,

      backgroundColor:
          card,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),

      builder: (context) {
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
                Text(
                  title,

                  style:
                      const TextStyle(
                    color:
                        Colors.white,

                    fontSize:
                        19,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                ...details.map(
                  (item) {
                    return Container(
                      width:
                          double.infinity,

                      margin:
                          const EdgeInsets.only(
                        bottom: 8,
                      ),

                      padding:
                          const EdgeInsets.all(
                        13,
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
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Text(
                            item[0],

                            style:
                                const TextStyle(
                              color:
                                  Colors.white38,

                              fontSize:
                                  9,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            item[1],

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
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(
                  height: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}