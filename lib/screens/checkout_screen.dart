import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../services/location_service.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() =>
      _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color orange = Color(0xFFFF9800);
  static const Color background = Color(0xFF080A08);
  static const Color card = Color(0xFF151515);
  static const Color cardLight = Color(0xFF1D1D1D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  String _buyerName = 'Buyer';
  String _phone = '';
  String _email = '';
  String _storeName = '';

  String _deliveryAddress =
      'Getting current location...';

  String _avatarUrl = '';

  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();

    _loadBuyerProfile();
    _loadLocation();
  }

  // ============================================================
  // BUYER PROFILE
  // ============================================================

  Future<void> _loadBuyerProfile() async {
    final user = _auth.currentUser;

    if (user == null) return;

    try {
      String name =
          user.displayName?.trim() ?? '';

      String phone =
          user.phoneNumber?.trim() ?? '';

      String email =
          user.email?.trim() ?? '';

      String avatar =
          user.photoURL?.trim() ?? '';

      String store = '';

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};

        if (name.isEmpty) {
          name = _firstValue(
            data,
            [
              'name',
              'fullName',
              'displayName',
              'buyerName',
            ],
          );
        }

        if (phone.isEmpty) {
          phone = _firstValue(
            data,
            [
              'phone',
              'phoneNumber',
              'mobile',
              'mobileNumber',
            ],
          );
        }

        if (email.isEmpty) {
          email = _firstValue(
            data,
            [
              'email',
              'mail',
            ],
          );
        }

        store = _firstValue(
          data,
          [
            'storeName',
            'shopName',
            'businessName',
            'store',
          ],
        );

        if (avatar.isEmpty) {
          avatar = _firstValue(
            data,
            [
              'avatarUrl',
              'avatar',
              'photoUrl',
              'profileImage',
              'profileImageUrl',
              'imageUrl',
            ],
          );
        }
      }

      if (name.isEmpty) {
        name = 'Buyer';
      }

      if (!mounted) return;

      setState(() {
        _buyerName = name;
        _phone = phone;
        _email = email;
        _storeName = store;
        _avatarUrl = avatar;
      });
    } catch (e) {
      debugPrint(
        'PROFILE ERROR: $e',
      );
    }
  }

  String _firstValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value =
          data[key]?.toString().trim();

      if (value != null &&
          value.isNotEmpty &&
          value != 'null') {
        return value;
      }
    }

    return '';
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> _loadLocation() async {
    setState(() {
      _loadingLocation = true;
      _deliveryAddress =
          'Getting current location...';
    });

    try {
      final position =
          await LocationService
              .getCurrentLocation();

      final placemarks =
          await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        throw Exception(
          'Address not found',
        );
      }

      final place = placemarks.first;

      final parts = <String>[];

      _addPart(parts, place.name);
      _addPart(parts, place.street);
      _addPart(parts, place.subLocality);
      _addPart(parts, place.locality);
      _addPart(
        parts,
        place.subAdministrativeArea,
      );
      _addPart(
        parts,
        place.administrativeArea,
      );
      _addPart(
        parts,
        place.postalCode,
      );

      if (!mounted) return;

      setState(() {
        _deliveryAddress =
            parts.join(', ');

        _loadingLocation = false;
      });
    } catch (e) {
      debugPrint(
        'LOCATION ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _deliveryAddress =
            'Unable to get current location';

        _loadingLocation = false;
      });
    }
  }

  void _addPart(
    List<String> parts,
    String? value,
  ) {
    if (value == null) return;

    final cleaned = value.trim();

    if (cleaned.isEmpty) return;

    if (!parts.contains(cleaned)) {
      parts.add(cleaned);
    }
  }

  // ============================================================
  // CART STREAM
  // ============================================================

  Stream<QuerySnapshot<
      Map<String, dynamic>>> _cartStream() {
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),

            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<
                      Map<String, dynamic>>>(
                stream: _cartStream(),
                builder: (
                  context,
                  snapshot,
                ) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(
                        color: orange,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Unable to load checkout',
                        style:
                            const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    );
                  }

                  final docs =
                      snapshot.data?.docs ??
                          [];

                  if (docs.isEmpty) {
                    return _emptyCart();
                  }

                  return _checkoutBody(docs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        10,
        8,
        15,
        8,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 4),

          const Icon(
            Icons.lock_rounded,
            color: orange,
            size: 20,
          ),

          const SizedBox(width: 8),

          const Expanded(
            child: Text(
              'Checkout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),

          const Text(
            'Step 1 of 2',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHECKOUT BODY
  // ============================================================

  Widget _checkoutBody(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        docs,
  ) {
    double subtotal = 0;
    double totalQuantity = 0;

    for (final doc in docs) {
      final data = doc.data();

      final quantity =
          _double(data['quantity']);

      final price =
          _double(data['price']);

      subtotal +=
          quantity * price;

      totalQuantity += quantity;
    }

    final deliveryFee =
        subtotal >= 499
            ? 0.0
            : 40.0;

    final total =
        subtotal + deliveryFee;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics:
                const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              14,
              5,
              14,
              20,
            ),
            child: Column(
              children: [
                _progressIndicator(),

                const SizedBox(
                  height: 14,
                ),

                // 1
                _addressCard(),

                const SizedBox(
                  height: 12,
                ),

                // 2 + 3
                _buyerCard(),

                const SizedBox(
                  height: 12,
                ),

                // 4-7
                _orderItemsCard(docs),

                const SizedBox(
                  height: 12,
                ),

                // 8-10
                _summaryCard(
                  subtotal,
                  totalQuantity,
                  deliveryFee,
                  total,
                ),

                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),

        _continueButton(total),
      ],
    );
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  Widget _progressIndicator() {
    return Row(
      children: [
        _step(
          '1',
          'Checkout',
          true,
        ),

        Expanded(
          child: Container(
            height: 2,
            color:
                orange.withValues(
              alpha: .25,
            ),
          ),
        ),

        _step(
          '2',
          'Payment',
          false,
        ),
      ],
    );
  }

  Widget _step(
    String number,
    String title,
    bool active,
  ) {
    return Row(
      children: [
        Container(
          width: 27,
          height: 27,
          alignment:
              Alignment.center,
          decoration:
              BoxDecoration(
            color: active
                ? orange
                : cardLight,
            shape:
                BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              color: active
                  ? Colors.black
                  : Colors.white38,
              fontSize: 10,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ),

        const SizedBox(width: 5),

        Text(
          title,
          style: TextStyle(
            color: active
                ? orange
                : Colors.white38,
            fontSize: 9,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ADDRESS
  // ============================================================

  Widget _addressCard() {
    return _card(
      title: '1. Delivery Address',
      icon:
          Icons.location_on_rounded,
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
                12,
              ),
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: orange,
              size: 21,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'Current Location',
                  style: TextStyle(
                    color: orange,
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  _deliveryAddress,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed:
                _loadingLocation
                    ? null
                    : _loadLocation,
            icon: const Icon(
              Icons.refresh_rounded,
              color: orange,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUYER
  // ============================================================

  Widget _buyerCard() {
    return _card(
      title: '2. Buyer Details',
      icon: Icons.person_rounded,
      child: Row(
        children: [
          Container(
            width: 53,
            height: 53,
            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,
              border: Border.all(
                color: orange,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _avatarUrl
                      .isNotEmpty
                  ? Image.network(
                      _avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) =>
                              _avatarFallback(),
                    )
                  : _avatarFallback(),
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  _buyerName,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons.phone_rounded,
                      color: orange,
                      size: 12,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      _phone.isEmpty
                          ? 'Phone number not available'
                          : _phone,
                      style:
                          const TextStyle(
                        color:
                            Colors.white60,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),

                if (_storeName
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    _storeName,
                    style:
                        const TextStyle(
                      color:
                          Colors.white38,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: const Color(
        0xFF2B2112,
      ),
      alignment: Alignment.center,
      child: Text(
        _buyerName.isEmpty
            ? 'B'
            : _buyerName[0]
                .toUpperCase(),
        style:
            const TextStyle(
          color: orange,
          fontSize: 20,
          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }

  // ============================================================
  // ORDER ITEMS
  // ============================================================

  Widget _orderItemsCard(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        docs,
  ) {
    return _card(
      title: '4. Order Items',
      icon:
          Icons.shopping_basket_rounded,
      child: Column(
        children: [
          for (int i = 0;
              i < docs.length;
              i++) ...[
            _orderItem(docs[i]),

            if (i < docs.length - 1)
              Divider(
                height: 22,
                color:
                    Colors.white.withValues(
                  alpha: .08,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _orderItem(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc,
  ) {
    final data = doc.data();

    final name =
        data['name']?.toString() ??
            'Product';

    final farmer =
        data['farmerName']
                ?.toString() ??
            'Farmer';

    final image =
        data['image']?.toString() ??
            '';

    final unit =
        data['unit']?.toString() ??
            'kg';

    final quantity =
        _double(data['quantity']);

    final price =
        _double(data['price']);

    final originalPrice =
        _double(
      data['originalPrice'],
    );

    final negotiatedPrice =
        _double(
      data['negotiatedPrice'],
    );

    bool isNegotiated =
        data['fromNegotiation'] ==
                true ||
            data['dealAccepted'] ==
                true ||
            negotiatedPrice > 0 ||
            (originalPrice > 0 &&
                originalPrice !=
                    price);

    double displayPrice = price;

    if (negotiatedPrice > 0) {
      displayPrice =
          negotiatedPrice;
    }

    final itemTotal =
        quantity * displayPrice;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 65,
          height: 65,
          decoration:
              BoxDecoration(
            color: cardLight,
            borderRadius:
                BorderRadius.circular(
              11,
            ),
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(
              11,
            ),
            child: _productImage(
              image,
              name,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),

                  Text(
                    '₹${_price(itemTotal)}',
                    style:
                        const TextStyle(
                      color: orange,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              // FARMER
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    color:
                        Colors.white38,
                    size: 12,
                  ),
                  const SizedBox(
                    width: 4,
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
                            Colors.white54,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              Row(
                children: [
                  // QUANTITY
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
                      '${_qty(quantity)} $unit',
                      style:
                          const TextStyle(
                        color: orange,
                        fontSize: 8,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  // PRICE
                  Text(
                    '₹${_price(displayPrice)}/$unit',
                    style:
                        const TextStyle(
                      color:
                          Colors.white54,
                      fontSize: 8,
                    ),
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  // NEGOTIATED
                  if (isNegotiated)
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            orange.withValues(
                          alpha: .12,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          5,
                        ),
                      ),
                      child:
                          const Text(
                        'NEGOTIATED PRICE',
                        style:
                            TextStyle(
                          color: orange,
                          fontSize: 5.5,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),

              // ORIGINAL + NEGOTIATED PRICE
              if (isNegotiated &&
                  originalPrice >
                      0) ...[
                const SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    Text(
                      'Farmer price ₹${_price(originalPrice)}',
                      style:
                          const TextStyle(
                        color:
                            Colors.white30,
                        fontSize: 7,
                        decoration:
                            TextDecoration
                                .lineThrough,
                      ),
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    Text(
                      'Deal ₹${_price(displayPrice)}',
                      style:
                          const TextStyle(
                        color:
                            Colors.greenAccent,
                        fontSize: 7,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _summaryCard(
    double subtotal,
    double quantity,
    double delivery,
    double total,
  ) {
    return _card(
      title: '8. Order Summary',
      icon:
          Icons.receipt_long_rounded,
      child: Column(
        children: [
          _summaryRow(
            'Subtotal (${_qty(quantity)} kg)',
            '₹${_price(subtotal)}',
          ),

          const SizedBox(height: 12),

          _summaryRow(
            'Delivery Fee',
            delivery == 0
                ? 'FREE'
                : '₹${_price(delivery)}',
            valueColor:
                delivery == 0
                    ? Colors.greenAccent
                    : Colors.white,
          ),

          const SizedBox(height: 12),

          Divider(
            color:
                Colors.white.withValues(
              alpha: .08,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Expanded(
                child: Text(
                  '10. Total',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '₹${_price(total)}',
                style:
                    const TextStyle(
                  color: orange,
                  fontSize: 20,
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
              fontSize: 10,
            ),
          ),
        ),
        Text(
          value,
          style:
              TextStyle(
            color: valueColor,
            fontSize: 11,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONTINUE TO PAYMENT
  // ============================================================

  Widget _continueButton(
    double total,
  ) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        14,
        9,
        14,
        13,
      ),
      decoration:
          BoxDecoration(
        color: card,
        border: Border(
          top: BorderSide(
            color:
                Colors.white.withValues(
              alpha: .08,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 7,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              Text(
                '₹${_price(total)}',
                style:
                    const TextStyle(
                  color: orange,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          Expanded(
            child: SizedBox(
              height: 49,
              child:
                  ElevatedButton(
                onPressed:
                    _loadingLocation
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PaymentScreen(
                                  totalAmount:
                                      total,
                                  buyerName:
                                      _buyerName,
                                  phone:
                                      _phone,
                                  deliveryAddress:
                                      _deliveryAddress,
                                ),
                              ),
                            );
                          },
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      orange,
                  foregroundColor:
                      Colors.black,
                  disabledBackgroundColor:
                      Colors.white12,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Text(
                      'Continue to Payment',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons
                          .arrow_forward_rounded,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color:
              Colors.white.withValues(
            alpha: .07,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(
                  color:
                      orange.withValues(
                    alpha: .10,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                ),
                child: Icon(
                  icon,
                  color: orange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          child,
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
    if (image.isNotEmpty &&
        (image.startsWith(
              'http://',
            ) ||
            image.startsWith(
              'https://',
            ))) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) =>
                _placeholder(name),
      );
    }

    if (image.isNotEmpty) {
      return Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) =>
                _placeholder(name),
      );
    }

    return _placeholder(name);
  }

  Widget _placeholder(
    String name,
  ) {
    return Container(
      color: cardLight,
      alignment: Alignment.center,
      child: const Icon(
        Icons.eco_rounded,
        color: orange,
        size: 30,
      ),
    );
  }

  // ============================================================
  // EMPTY CART
  // ============================================================

  Widget _emptyCart() {
    return Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          const Icon(
            Icons
                .shopping_cart_outlined,
            color: orange,
            size: 50,
          ),
          const SizedBox(height: 15),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  orange,
              foregroundColor:
                  Colors.black,
            ),
            child:
                const Text(
              'Back to Cart',
            ),
          ),
        ],
      ),
    );
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
    if (value ==
        value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  String _qty(double value) {
    if (value ==
        value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }
}