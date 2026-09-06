import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'checkout_screen.dart';

import 'buyer_market_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color orange = Color(0xFFFF9800);
  static const Color green = Color(0xFF4CAF50);
  static const Color background = Color(0xFF080A08);
  static const Color card = Color(0xFF151515);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // FIRESTORE CART
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _cartStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .snapshots();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _double(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _price(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  String _qty(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _cartStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: orange,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading cart\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            double totalWeight = 0;
            double subtotal = 0;

            for (final doc in docs) {
              final data = doc.data();

              final quantity =
                  _double(data['quantity']);

              final price =
                  _double(data['price']);

              totalWeight += quantity;
              subtotal += quantity * price;
            }

            final delivery =
                subtotal >= 499 ? 0.0 : 40.0;

            final packaging = 10.0;

            final total =
                subtotal +
                    delivery +
                    packaging;

            return Column(
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                _buildHeader(
                  docs.length,
                  totalWeight,
                ),

                // ==================================================
                // CONTENT
                // ==================================================

                Expanded(
                  child: docs.isEmpty
                      ? _buildEmptyCart()
                      : ListView(
                          physics:
                              const BouncingScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(
                            14,
                            8,
                            14,
                            25,
                          ),
                          children: [
                            _buildTrustCard(),

                            const SizedBox(
                              height: 18,
                            ),

                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Your Items',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight:
                                          FontWeight.w800,
                                    ),
                                  ),
                                ),

                                GestureDetector(
                                  onTap:
                                      _clearCartDialog,
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons
                                            .delete_sweep_outlined,
                                        color: orange,
                                        size: 19,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Text(
                                        'Clear',
                                        style: TextStyle(
                                          color: orange,
                                          fontWeight:
                                              FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            // =================================================
                            // CART ITEMS
                            // =================================================

                            ...docs.map(
                              (doc) => Padding(
                                padding:
                                    const EdgeInsets.only(
                                  bottom: 12,
                                ),
                                child:
                                    _buildCartItem(doc),
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            _buildBrowseCard(
                              subtotal,
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            _buildSummary(
                              subtotal,
                              totalWeight,
                              delivery,
                              packaging,
                              total,
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            _buildCheckout(
                              total,
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    int count,
    double weight,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        10,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  orange.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: orange,
              size: 28,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  '$count items • ${_qty(weight)} kg',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.location_on_rounded,
            color: orange,
            size: 19,
          ),

          const SizedBox(
            width: 2,
          ),

          const Text(
            'Coimbatore, TN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          Stack(
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 27,
              ),
              Positioned(
                right: 1,
                top: 1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration:
                      const BoxDecoration(
                    color: orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRUST CARD
  // ============================================================

  Widget _buildTrustCard() {
    return Container(
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:
            orange.withValues(alpha: .06),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              orange.withValues(alpha: .18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  orange.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: orange,
              size: 26,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Trusted farmer products',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                SizedBox(
                  height: 3,
                ),
                Text(
                  'Fresh • Quality checked • Direct from farms',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
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
  // CART ITEM
  // ============================================================

  Widget _buildCartItem(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc,
  ) {
    final data = doc.data();

    final name =
        data['name']?.toString() ??
            'Product';

    final farmer =
        data['farmerName']?.toString() ??
            'Farmer';

    final location =
        data['location']?.toString() ??
            'Coimbatore, TN';

    final image =
        data['image']?.toString() ??
            '';

    final unit =
        data['unit']?.toString() ??
            'Kg';

    final quality =
        data['quality']?.toString() ??
            'Farm Fresh';

    final price =
        _double(data['price']);

    final quantity =
        _double(data['quantity']);

    final itemTotal =
        price * quantity;

    final isDeal =
        data['fromNegotiation'] ==
                true ||
            data['dealAccepted'] ==
                true;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: isDeal
              ? green.withValues(
                  alpha: .55,
                )
              : Colors.white.withValues(
                  alpha: .10,
                ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ========================================================
          // IMAGE
          // ========================================================

          ClipRRect(
            borderRadius:
                BorderRadius.circular(14),
            child: SizedBox(
              width: 105,
              height: 145,
              child:
                  _productImage(
                image,
                name,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // ========================================================
          // DETAILS
          // ========================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () =>
                          _removeItem(
                        doc.id,
                      ),
                      child:
                          const Icon(
                        Icons
                            .delete_outline_rounded,
                        color:
                            Colors.white54,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  '₹${_price(price)} / $unit',
                  style: TextStyle(
                    color: isDeal
                        ? green
                        : orange,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                // DEAL BADGE
                if (isDeal)
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          green.withValues(
                        alpha: .12,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        7,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons
                              .handshake_rounded,
                          color: green,
                          size: 13,
                        ),
                        SizedBox(
                          width: 4,
                        ),
                        Text(
                          'NEGOTIATED DEAL',
                          style:
                              TextStyle(
                            color: green,
                            fontSize: 8,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(
                  height: 8,
                ),

                // FARMER
                Row(
                  children: [
                    Container(
                      width: 25,
                      height: 25,
                      decoration:
                          BoxDecoration(
                        color: orange
                            .withValues(
                          alpha: .12,
                        ),
                        shape:
                            BoxShape.circle,
                      ),
                      child:
                          const Icon(
                        Icons.person_rounded,
                        color: orange,
                        size: 15,
                      ),
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Expanded(
                      child: Text(
                        farmer,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 4,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons
                          .location_on_rounded,
                      color:
                          Colors.white38,
                      size: 13,
                    ),
                    const SizedBox(
                      width: 3,
                    ),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            orange.withValues(
                          alpha: .10,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          6,
                        ),
                      ),
                      child: Text(
                        quality,
                        style:
                            const TextStyle(
                          color: orange,
                          fontSize: 8,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // QUANTITY
                    Container(
                      height: 32,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFF0D0D0D,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          8,
                        ),
                        border:
                            Border.all(
                          color: Colors
                              .white
                              .withValues(
                            alpha: .12,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _updateQuantity(
                              doc.id,
                              quantity - 1,
                            ),
                            child:
                                const SizedBox(
                              width: 28,
                              child:
                                  Icon(
                                Icons
                                    .remove_rounded,
                                color:
                                    Colors.white,
                                size: 16,
                              ),
                            ),
                          ),

                          Text(
                            _qty(quantity),
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),

                          GestureDetector(
                            onTap: () =>
                                _updateQuantity(
                              doc.id,
                              quantity + 1,
                            ),
                            child:
                                const SizedBox(
                              width: 28,
                              child:
                                  Icon(
                                Icons
                                    .add_rounded,
                                color:
                                    Colors.white,
                                size: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 7,
                ),

                Align(
                  alignment:
                      Alignment.centerRight,
                  child: Text(
                    '₹${_price(itemTotal)}',
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w900,
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
  // PRODUCT IMAGE
  // ============================================================

  Widget _productImage(
    String image,
    String name,
  ) {
    if (image.startsWith(
          'http://',
        ) ||
        image.startsWith(
          'https://',
        )) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) =>
                _imagePlaceholder(name),
      );
    }

    return _imagePlaceholder(name);
  }

  Widget _imagePlaceholder(
    String name,
  ) {
    IconData icon =
        Icons.eco_rounded;

    final n = name.toLowerCase();

    if (n.contains('carrot')) {
      icon = Icons.eco_rounded;
    } else if (n.contains('tomato')) {
      icon =
          Icons.local_florist_rounded;
    } else if (n.contains('potato')) {
      icon =
          Icons.agriculture_rounded;
    } else if (n.contains('onion')) {
      icon = Icons.spa_rounded;
    }

    return Container(
      color:
          const Color(0xFF222222),
      child: Center(
        child: Icon(
          icon,
          color: orange,
          size: 45,
        ),
      ),
    );
  }

  // ============================================================
  // BROWSE
  // ============================================================

  Widget _buildBrowseCard(
    double subtotal,
  ) {
    final remaining =
        subtotal >= 499
            ? 0
            : 499 - subtotal;

    return Container(
      padding:
          const EdgeInsets.all(13),
      decoration:
          BoxDecoration(
        color: const Color(
          0xFF101210,
        ),
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white
              .withValues(
            alpha: .10,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.eco_rounded,
            color: orange,
            size: 32,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              remaining > 0
                  ? 'Add ₹${_price(remaining.toDouble())} more for FREE delivery'
                  : 'FREE delivery unlocked! 🎉',
              style:
                  const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const BuyerMarketScreen(),
                ),
              );
            },
            style:
                OutlinedButton.styleFrom(
              foregroundColor: orange,
              side: const BorderSide(
                color: orange,
              ),
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 10,
                vertical: 8,
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
                const Text(
              'Browse',
              style:
                  TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(
    double subtotal,
    double weight,
    double delivery,
    double packaging,
    double total,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white
              .withValues(
            alpha: .08,
          ),
        ),
      ),
      child: Column(
        children: [
          const Align(
            alignment:
                Alignment.centerLeft,
            child: Text(
              'Order Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          _summaryRow(
            'Subtotal (${_qty(weight)} kg)',
            '₹${_price(subtotal)}',
          ),

          const SizedBox(
            height: 10,
          ),

          _summaryRow(
            'Delivery',
            delivery == 0
                ? 'FREE'
                : '₹${_price(delivery)}',
            valueColor:
                delivery == 0
                    ? green
                    : Colors.white,
          ),

          const SizedBox(
            height: 10,
          ),

          _summaryRow(
            'Packaging',
            '₹${_price(packaging)}',
          ),

          const SizedBox(
            height: 13,
          ),

          Divider(
            color: Colors.white
                .withValues(
              alpha: .12,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '₹${_price(total)}',
                style: const TextStyle(
                  color: orange,
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String title,
    String value, {
    Color valueColor =
        Colors.white,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style:
                const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CHECKOUT
  // ============================================================

  Widget _buildCheckout(
    double total,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color:
            orange.withValues(
          alpha: .08,
        ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              orange.withValues(
            alpha: .20,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons
                    .local_shipping_outlined,
                color: orange,
                size: 26,
              ),

              const SizedBox(
                width: 9,
              ),

              const Expanded(
                child: Text(
                  'Ready to place your order?',
                  style:
                      TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child:
                ElevatedButton(
              onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const CheckoutScreen(),
    ),
  );
},
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    orange,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),
              child:
                  Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  Text(
                    'Proceed to Checkout • ₹${_price(total)}',
                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  const Icon(
                    Icons
                        .arrow_forward_rounded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration:
                BoxDecoration(
              color:
                  orange.withValues(
                alpha: .10,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons
                  .shopping_cart_outlined,
              color: orange,
              size: 48,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          const Text(
            'Your cart is empty',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Add fresh products directly from\nfarmers near you.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(
            height: 22,
          ),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const BuyerMarketScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.storefront_rounded,
            ),
            label:
                const Text(
              'Browse Market',
            ),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  orange,
              foregroundColor:
                  Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 20,
                vertical: 13,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPDATE QUANTITY
  // ============================================================

  Future<void> _updateQuantity(
    String id,
    double quantity,
  ) async {
    final user =
        _auth.currentUser;

    if (user == null) return;

    if (quantity <= 0) {
      await _removeItem(id);
      return;
    }

    try {
      await _firestore
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(id)
          .update({
        'quantity': quantity,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showSnack(
        'Unable to update quantity.',
      );
    }
  }

  // ============================================================
  // REMOVE
  // ============================================================

  Future<void> _removeItem(
    String id,
  ) async {
    final user =
        _auth.currentUser;

    if (user == null) return;

    try {
      await _firestore
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(id)
          .delete();

      _showSnack(
        'Item removed.',
      );
    } catch (e) {
      _showSnack(
        'Unable to remove item.',
      );
    }
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void _clearCartDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: card,
          title: const Text(
            'Clear Cart?',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: const Text(
            'Remove all products from your cart?',
            style: TextStyle(
              color: Colors.white70,
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
                  color:
                      Colors.white54,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
                _clearCart();
              },
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: orange,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearCart() async {
    final user =
        _auth.currentUser;

    if (user == null) return;

    try {
      final snapshot =
          await _firestore
              .collection('carts')
              .doc(user.uid)
              .collection('items')
              .get();

      final batch =
          _firestore.batch();

      for (final doc
          in snapshot.docs) {
        batch.delete(
          doc.reference,
        );
      }

      await batch.commit();

      _showSnack(
        'Cart cleared.',
      );
    } catch (e) {
      _showSnack(
        'Unable to clear cart.',
      );
    }
  }

  // ============================================================
  // SNACK
  // ============================================================

  void _showSnack(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),
        backgroundColor:
            card,
        behavior:
            SnackBarBehavior
                .floating,
      ),
    );
  }
}