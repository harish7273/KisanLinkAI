import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/chat_service.dart';
import 'cart_screen.dart';

class ChatScreen extends StatefulWidget {
  final ProductModel? product;

  const ChatScreen({
    super.key,
    this.product,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange = Color(0xFFFF9800);
  static const Color green = Color(0xFF4CAF50);
  static const Color background = Color(0xFF050705);
  static const Color card = Color(0xFF151817);
  static const Color cardLight = Color(0xFF1D211F);

  // ============================================================
  // SERVICES
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final ChatService _chatService = ChatService();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _messageController =
      TextEditingController();

  final TextEditingController _offerController =
      TextEditingController(text: '52');

  final ScrollController _scrollController =
      ScrollController();

  // ============================================================
  // STATE
  // ============================================================

  String? _chatId;

  bool _loading = true;

  bool _sending = false;

  bool _addingDeal = false;

  bool _dealAddedToCart = false;

  String? _error;

  double _quantity = 20;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initializeChat();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _messageController.dispose();
    _offerController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // INITIALIZE CHAT
  // ============================================================

  Future<void> _initializeChat() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _error = 'Please login first.';
        });

        return;
      }

      if (widget.product == null) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _error = 'Product information is missing.';
        });

        return;
      }

      final product = widget.product!;

      if (product.farmerId.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _error = 'Farmer information is missing.';
        });

        return;
      }

      final buyerName =
          user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'Buyer';

      final farmerName =
          product.farmerName.trim().isNotEmpty
              ? product.farmerName.trim()
              : 'Farmer';

      final chatId = _chatService.getChatId(
        buyerId: user.uid,
        farmerId: product.farmerId,
        productId: product.id,
      );

      await _chatService.createChat(
        chatId: chatId,
        buyerId: user.uid,
        farmerId: product.farmerId,
        buyerName: buyerName,
        farmerName: farmerName,
        productId: product.id,
        productName: product.name,
        productPrice: product.price,
        productUnit: product.unit,
      );

      if (!mounted) return;

      setState(() {
        _chatId = chatId;
        _loading = false;
      });

      await _checkDealStatus();
    } catch (e) {
      debugPrint('Chat initialization error: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Unable to start chat.';
      });
    }
  }

  // ============================================================
  // CHECK DEAL STATUS
  // ============================================================

  Future<void> _checkDealStatus() async {
    if (_chatId == null) return;

    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(_chatId!)
          .get();

      final data = snapshot.data();

      if (data == null) return;

      if (!mounted) return;

      setState(() {
        _dealAddedToCart =
            data['dealAddedToCart'] == true;
      });
    } catch (e) {
      debugPrint('Deal status error: $e');
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: background,
        body: const Center(
          child: CircularProgressIndicator(
            color: orange,
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
        ),
      );
    }

    final product = widget.product!;

    final farmerName =
        product.farmerName.trim().isNotEmpty
            ? product.farmerName.trim()
            : 'Farmer';

    return Scaffold(
      backgroundColor: background,
      appBar: _buildAppBar(farmerName),
      body: Column(
        children: [
          _buildProductHeader(product),

          Expanded(
            child: _buildConversation(),
          ),

          _buildComposer(),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(
    String farmerName,
  ) {
    return AppBar(
      backgroundColor: const Color(0xFF050505),
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: orange.withValues(alpha: .12),
              shape: BoxShape.circle,
              border: Border.all(
                color: orange.withValues(alpha: .30),
              ),
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: orange,
              size: 23,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farmerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                const Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: green,
                      size: 6,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Farmer',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
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
          onPressed: () {},
          icon: const Icon(
            Icons.more_vert_rounded,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRODUCT HEADER
  // ============================================================

  Widget _buildProductHeader(
    ProductModel product,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        7,
      ),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: orange.withValues(alpha: .25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: orange.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: orange,
              size: 29,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Negotiating about',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 8,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Farmer price: ₹${product.price.toStringAsFixed(0)} / ${product.unit}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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
  // CONVERSATION
  // ============================================================

  Widget _buildConversation() {
    if (_chatId == null) {
      return const Center(
        child: Text(
          'Chat unavailable.',
          style: TextStyle(
            color: Colors.white54,
          ),
        ),
      );
    }

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('chats')
          .doc(_chatId!)
          .snapshots(),
      builder: (context, chatSnapshot) {
        final chatData =
            chatSnapshot.data?.data();

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _chatService.messagesStream(
            _chatId!,
          ),
          builder: (context, messageSnapshot) {
            if (messageSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: orange,
                ),
              );
            }

            if (messageSnapshot.hasError) {
              return const Center(
                child: Text(
                  'Unable to load messages.',
                  style: TextStyle(
                    color: Colors.white54,
                  ),
                ),
              );
            }

            final messages =
                messageSnapshot.data?.docs.toList() ??
                    [];

            messages.sort((a, b) {
              final aTime =
                  a.data()['createdAt'];

              final bTime =
                  b.data()['createdAt'];

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

              if (aTime is Timestamp &&
                  bTime is Timestamp) {
                return aTime.compareTo(bTime);
              }

              return 0;
            });

            WidgetsBinding.instance
                .addPostFrameCallback((_) {
              _scrollToBottom();
            });

            return ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                12,
              ),
              children: [
                _todayChip(),

                const SizedBox(height: 12),

                if (messages.isEmpty)
                  _buildEmptyChat(),

                ...messages.map(
                  (doc) {
                    return _messageBubble(
                      doc.data(),
                    );
                  },
                ),

                if (chatData != null)
                  ..._buildNegotiationArea(
                    chatData,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // NEGOTIATION AREA
  // ============================================================

  List<Widget> _buildNegotiationArea(
    Map<String, dynamic> data,
  ) {
    final status =
        data['negotiationStatus']?.toString() ?? '';

    final widgets = <Widget>[];

    if (status == 'buyer_offered' ||
        status == 'farmer_countered') {
      widgets.add(
        _buildOfferCard(data),
      );
    }

    if (status == 'farmer_countered') {
      widgets.add(
        _buildCounterOfferCard(data),
      );
    }

    if (status == 'accepted') {
      widgets.add(
        _buildDealAcceptedCard(data),
      );
    }

    return widgets;
  }

  // ============================================================
  // BUYER OFFER CARD
  // ============================================================

  Widget _buildOfferCard(
    Map<String, dynamic> data,
  ) {
    final offer = _readDouble(
      data['buyerOffer'],
      52,
    );

    final quantity = _readDouble(
      data['negotiationQuantity'],
      _quantity,
    );

    final total = offer * quantity;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF211706),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: orange,
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.handshake_rounded,
                color: orange,
                size: 22,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your Offer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          _dealInfoRow(
            'Offer',
            '₹${offer.toStringAsFixed(0)} / kg',
          ),

          const SizedBox(height: 7),

          _dealInfoRow(
            'Quantity',
            '${_formatQuantity(quantity)} kg',
          ),

          const SizedBox(height: 7),

          _dealInfoRow(
            'Total',
            '₹${total.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FARMER COUNTER OFFER
  // ============================================================

  Widget _buildCounterOfferCard(
    Map<String, dynamic> data,
  ) {
    final counter = _readDouble(
      data['counterOffer'],
      56,
    );

    final quantity = _readDouble(
      data['negotiationQuantity'],
      20,
    );

    final total = counter * quantity;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF09200C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: green.withValues(alpha: .85),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                color: green,
                size: 24,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Farmer Counter Offer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Text(
            '₹${counter.toStringAsFixed(0)} / kg',
            style: const TextStyle(
              color: green,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            '${_formatQuantity(quantity)} kg × ₹${counter.toStringAsFixed(0)} = ₹${total.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _actionButton(
                  text:
                      'Accept ₹${counter.toStringAsFixed(0)}',
                  color: green,
                  onTap: () {
                    _acceptCounterOffer(
                      counter,
                      quantity,
                    );
                  },
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: _actionButton(
                  text: 'Counter',
                  color: orange,
                  onTap: () {
                    _showCounterDialog(
                      quantity,
                    );
                  },
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: _actionButton(
                  text: 'Reject',
                  color: Colors.redAccent,
                  onTap: _rejectOffer,
                ),
              ),
            ],
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
    final price = _readDouble(
      data['dealPrice'],
      56,
    );

    final quantity = _readDouble(
      data['dealQuantity'],
      20,
    );

    final total = price * quantity;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF091A0C),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: green.withValues(alpha: .85),
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                '🤝',
                style: TextStyle(
                  fontSize: 23,
                ),
              ),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Deal Accepted',
                  style: TextStyle(
                    color: green,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Icon(
                Icons.verified_rounded,
                color: green,
                size: 27,
              ),
            ],
          ),

          const SizedBox(height: 13),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_formatQuantity(quantity)} kg '
              '${widget.product?.name ?? 'Product'} × '
              '₹${price.toStringAsFixed(0)}/kg',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Divider(
            color: Colors.white12,
          ),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Text(
                '₹${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: green,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed:
                  _addingDeal ||
                          _dealAddedToCart
                      ? null
                      : () {
                          _addDealToCart(
                            price,
                            quantity,
                          );
                        },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _dealAddedToCart
                        ? const Color(0xFF275E2B)
                        : green,
                disabledBackgroundColor:
                    _dealAddedToCart
                        ? const Color(0xFF275E2B)
                        : green.withValues(
                            alpha: .45,
                          ),
                foregroundColor: Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              icon: _addingDeal
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child:
                          CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _dealAddedToCart
                          ? Icons.check_circle_rounded
                          : Icons.shopping_cart_rounded,
                      size: 19,
                    ),
              label: Text(
                _dealAddedToCart
                    ? 'Added to Cart'
                    : 'Add Deal to Cart',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          if (_dealAddedToCart) ...[
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: _openCart,
                icon: const Icon(
                  Icons.shopping_cart_rounded,
                  size: 17,
                ),
                label: const Text(
                  'Go to Cart',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor: orange,
                  side: const BorderSide(
                    color: orange,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ACCEPT COUNTER OFFER
  // ============================================================

  Future<void> _acceptCounterOffer(
    double price,
    double quantity,
  ) async {
    if (_chatId == null) {
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _firestore
          .collection('chats')
          .doc(_chatId!)
          .set(
        {
          'negotiationStatus': 'accepted',

          'dealPrice': price,

          'dealQuantity': quantity,

          'acceptedPrice': price,

          'acceptedQuantity': quantity,

          'dealAcceptedBy': user.uid,

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
        chatId: _chatId!,
        senderId: user.uid,
        senderName:
            user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : 'Buyer',
        message:
            'Buyer accepted ₹${price.toStringAsFixed(0)}/kg',
      );

      if (!mounted) return;

      _showSnack(
        'Deal accepted 🤝',
      );
    } catch (e) {
      debugPrint(
        'Accept counter error: $e',
      );

      _showSnack(
        'Could not accept deal.',
      );
    }
  }

  // ============================================================
  // COUNTER DIALOG
  // ============================================================

  Future<void> _showCounterDialog(
    double quantity,
  ) async {
    final controller =
        TextEditingController(
      text: _offerController.text,
    );

    final value =
        await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: card,
          title: const Text(
            'Counter Offer',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration:
                const InputDecoration(
              prefixText: '₹ ',
              prefixStyle:
                  TextStyle(
                color: orange,
              ),
              labelText: 'Your price',
              labelStyle:
                  TextStyle(
                color: Colors.white54,
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
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                final price =
                    double.tryParse(
                  controller.text,
                );

                if (price != null &&
                    price > 0) {
                  Navigator.pop(
                    dialogContext,
                    price,
                  );
                }
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.black,
              ),
              child:
                  const Text('Send'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (value == null ||
        _chatId == null) {
      return;
    }

    final user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _firestore
          .collection('chats')
          .doc(_chatId!)
          .set(
        {
          'negotiationStatus':
              'buyer_offered',

          'buyerOffer': value,

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
        chatId: _chatId!,
        senderId: user.uid,
        senderName:
            user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : 'Buyer',
        message:
            'Buyer countered with ₹${value.toStringAsFixed(0)}/kg',
      );

      _offerController.text =
          value.toStringAsFixed(0);

      _showSnack(
        'Counter offer sent.',
      );
    } catch (e) {
      debugPrint(
        'Counter error: $e',
      );

      _showSnack(
        'Could not send counter offer.',
      );
    }
  }

  // ============================================================
  // SEND BUYER OFFER
  // ============================================================

  Future<void> _sendOffer() async {
    if (_chatId == null) {
      _showSnack(
        'Chat is not ready.',
      );
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      _showSnack(
        'Please login first.',
      );
      return;
    }

    final offer =
        double.tryParse(
      _offerController.text.trim(),
    );

    if (offer == null ||
        offer <= 0) {
      _showSnack(
        'Enter a valid offer price.',
      );
      return;
    }

    if (_quantity <= 0) {
      _showSnack(
        'Enter a valid quantity.',
      );
      return;
    }

    try {
      final senderName =
          user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'Buyer';

      // --------------------------------------------------------
      // SAVE OFFER TO CHAT
      // --------------------------------------------------------

      await _firestore
          .collection('chats')
          .doc(_chatId!)
          .set(
        {
          'negotiationStatus':
              'buyer_offered',

          'buyerOffer':
              offer,

          'negotiationQuantity':
              _quantity,

          'negotiationBuyerId':
              user.uid,

          'negotiationUpdatedAt':
              FieldValue.serverTimestamp(),

          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      // --------------------------------------------------------
      // SEND MESSAGE
      // --------------------------------------------------------

      await _chatService.sendMessage(
        chatId: _chatId!,
        senderId: user.uid,
        senderName: senderName,
        message:
            'Buyer offered ₹${offer.toStringAsFixed(0)}/kg '
            'for ${_formatQuantity(_quantity)} kg',
      );

      if (!mounted) return;

      _showSnack(
        'Offer sent: ₹${offer.toStringAsFixed(0)}/kg',
      );

      _scrollToBottom();
    } catch (e) {
      debugPrint(
        'SEND OFFER ERROR: $e',
      );

      if (!mounted) return;

      _showSnack(
        'Could not send offer.',
      );
    }
  }

  // ============================================================
  // REJECT OFFER
  // ============================================================

  Future<void> _rejectOffer() async {
    if (_chatId == null) {
      return;
    }

    final user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _firestore
          .collection('chats')
          .doc(_chatId!)
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
        chatId: _chatId!,
        senderId: user.uid,
        senderName:
            user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : 'Buyer',
        message:
            'Buyer rejected the counter offer.',
      );

      _showSnack(
        'Offer rejected.',
      );
    } catch (e) {
      debugPrint(
        'Reject error: $e',
      );

      _showSnack(
        'Could not reject offer.',
      );
    }
  }

  // ============================================================
  // ADD DEAL TO BUYER CART
  // ============================================================

  Future<void> _addDealToCart(
    double price,
    double quantity,
  ) async {
    if (_addingDeal) {
      return;
    }

    final user =
        _auth.currentUser;

    if (user == null) {
      _showSnack(
        'Please login first.',
      );
      return;
    }

    if (widget.product == null ||
        _chatId == null) {
      _showSnack(
        'Product information is missing.',
      );
      return;
    }

    final product =
        widget.product!;

    setState(() {
      _addingDeal = true;
    });

    try {
      final cartRef =
          _firestore
              .collection('carts')
              .doc(user.uid);

      // Unique ID for negotiated deal.
      final cartItemId =
          '${product.id}_deal_$_chatId';

      final itemRef =
          cartRef
              .collection('items')
              .doc(cartItemId);

      await itemRef.set({
        'productId':
            product.id,

        'name':
            product.name,

        'farmerId':
            product.farmerId,

        'farmerName':
            product.farmerName,

        'location':
            product.location,

        // NEGOTIATED PRICE
        'price':
            price,

        // NEGOTIATED QUANTITY
        'quantity':
            quantity,

        'unit':
            product.unit,

        'image':
            product.image,

        'quality':
            product.quality,

        'organic':
            product.organic,

        'fromNegotiation':
            true,

        'dealAccepted':
            true,

        'chatId':
            _chatId,

        'buyerId':
            user.uid,

        'createdAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      // --------------------------------------------------------
      // UPDATE CART ROOT
      // --------------------------------------------------------

      await cartRef.set(
        {
          'buyerId':
              user.uid,

          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      // --------------------------------------------------------
      // UPDATE CHAT
      // --------------------------------------------------------

      await _firestore
          .collection('chats')
          .doc(_chatId!)
          .set(
        {
          'dealAddedToCart':
              true,

          'dealBuyerId':
              user.uid,

          'dealPrice':
              price,

          'dealQuantity':
              quantity,

          'dealAddedAt':
              FieldValue.serverTimestamp(),

          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _dealAddedToCart = true;
      });

      _showSnack(
        '🤝 Deal added to your cart!',
      );

      await Future.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      if (!mounted) {
        return;
      }

      _openCart();
    } catch (e) {
      debugPrint(
        'Add deal to cart error: $e',
      );

      if (!mounted) {
        return;
      }

      _showSnack(
        'Could not add deal to cart.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _addingDeal = false;
        });
      }
    }
  }

  // ============================================================
  // OPEN CART
  // ============================================================

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CartScreen(),
      ),
    );
  }

  // ============================================================
  // SEND NORMAL MESSAGE
  // ============================================================

  Future<void> _sendMessage() async {
    if (_sending) {
      return;
    }

    final user =
        _auth.currentUser;

    if (user == null) {
      _showSnack(
        'Please login first.',
      );
      return;
    }

    final text =
        _messageController.text.trim();

    if (text.isEmpty ||
        _chatId == null) {
      return;
    }

    setState(() {
      _sending = true;
    });

    _messageController.clear();

    try {
      final senderName =
          user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'Buyer';

      await _chatService.sendMessage(
        chatId: _chatId!,
        senderId: user.uid,
        senderName: senderName,
        message: text,
      );

      _scrollToBottom();
    } catch (e) {
      debugPrint(
        'Send message error: $e',
      );

      _messageController.text = text;

      _showSnack(
        'Message failed.',
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
  // OFFER BOTTOM SHEET
  // ============================================================

  void _showOfferSheet() {
    _quantity = 20;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            final product =
                widget.product!;

            final offer =
                double.tryParse(
                      _offerController.text.trim(),
                    ) ??
                    0;

            final total =
                offer * _quantity;

            return SafeArea(
              child: Container(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 14,
                  bottom:
                      MediaQuery.of(context)
                              .viewInsets
                              .bottom +
                          18,
                ),
                decoration:
                    const BoxDecoration(
                  color: card,
                  borderRadius:
                      BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
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
                      ),

                      const SizedBox(height: 18),

                      const Row(
                        children: [
                          Text(
                            '🤝',
                            style: TextStyle(
                              fontSize: 25,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Make an Offer',
                            style: TextStyle(
                              color: orange,
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(12),
                        decoration:
                            BoxDecoration(
                          color: orange.withValues(
                            alpha: .07,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Farmer price',
                                style: TextStyle(
                                  color:
                                      Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Text(
                              '₹${product.price.toStringAsFixed(0)}/${product.unit}',
                              style:
                                  const TextStyle(
                                color: orange,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 13),

                      const Text(
                        'Your Offer',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Container(
                        height: 48,
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(0xFF101210),
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                          border: Border.all(
                            color: orange,
                          ),
                        ),
                        child: TextField(
                          controller:
                              _offerController,
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.bold,
                          ),
                          cursorColor: orange,
                          onChanged: (_) {
                            setSheetState(() {});
                          },
                          decoration:
                              const InputDecoration(
                            prefixText: '₹ ',
                            prefixStyle:
                                TextStyle(
                              color: orange,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                            suffixText: '/kg',
                            suffixStyle:
                                TextStyle(
                              color:
                                  Colors.white54,
                            ),
                            border:
                                InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Quantity',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      _sheetQuantityControl(
                        setSheetState,
                      ),

                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(14),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(0xFF0C1E0C),
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                          border: Border.all(
                            color:
                                green.withValues(
                              alpha: .25,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Calculated Total',
                                style: TextStyle(
                                  color:
                                      Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Text(
                              '₹${total.toStringAsFixed(0)}',
                              style:
                                  const TextStyle(
                                color: green,
                                fontSize: 19,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                            );

                            _sendOffer();
                          },
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                orange,
                            foregroundColor:
                                Colors.black,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                13,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Send Offer',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w900,
                              fontSize: 14,
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
  }

  // ============================================================
  // QUANTITY CONTROL
  // ============================================================

  Widget _sheetQuantityControl(
    StateSetter setSheetState,
  ) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF161816),
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color: Colors.white12,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_quantity > 1) {
                setSheetState(() {
                  _quantity -= 1;
                });
              }
            },
            icon: const Icon(
              Icons.remove_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),

          Expanded(
            child: Center(
              child: Text(
                '${_formatQuantity(_quantity)} kg',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

          IconButton(
            onPressed: () {
              setSheetState(() {
                _quantity += 1;
              });
            },
            icon: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT COMPOSER
  // ============================================================

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          10,
          7,
          10,
          7,
        ),
        color: const Color(0xFF0D0F0D),
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(
                minWidth: 32,
                minHeight: 40,
              ),
              icon: const Icon(
                Icons.attach_file_rounded,
                color: Colors.white54,
                size: 21,
              ),
            ),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF181B19),
                  borderRadius:
                      BorderRadius.circular(24),
                ),
                child: TextField(
                  controller:
                      _messageController,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  decoration:
                      const InputDecoration(
                    border: InputBorder.none,
                    hintText:
                        'Type a message...',
                    hintStyle: TextStyle(
                      color: Colors.white30,
                      fontSize: 12,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                  ),
                ),
              ),
            ),

            IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(
                minWidth: 32,
                minHeight: 40,
              ),
              icon: const Icon(
                Icons.mic_none_rounded,
                color: Colors.white54,
                size: 21,
              ),
            ),

            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 43,
                height: 43,
                decoration:
                    const BoxDecoration(
                  color: orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 5),

            GestureDetector(
              onTap: _showOfferSheet,
              child: Container(
                height: 41,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      orange.withValues(
                    alpha: .10,
                  ),
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                    color: orange,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '₹ Offer',
                    style: TextStyle(
                      color: orange,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _messageBubble(
    Map<String, dynamic> data,
  ) {
    final user =
        _auth.currentUser;

    final senderId =
        data['senderId']?.toString();

    final message =
        data['message']?.toString() ?? '';

    final timestamp =
        data['createdAt'];

    final isBuyer =
        user != null &&
            senderId == user.uid;

    return Align(
      alignment: isBuyer
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 290,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 8,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isBuyer
              ? orange
              : const Color(0xFF172018),
          borderRadius:
              BorderRadius.only(
            topLeft:
                const Radius.circular(16),
            topRight:
                const Radius.circular(16),
            bottomLeft:
                Radius.circular(
              isBuyer ? 16 : 3,
            ),
            bottomRight:
                Radius.circular(
              isBuyer ? 3 : 16,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                message,
                style: TextStyle(
                  color: isBuyer
                      ? Colors.black
                      : Colors.white,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 3),

            Text(
              _formatTime(timestamp),
              style: TextStyle(
                color: isBuyer
                    ? Colors.black54
                    : Colors.white38,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
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
      height: 39,
      child: OutlinedButton(
        onPressed: onTap,
        style:
            OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
            color: color,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 4,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DEAL INFO ROW
  // ============================================================

  Widget _dealInfoRow(
    String title,
    String value,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY CHAT
  // ============================================================

  Widget _buildEmptyChat() {
    return Padding(
      padding:
          const EdgeInsets.only(
        top: 45,
        bottom: 25,
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration:
                BoxDecoration(
              color:
                  orange.withValues(
                alpha: .10,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_rounded,
              color: orange,
              size: 29,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Start a conversation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Ask about price, quantity, quality or delivery.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
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
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 5,
        ),
        decoration:
            BoxDecoration(
          color: card,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: const Text(
          'Today',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 9,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // READ DOUBLE
  // ============================================================

  double _readDouble(
    dynamic value,
    double fallback,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    final parsed =
        double.tryParse(
      value?.toString() ?? '',
    );

    return parsed ?? fallback;
  }

  // ============================================================
  // FORMAT QUANTITY
  // ============================================================

  String _formatQuantity(
    double value,
  ) {
    if (value ==
        value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(
    dynamic value,
  ) {
    if (value == null ||
        value is! Timestamp) {
      return '';
    }

    final date = value.toDate();

    final hour =
        date.hour % 12 == 0
            ? 12
            : date.hour % 12;

    final minute = date.minute
        .toString()
        .padLeft(2, '0');

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
            milliseconds: 250,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnack(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 11,
          ),
        ),
        backgroundColor: cardLight,
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }
}