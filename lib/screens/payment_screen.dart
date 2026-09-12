import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../constants/api_config.dart';
import '../services/location_service.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String buyerName;
  final String phone;
  final String deliveryAddress;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.buyerName,
    required this.phone,
    required this.deliveryAddress,
  });

  @override
  State<PaymentScreen> createState() =>
      _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange =
      Color(0xFFFF9800);

  static const Color background =
      Color(0xFF080A08);

  static const Color card =
      Color(0xFF151515);

  static const Color cardLight =
      Color(0xFF1D1D1D);

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // RAZORPAY
  // ============================================================

  late Razorpay _razorpay;

  bool _processing = false;

  String _selectedPayment = 'UPI';

  // ============================================================
  // BACKEND
  // ============================================================

  static String get backendUrl => ApiConfig.paymentBackendUrl;

  // ============================================================
  // RAZORPAY KEY
  // ============================================================

  static const String razorpayKeyId = ApiConfig.defaultRazorpayKeyId;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      _handlePaymentSuccess,
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      _handlePaymentError,
    );

    _razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
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
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  14,
                  8,
                  14,
                  20,
                ),
                child: Column(
                  children: [
                    _progress(),

                    const SizedBox(
                      height: 18,
                    ),

                    _paymentMethods(),

                    const SizedBox(
                      height: 14,
                    ),

                    _selectedPaymentDetails(),

                    const SizedBox(
                      height: 14,
                    ),

                    _orderTotal(),

                    const SizedBox(
                      height: 15,
                    ),

                    _securePayment(),
                  ],
                ),
              ),
            ),

            _payButton(),
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
            onPressed: _processing
                ? null
                : () {
                    Navigator.pop(context);
                  },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 4),

          const Icon(
            Icons.payments_rounded,
            color: orange,
            size: 22,
          ),

          const SizedBox(width: 8),

          const Expanded(
            child: Text(
              'Payment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const Text(
            'Step 2 of 2',
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
  // PROGRESS
  // ============================================================

  Widget _progress() {
    return Row(
      children: [
        _progressStep(
          '1',
          'Checkout',
        ),

        Expanded(
          child: Container(
            height: 2,
            color: orange.withOpacity(.35),
          ),
        ),

        _progressStep(
          '2',
          'Payment',
        ),
      ],
    );
  }

  Widget _progressStep(
    String number,
    String title,
  ) {
    return Row(
      children: [
        Container(
          width: 27,
          height: 27,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: orange,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        const SizedBox(width: 5),

        Text(
          title,
          style: const TextStyle(
            color: orange,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAYMENT METHODS
  // ============================================================

  Widget _paymentMethods() {
    return _section(
      title: 'Choose Payment Method',
      icon: Icons.payment_rounded,
      child: Column(
        children: [
          _paymentOption(
            value: 'UPI',
            title: 'UPI',
            subtitle:
                'Google Pay, PhonePe, Paytm & more',
            icon:
                Icons.account_balance_wallet_rounded,
          ),

          const SizedBox(height: 9),

          _paymentOption(
            value: 'Card',
            title: 'Debit / Credit Card',
            subtitle:
                'Visa, Mastercard, RuPay',
            icon:
                Icons.credit_card_rounded,
          ),

          const SizedBox(height: 9),

          _paymentOption(
            value: 'COD',
            title: 'Cash on Delivery',
            subtitle:
                'Pay when your order arrives',
            icon:
                Icons.local_shipping_rounded,
          ),
        ],
      ),
    );
  }

  Widget _paymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected =
        _selectedPayment == value;

    return InkWell(
      onTap: _processing
          ? null
          : () {
              setState(() {
                _selectedPayment = value;
              });
            },
      borderRadius:
          BorderRadius.circular(14),
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.all(12),
        decoration:
            BoxDecoration(
          color: selected
              ? orange.withOpacity(.08)
              : cardLight,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? orange
                : Colors.white.withOpacity(.07),
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(
                color: selected
                    ? orange.withOpacity(.12)
                    : Colors.white.withOpacity(.04),
                borderRadius:
                    BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color:
                    selected
                        ? orange
                        : Colors.white54,
                size: 20,
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style:
                        const TextStyle(
                      color: Colors.white54,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 19,
              height: 19,
              decoration:
                  BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? orange
                      : Colors.white30,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Center(
                      child: Icon(
                        Icons.circle,
                        color: orange,
                        size: 9,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SELECTED PAYMENT DETAILS
  // ============================================================

  Widget _selectedPaymentDetails() {
    if (_selectedPayment == 'Card') {
      return _cardDetails();
    }

    if (_selectedPayment == 'COD') {
      return _codDetails();
    }

    return _upiDetails();
  }

  Widget _upiDetails() {
    return _section(
      title: 'UPI Payment',
      icon:
          Icons.account_balance_wallet_rounded,
      child: _infoBox(
        icon: Icons.flash_on_rounded,
        message:
            'You will be redirected to Razorpay '
            'to complete your UPI payment securely.',
      ),
    );
  }

  Widget _cardDetails() {
    return _section(
      title: 'Card Payment',
      icon:
          Icons.credit_card_rounded,
      child: _infoBox(
        icon: Icons.lock_outline_rounded,
        message:
            'Your card details are securely '
            'handled by Razorpay.',
      ),
    );
  }

  Widget _codDetails() {
    return _section(
      title: 'Cash on Delivery',
      icon:
          Icons.local_shipping_rounded,
      child: _infoBox(
        icon: Icons.check_circle_outline,
        message:
            'Pay the delivery partner when '
            'your order arrives.',
        green: true,
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String message,
    bool green = false,
  }) {
    final color =
        green ? Colors.greenAccent : orange;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(13),
      decoration:
          BoxDecoration(
        color: color.withOpacity(.05),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(
                color: Colors.white54,
                fontSize: 9,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORDER TOTAL
  // ============================================================

  Widget _orderTotal() {
    return _section(
      title: 'Order Total',
      icon:
          Icons.receipt_long_rounded,
      child: Column(
        children: [
          _totalRow(
            'Order amount',
            widget.totalAmount,
          ),

          const SizedBox(height: 10),

          _totalRow(
            'Delivery',
            0,
            free: true,
          ),

          const SizedBox(height: 12),

          Divider(
            color:
                Colors.white.withOpacity(.08),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Payable',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),

              Text(
                '₹${_price(widget.totalAmount)}',
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

  Widget _totalRow(
    String title,
    double amount, {
    bool free = false,
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
          free
              ? 'FREE'
              : '₹${_price(amount)}',
          style: TextStyle(
            color: free
                ? Colors.greenAccent
                : Colors.white,
            fontSize: 10,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECURE PAYMENT
  // ============================================================

  Widget _securePayment() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        color:
            Colors.greenAccent.withOpacity(.04),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              Colors.greenAccent.withOpacity(.10),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Colors.greenAccent,
            size: 18,
          ),

          SizedBox(width: 9),

          Expanded(
            child: Text(
              'Secure payment powered by Razorpay. '
              'Your payment information is protected.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 8,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAY BUTTON
  // ============================================================

  Widget _payButton() {
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
                Colors.white.withOpacity(.08),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 51,
        child: ElevatedButton(
          onPressed:
              _processing ? null : _payNow,
          style:
              ElevatedButton.styleFrom(
            backgroundColor: orange,
            disabledBackgroundColor:
                orange.withOpacity(.35),
            foregroundColor: Colors.black,
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(15),
            ),
          ),
          child: _processing
              ? const SizedBox(
                  width: 21,
                  height: 21,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black,
                  ),
                )
              : Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedPayment == 'COD'
                          ? Icons
                              .local_shipping_rounded
                          : Icons.lock_rounded,
                      size: 17,
                    ),

                    const SizedBox(width: 7),

                    Text(
                      _selectedPayment == 'COD'
                          ? 'Place Order'
                          : 'Pay ₹${_price(widget.totalAmount)}',
                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // PAY NOW
  // ============================================================

  Future<void> _payNow() async {
    if (_processing) return;

    final user =
        _auth.currentUser;

    if (user == null) {
      _snack(
        'Please login again.',
      );
      return;
    }

    if (widget.totalAmount <= 0) {
      _snack(
        'Invalid order amount.',
      );
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      if (_selectedPayment == 'COD') {
        await _createFirestoreOrder(
          paymentStatus: 'Pending',
        );

        return;
      }

      await _startRazorpayPayment();
    } catch (e) {
      debugPrint(
        'PAYMENT START ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _processing = false;
      });

      _snack(
        'Unable to start payment: $e',
      );
    }
  }

  // ============================================================
  // RAZORPAY ORDER
  // ============================================================

  Future<void> _startRazorpayPayment() async {
    final amountPaise = (widget.totalAmount * 100).round();
    final candidates = ApiConfig.candidateBackendUrls;

    debugPrint('========================================');
    debugPrint('CREATING RAZORPAY ORDER');
    debugPrint('Amount: $amountPaise paise');
    debugPrint('Candidate hosts: $candidates');
    debugPrint('========================================');

    http.Response? response;
    String? successfulUrl;
    dynamic lastError;

    for (final host in candidates) {
      try {
        debugPrint('Trying Razorpay backend at: $host/api/payment/create-order');
        final res = await http.post(
          Uri.parse('$host/api/payment/create-order'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'amount': amountPaise,
            'receipt': 'KISANAI_${DateTime.now().millisecondsSinceEpoch}',
          }),
        ).timeout(const Duration(seconds: 4));

        debugPrint('Backend response from $host: ${res.statusCode}');

        if (res.statusCode == 200 || res.statusCode == 201) {
          response = res;
          successfulUrl = host;
          ApiConfig.setWorkingUrl(host);
          debugPrint('✅ Successfully connected to payment backend at $host');
          break;
        } else {
          lastError = 'Server returned ${res.statusCode}: ${res.body}';
        }
      } catch (e) {
        debugPrint('Backend attempt failed for $host: $e');
        lastError = e;
      }
    }

    if (response == null || successfulUrl == null) {
      throw Exception(
        'Payment backend unreachable ($lastError). Please verify Spring Boot is running on port 8080 at http://${ApiConfig.machineLanIp}:8080',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final orderId = data['orderId']?.toString();

    if (orderId == null || orderId.isEmpty) {
      throw Exception('Razorpay order ID missing from server response.');
    }

    final options =
        <String, dynamic>{
      'key': razorpayKeyId,
      'amount': amountPaise,
      'currency': 'INR',
      'name': 'KisanAI',
      'description':
          'KisanAI Farmer Marketplace',
      'order_id': orderId,
      'prefill': {
        'name':
            widget.buyerName,
        'contact':
            widget.phone,
      },
      'theme': {
        'color': '#FF9800',
      },
    };

    debugPrint(
      'OPENING RAZORPAY',
    );

    debugPrint(
      'Order ID: $orderId',
    );

    _razorpay.open(options);
  }

  // ============================================================
  // RAZORPAY SUCCESS
  // ============================================================

  Future<void> _handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) async {
    debugPrint(
      '========================================',
    );

    debugPrint(
      'RAZORPAY SUCCESS',
    );

    debugPrint(
      'Payment ID: ${response.paymentId}',
    );

    debugPrint(
      'Order ID: ${response.orderId}',
    );

    debugPrint(
      'Signature: ${response.signature}',
    );

    debugPrint(
      '========================================',
    );

    try {
      // ========================================================
      // 1. SERVER-SIDE SIGNATURE VERIFICATION
      // ========================================================
      debugPrint('VERIFYING SIGNATURE ON SPRING BOOT BACKEND...');
      final verifyResponse = await http.post(
        Uri.parse('$backendUrl/api/payment/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpayOrderId': response.orderId ?? '',
          'razorpayPaymentId': response.paymentId ?? '',
          'razorpaySignature': response.signature ?? '',
        }),
      ).timeout(const Duration(seconds: 15));

      if (verifyResponse.statusCode != 200) {
        throw Exception('Payment verification failed on server: ${verifyResponse.body}');
      }

      final verifyResult = jsonDecode(verifyResponse.body) as Map<String, dynamic>;
      if (verifyResult['verified'] != true) {
        throw Exception('Server rejected payment signature: ${verifyResult['message']}');
      }

      debugPrint('✅ PAYMENT SIGNATURE VERIFIED BY SERVER SUCCESSFULLY');

      // ========================================================
      // 2. CREATE FIRESTORE ORDER
      // ========================================================
      await _createFirestoreOrder(
        paymentStatus: 'Paid',
        razorpayPaymentId: response.paymentId,
        razorpayOrderId: response.orderId,
        razorpaySignature: response.signature,
      );
    } catch (e) {
      debugPrint(
        'ORDER CREATION / VERIFICATION ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _processing = false;
      });

      _snack(
        'Payment error: $e',
      );
    }
  }

  // ============================================================
  // PAYMENT ERROR
  // ============================================================

  void _handlePaymentError(
    PaymentFailureResponse response,
  ) {
    debugPrint(
      'RAZORPAY ERROR',
    );

    debugPrint(
      'Code: ${response.code}',
    );

    debugPrint(
      'Message: ${response.message}',
    );

    if (!mounted) return;

    setState(() {
      _processing = false;
    });

    _snack(
      response.message ??
          'Payment failed.',
    );
  }

  // ============================================================
  // EXTERNAL WALLET
  // ============================================================

  void _handleExternalWallet(
    ExternalWalletResponse response,
  ) {
    debugPrint(
      'EXTERNAL WALLET: '
      '${response.walletName}',
    );

    if (!mounted) return;

    _snack(
      'External wallet selected: '
      '${response.walletName ?? "Wallet"}',
    );
  }

  // ============================================================
  // CREATE FIRESTORE ORDER
  // ============================================================

  Future<void> _createFirestoreOrder({
    required String paymentStatus,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User not logged in.',
      );
    }

    // ==========================================================
    // GET CART
    // ==========================================================

    final cartSnapshot =
        await _firestore
            .collection('carts')
            .doc(user.uid)
            .collection('items')
            .get();

    if (cartSnapshot.docs.isEmpty) {
      throw Exception(
        'Cart is empty.',
      );
    }

    // ==========================================================
    // ORDER ITEMS
    // ==========================================================

    final List<Map<String, dynamic>>
        items = [];

    double subtotal = 0;

    for (final cartDoc
        in cartSnapshot.docs) {
      final cartData =
          cartDoc.data();

      final quantity =
          _double(
        cartData['quantity'],
      );

      final cartPrice =
          _double(
        cartData['price'],
      );

      final negotiatedPrice =
          _double(
        cartData['negotiatedPrice'],
      );

      final finalPrice =
          negotiatedPrice > 0
              ? negotiatedPrice
              : cartPrice;

      final itemTotal =
          quantity * finalPrice;

      subtotal += itemTotal;

      // ========================================================
      // PRODUCT ID
      // ========================================================

      final String productId =
          cartData['productId']
                  ?.toString() ??
              cartDoc.id;

      // ========================================================
      // DEFAULT VALUES
      // ========================================================

      String farmerId =
          cartData['farmerId']
                  ?.toString() ??
              '';

      String farmerName =
          cartData['farmerName']
                  ?.toString() ??
              'Farmer';

      String productName =
          cartData['name']
                  ?.toString() ??
              'Product';

      String image =
          cartData['image']
                  ?.toString() ??
              '';

      String location =
          cartData['location']
                  ?.toString() ??
              '';

      String unit =
          cartData['unit']
                  ?.toString() ??
              'Kg';

      // ========================================================
      // GET ACTUAL PRODUCT
      // ========================================================

      try {
        final productDoc =
            await _firestore
                .collection('products')
                .doc(productId)
                .get();

        if (productDoc.exists) {
          final productData =
              productDoc.data() ??
                  {};

          // ⭐ MAIN FIX
          final actualFarmerId =
              productData['farmerId']
                  ?.toString();

          if (actualFarmerId != null &&
              actualFarmerId.isNotEmpty) {
            farmerId =
                actualFarmerId;
          }

          final actualFarmerName =
              productData['farmerName']
                  ?.toString();

          if (actualFarmerName != null &&
              actualFarmerName.isNotEmpty) {
            farmerName =
                actualFarmerName;
          }

          final actualProductName =
              productData['name']
                  ?.toString();

          if (actualProductName != null &&
              actualProductName.isNotEmpty) {
            productName =
                actualProductName;
          }

          final actualImage =
              productData['image']
                  ?.toString();

          if (actualImage != null &&
              actualImage.isNotEmpty) {
            image = actualImage;
          }

          final actualLocation =
              productData['location']
                  ?.toString();

          if (actualLocation != null &&
              actualLocation.isNotEmpty) {
            location =
                actualLocation;
          }

          final actualUnit =
              productData['unit']
                  ?.toString();

          if (actualUnit != null &&
              actualUnit.isNotEmpty) {
            unit = actualUnit;
          }

          debugPrint(
            '----------------------------------------',
          );

          debugPrint(
            'PRODUCT LOOKUP',
          );

          debugPrint(
            'Product ID: $productId',
          );

          debugPrint(
            'Product Name: $productName',
          );

          debugPrint(
            'ACTUAL FARMER ID: $farmerId',
          );

          debugPrint(
            'ACTUAL FARMER NAME: $farmerName',
          );

          debugPrint(
            '----------------------------------------',
          );
        } else {
          debugPrint(
            '⚠️ PRODUCT NOT FOUND: $productId',
          );
        }
      } catch (e) {
        debugPrint(
          'PRODUCT LOOKUP ERROR: $e',
        );
      }

      // ========================================================
      // CREATE ITEM MAP
      // ========================================================

      final Map<String, dynamic>
          orderItem = {
        'productId': productId,

        'name': productName,

        'quantity': quantity,

        'unit': unit,

        'price': finalPrice,

        'itemTotal': itemTotal,

        // ⭐ CORRECT FARMER ID
        'farmerId': farmerId,

        'farmerName': farmerName,

        'image': image,

        'location': location,

        'negotiatedPrice':
            negotiatedPrice > 0
                ? negotiatedPrice
                : null,

        'fromNegotiation':
            cartData['fromNegotiation'] ==
                true,

        'dealAccepted':
            cartData['dealAccepted'] ==
                true,
      };

      items.add(orderItem);

      debugPrint(
        'ORDER ITEM CREATED',
      );

      debugPrint(
        'Product: $productName',
      );

      debugPrint(
        'Farmer ID: $farmerId',
      );

      debugPrint(
        'Farmer Name: $farmerName',
      );
    }

    // ==========================================================
    // DELIVERY
    // ==========================================================

    final deliveryFee = subtotal >= 499 ? 0.0 : 40.0;
    final total = subtotal + deliveryFee;

    // ==========================================================
    // MULTI-FARMER CART SPLITTING & COORDINATES
    // ==========================================================

    double buyerLat = 11.0168;
    double buyerLng = 76.9558;
    try {
      final pos = await LocationService.getCurrentLocation();
      buyerLat = pos.latitude;
      buyerLng = pos.longitude;
    } catch (_) {}

    // Group items by farmerId
    final Map<String, List<Map<String, dynamic>>> farmerGroupedItems = {};
    for (final item in items) {
      final fId = item['farmerId']?.toString() ?? 'unknown_farmer';
      farmerGroupedItems.putIfAbsent(fId, () => []).add(item);
    }

    final String paymentGroupId = 'PAY_${DateTime.now().millisecondsSinceEpoch}';
    String lastCreatedOrderId = '';

    for (final entry in farmerGroupedItems.entries) {
      final currentFarmerId = entry.key;
      final currentItems = entry.value;

      double farmerSubtotal = 0;
      for (final it in currentItems) {
        farmerSubtotal += _double(it['itemTotal']);
      }

      final currentFarmerName = currentItems.first['farmerName']?.toString() ?? 'Farmer';
      final currentFarmerLocation = currentItems.first['location']?.toString() ?? 'Farm';

      // Lookup farmer GPS from users collection if available
      double farmLat = 11.0168;
      double farmLng = 76.9558;
      try {
        final farmerDoc = await _firestore.collection('users').doc(currentFarmerId).get();
        if (farmerDoc.exists) {
          final fData = farmerDoc.data() ?? {};
          if (fData['currentLat'] != null) farmLat = _double(fData['currentLat']);
          if (fData['currentLng'] != null) farmLng = _double(fData['currentLng']);
        }
      } catch (_) {}

      // Secure 4-digit OTPs
      final random = Random();
      final String pickupOtp = (1000 + random.nextInt(9000)).toString();
      final String deliveryOtp = (1000 + random.nextInt(9000)).toString();

      final orderRef = _firestore.collection('orders').doc();
      lastCreatedOrderId = orderRef.id;

      final double currentDeliveryFee = farmerSubtotal >= 499 ? 0.0 : 40.0;
      final double currentTotal = farmerSubtotal + currentDeliveryFee;

      await orderRef.set({
        'orderId': orderRef.id,
        'paymentGroupId': paymentGroupId,
        'buyerId': user.uid,
        'buyerName': widget.buyerName,
        'buyerPhone': widget.phone,
        'deliveryAddress': widget.deliveryAddress,
        'farmerId': currentFarmerId,
        'farmerName': currentFarmerName,
        'farmerLocation': currentFarmerLocation,
        'items': currentItems,
        'subtotal': farmerSubtotal,
        'deliveryFee': currentDeliveryFee,
        'totalAmount': currentTotal,
        'paymentMethod': _selectedPayment,
        'paymentStatus': paymentStatus,
        'orderStatus': 'Placed',
        'deliveryStatus': 'Pending',
        'pickupOtp': pickupOtp,
        'deliveryOtp': deliveryOtp,
        'pickupLatitude': farmLat,
        'pickupLongitude': farmLng,
        'dropLatitude': buyerLat,
        'dropLongitude': buyerLng,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpayOrderId': razorpayOrderId,
        'razorpaySignature': razorpaySignature,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notification for this farmer
      final firstProductName = currentItems.first['name']?.toString() ?? 'Product';
      final quantity = _double(currentItems.first['quantity']);
      final unit = currentItems.first['unit']?.toString() ?? 'Kg';

      await _firestore.collection('notifications').add({
        'recipientId': currentFarmerId,
        'title': 'New Order',
        'message': '${widget.buyerName} ordered ${_quantity(quantity)} $unit $firstProductName',
        'type': 'new_order',
        'orderId': orderRef.id,
        'buyerId': user.uid,
        'buyerName': widget.buyerName,
        'farmerId': currentFarmerId,
        'farmerName': currentFarmerName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // ==========================================================
    // CLEAR CART
    // ==========================================================

    final batch =
        _firestore.batch();

    for (final doc
        in cartSnapshot.docs) {
      batch.delete(
        doc.reference,
      );
    }

    await batch.commit();

    debugPrint(
      '🛒 CART CLEARED',
    );

    // ==========================================================
    // SUCCESS
    // ==========================================================

    if (!mounted) return;

    setState(() {
      _processing = false;
    });

    await _successDialog(
      lastCreatedOrderId,
      total,
    );
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  Future<void> _successDialog(
    String orderId,
    double total,
  ) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: card,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          child: Padding(
            padding:
                const EdgeInsets.all(22),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.greenAccent
                            .withOpacity(.10),
                    shape:
                        BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons
                        .check_circle_rounded,
                    color:
                        Colors.greenAccent,
                    size: 44,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Order Placed!',
                  style:
                      TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Your order has been placed successfully.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 15),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(11),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white
                            .withOpacity(.035),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ORDER ID',
                        style:
                            TextStyle(
                          color:
                              Colors.white38,
                          fontSize: 7,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        orderId,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
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
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child:
                      ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        dialogContext,
                      ).pop();

                      Navigator.of(
                        context,
                      ).pop();

                      Navigator.of(
                        context,
                      ).pop();
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
                          13,
                        ),
                      ),
                    ),
                    child:
                        const Text(
                      'Done',
                      style:
                          TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w900,
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
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _section({
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
            BorderRadius.circular(17),
        border: Border.all(
          color:
              Colors.white.withOpacity(.07),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration:
                    BoxDecoration(
                  color:
                      orange.withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(10),
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

  String _quantity(double value) {
    if (value ==
        value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  String _price(double value) {
    if (value ==
        value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  void _snack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor: cardLight,
        behavior:
            SnackBarBehavior.floating,
        content: Text(
          message,
          style:
              const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}