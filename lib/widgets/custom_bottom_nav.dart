import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/farmer_chats_screen.dart';
import '../screens/role_screen.dart';

class CustomHeader extends StatelessWidget {
  final String farmerName;

  const CustomHeader({
    super.key,
    required this.farmerName,
  });

  // ============================================================
  // COLORS
  // ============================================================

  static const Color green =
      Color(0xFF017422);

  static const Color background =
      Color(0xFF0B0B0B);

  static const Color card =
      Color(0xFF181818);

  // ============================================================
  // MENU
  // ============================================================

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: card,
      isScrollControlled: true,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),

      builder: (context) {
        final screenHeight =
            MediaQuery.of(context)
                .size
                .height;

        return SafeArea(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(
              maxHeight:
                  screenHeight * 0.78,
            ),

            child:
                SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),

              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  20,
                ),

                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    // ==================================================
                    // HANDLE
                    // ==================================================

                    Container(
                      width: 45,
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

                    // ==================================================
                    // TITLE
                    // ==================================================

                    const Align(
                      alignment:
                          Alignment
                              .centerLeft,

                      child: Text(
                        'Menu',

                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // CHAT
                    // ==================================================

                    _menuItem(
                      context,
                      Icons
                          .chat_bubble_outline_rounded,
                      'Chat with Buyers',
                      () {
                        Navigator.pop(
                          context,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const FarmerChatsScreen(),
                          ),
                        );
                      },
                    ),

                    // ==================================================
                    // PRODUCTS
                    // ==================================================

                    _menuItem(
                      context,
                      Icons
                          .inventory_2_outlined,
                      'My Products',
                      () {
                        Navigator.pop(
                          context,
                        );

                        // Add your farmer products
                        // navigation here later.
                      },
                    ),

                    // ==================================================
                    // ANALYTICS
                    // ==================================================

                    _menuItem(
                      context,
                      Icons
                          .analytics_outlined,
                      'Analytics',
                      () {
                        Navigator.pop(
                          context,
                        );

                        // Add your analytics
                        // navigation here later.
                      },
                    ),

                    // ==================================================
                    // ORDERS
                    // ==================================================

                    _menuItem(
                      context,
                      Icons
                          .shopping_bag_outlined,
                      'Orders',
                      () {
                        Navigator.pop(
                          context,
                        );

                        // Add farmer orders
                        // navigation here later.
                      },
                    ),

                    // ==================================================
                    // SETTINGS
                    // ==================================================

                    _menuItem(
                      context,
                      Icons
                          .settings_outlined,
                      'Settings',
                      () {
                        Navigator.pop(
                          context,
                        );

                        // Add settings screen
                        // later.
                      },
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    const Divider(
                      color:
                          Colors.white12,
                      height: 20,
                    ),

                    // ==================================================
                    // LOGOUT
                    // ==================================================

                    ListTile(
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 4,
                      ),

                      leading:
                          Container(
                        width: 42,
                        height: 42,

                        decoration:
                            BoxDecoration(
                          color: Colors
                              .redAccent
                              .withValues(
                            alpha: 0.10,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),

                        child:
                            const Icon(
                          Icons
                              .logout_rounded,
                          color:
                              Colors.redAccent,
                          size: 22,
                        ),
                      ),

                      title:
                          const Text(
                        'Logout',

                        style:
                            TextStyle(
                          color:
                              Colors.redAccent,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      subtitle:
                          const Text(
                        'Sign out of your account',

                        style:
                            TextStyle(
                          color:
                              Colors.white30,
                          fontSize: 10,
                        ),
                      ),

                      trailing:
                          const Icon(
                        Icons
                            .arrow_forward_ios_rounded,
                        color:
                            Colors.white30,
                        size: 15,
                      ),

                      onTap: () {
                        Navigator.pop(
                          context,
                        );

                        _showLogoutDialog(
                          context,
                        );
                      },
                    ),

                    const SizedBox(
                      height: 5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MENU ITEM
  // ============================================================

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 4,
      ),

      leading:
          Container(
        width: 42,
        height: 42,

        decoration:
            BoxDecoration(
          color:
              green.withValues(
            alpha: 0.10,
          ),

          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),

        child: Icon(
          icon,
          color: green,
          size: 21,
        ),
      ),

      title:
          Text(
        title,

        style:
            const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight:
              FontWeight.w600,
        ),
      ),

      trailing:
          const Icon(
        Icons
            .arrow_forward_ios_rounded,
        color: Colors.white24,
        size: 14,
      ),

      onTap: onTap,
    );
  }

  // ============================================================
  // LOGOUT CONFIRMATION
  // ============================================================

  void _showLogoutDialog(
    BuildContext context,
  ) {
    showDialog(
      context: context,

      builder:
          (dialogContext) {
        return AlertDialog(
          backgroundColor:
              card,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),

          title:
              const Text(
            'Logout?',

            style:
                TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          content:
              const Text(
            'Are you sure you want to logout from Vidhai?',

            style:
                TextStyle(
              color: Colors.white54,
              fontSize: 12,
              height: 1.4,
            ),
          ),

          actions: [
            // ==================================================
            // CANCEL
            // ==================================================

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
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

            // ==================================================
            // LOGOUT
            // ==================================================

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                _logout(
                  context,
                );
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,

                foregroundColor:
                    Colors.white,

                elevation: 0,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
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
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(
    BuildContext context,
  ) async {
    try {
      await FirebaseAuth
          .instance
          .signOut();

      if (!context.mounted) {
        return;
      }

      // ========================================================
      // CLEAR ENTIRE NAVIGATION STACK
      // ========================================================

      Navigator.pushAndRemoveUntil(
        context,

        MaterialPageRoute(
          builder: (_) =>
              const RoleScreen(),
        ),

        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to logout. Please try again.',
          ),

          backgroundColor:
              Colors.redAccent,

          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // BUILD HEADER
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        10,
      ),

      color: background,

      child: Row(
        children: [
          // ======================================================
          // FARMER ICON
          // ======================================================

          Container(
            width: 48,
            height: 48,

            decoration:
                BoxDecoration(
              color:
                  green.withValues(
                alpha: 0.12,
              ),

              shape:
                  BoxShape.circle,

              border:
                  Border.all(
                color:
                    green.withValues(
                  alpha: 0.25,
                ),
              ),
            ),

            child:
                const Icon(
              Icons
                  .agriculture_rounded,
              color: green,
              size: 25,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // ======================================================
          // NAME
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                const Text(
                  'Welcome back',

                  style:
                      TextStyle(
                    color:
                        Colors.white38,
                    fontSize: 9,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  farmerName,

                  maxLines: 1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // NOTIFICATION
          // ======================================================

          IconButton(
            onPressed: () {},

            icon:
                const Icon(
              Icons
                  .notifications_none_rounded,
              color:
                  Colors.white70,
              size: 25,
            ),
          ),

          // ======================================================
          // HAMBURGER
          // ======================================================

          Container(
            width: 42,
            height: 42,

            decoration:
                BoxDecoration(
              color:
                  card,

              borderRadius:
                  BorderRadius.circular(
                12,
              ),

              border:
                  Border.all(
                color:
                    Colors.white
                        .withValues(
                  alpha: 0.06,
                ),
              ),
            ),

            child: IconButton(
              padding:
                  EdgeInsets.zero,

              onPressed: () {
                _showMenu(
                  context,
                );
              },

              icon:
                  const Icon(
                Icons
                    .menu_rounded,
                color:
                    Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}