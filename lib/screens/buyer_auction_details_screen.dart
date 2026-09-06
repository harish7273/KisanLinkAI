import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BuyerAuctionDetailsScreen
    extends StatefulWidget {
  final Map<String, dynamic> auction;

  const BuyerAuctionDetailsScreen({
    super.key,
    required this.auction,
  });

  @override
  State<BuyerAuctionDetailsScreen> createState() =>
      _BuyerAuctionDetailsScreenState();
}

class _BuyerAuctionDetailsScreenState
    extends State<BuyerAuctionDetailsScreen> {
  // ============================================================
  // VIDHAI COLORS
  // ============================================================

  static const Color orange =
      Color(0xFFFF9800);

  static const Color orangeDark =
      Color(0xFFC66A00);

  static const Color background =
      Color(0xFF080A08);

  static const Color card =
      Color(0xFF151817);

  static const Color cardLight =
      Color(0xFF1C201E);

  static const Color textSecondary =
      Color(0xFF9A9D9B);

  static const Color green =
      Color(0xFF4CAF50);

  static const Color red =
      Color(0xFFFF5252);

  // ============================================================
  // STATE
  // ============================================================

  late double currentBid;
  late double myBid;

  int imageIndex = 0;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    currentBid = _number(
      widget.auction['highestBid'] ??
          widget.auction['currentBid'] ??
          widget.auction['startPrice'],
    );

    myBid = currentBid + 1;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final auction = widget.auction;

    final String productName = _string(
      auction['productName'],
      'Fresh Product',
    );

    final String quantity = _string(
      auction['quantity'],
      '0',
    );

    final String unit = _string(
      auction['unit'],
      'kg',
    );

    final String quality = _string(
      auction['quality'],
      'Premium',
    );

    final String sellerName = _string(
      auction['sellerName'] ??
          auction['farmerName'],
      'Farmer',
    );

    final String location = _string(
      auction['location'],
      'Coimbatore, Tamil Nadu',
    );

    final int bidCount = _int(
      auction['bidCount'],
    );

    final double startPrice = _number(
      auction['startPrice'],
    );

    final DateTime? endTime =
        _toDate(
      auction['endTime'],
    );

    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            _buildHeader(),

            // ==================================================
            // CONTENT
            // ==================================================

            Expanded(
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),

                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  10,
                  12,
                  25,
                ),

                child: Column(
                  children: [
                    // ==========================================
                    // MAIN AUCTION CARD
                    // ==========================================

                    Container(
                      width: double.infinity,

                      decoration:
                          BoxDecoration(
                        color: card,

                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),

                        border:
                            Border.all(
                          color:
                              Colors.white
                                  .withValues(
                            alpha: 0.07,
                          ),
                        ),
                      ),

                      child: Column(
                        children: [
                          // ======================================
                          // STATUS BAR
                          // ======================================

                          _buildStatusBar(
                            endTime,
                          ),

                          // ======================================
                          // PRODUCT IMAGE
                          // ======================================

                          _buildProductImage(
                            productName,
                            auction,
                          ),

                          // ======================================
                          // PRODUCT INFO
                          // ======================================

                          Padding(
                            padding:
                                const EdgeInsets
                                    .fromLTRB(
                              14,
                              12,
                              14,
                              14,
                            ),

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                Text(
                                  productName,

                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        17,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Text(
                                  '$quality Quality  •  $quantity $unit',

                                  style:
                                      const TextStyle(
                                    color:
                                        textSecondary,
                                    fontSize:
                                        10,
                                  ),
                                ),

                                const SizedBox(
                                  height: 17,
                                ),

                                // ==================================
                                // BID ROW
                                // ==================================

                                Row(
                                  children: [
                                    Expanded(
                                      child:
                                          _buildBidInfo(
                                        title:
                                            'Current Bid',
                                        value:
                                            '₹${currentBid.toStringAsFixed(0)} / $unit',
                                        color:
                                            orange,
                                      ),
                                    ),

                                    Container(
                                      width: 1,
                                      height: 48,

                                      color:
                                          Colors.white
                                              .withValues(
                                        alpha:
                                            0.08,
                                      ),
                                    ),

                                    Expanded(
                                      child:
                                          _buildBidInfo(
                                        title:
                                            'My Current Bid',
                                        value:
                                            '₹${myBid.toStringAsFixed(0)} / $unit',
                                        color:
                                            green,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 11,
                                ),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons
                                          .people_outline_rounded,
                                      color:
                                          textSecondary,
                                      size: 15,
                                    ),

                                    const SizedBox(
                                      width: 5,
                                    ),

                                    Text(
                                      '$bidCount Bids',

                                      style:
                                          const TextStyle(
                                        color:
                                            textSecondary,
                                        fontSize:
                                            9,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ======================================
                          // DIVIDER
                          // ======================================

                          _divider(),

                          // ======================================
                          // AUCTION DETAILS
                          // ======================================

                          _buildAuctionDetails(
                            startPrice:
                                startPrice,
                            quantity:
                                quantity,
                            unit:
                                unit,
                            quality:
                                quality,
                            sellerName:
                                sellerName,
                            location:
                                location,
                            endTime:
                                endTime,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==========================================
                    // PLACE BID CARD
                    // ==========================================

                    _buildPlaceBidCard(
                      unit: unit,
                    ),
                  ],
                ),
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

  Widget _buildHeader() {
    return Container(
      height: 65,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
      ),

      decoration:
          const BoxDecoration(
        color: background,
      ),

      child: Row(
        children: [
          // BACK

          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },

            child: Container(
              width: 40,
              height: 40,

              decoration:
                  BoxDecoration(
                color: card,

                shape:
                    BoxShape.circle,

                border:
                    Border.all(
                  color:
                      Colors.white
                          .withValues(
                    alpha: 0.07,
                  ),
                ),
              ),

              child:
                  const Icon(
                Icons
                    .arrow_back_rounded,
                color:
                    Colors.white,
                size: 21,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          const Expanded(
            child: Text(
              'Auction Details',

              style:
                  TextStyle(
                color:
                    Colors.white,
                fontSize:
                    18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),

          // SHARE

          GestureDetector(
            onTap: () {
              _showMessage(
                'Share feature coming soon.',
              );
            },

            child: const Icon(
              Icons.share_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BAR
  // ============================================================

  Widget _buildStatusBar(
    DateTime? endTime,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        10,
      ),

      child: Row(
        children: [
          // LIVE

          Container(
            width: 7,
            height: 7,

            decoration:
                const BoxDecoration(
              color: orange,
              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          const Text(
            'Live Auction',

            style:
                TextStyle(
              color: orange,
              fontSize: 10,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const Spacer(),

          const Icon(
            Icons
                .access_time_rounded,
            color:
                Colors.white70,
            size: 15,
          ),

          const SizedBox(
            width: 4,
          ),

          Text(
            _remainingTime(
              endTime,
            ),

            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildProductImage(
    String productName,
    Map<String, dynamic> auction,
  ) {
    String imageAsset =
        _string(
      auction['imageAsset'],
      '',
    );

    if (imageAsset.isEmpty) {
      imageAsset =
          _findProductImage(
        productName,
      );
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
      ),

      child: Stack(
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              13,
            ),

            child: imageAsset.isEmpty
                ? _imagePlaceholder()
                : Image.asset(
                    imageAsset,

                    width:
                        double.infinity,

                    height: 190,

                    fit: BoxFit.cover,

                    errorBuilder:
                        (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return _imagePlaceholder();
                    },
                  ),
          ),

          // IMAGE COUNT

          Positioned(
            right: 10,
            bottom: 9,

            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 7,
                vertical: 4,
              ),

              decoration:
                  BoxDecoration(
                color: Colors.black
                    .withValues(
                  alpha: 0.65,
                ),

                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
              ),

              child:
                  Text(
                '${imageIndex + 1}/1',

                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 8,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMAGE PLACEHOLDER
  // ============================================================

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 190,

      color: cardLight,

      child:
          const Icon(
        Icons
            .agriculture_rounded,
        color: orange,
        size: 55,
      ),
    );
  }

  // ============================================================
  // BID INFO
  // ============================================================

  Widget _buildBidInfo({
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            title,

            style:
                const TextStyle(
              color:
                  textSecondary,
              fontSize: 9,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            value,

            style:
                TextStyle(
              color: color,
              fontSize: 17,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _divider() {
    return Container(
      height: 1,

      color:
          Colors.white.withValues(
        alpha: 0.07,
      ),
    );
  }

  // ============================================================
  // AUCTION DETAILS
  // ============================================================

  Widget _buildAuctionDetails({
    required double startPrice,
    required String quantity,
    required String unit,
    required String quality,
    required String sellerName,
    required String location,
    required DateTime? endTime,
  }) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        14,
        13,
        14,
        15,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Auction Details',

            style:
                TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          _detailRow(
            'Start Price',
            '₹${startPrice.toStringAsFixed(0)} / kg',
          ),

          const SizedBox(
            height: 12,
          ),

          _detailRow(
            'Quantity',
            '$quantity $unit',
          ),

          const SizedBox(
            height: 12,
          ),

          _detailRow(
            'Quality Grade',
            quality,
          ),

          const SizedBox(
            height: 15,
          ),

          // SELLER

          Row(
            children: [
              Container(
                width: 39,
                height: 39,

                decoration:
                    BoxDecoration(
                  color:
                      orange.withValues(
                    alpha: 0.12,
                  ),

                  shape:
                      BoxShape.circle,
                ),

                child:
                    const Icon(
                  Icons
                      .person_rounded,
                  color: orange,
                  size: 22,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    const Text(
                      'Seller',

                      style:
                          TextStyle(
                        color:
                            textSecondary,
                        fontSize:
                            9,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      sellerName,

                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            10,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      location,

                      maxLines: 1,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          const TextStyle(
                        color:
                            textSecondary,
                        fontSize:
                            8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          _detailRow(
            'Auction Ends',
            endTime == null
                ? 'Not specified'
                : _formatDateTime(
                    endTime,
                  ),
            icon:
                Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    String title,
    String value, {
    IconData? icon,
  }) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: textSecondary,
                  size: 14,
                ),

                const SizedBox(
                  width: 5,
                ),
              ],

              Text(
                title,

                style:
                    const TextStyle(
                  color:
                      textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),

        Text(
          value,

          style:
              const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PLACE BID CARD
  // ============================================================

  Widget _buildPlaceBidCard({
    required String unit,
  }) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.fromLTRB(
        13,
        14,
        13,
        13,
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
              orange.withValues(
            alpha: 0.13,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          // TITLE

          const Text(
            'Place Your Bid',

            style:
                TextStyle(
              color:
                  Colors.white,
              fontSize: 13,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            'Minimum next bid: ₹${(currentBid + 1).toStringAsFixed(0)} / $unit',

            style:
                const TextStyle(
              color:
                  textSecondary,
              fontSize: 9,
            ),
          ),

          const SizedBox(
            height: 13,
          ),

          // BID CONTROL

          Row(
            children: [
              // MINUS

              GestureDetector(
                onTap: () {
                  if (myBid >
                      currentBid + 1) {
                    setState(() {
                      myBid -= 1;
                    });
                  }
                },

                child:
                    _bidControlButton(
                  Icons.remove_rounded,
                ),
              ),

              // AMOUNT

              Expanded(
                child: Container(
                  height: 48,

                  decoration:
                      BoxDecoration(
                    color:
                        background,

                    border:
                        Border.all(
                      color:
                          Colors.white
                              .withValues(
                        alpha: 0.07,
                      ),
                    ),
                  ),

                  child:
                      Center(
                    child:
                        Text(
                      '₹${myBid.toStringAsFixed(0)}',

                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            14,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),

              // PLUS

              GestureDetector(
                onTap: () {
                  setState(() {
                    myBid += 1;
                  });
                },

                child:
                    _bidControlButton(
                  Icons.add_rounded,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // BID NOW

              SizedBox(
                height: 48,
                width: 105,

                child:
                    ElevatedButton(
                  onPressed:
                      _placeBid,

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        orange,

                    foregroundColor:
                        Colors.black,

                    elevation:
                        0,

                    padding:
                        EdgeInsets.zero,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        10,
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
                            .gavel_rounded,
                        size: 15,
                      ),

                      SizedBox(
                        width: 5,
                      ),

                      Text(
                        'Bid Now',

                        style:
                            TextStyle(
                          fontSize:
                              10,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // INFO

          Container(
            width: double.infinity,

            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 10,
              vertical: 9,
            ),

            decoration:
                BoxDecoration(
              color:
                  orange.withValues(
                alpha: 0.08,
              ),

              borderRadius:
                  BorderRadius.circular(
                8,
              ),
            ),

            child: Row(
              children: [
                const Icon(
                  Icons
                      .verified_user_outlined,
                  color: orange,
                  size: 14,
                ),

                const SizedBox(
                  width: 6,
                ),

                const Expanded(
                  child: Text(
                    "You won't be charged until you win the auction.",

                    style:
                        TextStyle(
                      color:
                          orange,
                      fontSize: 8,
                      fontWeight:
                          FontWeight.w500,
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
  // BID CONTROL BUTTON
  // ============================================================

  Widget _bidControlButton(
    IconData icon,
  ) {
    return Container(
      width: 42,
      height: 48,

      decoration:
          BoxDecoration(
        color: background,

        border:
            Border.all(
          color:
              Colors.white
                  .withValues(
            alpha: 0.07,
          ),
        ),

        borderRadius:
            BorderRadius.circular(
          9,
        ),
      ),

      child:
          Icon(
        icon,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  // ============================================================
  // PLACE BID
  // ============================================================

  Future<void> _placeBid() async {
    if (myBid <= currentBid) {
      _showMessage(
        'Your bid must be higher than the current bid.',
      );

      return;
    }

    final String auctionId =
        _string(
      widget.auction['id'],
      '',
    );

    if (auctionId.isEmpty) {
      _showMessage(
        'Auction ID is missing.',
      );

      return;
    }

    try {
      await FirebaseFirestore
          .instance
          .collection('auctions')
          .doc(auctionId)
          .update({
        'highestBid': myBid,
        'currentBid': myBid,
        'bidCount':
            FieldValue.increment(1),
        'lastBidAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        currentBid = myBid;
        myBid = currentBid + 1;
      });

      _showMessage(
        'Bid placed successfully!',
        success: true,
      );
    } catch (e) {
      _showMessage(
        'Unable to place bid. Please try again.',
      );
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,

          style:
              const TextStyle(
            fontSize: 10,
          ),
        ),

        backgroundColor:
            success
                ? green
                : cardLight,

        behavior:
            SnackBarBehavior
                .floating,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            10,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE
  // ============================================================

  String _findProductImage(
    String name,
  ) {
    final value =
        name.toLowerCase();

    if (value.contains('tomato')) {
      return 'assets/products/tomato.png';
    }

    if (value.contains('potato')) {
      return 'assets/products/potato.png';
    }

    if (value.contains('carrot')) {
      return 'assets/products/carrot.png';
    }

    if (value.contains('chilli') ||
        value.contains('chili')) {
      return 'assets/products/chilli.png';
    }

    if (value.contains('daily') ||
        value.contains('dairy')) {
      return 'assets/products/daily.png';
    }

    if (value.contains('grain')) {
      return 'assets/products/grains.png';
    }

    if (value.contains('spice')) {
      return 'assets/products/spices.png';
    }

    if (value.contains('fruit')) {
      return 'assets/products/fruit.png';
    }

    if (value.contains('vegetable')) {
      return 'assets/products/vegetables.png';
    }

    return '';
  }

  // ============================================================
  // REMAINING TIME
  // ============================================================

  String _remainingTime(
    DateTime? endTime,
  ) {
    if (endTime == null) {
      return 'Time not set';
    }

    final Duration remaining =
        endTime.difference(
      DateTime.now(),
    );

    if (remaining.isNegative) {
      return 'Auction ended';
    }

    final int hours =
        remaining.inHours;

    final int minutes =
        remaining.inMinutes
            .remainder(60);

    final int seconds =
        remaining.inSeconds
            .remainder(60);

    return '${hours.toString().padLeft(2, '0')}h '
        '${minutes.toString().padLeft(2, '0')}m '
        '${seconds.toString().padLeft(2, '0')}s left';
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDateTime(
    DateTime date,
  ) {
    final int hour =
        date.hour % 12 == 0
            ? 12
            : date.hour % 12;

    final String minute =
        date.minute
            .toString()
            .padLeft(
          2,
          '0',
        );

    final String period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return 'Today, '
        '$hour:$minute $period';
  }

  // ============================================================
  // FIREBASE DATE
  // ============================================================

  DateTime? _toDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // ============================================================
  // STRING
  // ============================================================

  String _string(
    dynamic value,
    String fallback,
  ) {
    if (value == null) {
      return fallback;
    }

    final String result =
        value.toString().trim();

    if (result.isEmpty) {
      return fallback;
    }

    return result;
  }

  // ============================================================
  // NUMBER
  // ============================================================

  double _number(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // INT
  // ============================================================

  int _int(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}