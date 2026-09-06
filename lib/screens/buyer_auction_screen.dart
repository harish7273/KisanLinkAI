import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'buyer_auction_details_screen.dart';

class BuyerAuctionScreen extends StatefulWidget {
  const BuyerAuctionScreen({
    super.key,
  });

  @override
  State<BuyerAuctionScreen> createState() =>
      _BuyerAuctionScreenState();
}

class _BuyerAuctionScreenState
    extends State<BuyerAuctionScreen> {
  // ============================================================
  // VIDHAI COLORS
  // ============================================================

  static const Color orange =
      Color(0xFFFF9800);

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
  // FIREBASE
  // ============================================================

  final CollectionReference<
          Map<String, dynamic>>
      _auctionCollection =
      FirebaseFirestore.instance
          .collection('auctions');

  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController
      _searchController =
      TextEditingController();

  String _searchQuery = '';

  // ============================================================
  // TAB
  // ============================================================

  int _selectedTab = 0;

  final List<String> _tabs = [
    'All Auctions',
    'Live Now',
    'Upcoming',
    'Ending Soon',
  ];

  // ============================================================
  // TIMER
  // ============================================================

  Timer? _refreshTimer;

  // ============================================================
  // PRODUCT ASSETS
  // ============================================================

  final Map<String, String>
      _productImages = {
    'tomato':
        'assets/products/tomato.png',
    'tomatoes':
        'assets/products/tomato.png',

    'fresh tomato':
        'assets/products/tomato.png',
    'fresh tomatoes':
        'assets/products/tomato.png',

    'potato':
        'assets/products/potato.png',
    'potatoes':
        'assets/products/potato.png',
    'farm potatoes':
        'assets/products/potato.png',

    'carrot':
        'assets/products/carrot.png',
    'carrots':
        'assets/products/carrot.png',

    'chilli':
        'assets/products/chilli.png',
    'chili':
        'assets/products/chilli.png',
    'green chilli':
        'assets/products/chilli.png',
    'green chillies':
        'assets/products/chilli.png',

    'fruit':
        'assets/products/fruit.png',
    'fruits':
        'assets/products/fruit.png',

    'grain':
        'assets/products/grains.png',
    'grains':
        'assets/products/grains.png',

    'spice':
        'assets/products/spices.png',
    'spices':
        'assets/products/spices.png',

    'dairy':
        'assets/products/daily.png',
    'daily':
        'assets/products/daily.png',

    'vegetable':
        'assets/products/vegetables.png',
    'vegetables':
        'assets/products/vegetables.png',
  };

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _onSearchChanged,
    );

    _refreshTimer =
        Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  // ============================================================
  // SEARCH CHANGE
  // ============================================================

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {
      _searchQuery =
          _searchController.text
              .trim()
              .toLowerCase();
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          background,

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            _buildSearchBar(),

            _buildTabs(),

            Expanded(
              child:
                  _buildAuctionStream(),
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
      padding:
          const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        12,
      ),

      child: Row(
        children: [
          // BACK BUTTON
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },

            child: Container(
              width: 42,
              height: 42,

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

          // TITLE
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  'Auctions',

                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                SizedBox(
                  height: 2,
                ),

                Text(
                  'Bid and get the best farm products',

                  style:
                      TextStyle(
                    color:
                        textSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          // GAVEL
          Container(
            width: 43,
            height: 43,

            decoration:
                BoxDecoration(
              color:
                  orange.withValues(
                alpha: 0.12,
              ),

              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),

            child:
                const Icon(
              Icons.gavel_rounded,
              color: orange,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),

      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 47,

              decoration:
                  BoxDecoration(
                color: card,

                borderRadius:
                    BorderRadius.circular(
                  14,
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

              child: TextField(
                controller:
                    _searchController,

                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 12,
                ),

                decoration:
                    const InputDecoration(
                  prefixIcon:
                      Icon(
                    Icons
                        .search_rounded,
                    color:
                        Colors.white54,
                    size: 21,
                  ),

                  hintText:
                      'Search auctions...',

                  hintStyle:
                      TextStyle(
                    color:
                        Colors.white38,
                    fontSize: 11,
                  ),

                  border:
                      InputBorder.none,

                  contentPadding:
                      EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Container(
            width: 47,
            height: 47,

            decoration:
                BoxDecoration(
              color: card,

              borderRadius:
                  BorderRadius.circular(
                14,
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

            child:
                const Icon(
              Icons.tune_rounded,
              color: orange,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return SizedBox(
      height: 50,

      child:
          ListView.separated(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          5,
        ),

        scrollDirection:
            Axis.horizontal,

        itemCount:
            _tabs.length,

        separatorBuilder:
            (_, __) =>
                const SizedBox(
          width: 8,
        ),

        itemBuilder:
            (context, index) {
          final bool selected =
              _selectedTab ==
                  index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTab =
                    index;
              });
            },

            child:
                AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 180,
              ),

              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 14,
              ),

              decoration:
                  BoxDecoration(
                color: selected
                    ? orange
                    : card,

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),

                border:
                    Border.all(
                  color: selected
                      ? orange
                      : Colors.white
                          .withValues(
                          alpha: 0.07,
                        ),
                ),
              ),

              child:
                  Center(
                child: Text(
                  _tabs[index],

                  style:
                      TextStyle(
                    color: selected
                        ? Colors.black
                        : Colors.white70,

                    fontSize: 9,

                    fontWeight:
                        selected
                            ? FontWeight.w800
                            : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // FIREBASE AUCTION STREAM
  // ============================================================

  Widget _buildAuctionStream() {
    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream:
          _auctionCollection
              .snapshots(),

      builder:
          (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(
              color: orange,
              strokeWidth: 2,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildError();
        }

        final List<
                Map<String, dynamic>>
            auctions = [];

        for (final doc
            in snapshot.data?.docs ??
                []) {
          final Map<String, dynamic>
              data = doc.data();

          final auction =
              <String, dynamic>{
            'id': doc.id,
            ...data,
          };

          if (_matchesSearch(
                auction,
              ) &&
              _matchesTab(
                auction,
              )) {
            auctions.add(
              auction,
            );
          }
        }

        final liveAuctions =
            auctions.where(
          (auction) =>
              _getStatus(
                auction,
              ) ==
              'live',
        ).toList();

        final upcomingAuctions =
            auctions.where(
          (auction) =>
              _getStatus(
                auction,
              ) ==
              'upcoming',
        ).toList();

        // --------------------------------------------------------
        // EMPTY
        // --------------------------------------------------------

        if (liveAuctions.isEmpty &&
            upcomingAuctions.isEmpty) {
          return _buildEmpty();
        }

        return ListView(
          physics:
              const BouncingScrollPhysics(),

          padding:
              const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            30,
          ),

          children: [
            // ====================================================
            // LIVE
            // ====================================================

            if (liveAuctions
                .isNotEmpty) ...[
              _buildSectionHeader(
                'Live Auctions',
                liveAuctions.length,
                true,
              ),

              const SizedBox(
                height: 10,
              ),

              ...liveAuctions.map(
                _buildLiveAuctionCard,
              ),
            ],

            // ====================================================
            // UPCOMING
            // ====================================================

            if (upcomingAuctions
                .isNotEmpty) ...[
              const SizedBox(
                height: 12,
              ),

              _buildSectionHeader(
                'Upcoming Auctions',
                upcomingAuctions.length,
                false,
              ),

              const SizedBox(
                height: 10,
              ),

              ...upcomingAuctions.map(
                _buildUpcomingAuctionCard,
              ),
            ],
          ],
        );
      },
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(
    String title,
    int count,
    bool live,
  ) {
    return Row(
      children: [
        if (live)
          Container(
            width: 7,
            height: 7,

            margin:
                const EdgeInsets.only(
              right: 7,
            ),

            decoration:
                const BoxDecoration(
              color: orange,
              shape:
                  BoxShape.circle,
            ),
          ),

        Text(
          title,

          style:
              const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        const SizedBox(
          width: 7,
        ),

        Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 7,
            vertical: 3,
          ),

          decoration:
              BoxDecoration(
            color:
                orange.withValues(
              alpha: 0.12,
            ),

            borderRadius:
                BorderRadius.circular(
              8,
            ),
          ),

          child:
              Text(
            '$count',

            style:
                const TextStyle(
              color: orange,
              fontSize: 8,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LIVE AUCTION CARD
  // ============================================================

  Widget _buildLiveAuctionCard(
    Map<String, dynamic> auction,
  ) {
    final String name =
        _string(
      auction['productName'],
      'Fresh Product',
    );

    final String quantity =
        _string(
      auction['quantity'],
      '0',
    );

    final String unit =
        _string(
      auction['unit'],
      'kg',
    );

    final String quality =
        _string(
      auction['quality'],
      'Premium Quality',
    );

    final double currentBid =
        _number(
      auction['highestBid'] ??
          auction['currentBid'] ??
          auction['startPrice'],
    );

    final int bidCount =
        _int(
      auction['bidCount'],
    );

    final DateTime? endTime =
        _toDate(
      auction['endTime'],
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                BuyerAuctionDetailsScreen(
              auction: auction,
            ),
          ),
        );
      },

      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 11,
        ),

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
                orange.withValues(
              alpha: 0.15,
            ),
          ),
        ),

        child: Column(
          children: [
            // ==================================================
            // ORANGE TOP LINE
            // ==================================================

            Container(
              height: 3,

              decoration:
                  const BoxDecoration(
                color: orange,

                borderRadius:
                    BorderRadius.vertical(
                  top:
                      Radius.circular(
                    18,
                  ),
                ),
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.all(
                10,
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  // ==============================================
                  // IMAGE
                  // ==============================================

                  _buildProductImage(
                    auction,
                    width: 92,
                    height: 112,
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  // ==============================================
                  // DETAILS
                  // ==============================================

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Row(
                          children: [
                            Expanded(
                              child:
                                  Text(
                                name,

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
                                      15,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ),

                            _liveBadge(),
                          ],
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          '$quantity $unit  •  $quality',

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

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

                        const Text(
                          'CURRENT BID',

                          style:
                              TextStyle(
                            color:
                                textSecondary,
                            fontSize:
                                8,
                            fontWeight:
                                FontWeight.w600,
                            letterSpacing:
                                0.4,
                          ),
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        Text(
                          '₹${currentBid.toStringAsFixed(0)} / $unit',

                          style:
                              const TextStyle(
                            color:
                                orange,
                            fontSize:
                                18,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .people_outline_rounded,
                              color:
                                  textSecondary,
                              size: 13,
                            ),

                            const SizedBox(
                              width: 4,
                            ),

                            Text(
                              '$bidCount bids',

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
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // BOTTOM
            // ==================================================

            Container(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                12,
                8,
                12,
                10,
              ),

              child: Row(
                children: [
                  Expanded(
                    child:
                        _buildTimeWidget(
                      endTime,
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  SizedBox(
                    height: 38,

                    child:
                        ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BuyerAuctionDetailsScreen(
                              auction:
                                  auction,
                            ),
                          ),
                        );
                      },

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            orange,

                        foregroundColor:
                            Colors.black,

                        elevation: 0,

                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              16,
                        ),

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
                        mainAxisSize:
                            MainAxisSize.min,

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
                            'View Auction',

                            style:
                                TextStyle(
                              fontSize:
                                  9,
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
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UPCOMING AUCTION CARD
  // ============================================================

  Widget _buildUpcomingAuctionCard(
    Map<String, dynamic> auction,
  ) {
    final String name =
        _string(
      auction['productName'],
      'Fresh Product',
    );

    final String quantity =
        _string(
      auction['quantity'],
      '0',
    );

    final String unit =
        _string(
      auction['unit'],
      'kg',
    );

    final String quality =
        _string(
      auction['quality'],
      'Premium Quality',
    );

    final double startPrice =
        _number(
      auction['startPrice'],
    );

    final DateTime? startTime =
        _toDate(
      auction['startTime'],
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                BuyerAuctionDetailsScreen(
              auction: auction,
            ),
          ),
        );
      },

      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 11,
        ),

        padding:
            const EdgeInsets.all(
          10,
        ),

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
                Colors.white.withValues(
              alpha: 0.07,
            ),
          ),
        ),

        child: Row(
          children: [
            // IMAGE

            _buildProductImage(
              auction,
              width: 82,
              height: 95,
            ),

            const SizedBox(
              width: 11,
            ),

            // DETAILS

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

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
                            color:
                                Colors.white,
                            fontSize: 14,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),

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
                            alpha: 0.12,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            7,
                          ),
                        ),

                        child:
                            const Text(
                          'UPCOMING',

                          style:
                              TextStyle(
                            color:
                                orange,
                            fontSize:
                                6.5,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    '$quantity $unit  •  $quality',

                    style:
                        const TextStyle(
                      color:
                          textSecondary,
                      fontSize: 8,
                    ),
                  ),

                  const SizedBox(
                    height: 9,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .calendar_today_outlined,
                        color: orange,
                        size: 13,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Expanded(
                        child:
                            Text(
                          startTime == null
                              ? 'Starting soon'
                              : _formatDateTime(
                                  startTime,
                                ),

                          style:
                              const TextStyle(
                            color:
                                Colors.white70,
                            fontSize: 8,
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
                      const Text(
                        'Starting at ',

                        style:
                            TextStyle(
                          color:
                              textSecondary,
                          fontSize: 8,
                        ),
                      ),

                      Text(
                        '₹${startPrice.toStringAsFixed(0)} / $unit',

                        style:
                            const TextStyle(
                          color:
                              orange,
                          fontSize: 10,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LIVE BADGE
  // ============================================================

  Widget _liveBadge() {
    return Container(
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
          alpha: 0.12,
        ),

        borderRadius:
            BorderRadius.circular(
          7,
        ),

        border:
            Border.all(
          color:
              orange.withValues(
            alpha: 0.25,
          ),
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Container(
            width: 5,
            height: 5,

            decoration:
                const BoxDecoration(
              color: orange,
              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          const Text(
            'LIVE',

            style:
                TextStyle(
              color: orange,
              fontSize: 7,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIME
  // ============================================================

  Widget _buildTimeWidget(
    DateTime? endTime,
  ) {
    if (endTime == null) {
      return const Row(
        children: [
          Icon(
            Icons
                .access_time_rounded,
            color:
                textSecondary,
            size: 15,
          ),

          SizedBox(
            width: 5,
          ),

          Text(
            'Live auction',

            style:
                TextStyle(
              color:
                  textSecondary,
              fontSize: 8,
            ),
          ),
        ],
      );
    }

    final Duration remaining =
        endTime.difference(
      DateTime.now(),
    );

    if (remaining.isNegative) {
      return const Row(
        children: [
          Icon(
            Icons
                .access_time_rounded,
            color: red,
            size: 15,
          ),

          SizedBox(
            width: 5,
          ),

          Text(
            'Auction ended',

            style:
                TextStyle(
              color: red,
              fontSize: 8,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final int hours =
        remaining.inHours;

    final int minutes =
        remaining.inMinutes
            .remainder(60);

    return Row(
      children: [
        const Icon(
          Icons
              .access_time_rounded,
          color: orange,
          size: 15,
        ),

        const SizedBox(
          width: 5,
        ),

        Text(
          hours > 0
              ? '${hours}h ${minutes}m left'
              : '${minutes}m left',

          style:
              const TextStyle(
            color: orange,
            fontSize: 9,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildProductImage(
    Map<String, dynamic> auction, {
    required double width,
    required double height,
  }) {
    String imageAsset =
        _string(
      auction['imageAsset'],
      '',
    );

    if (imageAsset.isEmpty) {
      final String name =
          _string(
        auction['productName'],
        '',
      ).toLowerCase();

      imageAsset =
          _productImages[name] ??
              _findProductImage(name);
    }

    if (imageAsset.isEmpty) {
      return _imagePlaceholder(
        width,
        height,
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        13,
      ),

      child: Image.asset(
        imageAsset,

        width: width,
        height: height,

        fit: BoxFit.cover,

        errorBuilder:
            (
          context,
          error,
          stackTrace,
        ) {
          return _imagePlaceholder(
            width,
            height,
          );
        },
      ),
    );
  }

  // ============================================================
  // FIND IMAGE
  // ============================================================

  String _findProductImage(
    String name,
  ) {
    if (name.contains('tomato')) {
      return 'assets/products/tomato.png';
    }

    if (name.contains('potato')) {
      return 'assets/products/potato.png';
    }

    if (name.contains('carrot')) {
      return 'assets/products/carrot.png';
    }

    if (name.contains('chilli') ||
        name.contains('chili')) {
      return 'assets/products/chilli.png';
    }

    if (name.contains('fruit')) {
      return 'assets/products/fruit.png';
    }

    if (name.contains('grain')) {
      return 'assets/products/grains.png';
    }

    if (name.contains('spice')) {
      return 'assets/products/spices.png';
    }

    if (name.contains('dairy') ||
        name.contains('daily')) {
      return 'assets/products/daily.png';
    }

    if (name.contains('vegetable')) {
      return 'assets/products/vegetables.png';
    }

    return '';
  }

  // ============================================================
  // PLACEHOLDER
  // ============================================================

  Widget _imagePlaceholder(
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,

      decoration:
          BoxDecoration(
        color: cardLight,

        borderRadius:
            BorderRadius.circular(
          13,
        ),
      ),

      child:
          const Icon(
        Icons
            .agriculture_rounded,
        color: orange,
        size: 30,
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _getStatus(
    Map<String, dynamic> auction,
  ) {
    final DateTime now =
        DateTime.now();

    final DateTime? start =
        _toDate(
      auction['startTime'],
    );

    final DateTime? end =
        _toDate(
      auction['endTime'],
    );

    if (end != null &&
        now.isAfter(end)) {
      return 'ended';
    }

    if (start != null &&
        now.isBefore(start)) {
      return 'upcoming';
    }

    return 'live';
  }

  // ============================================================
  // TAB FILTER
  // ============================================================

  bool _matchesTab(
    Map<String, dynamic> auction,
  ) {
    final status =
        _getStatus(
      auction,
    );

    switch (_selectedTab) {
      case 0:
        return status == 'live' ||
            status == 'upcoming';

      case 1:
        return status == 'live';

      case 2:
        return status == 'upcoming';

      case 3:
        return _isEndingSoon(
          auction,
        );

      default:
        return true;
    }
  }

  // ============================================================
  // SEARCH FILTER
  // ============================================================

  bool _matchesSearch(
    Map<String, dynamic> auction,
  ) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final name =
        _string(
      auction['productName'],
      '',
    ).toLowerCase();

    final category =
        _string(
      auction['category'],
      '',
    ).toLowerCase();

    return name.contains(
          _searchQuery,
        ) ||
        category.contains(
          _searchQuery,
        );
  }

  // ============================================================
  // ENDING SOON
  // ============================================================

  bool _isEndingSoon(
    Map<String, dynamic> auction,
  ) {
    if (_getStatus(auction) !=
        'live') {
      return false;
    }

    final DateTime? end =
        _toDate(
      auction['endTime'],
    );

    if (end == null) {
      return false;
    }

    final Duration remaining =
        end.difference(
      DateTime.now(),
    );

    return remaining.inHours < 3;
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          30,
        ),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 80,
              height: 80,

              decoration:
                  BoxDecoration(
                color:
                    orange.withValues(
                  alpha: 0.10,
                ),

                shape:
                    BoxShape.circle,
              ),

              child:
                  const Icon(
                Icons.gavel_rounded,
                color: orange,
                size: 37,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'No Auctions Available',

              style:
                  TextStyle(
                color:
                    Colors.white,
                fontSize: 17,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            const Text(
              'There are no auctions matching your selection right now.',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    textSecondary,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          30,
        ),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              color: red,
              size: 45,
            ),

            const SizedBox(
              height: 13,
            ),

            const Text(
              'Unable to load auctions',

              style:
                  TextStyle(
                color:
                    Colors.white,
                fontSize: 16,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {});
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    orange,

                foregroundColor:
                    Colors.black,

                elevation: 0,
              ),

              child:
                  const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
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

    return '${date.day}/${date.month} '
        '$hour:$minute $period';
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

    final result =
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
  // INTEGER
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