import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';

class FarmerChatScreen extends StatefulWidget {
  final String chatId;
  final String farmerId;

  // Existing fallback values
  final String buyerName;
  final String productName;

  const FarmerChatScreen({
    super.key,
    required this.chatId,
    required this.farmerId,
    required this.buyerName,
    required this.productName,
  });

  @override
  State<FarmerChatScreen> createState() =>
      _FarmerChatScreenState();
}

class _FarmerChatScreenState
    extends State<FarmerChatScreen> {
  // ============================================================
  // SERVICES
  // ============================================================

  final ChatService _chatService =
      ChatService();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _messageController =
      TextEditingController();

  final TextEditingController _counterController =
      TextEditingController(text: '56');

  final ScrollController _scrollController =
      ScrollController();

  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange =
      Color(0xFFFF9800);

  static const Color green =
      Color(0xFF4CAF32);

  static const Color background =
      Color(0xFF050505);

  static const Color card =
      Color(0xFF151817);

  static const Color cardLight =
      Color(0xFF1D211F);

  // ============================================================
  // STATE
  // ============================================================

  bool _sending = false;

  String _buyerName = 'Buyer';
  String _buyerAvatar = 'buyer_1';

  bool _profileLoaded = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _buyerName =
        widget.buyerName.isEmpty
            ? 'Buyer'
            : widget.buyerName;

    _loadBuyerProfile();
  }

  // ============================================================
  // LOAD BUYER PROFILE
  // ============================================================

  Future<void> _loadBuyerProfile() async {
    try {
      final chatDoc = await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .get();

      final chatData =
          chatDoc.data();

      if (chatData == null) {
        return;
      }

      // --------------------------------------------------------
      // GET BUYER ID FROM CHAT
      // --------------------------------------------------------

      final buyerId =
          chatData['buyerId']
                  ?.toString()
                  .trim() ??
              '';

      // --------------------------------------------------------
      // FALLBACK CHAT NAME
      // --------------------------------------------------------

      final fallbackName =
          chatData['buyerName']
                  ?.toString()
                  .trim() ??
              '';

      if (fallbackName.isNotEmpty) {
        _buyerName = fallbackName;
      }

      // --------------------------------------------------------
      // GET USER PROFILE
      // --------------------------------------------------------

      if (buyerId.isNotEmpty) {
        final userDoc = await _firestore
            .collection('users')
            .doc(buyerId)
            .get();

        final userData =
            userDoc.data();

        if (userData != null) {
          String name = '';

          // Try name
          if (userData['name'] != null) {
            name =
                userData['name']
                    .toString()
                    .trim();
          }

          // Try userName
          if (name.isEmpty &&
              userData['userName'] != null) {
            name =
                userData['userName']
                    .toString()
                    .trim();
          }

          // Try username
          if (name.isEmpty &&
              userData['username'] != null) {
            name =
                userData['username']
                    .toString()
                    .trim();
          }

          // Try displayName
          if (name.isEmpty &&
              userData['displayName'] != null) {
            name =
                userData['displayName']
                    .toString()
                    .trim();
          }

          // Try fullName
          if (name.isEmpty &&
              userData['fullName'] != null) {
            name =
                userData['fullName']
                    .toString()
                    .trim();
          }

          if (name.isNotEmpty) {
            _buyerName = name;
          }

          // ----------------------------------------------------
          // AVATAR
          // ----------------------------------------------------

          final avatar =
              userData['profileAvatar']
                      ?.toString()
                      .trim() ??
                  '';

          if (avatar.startsWith('buyer_')) {
            _buyerAvatar = avatar;
          }
        }
      }
    } catch (e) {
      debugPrint(
        'Unable to load buyer profile: $e',
      );
    }

    if (mounted) {
      setState(() {
        _profileLoaded = true;
      });
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _messageController.dispose();
    _counterController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> _sendMessage() async {
    if (_sending) return;

    final message =
        _messageController.text.trim();

    if (message.isEmpty) {
      return;
    }

    final user =
        _auth.currentUser;

    if (user == null) {
      _showError(
        'Farmer is not logged in.',
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    _messageController.clear();

    try {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: user.uid,
        senderName: 'Farmer',
        message: message,
      );

      _scrollToBottom();
    } catch (e) {
      _messageController.text =
          message;

      _showError(
        'Unable to send message.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
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

      resizeToAvoidBottomInset:
          true,

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
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
        ),

        titleSpacing: 0,

        title: Row(
          children: [
            // ==================================================
            // BUYER AVATAR
            // ==================================================

            _buildBuyerAvatar(
              _buyerAvatar,
            ),

            const SizedBox(
              width: 10,
            ),

            // ==================================================
            // BUYER NAME
            // ==================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _buyerName,

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          15,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  const Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color:
                            Colors.green,
                        size: 6,
                      ),

                      SizedBox(
                        width: 5,
                      ),

                      Text(
                        'Buyer',
                        style:
                            TextStyle(
                          color:
                              Colors.white54,
                          fontSize:
                              9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed:
                _loadBuyerProfile,

            icon:
                const Icon(
              Icons.refresh_rounded,
              color:
                  Colors.white54,
              size: 21,
            ),
          ),

          IconButton(
            onPressed:
                _showChatInfo,

            icon:
                const Icon(
              Icons.more_vert_rounded,
              color:
                  Colors.white70,
            ),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Column(
        children: [
          _buildProductHeader(),

          Expanded(
            child:
                StreamBuilder<
                    DocumentSnapshot<
                        Map<String,
                            dynamic>>>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .snapshots(),

              builder:
                  (
                context,
                chatSnapshot,
              ) {
                final chatData =
                    chatSnapshot
                            .data
                            ?.data() ??
                        {};

                return StreamBuilder<
                    QuerySnapshot<
                        Map<String,
                            dynamic>>>(
                  stream:
                      _chatService
                          .messagesStream(
                    widget.chatId,
                  ),

                  builder:
                      (
                    context,
                    snapshot,
                  ) {
                    if (snapshot.hasError) {
                      return _buildError(
                        'Unable to load messages.',
                      );
                    }

                    if (snapshot
                            .connectionState ==
                        ConnectionState
                            .waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(
                          color:
                              orange,
                        ),
                      );
                    }

                    final messages =
                        snapshot.data
                                ?.docs
                                .toList() ??
                            [];

                    // ------------------------------------------
                    // SORT
                    // ------------------------------------------

                    messages.sort(
                      (a, b) {
                        final aTime =
                            a.data()[
                                'createdAt'];

                        final bTime =
                            b.data()[
                                'createdAt'];

                        if (aTime == null &&
                            bTime == null) {
                          return 0;
                        }

                        if (aTime == null) {
                          return 1;
                        }

                        if (bTime == null) {
                          return -1;
                        }

                        if (aTime
                                is Timestamp &&
                            bTime
                                is Timestamp) {
                          return aTime.compareTo(
                            bTime,
                          );
                        }

                        return 0;
                      },
                    );

                    WidgetsBinding
                        .instance
                        .addPostFrameCallback(
                      (_) {
                        _scrollToBottom();
                      },
                    );

                    return ListView(
                      controller:
                          _scrollController,

                      physics:
                          const BouncingScrollPhysics(),

                      padding:
                          const EdgeInsets.fromLTRB(
                        14,
                        10,
                        14,
                        15,
                      ),

                      children: [
                        _todayChip(),

                        const SizedBox(
                          height: 10,
                        ),

                        if (messages.isEmpty)
                          _buildEmptyChat(),

                        // ==================================================
                        // MESSAGES
                        // ==================================================

                        ...messages.map(
                          (doc) {
                            final data =
                                doc.data();

                            final senderId =
                                data[
                                    'senderId'];

                            final message =
                                data[
                                        'message']
                                    ?.toString() ??
                                    '';

                            final timestamp =
                                data[
                                    'createdAt'];

                            final currentUser =
                                _auth
                                    .currentUser;

                            final isFarmer =
                                currentUser !=
                                        null &&
                                    senderId ==
                                        currentUser
                                            .uid;

                            return _messageBubble(
                              message,
                              isFarmer,
                              timestamp,
                            );
                          },
                        ),

                        // ==================================================
                        // BUYER OFFER
                        // ==================================================

                        if (chatData[
                                'negotiationStatus'] ==
                            'buyer_offered')
                          _buildBuyerOfferCard(
                            chatData,
                          ),

                        // ==================================================
                        // FARMER COUNTER
                        // ==================================================

                        if (chatData[
                                'negotiationStatus'] ==
                            'farmer_countered')
                          _buildFarmerCounterStatus(
                            chatData,
                          ),

                        // ==================================================
                        // ACCEPTED DEAL
                        // ==================================================

                        if (chatData[
                                'negotiationStatus'] ==
                            'accepted')
                          _buildDealAcceptedCard(
                            chatData,
                          ),

                        const SizedBox(
                          height: 8,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          _buildInput(),
        ],
      ),
    );
  }

  // ============================================================
  // BUYER AVATAR
  // ============================================================

  Widget _buildBuyerAvatar(
    String avatar,
  ) {
    return Container(
      width: 43,
      height: 43,

      decoration:
          BoxDecoration(
        shape:
            BoxShape.circle,

        color:
            orange.withValues(
          alpha: .10,
        ),

        border:
            Border.all(
          color:
              orange.withValues(
            alpha: .45,
          ),

          width: 1.3,
        ),
      ),

      child:
          ClipOval(
        child:
            Image.asset(
          'assets/avatars/$avatar.png',

          width: 43,
          height: 43,

          fit:
              BoxFit.cover,

          errorBuilder:
              (
            context,
            error,
            stackTrace,
          ) {
            return const Icon(
              Icons.person_rounded,
              color: orange,
              size: 25,
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT HEADER
  // ============================================================

  Widget _buildProductHeader() {
    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.fromLTRB(
        14,
        3,
        14,
        7,
      ),

      padding:
          const EdgeInsets.all(11),

      decoration:
          BoxDecoration(
        color: card,

        borderRadius:
            BorderRadius.circular(14),

        border:
            Border.all(
          color:
              orange.withValues(
            alpha: .18,
          ),
        ),
      ),

      child:
          Row(
        children: [
          Container(
            width: 43,
            height: 43,

            decoration:
                BoxDecoration(
              color:
                  orange.withValues(
                alpha: .10,
              ),

              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),

            child:
                const Icon(
              Icons.eco_rounded,
              color: orange,
              size: 24,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                const Text(
                  'Chatting about',

                  style:
                      TextStyle(
                    color:
                        Colors.white38,
                    fontSize:
                        8,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  widget.productName,

                  maxLines: 1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        13,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                const Text(
                  'Buyer negotiation',

                  style:
                      TextStyle(
                    color: orange,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chat_rounded,
            color:
                Colors.white30,
            size: 18,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _messageBubble(
    String message,
    bool isFarmer,
    dynamic timestamp,
  ) {
    return Align(
      alignment:
          isFarmer
              ? Alignment.centerRight
              : Alignment.centerLeft,

      child: Container(
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.of(context)
                      .size
                      .width *
                  .76,
        ),

        margin:
            const EdgeInsets.only(
          bottom: 8,
        ),

        padding:
            const EdgeInsets.fromLTRB(
          13,
          10,
          13,
          7,
        ),

        decoration:
            BoxDecoration(
          // FARMER = GREEN
          // BUYER = ORANGE
          color:
              isFarmer
                  ? green
                  : orange,

          borderRadius:
              BorderRadius.only(
            topLeft:
                const Radius.circular(
              16,
            ),

            topRight:
                const Radius.circular(
              16,
            ),

            bottomLeft:
                Radius.circular(
              isFarmer ? 16 : 3,
            ),

            bottomRight:
                Radius.circular(
              isFarmer ? 3 : 16,
            ),
          ),
        ),

        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .end,

          children: [
            Align(
              alignment:
                  Alignment.centerLeft,

              child:
                  Text(
                message,

                style:
                    TextStyle(
                  color:
                      Colors.black,

                  fontSize:
                      13,

                  height:
                      1.3,
                ),
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            Text(
              _formatTime(
                timestamp,
              ),

              style:
                  const TextStyle(
                color:
                    Colors.black54,
                fontSize:
                    8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUYER OFFER CARD
  // ============================================================

  Widget _buildBuyerOfferCard(
    Map<String, dynamic> data,
  ) {
    final offer =
        _readDouble(
      data['buyerOffer'],
      52,
    );

    final quantity =
        _readDouble(
      data['negotiationQuantity'],
      20,
    );

    final total =
        offer * quantity;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(15),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFF181205),

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color: orange,
          width: 1.4,
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          const Row(
            children: [
              Icon(
                Icons.handshake_rounded,
                color: orange,
                size: 23,
              ),

              SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                    Text(
                  'Buyer Offer',

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
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Container(
            padding:
                const EdgeInsets.all(
              12,
            ),

            decoration:
                BoxDecoration(
              color:
                  card,

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child:
                Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          _detailItem(
                        'Product',
                        widget.productName,
                      ),
                    ),

                    Expanded(
                      child:
                          _detailItem(
                        'Buyer Offer',
                        '₹${offer.toStringAsFixed(0)}/kg',
                        valueColor:
                            orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          _detailItem(
                        'Quantity',
                        '${_formatQuantity(quantity)} kg',
                      ),
                    ),

                    Expanded(
                      child:
                          _detailItem(
                        'Total',
                        '₹${total.toStringAsFixed(0)}',
                        valueColor:
                            green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _actionButton(
                  text:
                      'Accept ₹${offer.toStringAsFixed(0)}',
                  color:
                      green,
                  onTap:
                      () {
                    _acceptBuyerOffer(
                      offer,
                      quantity,
                    );
                  },
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Expanded(
                child:
                    _actionButton(
                  text:
                      'Counter',
                  color:
                      orange,
                  onTap:
                      () {
                    _showCounterDialog(
                      quantity,
                    );
                  },
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Expanded(
                child:
                    _actionButton(
                  text:
                      'Reject',
                  color:
                      Colors.redAccent,
                  onTap:
                      _rejectOffer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FARMER COUNTER
  // ============================================================

  Widget _buildFarmerCounterStatus(
    Map<String, dynamic> data,
  ) {
    final counter =
        _readDouble(
      data['farmerCounterOffer'],
      56,
    );

    final quantity =
        _readDouble(
      data['negotiationQuantity'],
      20,
    );

    final total =
        counter * quantity;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(
        15,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFF111008),

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              orange.withValues(
            alpha: .55,
          ),
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          const Row(
            children: [
              Icon(
                Icons.reply_rounded,
                color: orange,
                size: 23,
              ),

              SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                    Text(
                  'Your Counter Offer',

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
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            '₹${counter.toStringAsFixed(0)}/kg',

            style:
                const TextStyle(
              color: orange,
              fontSize: 25,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            '${_formatQuantity(quantity)} kg × '
            '₹${counter.toStringAsFixed(0)} = '
            '₹${total.toStringAsFixed(0)}',

            style:
                const TextStyle(
              color:
                  Colors.white60,
              fontSize:
                  11,
            ),
          ),

          const SizedBox(
            height: 9,
          ),

          const Text(
            'Waiting for buyer response...',

            style:
                TextStyle(
              color: orange,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DEAL ACCEPTED
  // ============================================================

  Widget _buildDealAcceptedCard(
    Map<String, dynamic> data,
  ) {
    final price =
        _readDouble(
      data['dealPrice'],
      56,
    );

    final quantity =
        _readDouble(
      data['dealQuantity'],
      20,
    );

    final total =
        price * quantity;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFF081A0B),

        borderRadius:
            BorderRadius.circular(
          19,
        ),

        border:
            Border.all(
          color:
              green,

          width:
              1.4,
        ),
      ),

      child:
          Column(
        children: [
          const Row(
            children: [
              Text(
                '🤝',
                style:
                    TextStyle(
                  fontSize: 23,
                ),
              ),

              SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                    Text(
                  'Deal Accepted',

                  style:
                      TextStyle(
                    color:
                        green,
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              Icon(
                Icons.verified_rounded,
                color:
                    green,
                size:
                    27,
              ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          Align(
            alignment:
                Alignment.centerLeft,

            child:
                Text(
              '${_formatQuantity(quantity)} kg '
              '${widget.productName} × '
              '₹${price.toStringAsFixed(0)}/kg',

              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize:
                    13,
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          const Divider(
            color:
                Colors.white12,
          ),

          Row(
            children: [
              const Expanded(
                child:
                    Text(
                  'Total',

                  style:
                      TextStyle(
                    color:
                        Colors.white70,
                    fontSize:
                        15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              Text(
                '₹${total.toStringAsFixed(0)}',

                style:
                    const TextStyle(
                  color:
                      green,
                  fontSize:
                      22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Container(
            width:
                double.infinity,

            padding:
                const EdgeInsets.all(
              10,
            ),

            decoration:
                BoxDecoration(
              color:
                  green.withValues(
                alpha: .08,
              ),

              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),

            child:
                const Row(
              children: [
                Icon(
                  Icons
                      .check_circle_rounded,
                  color:
                      green,
                  size:
                      18,
                ),

                SizedBox(
                  width: 7,
                ),

                Expanded(
                  child:
                      Text(
                    'The buyer has accepted the deal.',

                    style:
                        TextStyle(
                      color:
                          Colors.white70,
                      fontSize:
                          10,
                    ),
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
  // INPUT
  // ============================================================

  Widget _buildInput() {
    return SafeArea(
      top: false,

      child:
          Container(
        padding:
            const EdgeInsets.fromLTRB(
          10,
          7,
          10,
          8,
        ),

        color:
            const Color(0xFF0D0D0D),

        child:
            Row(
          children: [
            IconButton(
              onPressed: () {
                _showError(
                  'Attachment feature coming soon.',
                );
              },

              padding:
                  EdgeInsets.zero,

              constraints:
                  const BoxConstraints(
                minWidth:
                    30,
              ),

              icon:
                  const Icon(
                Icons.attach_file_rounded,
                color:
                    Colors.white54,
                size:
                    21,
              ),
            ),

            const SizedBox(
              width: 3,
            ),

            Expanded(
              child:
                  Container(
                constraints:
                    const BoxConstraints(
                  minHeight:
                      43,
                  maxHeight:
                      90,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      card,

                  borderRadius:
                      BorderRadius.circular(
                    21,
                  ),
                ),

                child:
                    TextField(
                  controller:
                      _messageController,

                  minLines:
                      1,

                  maxLines:
                      3,

                  textCapitalization:
                      TextCapitalization
                          .sentences,

                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        12,
                  ),

                  cursorColor:
                      green,

                  decoration:
                      const InputDecoration(
                    border:
                        InputBorder.none,

                    hintText:
                        'Type a message...',

                    hintStyle:
                        TextStyle(
                      color:
                          Colors.white30,
                      fontSize:
                          11,
                    ),

                    contentPadding:
                        EdgeInsets.symmetric(
                      horizontal:
                          14,
                      vertical:
                          11,
                    ),
                  ),

                  onSubmitted:
                      (_) {
                    _sendMessage();
                  },
                ),
              ),
            ),

            const SizedBox(
              width: 5,
            ),

            IconButton(
              onPressed: () {
                _showError(
                  'Voice message coming soon.',
                );
              },

              padding:
                  EdgeInsets.zero,

              constraints:
                  const BoxConstraints(
                minWidth:
                    30,
              ),

              icon:
                  const Icon(
                Icons.mic_none_rounded,
                color:
                    Colors.white54,
                size:
                    21,
              ),
            ),

            GestureDetector(
              onTap:
                  _sending
                      ? null
                      : _sendMessage,

              child:
                  Container(
                width:
                    43,

                height:
                    43,

                decoration:
                    const BoxDecoration(
                  color:
                      green,

                  shape:
                      BoxShape.circle,
                ),

                child:
                    _sending
                        ? const Padding(
                            padding:
                                EdgeInsets.all(
                              12,
                            ),
                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.black,
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
                            Icons
                                .send_rounded,
                            color:
                                Colors.black,
                            size:
                                19,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACCEPT OFFER
  // ============================================================

  Future<void> _acceptBuyerOffer(
    double price,
    double quantity,
  ) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      _showError(
        'Farmer is not logged in.',
      );
      return;
    }

    try {
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .set(
        {
          'negotiationStatus':
              'accepted',

          'dealPrice':
              price,

          'dealQuantity':
              quantity,

          'dealAcceptedBy':
              user.uid,

          'dealAcceptedAt':
              FieldValue.serverTimestamp(),

          'updatedAt':
              FieldValue.serverTimestamp(),
        },

        SetOptions(
          merge: true,
        ),
      );

      await _chatService.sendMessage(
        chatId:
            widget.chatId,

        senderId:
            user.uid,

        senderName:
            'Farmer',

        message:
            'Farmer accepted ₹${price.toStringAsFixed(0)}/kg',
      );

      _showSuccess(
        'Offer accepted 🤝',
      );
    } catch (e) {
      _showError(
        'Unable to accept offer.',
      );
    }
  }

  // ============================================================
  // COUNTER DIALOG
  // ============================================================

  Future<void> _showCounterDialog(
    double quantity,
  ) async {
    _counterController.text =
        '56';

    final price =
        await showDialog<double>(
      context:
          context,

      builder:
          (dialogContext) {
        return AlertDialog(
          backgroundColor:
              card,

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
                Icons
                    .handshake_rounded,
                color:
                    orange,
              ),

              SizedBox(
                width: 8,
              ),

              Text(
                'Counter Offer',

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
              TextField(
            controller:
                _counterController,

            autofocus:
                true,

            keyboardType:
                const TextInputType
                    .numberWithOptions(
              decimal:
                  true,
            ),

            style:
                const TextStyle(
              color:
                  orange,
              fontSize:
                  18,
              fontWeight:
                  FontWeight.bold,
            ),

            cursorColor:
                orange,

            decoration:
                InputDecoration(
              prefixText:
                  '₹ ',

              prefixStyle:
                  const TextStyle(
                color:
                    orange,
                fontWeight:
                    FontWeight.bold,
              ),

              suffixText:
                  '/kg',

              suffixStyle:
                  const TextStyle(
                color:
                    Colors.white54,
                fontSize:
                    11,
              ),

              filled:
                  true,

              fillColor:
                  const Color(
                0xFF0B0D0B,
              ),

              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  11,
                ),

                borderSide:
                    const BorderSide(
                  color:
                      orange,
                ),
              ),

              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  11,
                ),

                borderSide:
                    const BorderSide(
                  color:
                      orange,
                  width:
                      1.5,
                ),
              ),
            ),
          ),

          actions: [
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

            ElevatedButton(
              onPressed: () {
                final value =
                    double.tryParse(
                  _counterController
                      .text
                      .trim(),
                );

                if (value == null ||
                    value <= 0) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    orange,

                foregroundColor:
                    Colors.black,

                elevation:
                    0,
              ),

              child:
                  const Text(
                'Send Counter',

                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (price == null) {
      return;
    }

    await _sendCounterOffer(
      price,
      quantity,
    );
  }

  // ============================================================
  // SEND COUNTER
  // ============================================================

  Future<void> _sendCounterOffer(
    double price,
    double quantity,
  ) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .set(
        {
          'negotiationStatus':
              'farmer_countered',

          'farmerCounterOffer':
              price,

          'negotiationQuantity':
              quantity,

          'negotiationUpdatedAt':
              FieldValue.serverTimestamp(),

          'updatedAt':
              FieldValue.serverTimestamp(),
        },

        SetOptions(
          merge: true,
        ),
      );

      await _chatService.sendMessage(
        chatId:
            widget.chatId,

        senderId:
            user.uid,

        senderName:
            'Farmer',

        message:
            'Farmer counter offered ₹${price.toStringAsFixed(0)}/kg',
      );

      _showSuccess(
        'Counter offer sent to $_buyerName.',
      );
    } catch (e) {
      _showError(
        'Unable to send counter offer.',
      );
    }
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<void> _rejectOffer() async {
    final user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .set(
        {
          'negotiationStatus':
              'rejected',

          'updatedAt':
              FieldValue.serverTimestamp(),
        },

        SetOptions(
          merge: true,
        ),
      );

      await _chatService.sendMessage(
        chatId:
            widget.chatId,

        senderId:
            user.uid,

        senderName:
            'Farmer',

        message:
            'Farmer rejected the offer.',
      );

      _showSuccess(
        'Offer rejected.',
      );
    } catch (e) {
      _showError(
        'Unable to reject offer.',
      );
    }
  }

  // ============================================================
  // DETAIL ITEM
  // ============================================================

  Widget _detailItem(
    String title,
    String value, {
    Color valueColor =
        Colors.white,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
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
          height: 4,
        ),

        Text(
          value,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style:
              TextStyle(
            color:
                valueColor,
            fontSize:
                13,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _actionButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height:
          40,

      child:
          OutlinedButton(
        onPressed:
            onTap,

        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              color,

          side:
              BorderSide(
            color:
                color,
          ),

          padding:
              const EdgeInsets.symmetric(
            horizontal:
                3,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              9,
            ),
          ),
        ),

        child:
            Text(
          text,

          maxLines:
              1,

          overflow:
              TextOverflow.ellipsis,

          style:
              const TextStyle(
            fontSize:
                9,

            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY CHAT
  // ============================================================

  Widget _buildEmptyChat() {
    return Padding(
      padding:
          const EdgeInsets.only(
        top: 60,
        bottom: 30,
      ),

      child:
          Column(
        children: [
          Container(
            width:
                65,

            height:
                65,

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
                  30,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'Start the conversation',

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
            height: 5,
          ),

          const Text(
            'Talk with the buyer about price and quantity.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  Colors.white38,

              fontSize:
                  10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TODAY
  // ============================================================

  Widget _todayChip() {
    return Center(
      child:
          Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal:
              12,
          vertical:
              5,
        ),

        decoration:
            BoxDecoration(
          color:
              card,

          borderRadius:
              BorderRadius.circular(
            20,
          ),
        ),

        child:
            const Text(
          'Today',

          style:
              TextStyle(
            color:
                Colors.white54,

            fontSize:
                9,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CHAT INFO
  // ============================================================

  void _showChatInfo() {
    showModalBottomSheet(
      context:
          context,

      backgroundColor:
          card,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(
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
              20,
            ),

            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                _buildBuyerAvatar(
                  _buyerAvatar,
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  _buyerName,

                  style:
                      const TextStyle(
                    color:
                        Colors.white,

                    fontSize:
                        17,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  widget.productName,

                  style:
                      const TextStyle(
                    color:
                        Colors.white38,

                    fontSize:
                        11,
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _readDouble(
    dynamic value,
    double fallback,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return fallback;
  }

  String _formatQuantity(
    double value,
  ) {
    if (value ==
        value.roundToDouble()) {
      return value
          .toInt()
          .toString();
    }

    return value.toStringAsFixed(
      1,
    );
  }

  String _formatTime(
    dynamic value,
  ) {
    if (value == null ||
        value is! Timestamp) {
      return '';
    }

    final date =
        value.toDate();

    final hour =
        date.hour % 12 == 0
            ? 12
            : date.hour % 12;

    final minute =
        date.minute
            .toString()
            .padLeft(
          2,
          '0',
        );

    final period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom() {
    Future.delayed(
      const Duration(
        milliseconds: 150,
      ),
      () {
        if (!_scrollController
            .hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController
              .position
              .maxScrollExtent,

          duration:
              const Duration(
            milliseconds:
                250,
          ),

          curve:
              Curves.easeOut,
        );
      },
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),

        backgroundColor:
            Colors.red.shade700,

        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  void _showSuccess(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),

        backgroundColor:
            const Color(
          0xFF176B20,
        ),

        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD ERROR
  // ============================================================

  Widget _buildError(
    String message,
  ) {
    return Center(
      child:
          Text(
        message,

        style:
            const TextStyle(
          color:
              Colors.white54,

          fontSize:
              12,
        ),
      ),
    );
  }
}