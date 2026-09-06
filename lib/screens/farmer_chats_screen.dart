import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'farmer_chat_screen.dart';

class FarmerChatsScreen extends StatefulWidget {
  const FarmerChatsScreen({
    super.key,
  });

  @override
  State<FarmerChatsScreen> createState() =>
      _FarmerChatsScreenState();
}

// ============================================================
// BUYER PROFILE DATA
// ============================================================

class BuyerProfileData {
  final String name;
  final String avatar;

  const BuyerProfileData({
    required this.name,
    required this.avatar,
  });
}

// ============================================================
// FARMER CHATS SCREEN
// ============================================================

class _FarmerChatsScreenState
    extends State<FarmerChatsScreen> {
  static const Color orange =
      Color(0xFFFF9800);

  static const Color background =
      Color(0xFF050505);

  static const Color card =
      Color(0xFF151515);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // Cache buyer profiles
  final Map<String, BuyerProfileData>
      _profileCache = {};

  // ============================================================
  // GET BUYER PROFILE
  // ============================================================

  Future<BuyerProfileData> _getBuyerProfile(
    String buyerId,
    String fallbackName,
  ) async {
    // ----------------------------------------------------------
    // If we already loaded this buyer
    // ----------------------------------------------------------

    if (_profileCache.containsKey(buyerId)) {
      return _profileCache[buyerId]!;
    }

    // ----------------------------------------------------------
    // No buyer ID
    // ----------------------------------------------------------

    if (buyerId.isEmpty) {
      return BuyerProfileData(
        name: fallbackName.isEmpty
            ? 'Buyer'
            : fallbackName,
        avatar: 'buyer_1',
      );
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(buyerId)
          .get();

      final data = doc.data();

      if (data != null) {
        // ======================================================
        // NAME
        // ======================================================

        String name = '';

        // Your buyer profile normally saves name here
        if (data['name'] != null) {
          name =
              data['name'].toString().trim();
        }

        // Backup fields in case your user document
        // uses another naming convention.
        if (name.isEmpty &&
            data['userName'] != null) {
          name =
              data['userName'].toString().trim();
        }

        if (name.isEmpty &&
            data['username'] != null) {
          name =
              data['username'].toString().trim();
        }

        if (name.isEmpty &&
            data['displayName'] != null) {
          name =
              data['displayName'].toString().trim();
        }

        if (name.isEmpty &&
            data['fullName'] != null) {
          name =
              data['fullName'].toString().trim();
        }

        // Finally use the chat's buyerName
        if (name.isEmpty) {
          name = fallbackName.trim();
        }

        if (name.isEmpty) {
          name = 'Buyer';
        }

        // ======================================================
        // AVATAR
        // ======================================================

        String avatar =
            data['profileAvatar']
                    ?.toString()
                    .trim() ??
                '';

        if (!avatar.startsWith('buyer_')) {
          avatar = 'buyer_1';
        }

        final profile =
            BuyerProfileData(
          name: name,
          avatar: avatar,
        );

        _profileCache[buyerId] =
            profile;

        return profile;
      }
    } catch (e) {
      debugPrint(
        'Error loading buyer profile: $e',
      );
    }

    // ==========================================================
    // FALLBACK
    // ==========================================================

    return BuyerProfileData(
      name: fallbackName.isEmpty
          ? 'Buyer'
          : fallbackName,
      avatar: 'buyer_1',
    );
  }

  // ============================================================
  // TIME FORMAT
  // ============================================================

  String _formatTime(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is! Timestamp) {
      return '';
    }

    final date = value.toDate();

    final now = DateTime.now();

    final isToday =
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    if (isToday) {
      final hour =
          date.hour % 12 == 0
              ? 12
              : date.hour % 12;

      final minute =
          date.minute
              .toString()
              .padLeft(2, '0');

      final period =
          date.hour >= 12
              ? 'PM'
              : 'AM';

      return '$hour:$minute $period';
    }

    return '${date.day}/${date.month}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final user =
        _auth.currentUser;

    // ==========================================================
    // NOT LOGGED IN
    // ==========================================================

    if (user == null) {
      return const Scaffold(
        backgroundColor:
            background,

        body: Center(
          child: Text(
            'Farmer is not logged in',

            style: TextStyle(
              color: Colors.white54,
            ),
          ),
        ),
      );
    }

    // ==========================================================
    // SCREEN
    // ==========================================================

    return Scaffold(
      backgroundColor:
          background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            background,

        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },

          icon:
              const Icon(
            Icons.arrow_back_rounded,

            color:
                Colors.white,
          ),
        ),

        titleSpacing: 0,

        title:
            const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              'Chats',

              style:
                  TextStyle(
                color:
                    Colors.white,

                fontSize:
                    20,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(
              height: 2,
            ),

            Text(
              'Talk with your buyers',

              style:
                  TextStyle(
                color:
                    Colors.white38,

                fontSize:
                    9,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _profileCache.clear();
              });
            },

            icon:
                const Icon(
              Icons.refresh_rounded,

              color:
                  Colors.white54,
            ),
          ),

          IconButton(
            onPressed: () {
              _showInfo();
            },

            icon:
                const Icon(
              Icons.info_outline_rounded,

              color:
                  Colors.white54,
            ),
          ),
        ],
      ),

      // ========================================================
      // CHAT STREAM
      // ========================================================

      body:
          StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
        stream:
            _firestore
                .collection('chats')
                .where(
                  'farmerId',
                  isEqualTo:
                      user.uid,
                )
                .snapshots(),

        builder:
            (
          context,
          snapshot,
        ) {
          // ====================================================
          // ERROR
          // ====================================================

          if (snapshot.hasError) {
            debugPrint(
              'FARMER CHAT ERROR: '
              '${snapshot.error}',
            );

            return Center(
              child:
                  Padding(
                padding:
                    const EdgeInsets.all(
                  30,
                ),

                child:
                    Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,

                  children: [
                    const Icon(
                      Icons
                          .error_outline_rounded,

                      color:
                          Colors.redAccent,

                      size:
                          48,
                    ),

                    const SizedBox(
                      height:
                          14,
                    ),

                    const Text(
                      'Unable to load chats',

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
                      height:
                          8,
                    ),

                    Text(
                      '${snapshot.error}',

                      textAlign:
                          TextAlign.center,

                      style:
                          const TextStyle(
                        color:
                            Colors.white38,

                        fontSize:
                            10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ====================================================
          // LOADING
          // ====================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color:
                    orange,

                strokeWidth:
                    2,
              ),
            );
          }

          // ====================================================
          // GET CHATS
          // ====================================================

          final chats =
              snapshot.data?.docs
                      .toList() ??
                  [];

          // ====================================================
          // SORT NEWEST FIRST
          // ====================================================

          chats.sort(
            (
              a,
              b,
            ) {
              final aData =
                  a.data();

              final bData =
                  b.data();

              final aTime =
                  aData['updatedAt'];

              final bTime =
                  bData['updatedAt'];

              if (aTime is Timestamp &&
                  bTime is Timestamp) {
                return bTime.compareTo(
                  aTime,
                );
              }

              if (aTime is Timestamp) {
                return -1;
              }

              if (bTime is Timestamp) {
                return 1;
              }

              return 0;
            },
          );

          // ====================================================
          // EMPTY
          // ====================================================

          if (chats.isEmpty) {
            return _emptyState();
          }

          // ====================================================
          // LIST
          // ====================================================

          return ListView.builder(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              10,
              16,
              30,
            ),

            itemCount:
                chats.length,

            itemBuilder:
                (
              context,
              index,
            ) {
              final doc =
                  chats[index];

              final data =
                  doc.data();

              return _chatCard(
                chatId:
                    doc.id,

                data:
                    data,
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // CHAT CARD
  // ============================================================

  Widget _chatCard({
    required String chatId,
    required Map<String, dynamic> data,
  }) {
    // ----------------------------------------------------------
    // CHAT DATA
    // ----------------------------------------------------------

    final buyerId =
        data['buyerId']
                ?.toString() ??
            '';

    final fallbackName =
        data['buyerName']
                ?.toString()
                .trim() ??
            '';

    final productName =
        data['productName']
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                true
            ? data['productName']
                .toString()
            : 'Product';

    final lastMessage =
        data['lastMessage']
                ?.toString()
                .trim() ??
            '';

    final updatedAt =
        data['updatedAt'];

    // ----------------------------------------------------------
    // LOAD ACTUAL BUYER PROFILE
    // ----------------------------------------------------------

    return FutureBuilder<
        BuyerProfileData>(
      future:
          _getBuyerProfile(
        buyerId,
        fallbackName,
      ),

      builder:
          (
        context,
        profileSnapshot,
      ) {
        // ------------------------------------------------------
        // USE PROFILE DATA
        // ------------------------------------------------------

        final profile =
            profileSnapshot.data;

        final buyerName =
            profile?.name ??
                (fallbackName.isEmpty
                    ? 'Buyer'
                    : fallbackName);

        final avatar =
            profile?.avatar ??
                'buyer_1';

        // ------------------------------------------------------
        // CARD
        // ------------------------------------------------------

        return Container(
          margin:
              const EdgeInsets.only(
            bottom: 10,
          ),

          decoration:
              BoxDecoration(
            color:
                card,

            borderRadius:
                BorderRadius.circular(
              18,
            ),

            border:
                Border.all(
              color:
                  Colors.white.withValues(
                alpha:
                    .08,
              ),
            ),
          ),

          child:
              InkWell(
            borderRadius:
                BorderRadius.circular(
              18,
            ),

            onTap: () {
              Navigator.push(
                context,

                MaterialPageRoute(
                  builder:
                      (
                    context,
                  ) =>
                      FarmerChatScreen(
                    chatId:
                        chatId,

                    farmerId:
                        data['farmerId']
                                ?.toString() ??
                            '',

                    buyerName:
                        buyerName,

                    productName:
                        productName,
                  ),
                ),
              );
            },

            child:
                Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                14,
                13,
                13,
                13,
              ),

              child:
                  Row(
                children: [
                  // ==================================================
                  // BUYER AVATAR
                  // ==================================================

                  _buildBuyerAvatar(
                    avatar,
                  ),

                  const SizedBox(
                    width:
                        12,
                  ),

                  // ==================================================
                  // TEXT
                  // ==================================================

                  Expanded(
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        // ==========================================
                        // BUYER NAME + TIME
                        // ==========================================

                        Row(
                          children: [
                            Expanded(
                              child:
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
                                      14,

                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(
                              width:
                                  5,
                            ),

                            Text(
                              _formatTime(
                                updatedAt,
                              ),

                              style:
                                  const TextStyle(
                                color:
                                    Colors.white30,

                                fontSize:
                                    8,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height:
                              5,
                        ),

                        // ==========================================
                        // PRODUCT
                        // ==========================================

                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .shopping_basket_outlined,

                              color:
                                  orange,

                              size:
                                  13,
                            ),

                            const SizedBox(
                              width:
                                  5,
                            ),

                            Expanded(
                              child:
                                  Text(
                                productName,

                                maxLines:
                                    1,

                                overflow:
                                    TextOverflow
                                        .ellipsis,

                                style:
                                    const TextStyle(
                                  color:
                                      orange,

                                  fontSize:
                                      10,

                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height:
                              5,
                        ),

                        // ==========================================
                        // LAST MESSAGE
                        // ==========================================

                        Text(
                          lastMessage.isEmpty
                              ? 'Start chatting'
                              : lastMessage,

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
                                10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width:
                        5,
                  ),

                  // ==================================================
                  // ARROW
                  // ==================================================

                  const Icon(
                    Icons
                        .chevron_right_rounded,

                    color:
                        Colors.white30,

                    size:
                        22,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUYER AVATAR
  // ============================================================

  Widget _buildBuyerAvatar(
    String avatar,
  ) {
    return Container(
      width:
          54,

      height:
          54,

      decoration:
          BoxDecoration(
        shape:
            BoxShape.circle,

        color:
            orange.withValues(
          alpha:
              .10,
        ),

        border:
            Border.all(
          color:
              orange.withValues(
            alpha:
                .40,
          ),

          width:
              1.5,
        ),
      ),

      child:
          ClipOval(
        child:
            Image.asset(
          'assets/avatars/$avatar.png',

          width:
              54,

          height:
              54,

          fit:
              BoxFit.cover,

          errorBuilder:
              (
            context,
            error,
            stackTrace,
          ) {
            return const Icon(
              Icons
                  .person_rounded,

              color:
                  orange,

              size:
                  28,
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Center(
      child:
          Column(
        mainAxisAlignment:
            MainAxisAlignment
                .center,

        children: [
          Container(
            width:
                75,

            height:
                75,

            decoration:
                BoxDecoration(
              color:
                  orange.withValues(
                alpha:
                    .10,
              ),

              shape:
                  BoxShape.circle,
            ),

            child:
                const Icon(
              Icons
                  .chat_bubble_outline_rounded,

              color:
                  orange,

              size:
                  34,
            ),
          ),

          const SizedBox(
            height:
                18,
          ),

          const Text(
            'No chats yet',

            style:
                TextStyle(
              color:
                  Colors.white,

              fontSize:
                  17,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height:
                7,
          ),

          const Text(
            'Chats with buyers will appear here.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  Colors.white38,

              fontSize:
                  11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO
  // ============================================================

  void _showInfo() {
    showDialog(
      context:
          context,

      builder:
          (context) {
        return AlertDialog(
          backgroundColor:
              card,

          title:
              const Text(
            'Buyer Chats',

            style:
                TextStyle(
              color:
                  Colors.white,
            ),
          ),

          content:
              const Text(
            'Your buyers appear here with their selected profile avatar and name.',

            style:
                TextStyle(
              color:
                  Colors.white60,
              fontSize:
                  13,
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
                'OK',

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
}